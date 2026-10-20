# -*- coding: utf-8 -*-
"""Pasos de telefonía VoIP (orden 500-599).

Catálogos y configuración de app.data.cr (ADNApp, SQL Server) generados desde la matriz; las llamadas se escriben a mano
por su volumen (millones de filas) y se cargan por período (--desde / --hasta):

  D1   llamadas en tres fuentes encadenadas por fecha, sin solapes:
         ADNApp.Telephony_cdr_historico (47,2 M, años anteriores) → hasta la primera fecha de ADNApp.Telephony_cdr
         ADNApp.Telephony_cdr (10,3 M, 2026)                       → hasta la primera fecha de la copia de MongoDB
         MongoDB (stg.mongo_Telephony_cdr, sep-oct 2026)           → desde su primera fecha
       La copia de MongoDB solo tiene sep-oct 2026 (se depura), así que el corte NO es fijo (2024-01-01): es la primera
       fecha presente en stg.mongo_Telephony_cdr (@Corte). Sin períodos vacíos ni llamadas duplicadas entre fuentes.
  D10  moneda de la llamada según el destino: 506 → CRC, otro → USD
  D5   tipo de cambio: el que registró la central (usd_exchange); si falta, el del día (ref.TipoCambio)
  ID-07 la llamada se asigna al servicio por CustomerCircuitNumber (circuito con un único servicio). Si no trae circuito
        válido (MongoDB no tiene el campo), respaldo por troncal aprobado el 19/10 (opción A): el servicio de la troncal
        del cliente cuando es uno solo; queda marcado ServicioPor=Troncal en AtributosExtendidos. Si la entrada y la
        salida son de servicios distintos la llamada queda sin servicio con anomalía ID-07 (troncal ambigua).
  IN-01 troncales: TroncalEntradaId/SalidaId solo para troncales de clientes (core.Troncal); las de proveedores (carriers,
        ref.TroncalProveedor) no son anomalía. Los números originales quedan siempre en AtributosExtendidos.
  DD-01 llamadas idénticas (todas las columnas salvo el id) dentro del período: se carga una
  DD-05 cada archivo de llamadas una sola vez (nombre + dispositivo)
Hora: los valores de la central no traen zona y están en hora de Costa Rica (D4), igual que ctl.fn_FechaCR.
"""
from ..auto import paso_matriz
from ..matriz import columnas as cols_matriz
from ..paso import Anomalia, Paso

_A = "AppDataCR"
_SRV_CIRC = "OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(sv.ServicioId) END AS ServicioId FROM core.Servicio sv " \
            "WHERE sv.Circuito = ctl.fn_Circuito(CONVERT(nvarchar(100), {x}))) {a}"


def _huella_fila(alias, cols):
    return ("CONVERT(nvarchar(66), HASHBYTES('SHA2_256', CONCAT_WS(N'|', "
            + ", ".join(f"ISNULL(CONVERT(nvarchar(4000), {alias}.[{c}]), N'~')" for c in cols) + ")), 2)")


