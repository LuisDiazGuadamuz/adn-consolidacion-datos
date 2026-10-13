# -*- coding: utf-8 -*-
"""Venta en línea (ADNPayV2, orden 600), flota (Navsat, orden 700) e históricos (History_Tables y Trengo, orden 800).

Venta en línea: la solicitud (ADNPayV2.Customer) es el centro; pagos, reservas, órdenes y aprovisionamiento se ligan a
ella por su índice. El cliente se toma de la tabla de correspondencia (ADNPayV2) o, si no, por cédula (ID-02).
Flota: las unidades se derivan de todas las tablas de Navsat y se clasifican por tipo (ES-09): vehículo de la empresa
(placa), vehículo propio ('Vehiculo Propio') o colaborador (nombre de persona). Solo las tablas base que mapea la matriz;
las variantes _v2 y _historico no están en la matriz aprobada.
Históricos (D12): Trengo y conexiones se cargan como fuentes históricas. Trengo se liga al contacto solo por ID_ZCRM
(ID-09); nunca por teléfono (ID-05, sin excepción).
"""
from ..auto import paso_matriz
from ..paso import Anomalia, Paso

_P = "ADNPayV2"
_N = "Navsat"
_H = "HistoryTables"


def _huella(alias, cols, fechas=()):
    """Llave de origen para tablas sin id: SHA-256 de las columnas que identifican la fila. Las fechas van en ISO
    completo (con segundos); la conversión por defecto de datetime los perdería."""
    def v(c):
        return f"CONVERT(nvarchar(30), {alias}.[{c}], 126)" if c in fechas else f"CONVERT(nvarchar(4000), {alias}.[{c}])"
    return ("CONVERT(nvarchar(66), HASHBYTES('SHA2_256', CONCAT_WS(N'|', "
            + ", ".join(f"ISNULL({v(c)}, N'~')" for c in cols) + ")), 2)")


def _producto_adnpay(tabla, x):
    return (f"(SELECT MIN(pr.ProductoId) FROM core.Producto pr WHERE pr.FuenteBase = N'ADNPayV2' "
            f"AND pr.FuenteTabla = N'{tabla}' AND pr.FuenteLlave = CAST({x} AS nvarchar(200)))")


def _orden_adnpay(tabla, x):
    return (f"(SELECT MIN(o.OrdenEnLineaId) FROM core.OrdenEnLinea o WHERE o.FuenteBase = N'ADNPayV2' "
            f"AND o.FuenteTabla = N'{tabla}' AND o.FuenteLlave = CAST({x} AS nvarchar(200)))")


# Período en hora de Costa Rica (las fechas de Navsat son datetimeoffset -06:00; @Hasta es exclusivo)
_PERIODO_CR = ("(@Desde IS NULL OR {x} >= TODATETIMEOFFSET(CAST(@Desde AS datetime2), '-06:00')) "
               "AND (@Hasta IS NULL OR {x} < TODATETIMEOFFSET(CAST(@Hasta AS datetime2), '-06:00'))")
_MIN_A_SEG = "DATEDIFF(SECOND, CAST('00:00:00' AS time), {x})"