PASOS = [
    # ------------------------------------------------------------------ catálogos
    paso_matriz("ref_ProveedorTelefonia", 500, "ref.ProveedorTelefonia", _A, "ADNApp", "Telephony_provider", "p",
                descripcion="Proveedores de telefonía (carriers)."),
    paso_matriz("ref_TroncalProveedor", 501, "ref.TroncalProveedor", _A, "ADNApp", "Telephony_providertrunk", "t",
                depende=["ref_ProveedorTelefonia"], descripcion="Troncales de los proveedores."),
    paso_matriz("ref_TarifaDestino", 502, "ref.TarifaDestino", _A, "ADNApp", "Telephony_countrydialcoderate", "r",
                override={"EsNumeroEspecial": "CAST(0 AS bit)"}, moneda=None, depende=["ref_ProveedorTelefonia"],
                descripcion="Tarifas por código de país (la moneda de cada tarifa sigue D10 según el código)."),
    paso_matriz("ref_TarifaNumeroEspecial", 503, "ref.TarifaDestino", _A, "ADNApp", "Telephony_specialnumberrate", "r",
                override={"EsNumeroEspecial": "CAST(1 AS bit)"},
                descripcion="Tarifas de números especiales (EsNumeroEspecial = 1)."),
    paso_matriz("ref_PaqueteMinutos", 504, "ref.PaqueteMinutos", _A, "ADNApp", "Telephony_minutepackage", "m",
                descripcion="Paquetes de minutos."),
    paso_matriz("ref_PaqueteMinutosCodigo", 505, "ref.PaqueteMinutosCodigo", _A, "ADNApp", "Telephony_minutepackagedialcode", "m",
                depende=["ref_PaqueteMinutos"], descripcion="Códigos de marcación incluidos en cada paquete de minutos."),

    # ------------------------------------------------------------------ configuración por servicio
    paso_matriz("core_Troncal", 510, "core.Troncal", _A, "ADNApp", "Telephony_trunk", "t",
                override={"SinRestriccion": "(SELECT TOP 1 tp.NoRestriction FROM ADNApp.dbo.Telephony_trunkpermissions tp "
                                            "WHERE tp.TrunkID_id = t.id ORDER BY tp.id DESC)",
                          "o_Repetido": "ROW_NUMBER() OVER (PARTITION BY ctl.fn_Texto(t.TrunkID) ORDER BY t.id DESC)"},
                auxiliares_extra=["o_Repetido"],
                filtros_extra=[("s.o_Repetido > 1", "DD-04",
                                "Código de troncal repetido en Telephony_trunk: se conserva el registro más reciente (id mayor)")],
                depende=["core_ClienteOrigen"],
                descripcion="Troncales de los clientes VoIP. El servicio se toma del cliente VoIP en la tabla de correspondencia "
                            "(ID-07). El permiso SinRestriccion viene de Telephony_trunkpermissions (se fusiona aquí). El código de "
                            "troncal es único en el modelo: si se repite en el origen se conserva el registro más reciente (DD-04)."),
    paso_matriz("core_TroncalPermisoCodigo", 511, "core.TroncalPermisoCodigo", _A, "ADNApp", "Telephony_trunkpermissiondialcode", "d",
                depende=["core_Troncal"], descripcion="Códigos de marcación permitidos por troncal."),
    paso_matriz("core_AlertaTroncal", 512, "core.AlertaTroncal", _A, "ADNApp", "Telephony_alertblockedtrunk", "a",
                depende=["core_Troncal"], descripcion="Bloqueos de troncales registrados por la central."),
    paso_matriz("core_LineaGratuita", 513, "core.LineaGratuita", _A, "ADNApp", "Telephony_freelines", "l",
                depende=["core_ClienteOrigen"], descripcion="Líneas gratuitas (toll free) asignadas a clientes VoIP."),
    paso_matriz("core_ServicioPaqueteMinutos", 514, "core.ServicioPaqueteMinutos", _A, "ADNApp", "Telephony_customerminutepackage", "c",
                depende=["core_ClienteOrigen", "ref_PaqueteMinutos"], descripcion="Paquetes de minutos contratados por servicio."),

    # ------------------------------------------------------------------ minutos de 2022 (histórico, D11)
    paso_matriz("core_MinutosHistorico_Cliente", 515, "core.MinutosContratadosHistorico", _A, "ADNApp", "Minutos_Customer", "m",
                llave_expr=_huella_fila("m", ["Description", "Minutes", "Customer_id"]),
                override={"TablaOrigen": "'Minutos_Customer'",
                          "ClienteVoIPOrigenId": "TRY_CONVERT(bigint, m.Customer_id)",
                          "ServicioId": "co.ServicioId", "ClienteId": "co.ClienteId"},
                extra_from="""OUTER APPLY (SELECT CASE WHEN COUNT(DISTINCT o.ServicioId) = 1 THEN MIN(o.ServicioId) END AS ServicioId,
                    CASE WHEN COUNT(DISTINCT o.ClienteId) = 1 THEN MIN(o.ClienteId) END AS ClienteId
             FROM core.ClienteOrigen o WHERE o.Sistema = 'AppDataCR'
               AND o.LlaveOrigen = CAST(TRY_CONVERT(bigint, m.Customer_id) AS nvarchar(200))) co""",
                depende=["core_ClienteOrigen"], reglas_extra=("D11", "DD-01"),
                descripcion="Tabla de minutos de dic-2022 (D11: se conserva como histórico). Sin llave en el origen: la llave "
                            "es la huella de la fila; filas idénticas se cargan una vez (DD-01)."),
    paso_matriz("core_MinutosHistorico_Cedula", 516, "core.MinutosContratadosHistorico", _A, "ADNApp", "MinutosLegalId", "m",
                llave_expr=_huella_fila("m", ["IDCard", "MinutosFijo", "MinutosCelular"]),
                override={"TablaOrigen": "'MinutosLegalId'"},
                depende=["core_Cliente"], reglas_extra=("D11", "DD-01"),
                descripcion="Minutos por cédula de dic-2022 (D11: histórico). El cliente se liga por cédula (ID-02)."),

    # ------------------------------------------------------------------ archivos y cortes
    paso_matriz("core_ArchivoCDR", 520, "core.ArchivoCDR", _A, "ADNApp", "Telephony_insertedcdrfiles", "f",
                override={"o_Repetido": "ROW_NUMBER() OVER (PARTITION BY ctl.fn_Texto(f.FileName), ctl.fn_Texto(f.VoipDevice) "
                                        "ORDER BY f.InsertionDate, f.id)"},
                auxiliares_extra=["o_Repetido"], reglas_extra=("DD-05",),
                filtros_extra=[("s.o_Repetido > 1", "DD-05", "Archivo de llamadas registrado más de una vez (mismo nombre y dispositivo)")],
                descripcion="Archivos de llamadas procesados. Cada archivo (nombre + dispositivo) se registra una sola vez (DD-05)."),
    paso_matriz("core_CorteVoIP", 521, "core.CorteVoIP", _A, "ADNApp", "ZohoEngine_zohocustomervoipbill", "b",
                depende=["core_Servicio", "core_Cliente"],
                descripcion="Cortes de facturación VoIP. Servicio por circuito (ID-01) y cliente por cédula (ID-02)."),
    paso_matriz("core_ConsumoVoIP_Corte", 522, "core.ConsumoVoIP", _A, "ADNApp", "ZohoEngine_zohocustomervoipbillservice", "s",
                override={"ServicioId": "cv.ServicioId", "ClienteId": "cv.ClienteId",
                          "FechaInicio": "cv.FechaInicio", "FechaFin": "cv.FechaFin"},
                extra_from="LEFT JOIN core.CorteVoIP cv ON cv.FuenteBase = N'ADNApp' AND cv.FuenteLlave = CAST(s.zoho_customer_voip_bill_id AS nvarchar(200))",
                fecha_dato="TODATETIMEOFFSET(CAST(cv.FechaInicio AS datetime2), '-06:00')",
                depende=["core_CorteVoIP"],
                descripcion="Consumo VoIP por tipo de servicio dentro de cada corte; hereda servicio, cliente y período del corte."),
    paso_matriz("core_ConsumoVoIP_Factura", 523, "core.ConsumoVoIP", _A, "ADNApp", "ZohoEngine_invoicevoip", "i",
                depende=["core_Servicio", "core_Cliente"],
                descripcion="Consumo VoIP facturado (invoicevoip). Servicio por circuito (ID-01) y cliente por cédula (ID-02)."),
]