PASOS = [
    # ------------------------------------------------------------------ venta en línea
    paso_matriz("core_SolicitudEnLinea", 600, "core.SolicitudEnLinea", _P, "ADNPayV2", "Customer", "c", llave="index",
                override={"ClienteId": "COALESCE(co.ClienteId, cl.ClienteId)",
                          "ProductoId": _producto_adnpay("Service", "c.[plan]"),
                          "Latitud": "COALESCE(ctl.fn_Coordenada(c.coordinates, 1), ctl.fn_Coordenada(c.coordinate, 1))",
                          "Longitud": "COALESCE(ctl.fn_Coordenada(c.coordinates, 2), ctl.fn_Coordenada(c.coordinate, 2))",
                          "IPTVAdicionales": "COALESCE(c.extra_iptv, TRY_CONVERT(int, ctl.fn_PrimerNumero(c.additional_iptv)))",
                          "CodigoPromocion": "COALESCE(ctl.fn_Texto(c.promotion_code), ctl.fn_Texto(c.promcode))"},
                extra_from="""OUTER APPLY (SELECT MIN(o.ClienteId) AS ClienteId FROM core.ClienteOrigen o
             WHERE o.Sistema = 'ADNPayV2' AND o.LlaveOrigen = CAST(c.[index] AS nvarchar(200))) co
LEFT JOIN core.Cliente cl ON cl.FuenteTabla = N'Cedula' AND cl.FuenteLlave = ctl.fn_Cedula(c.id)""",
                moneda="'CRC'", fecha_tc="CAST(q.FechaSolicitud AS date)",
                depende=["core_ClienteOrigen", "core_Producto_ADNPayServicio"],
                descripcion="Solicitudes de contratación en línea (ADNPayV2.Customer). Cliente por la tabla de correspondencia "
                            "o por cédula (ID-02); plan por el catálogo de servicios de ADNPayV2. Montos en colones."),
    paso_matriz("core_PagoEnLinea", 601, "core.PagoEnLinea", _P, "ADNPayV2", "OnvoCheckoutSession", "s", llave="session_index",
                fecha_tc="CAST(q.FechaCreacion AS date)", depende=["core_SolicitudEnLinea"],
                descripcion="Sesiones de pago de la pasarela Onvo."),
    paso_matriz("core_Reserva_Visita", 602, "core.ReservaInstalacion", _P, "ADNPayV2", "Visitdate", "v", llave="id",
                depende=["core_SolicitudEnLinea"], descripcion="Fechas de visita (tabla anterior Visitdate)."),
    paso_matriz("core_Reserva_Servicio", 603, "core.ReservaInstalacion", _P, "ADNPayV2", "ServiceReservations", "r",
                llave="reservation_id", depende=["core_SolicitudEnLinea"], descripcion="Reservas de instalación."),
    paso_matriz("core_OrdenEnLinea_Venta", 604, "core.OrdenEnLinea", _P, "ADNPayV2", "SaleOrder", "o", llave="order_id",
                override={"Tipo": "'VENTA'"}, moneda="'CRC'", fecha_tc="CAST(q.Fecha AS date)",
                depende=["core_SolicitudEnLinea"], descripcion="Órdenes de venta en línea (Tipo = VENTA), en colones."),
    paso_matriz("core_OrdenEnLinea_Carrito", 605, "core.OrdenEnLinea", _P, "ADNPayV2", "Cart", "k", llave="cart_id",
                override={"Tipo": "'CARRITO'"}, moneda="'CRC'", fecha_tc="CAST(q.Fecha AS date)",
                fecha_dato="ctl.fn_FechaCR(CONVERT(nvarchar(30), k.updated_at, 126))",
                depende=["core_SolicitudEnLinea"], descripcion="Carritos de compra (Tipo = CARRITO), en colones."),
    paso_matriz("core_OrdenEnLineaLinea_Venta", 606, "core.OrdenEnLineaLinea", _P, "ADNPayV2", "SaleOrderLine", "l", llave="line_id",
                override={"OrdenEnLineaId": _orden_adnpay("SaleOrder", "l.order_id"),
                          "ProductoId": _producto_adnpay("Product", "l.product_id")},
                moneda="'CRC'", depende=["core_OrdenEnLinea_Venta", "core_Producto_ADNPayProducto"],
                descripcion="Líneas de las órdenes de venta en línea. Sin orden → descarte IN-01."),
    paso_matriz("core_OrdenEnLineaLinea_Carrito", 607, "core.OrdenEnLineaLinea", _P, "ADNPayV2", "CartLine", "l", llave="line_id",
                override={"OrdenEnLineaId": _orden_adnpay("Cart", "l.cart_id"),
                          "ProductoId": _producto_adnpay("Product", "l.product_id")},
                moneda="'CRC'", depende=["core_OrdenEnLinea_Carrito", "core_Producto_ADNPayProducto"],
                descripcion="Líneas de los carritos. Sin carrito → descarte IN-01."),
    paso_matriz("core_AprovisionamientoOdoo", 608, "core.AprovisionamientoOdoo", _P, "ADNPayV2", "OdooProvisioning", "a",
                llave="id", depende=["core_SolicitudEnLinea"],
                descripcion="Aprovisionamiento en Odoo de las ventas en línea; el circuito se normaliza (ID-01)."),

    # ------------------------------------------------------------------ flota
    Paso(
        nombre="ref_UnidadFlota", orden=700, destino="ref.UnidadFlota",
        fuente=(_N, "SQLServer", "Navsat", "Ultima_ubicacion"), llave_origen="",
        descripcion="Unidades de flota derivadas de todas las tablas de Navsat (una por dispositivo, con la placa más "
                    "reciente). Clasificación ES-09: placa → VEHICULO_EMPRESA; 'propio' → VEHICULO_PROPIO; otro texto → COLABORADOR.",
        reglas=["ES-05", "ES-09", "IN-05", "DD-04"], columnas=["Dispositivo", "Placa", "TipoUnidad", "Descripcion"],
        dedup_orden="s.FuenteLlave",
        select="""
SELECT 'Navsat' AS FuenteSistema, N'Navsat' AS FuenteBase, N'Dispositivo' AS FuenteTabla, u.Dispositivo AS FuenteLlave,
       CAST(NULL AS datetimeoffset(0)) AS FechaDato, u.Dispositivo,
       CASE WHEN t.Tipo = 'VEHICULO_EMPRESA' THEN p.PlacaNorm END AS Placa, t.Tipo AS TipoUnidad, u.Texto AS Descripcion
FROM (
    SELECT Dispositivo, Texto, ROW_NUMBER() OVER (PARTITION BY Dispositivo ORDER BY Fecha DESC, Texto) AS rn FROM (
        SELECT CAST(ctl.fn_Texto(deviceName) AS nvarchar(100)) AS Dispositivo, ctl.fn_Texto(plateNumber) AS Texto, ctl.fn_FechaCR(crDateTime) AS Fecha FROM Navsat.dbo.Ultima_ubicacion
        UNION ALL SELECT CAST(ctl.fn_Texto(DeviceName) AS nvarchar(100)), ctl.fn_Texto(PlateNumber), TODATETIMEOFFSET(FechaInicio, '-06:00') FROM Navsat.dbo.viajes_ayer_finalizado
        UNION ALL SELECT CAST(ctl.fn_Texto(dispositivo) AS nvarchar(100)), ctl.fn_Texto(placa), TODATETIMEOFFSET(fecha, '-06:00') FROM Navsat.dbo.eventos
        UNION ALL SELECT CAST(ctl.fn_Texto(dispositivo) AS nvarchar(100)), ctl.fn_Texto(placa_vehiculo), TODATETIMEOFFSET(fecha_hora_incidente, '-06:00') FROM Navsat.dbo.Eco_Driving
    ) x WHERE Dispositivo IS NOT NULL) u
CROSS APPLY (SELECT UPPER(REPLACE(REPLACE(u.Texto, N'-', N''), N' ', N'')) AS PlacaNorm) p
CROSS APPLY (SELECT CASE WHEN u.Texto LIKE N'%propio%' THEN 'VEHICULO_PROPIO'
                         WHEN p.PlacaNorm COLLATE Latin1_General_BIN LIKE '[A-Z][A-Z][A-Z][0-9][0-9][0-9]'
                           OR p.PlacaNorm LIKE '[0-9][0-9][0-9][0-9][0-9][0-9]'
                           OR p.PlacaNorm LIKE '[0-9][0-9][0-9][0-9][0-9]'
                           OR p.PlacaNorm COLLATE Latin1_General_BIN LIKE '[A-Z][A-Z][0-9]%' AND LEN(p.PlacaNorm) <= 8 THEN 'VEHICULO_EMPRESA'
                         ELSE 'COLABORADOR' END AS Tipo) t
WHERE u.rn = 1
"""),
    paso_matriz("core_UbicacionFlota", 701, "core.UbicacionFlota", _N, "Navsat", "Ultima_ubicacion", "u",
                llave_expr=_huella("u", ["deviceName", "crDateTime", "latitude", "longitude"]),
                where=_PERIODO_CR.format(x="ctl.fn_FechaCR(u.crDateTime)"),
                requiere_periodo=True, depende=["ref_UnidadFlota"], reglas_extra=("DD-01",),
                descripcion="Posiciones reportadas por las unidades (sin llave en el origen: huella de dispositivo, fecha y coordenadas). "
                            "2,5 millones de filas: se carga por período (--desde/--hasta, hasta exclusivo)."),
    paso_matriz("core_ViajeFlota", 702, "core.ViajeFlota", _N, "Navsat", "viajes_ayer_finalizado", "v", llave="",
                # Id viene nulo en las 227.352 filas (IN-05 del perfilado): la llave es la huella del viaje
                llave_expr=_huella("v", ["DeviceName", "FechaInicio", "FechaFin", "KilometrosRecorridos"],
                                   fechas=("FechaInicio", "FechaFin")),
                override={"DuracionMinutos": "CAST(" + _MIN_A_SEG.format(x="v.Duracion") + " / 60.0 AS decimal(12,2))"},
                depende=["ref_UnidadFlota"], reglas_extra=("DD-01",),
                descripcion="Viajes finalizados de las unidades; la duración (time) se pasa a minutos. Id viene nulo en el "
                            "origen (IN-05): la llave es la huella de dispositivo, inicio, fin y kilómetros."),
    paso_matriz("core_EventoFlota", 703, "core.EventoFlota", _N, "Navsat", "eventos", "e",
                llave_expr=_huella("e", ["dispositivo", "fecha", "evento", "regla", "latitude", "longitude"], fechas=("fecha",)),
                depende=["ref_UnidadFlota"], reglas_extra=("DD-01",),
                descripcion="Eventos de las unidades (sin llave en el origen: huella de dispositivo, fecha, evento y posición)."),
    paso_matriz("core_IncidenteConduccion", 704, "core.IncidenteConduccion", _N, "Navsat", "Eco_Driving", "d",
                llave_expr=_huella("d", ["dispositivo", "fecha_hora_incidente", "id_evento", "tipo_incidente"], fechas=("fecha_hora_incidente",)),
                override={"DuracionSegundos": _MIN_A_SEG.format(x="d.duracion")},
                depende=["ref_UnidadFlota"], reglas_extra=("DD-01",),
                descripcion="Incidentes de conducción (eco driving); la duración (time) se pasa a segundos."),

    # ------------------------------------------------------------------ históricos (D12)
    paso_matriz("core_CheckInCampo", 800, "core.CheckInCampo", _H, "History_Tables", "check_in_navsat", "c", llave="Id",
                descripcion="Registros de visita en campo de los colaboradores (History_Tables)."),
    paso_matriz("core_EventoConexion", 801, "core.EventoConexion", _H, "History_Tables", "Conexiones_desconexiones_realizadas", "x",
                llave_expr=_huella("x", ["customer_name", "type", "date", "realized_by", "type_desc_rec", "date_desc_rec"],
                                    fechas=("date", "date_desc_rec")),
                override={"ContactoBooksId": "ctl.fn_Texto(x.customer_name)", "ClienteId": "co.ClienteId",
                          "o_FechaDesc": "CASE WHEN x.date_desc_rec IS NOT NULL THEN CONVERT(nvarchar(30), x.date_desc_rec, 126) END"},
                extra_from="""OUTER APPLY (SELECT CASE WHEN COUNT(DISTINCT o.ClienteId) = 1 THEN MIN(o.ClienteId) END AS ClienteId
             FROM core.ClienteOrigen o WHERE o.Sistema = 'ZohoBooks' AND o.LlaveOrigen = ctl.fn_Texto(x.customer_name)) co""",
                auxiliares_extra=["o_FechaDesc"],
                anomalias_extra=[Anomalia("ES-02", "FechaDesconexionReconexion", "s.o_FechaDesc",
                                          "s.o_FechaDesc IS NOT NULL AND s.FechaDesconexionReconexion IS NULL",
                                          "Fecha de desconexión/reconexión ficticia o fuera de rango")],
                depende=["core_ClienteOrigen"], reglas_extra=("D12", "ID-04", "DD-01"),
                descripcion="Conexiones y desconexiones realizadas (histórico, D12). customer_name es el id del contacto de "
                            "Books: el cliente se liga por la tabla de correspondencia (ID-04). Sin llave: huella de la fila."),
    paso_matriz("core_TicketAtencion", 802, "core.TicketAtencion", "Trengo", "ZCRM2Trengo", "trengo_data_tickets", "t",
                llave="id_case",
                override={"ContactoId": "ct.ContactoId", "ServicioId": "ct.ServicioId",
                          "o_IdZcrm": "z.IdZcrm"},
                extra_from="""CROSS APPLY (SELECT CONVERT(nvarchar(max), t.custom_data) COLLATE DATABASE_DEFAULT AS cd) d0
CROSS APPLY (SELECT CASE WHEN CHARINDEX(N'ID_ZCRM', d0.cd) > 0 THEN
                    NULLIF(LEFT(LTRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(d0.cd, CHARINDEX(N'ID_ZCRM', d0.cd) + 7, 60), N'''', N''), N'"', N''), N':', N'')), 19), N'')
                END COLLATE DATABASE_DEFAULT AS IdZcrm) z
OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(k.ContactoId) END AS ContactoId,
                    CASE WHEN COUNT(*) = 1 THEN MIN(k.ServicioId) END AS ServicioId
             FROM core.Contacto k WHERE k.ContactoCrmId = z.IdZcrm) ct""",
                auxiliares_extra=["o_IdZcrm"],
                anomalias_extra=[Anomalia("ID-09", "ContactoId", "s.o_IdZcrm", "s.o_IdZcrm IS NOT NULL AND s.ContactoId IS NULL",
                                          "ID_ZCRM del ticket sin contacto en el CRM")],
                depende=["core_Contacto"], reglas_extra=("D12", "ID-05", "ID-09", "D6"),
                descripcion="Tickets de Trengo (histórico, D12). Se ligan al contacto del CRM solo si custom_data trae ID_ZCRM "
                            "(ID-09) y, por él, al servicio. Nunca por teléfono (ID-05)."),
]