# ------------------------------------------------------------------ llamadas
_ATRIBUTOS = cols_matriz("ADNApp", "Telephony_cdr", "Atributo extendido")
_CONTENIDO = ["CDRTypeCode", "CDRTypeReason", "StartDateTime", "AnswerTimeOfDate", "DisconnectDateTime", "IngressTrunk",
              "EgressTrunk", "DialedNumber", "usd_exchange", "Destination", "DestinationCode", "DestinationRate",
              "DestinationRateNoProfit", "DestinationRound", "DurationInSeconds", "DurationInRoundedSeconds",
              "DurationInMinutes", "CallCost", "CallCostNoProfit", "CallingNumber", "BillingNumber", "VoipDevice",
              "CustomerIncrement", "CustomerPorcentage", "CustomerCircuitNumber", "RoutingDigits"]

_PREP_LLAMADAS = """
/* Corte entre fuentes (D1): primera fecha con llamadas en la copia de MongoDB; sin copia, todo sale de SQL Server */
DECLARE @Corte datetime2 = ISNULL((SELECT MIN(StartDateTime) FROM stg.mongo_Telephony_cdr), '9999-12-31');
DECLARE @CorteSQL datetime2 = ISNULL((SELECT MIN(StartDateTime) FROM ADNApp.dbo.Telephony_cdr), '9999-12-31');
/* Búsquedas precalculadas (una vez por ejecución, no por llamada) */
DROP TABLE IF EXISTS #circ, #tron;
SELECT Circuito, MIN(ServicioId) AS ServicioId, COUNT(*) AS n INTO #circ FROM core.Servicio WHERE Circuito IS NOT NULL GROUP BY Circuito;
CREATE UNIQUE CLUSTERED INDEX ix ON #circ (Circuito);
/* Servicio por troncal (aprobado 19/10, opción A): solo como respaldo cuando la llamada no trae circuito válido */
SELECT TRY_CONVERT(int, CodigoTroncal) AS Codigo, MIN(TroncalId) AS TroncalId, COUNT(*) AS n,
       CASE WHEN COUNT(*) = 1 THEN MIN(ServicioId) END AS ServicioId INTO #tron
FROM core.Troncal WHERE TRY_CONVERT(int, CodigoTroncal) IS NOT NULL GROUP BY TRY_CONVERT(int, CodigoTroncal);
CREATE UNIQUE CLUSTERED INDEX ix ON #tron (Codigo);
/* Troncales de proveedores (carriers): no son troncales de clientes, pero tampoco son anomalía */
DROP TABLE IF EXISTS #tprov;
SELECT DISTINCT TRY_CONVERT(int, CodigoTroncal) AS Codigo INTO #tprov FROM ref.TroncalProveedor WHERE TRY_CONVERT(int, CodigoTroncal) IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #tprov (Codigo);
"""


def _t(x, n):
    return f"NULLIF(LTRIM(RTRIM(CAST({x} AS nvarchar({n})))), N'')"


def _fecha(x):
    return f"CASE WHEN {x} >= '1990-01-01' THEN TODATETIMEOFFSET(CAST({x} AS datetime2(0)), '-06:00') END"


def _select_llamadas(origen, base, tabla_sql, llave, filtro_periodo, fuente_tabla="Telephony_cdr"):
    c = "c"
    atrib = ", ".join([f"{c}.IngressTrunk AS [IngressTrunk]", f"{c}.EgressTrunk AS [EgressTrunk]",
                       "CASE WHEN ci.ServicioId IS NULL AND st.ServicioId IS NOT NULL THEN N'Troncal' END AS [ServicioPor]"]
                      + [f"{_t(f'{c}.[{a}]', 400)} AS [{a}]" for a in _ATRIBUTOS])
    return f"""
SELECT q.*,
       CASE q.Moneda WHEN 'CRC' THEN CAST(1 AS decimal(19,6))
                     WHEN 'USD' THEN COALESCE(CASE WHEN q.o_TipoCambio > 1 THEN CAST(q.o_TipoCambio AS decimal(19,6)) END, tc.Venta) END AS TipoCambio,
       CASE q.Moneda WHEN 'CRC' THEN q.TarifaDestino WHEN 'USD' THEN CAST(q.TarifaDestino * COALESCE(CASE WHEN q.o_TipoCambio > 1 THEN q.o_TipoCambio END, tc.Venta) AS decimal(19,4)) END AS TarifaDestinoCRC,
       CASE q.Moneda WHEN 'CRC' THEN q.TarifaSinMargen WHEN 'USD' THEN CAST(q.TarifaSinMargen * COALESCE(CASE WHEN q.o_TipoCambio > 1 THEN q.o_TipoCambio END, tc.Venta) AS decimal(19,4)) END AS TarifaSinMargenCRC,
       CASE q.Moneda WHEN 'CRC' THEN q.Costo WHEN 'USD' THEN CAST(q.Costo * COALESCE(CASE WHEN q.o_TipoCambio > 1 THEN q.o_TipoCambio END, tc.Venta) AS decimal(19,4)) END AS CostoCRC,
       CASE q.Moneda WHEN 'CRC' THEN q.CostoSinMargen WHEN 'USD' THEN CAST(q.CostoSinMargen * COALESCE(CASE WHEN q.o_TipoCambio > 1 THEN q.o_TipoCambio END, tc.Venta) AS decimal(19,4)) END AS CostoSinMargenCRC
FROM (
    SELECT 'AppDataCR' AS FuenteSistema, N'{base}' AS FuenteBase, N'{fuente_tabla}' AS FuenteTabla,
           CAST({llave} AS nvarchar(200)) AS FuenteLlave, {_fecha(f'{c}.StartDateTime')} AS FechaDato,
           COALESCE(ci.ServicioId, st.ServicioId) AS ServicioId, ti.TroncalId AS TroncalEntradaId, te.TroncalId AS TroncalSalidaId,
           v.Circuito, {c}.CDRTypeCode AS TipoCDR, {_t(f'{c}.CDRTypeReason', 100)} AS RazonCDR,
           {_fecha(f'{c}.StartDateTime')} AS FechaInicio, {_fecha(f'{c}.AnswerTimeOfDate')} AS FechaRespuesta,
           {_fecha(f'{c}.DisconnectDateTime')} AS FechaFin,
           {_t(f'{c}.CallingNumber', 50)} AS NumeroOrigen, {_t(f'{c}.DialedNumber', 50)} AS NumeroMarcado,
           {_t(f'{c}.BillingNumber', 50)} AS NumeroFacturacion, {_t(f'{c}.RoutingDigits', 50)} AS DigitosRuteo,
           {_t(f'{c}.Destination', 150)} AS Destino, {_t(f'{c}.DestinationCode', 20)} AS CodigoDestino,
           {_t(f'{c}.VoipDevice', 100)} AS Dispositivo,
           TRY_CONVERT(decimal(12,2), {c}.DurationInSeconds) AS DuracionSegundos,
           TRY_CONVERT(decimal(12,2), {c}.DurationInRoundedSeconds) AS DuracionSegundosRedondeada,
           TRY_CONVERT(decimal(12,2), {c}.DurationInMinutes) AS DuracionMinutos,
           {c}.DestinationRound AS RedondeoDestino, {c}.CustomerIncrement AS IncrementoCliente,
           TRY_CONVERT(decimal(9,4), {c}.CustomerPorcentage) AS PorcentajeCliente,
           ctl.fn_MonedaLlamada({c}.DestinationCode) AS Moneda,
           TRY_CONVERT(decimal(19,4), {c}.DestinationRate) AS TarifaDestino,
           TRY_CONVERT(decimal(19,4), {c}.DestinationRateNoProfit) AS TarifaSinMargen,
           TRY_CONVERT(decimal(19,4), {c}.CallCost) AS Costo,
           TRY_CONVERT(decimal(19,4), {c}.CallCostNoProfit) AS CostoSinMargen,
           NULLIF((SELECT {atrib} FOR JSON PATH, WITHOUT_ARRAY_WRAPPER), N'{{}}') AS AtributosExtendidos,
           {c}.usd_exchange AS o_TipoCambio,
           {_t(f'{c}.CustomerCircuitNumber', 100)} AS o_Circuito,
           CASE WHEN v.Circuito IS NOT NULL AND ci.ServicioId IS NULL THEN v.Circuito END AS o_ServicioCircuito,
           CASE WHEN {c}.IngressTrunk IS NOT NULL AND ti.TroncalId IS NULL AND pi.Codigo IS NULL THEN CAST({c}.IngressTrunk AS nvarchar(20)) END AS o_TroncalEntrada,
           CASE WHEN {c}.EgressTrunk IS NOT NULL AND te.TroncalId IS NULL AND pe.Codigo IS NULL THEN CAST({c}.EgressTrunk AS nvarchar(20)) END AS o_TroncalSalida,
           CASE WHEN st.Ambigua = 1 THEN CONCAT(N'troncales ', {c}.IngressTrunk, N'/', {c}.EgressTrunk) END AS o_TroncalAmbigua,
           ROW_NUMBER() OVER (PARTITION BY {_huella_fila(c, _CONTENIDO)} ORDER BY CAST({llave} AS nvarchar(200))) AS o_Repetida
    FROM {tabla_sql} {c}
    CROSS APPLY (SELECT ctl.fn_Circuito(CONVERT(nvarchar(100), {c}.CustomerCircuitNumber)) AS Circuito) v
    LEFT JOIN #circ ci0 ON ci0.Circuito = v.Circuito
    OUTER APPLY (SELECT CASE WHEN ci0.n = 1 THEN ci0.ServicioId END AS ServicioId) ci
    LEFT JOIN #tron ti ON ti.Codigo = {c}.IngressTrunk AND ti.n = 1
    LEFT JOIN #tron te ON te.Codigo = {c}.EgressTrunk AND te.n = 1
    /* Respaldo por troncal: sin circuito válido, el servicio de la troncal del cliente si es uno solo; si la entrada y la
       salida son de servicios distintos la llamada queda sin servicio (ID-07, troncal ambigua) */
    OUTER APPLY (SELECT CASE WHEN v.Circuito IS NULL AND NOT (ti.ServicioId IS NOT NULL AND te.ServicioId IS NOT NULL
                                  AND ti.ServicioId <> te.ServicioId) THEN COALESCE(ti.ServicioId, te.ServicioId) END AS ServicioId,
                        CASE WHEN v.Circuito IS NULL AND ti.ServicioId IS NOT NULL AND te.ServicioId IS NOT NULL
                                  AND ti.ServicioId <> te.ServicioId THEN 1 END AS Ambigua) st
    LEFT JOIN #tprov pi ON pi.Codigo = {c}.IngressTrunk
    LEFT JOIN #tprov pe ON pe.Codigo = {c}.EgressTrunk
    WHERE {c}.StartDateTime IS NOT NULL AND {filtro_periodo}
      AND (@Desde IS NULL OR {c}.StartDateTime >= @Desde) AND (@Hasta IS NULL OR {c}.StartDateTime < @Hasta)
) q
OUTER APPLY (SELECT TOP 1 t.Venta FROM ref.TipoCambio t WHERE t.Fecha <= CAST(q.FechaInicio AS date) ORDER BY t.Fecha DESC) tc
"""


_COLS_LLAMADA = ["ServicioId", "TroncalEntradaId", "TroncalSalidaId", "Circuito", "TipoCDR", "RazonCDR", "FechaInicio",
                 "FechaRespuesta", "FechaFin", "NumeroOrigen", "NumeroMarcado", "NumeroFacturacion", "DigitosRuteo",
                 "Destino", "CodigoDestino", "Dispositivo", "DuracionSegundos", "DuracionSegundosRedondeada",
                 "DuracionMinutos", "RedondeoDestino", "IncrementoCliente", "PorcentajeCliente", "Moneda", "TipoCambio",
                 "TarifaDestino", "TarifaDestinoCRC", "TarifaSinMargen", "TarifaSinMargenCRC", "Costo", "CostoCRC",
                 "CostoSinMargen", "CostoSinMargenCRC", "AtributosExtendidos"]
_AUX_LLAMADA = ["o_TipoCambio", "o_Circuito", "o_ServicioCircuito", "o_TroncalEntrada", "o_TroncalSalida", "o_TroncalAmbigua",
                "o_Repetida"]
_ANOM_LLAMADA = [
    Anomalia("ID-01", "Circuito", "s.o_Circuito", "s.o_Circuito IS NOT NULL AND s.Circuito IS NULL", "Circuito que no cumple el patrón aprobado"),
    Anomalia("ID-07", "ServicioId", "s.o_ServicioCircuito", "s.o_ServicioCircuito IS NOT NULL",
             "Circuito de la llamada sin un único servicio en el modelo"),
    Anomalia("ID-07", "ServicioId", "s.o_TroncalAmbigua", "s.o_TroncalAmbigua IS NOT NULL",
             "Llamada sin circuito cuya troncal de entrada y de salida son de servicios distintos: queda sin servicio"),
    Anomalia("IN-01", "TroncalEntradaId", "s.o_TroncalEntrada", "s.o_TroncalEntrada IS NOT NULL",
             "Troncal de entrada que no es de un cliente ni de un proveedor"),
    Anomalia("IN-01", "TroncalSalidaId", "s.o_TroncalSalida", "s.o_TroncalSalida IS NOT NULL",
             "Troncal de salida que no es de un cliente ni de un proveedor"),
]
_REGLAS_LLAMADA = ["D1", "D4", "D5", "D6", "D10", "ID-01", "ID-07", "ES-01", "ES-02", "ES-04", "DD-01", "IN-01", "IN-05"]

PASOS += [
    Paso(
        nombre="core_Llamada_Historico", requiere_periodo=True, orden=529, destino="core.Llamada", depende=["core_Servicio", "core_Troncal", "ref_TipoCambio"],
        fuente=(_A, "SQLServer", "ADNApp", "Telephony_cdr_historico"), llave_origen="id",
        traza_from="ADNApp.dbo.Telephony_cdr_historico c", traza_llave="CAST(c.id AS nvarchar(200))", traza_columna="c.id", periodo_origen="c.StartDateTime",
        descripcion="Llamadas de años anteriores (ADNApp.Telephony_cdr_historico), hasta la primera fecha de ADNApp.Telephony_cdr (D1). "
                    "Según D7 el modelo guarda 24 meses en línea: cargar solo el período necesario con --desde/--hasta.",
        reglas=_REGLAS_LLAMADA + ["D7"], columnas=_COLS_LLAMADA, auxiliares=_AUX_LLAMADA, anomalias=_ANOM_LLAMADA,
        preparacion=_PREP_LLAMADAS, dedup_orden="s.FuenteLlave",
        filtros=[("s.o_Repetida > 1", "DD-01", "Llamada idéntica a otra del mismo período (todas las columnas salvo el id)")],
        select=_select_llamadas("sql", "ADNApp", "ADNApp.dbo.Telephony_cdr_historico", "c.id",
                                "c.StartDateTime < @CorteSQL AND c.StartDateTime < @Corte", "Telephony_cdr_historico")),
    Paso(
        nombre="core_Llamada_SQL", requiere_periodo=True, orden=530, destino="core.Llamada", depende=["core_Llamada_Historico"],
        fuente=(_A, "SQLServer", "ADNApp", "Telephony_cdr"), llave_origen="id",
        traza_from="ADNApp.dbo.Telephony_cdr c", traza_llave="CAST(c.id AS nvarchar(200))", traza_columna="c.id", periodo_origen="c.StartDateTime",
        descripcion="Llamadas de ADNApp.Telephony_cdr (2026) anteriores a la primera fecha de la copia de MongoDB (D1). "
                    "Cargar por período con --desde/--hasta.",
        reglas=_REGLAS_LLAMADA, columnas=_COLS_LLAMADA, auxiliares=_AUX_LLAMADA, anomalias=_ANOM_LLAMADA,
        preparacion=_PREP_LLAMADAS, dedup_orden="s.FuenteLlave",
        filtros=[("s.o_Repetida > 1", "DD-01", "Llamada idéntica a otra del mismo período (todas las columnas salvo el id)")],
        select=_select_llamadas("sql", "ADNApp", "ADNApp.dbo.Telephony_cdr", "c.id", "c.StartDateTime < @Corte")),
    Paso(
        nombre="core_Llamada", requiere_periodo=True, orden=531, destino="core.Llamada", depende=["core_Llamada_SQL"],
        fuente=(_A, "MongoDB", "developer_adn_app_db", "Telephony_cdr"), llave_origen="_id",
        traza_from="stg.mongo_Telephony_cdr c", traza_llave="CAST(c._id AS nvarchar(200))", traza_columna="c._id", periodo_origen="c.StartDateTime",
        descripcion="Llamadas desde la primera fecha de la copia de MongoDB (D1), copiadas antes a stg.mongo_Telephony_cdr con stage-mongo. "
                    "Cargar por período con --desde/--hasta.",
        reglas=_REGLAS_LLAMADA, columnas=_COLS_LLAMADA, auxiliares=_AUX_LLAMADA, anomalias=_ANOM_LLAMADA,
        preparacion=_PREP_LLAMADAS, dedup_orden="s.FuenteLlave",
        filtros=[("s.o_Repetida > 1", "DD-01", "Llamada idéntica a otra del mismo período (todas las columnas salvo el id)")],
        select=_select_llamadas("mongo", "developer_adn_app_db", "stg.mongo_Telephony_cdr", "c._id", "c.StartDateTime >= @Corte")),
]
