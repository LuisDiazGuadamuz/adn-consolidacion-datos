# -*- coding: utf-8 -*-
"""Pasos de facturación, cobro, bancos y compras (orden 400-499), generados desde la matriz de correspondencia.

Fuente principal: Zoho Books (ZBooks_Mirror). Los registros de Books se ligan al cliente y al servicio por la tabla de
correspondencia core.ClienteOrigen (ID-04, ID-06): el contacto de Books ya quedó emparejado por circuito o cédula.
Montos (D5): moneda original + equivalente en colones. Cuando Books trae el monto en moneda base (bcy_*), ese valor
contable manda; si no, se calcula con el tipo de cambio del día (ref.TipoCambio).
Las facturas y pagos repetidos en el espejo se depuran por la modificación más reciente (DD-02).
"""
from ..auto import paso_matriz
from ..paso import Anomalia, Paso

_B = "ZohoBooks"
_FECHA_FACTURA = "TODATETIMEOFFSET(CAST(f.Fecha AS datetime2), '-06:00')"


def _cliente_servicio(alias, col="customer_id"):
    """Cliente y servicio de un documento de Books (ID-04, ID-06, ID-03).

    El contacto de Books se busca en la tabla de correspondencia. Si el contacto quedó ligado por cédula (sin servicio)
    y el cliente tiene UN solo servicio, el documento es de ese servicio. Solo se marca anomalía cuando el cliente tiene
    varios servicios y el documento no indica a cuál corresponde, o cuando el contacto no está en la correspondencia.
    Los clientes que solo existen en Books (D8) no tienen servicio y no son anomalía."""
    v = f"ctl.fn_Texto({alias}.{col})"
    extra = f"""OUTER APPLY (SELECT CASE WHEN COUNT(DISTINCT o.ClienteId) = 1 THEN MIN(o.ClienteId) END AS ClienteId,
                    CASE WHEN COUNT(DISTINCT o.ServicioId) = 1 THEN MIN(o.ServicioId) END AS ServicioId
             FROM core.ClienteOrigen o WHERE o.Sistema = 'ZohoBooks' AND o.LlaveOrigen = {v}) co
OUTER APPLY (SELECT COUNT(*) AS n, MIN(sv.ServicioId) AS ServicioId FROM core.Servicio sv WHERE sv.ClienteId = co.ClienteId) sc"""
    override = {"ClienteId": "co.ClienteId",
                "ServicioId": "COALESCE(co.ServicioId, CASE WHEN sc.n = 1 THEN sc.ServicioId END)",
                "o_ServicioVarios": f"CASE WHEN co.ServicioId IS NULL AND sc.n > 1 THEN {v} END",
                "o_ClienteBooks": f"CASE WHEN co.ClienteId IS NULL THEN {v} END"}
    anomalias = [Anomalia("IN-01", "ServicioId", "s.o_ServicioVarios", "s.o_ServicioVarios IS NOT NULL",
                          "Cliente con varios servicios: el documento de Books no indica a cuál corresponde (ID-03)"),
                 Anomalia("IN-01", "ClienteId", "s.o_ClienteBooks", "s.o_ClienteBooks IS NOT NULL",
                          "Contacto de Books sin correspondencia en core.ClienteOrigen")]
    return dict(override=override, extra_from=extra, auxiliares_extra=["o_ServicioVarios", "o_ClienteBooks"],
                anomalias_extra=anomalias)

PASOS = [
    paso_matriz("core_CuentaBancaria", 400, "core.CuentaBancaria", _B, "ZBooks_Mirror", "bankaccounts", "b", llave="account_id",
                descripcion="Cuentas bancarias de Books. El saldo en colones es el saldo en moneda base de Books (bcy_balance)."),
    paso_matriz("core_MovimientoBancario", 401, "core.MovimientoBancario", _B, "ZBooks_Mirror", "banktransactions", "m",
                llave="transaction_id",
                override={"ClienteId": "co.ClienteId",
                          "o_ClienteBooks": "CASE WHEN co.ClienteId IS NULL AND NOT EXISTS (SELECT 1 FROM core.Proveedor pv "
                                            "WHERE pv.ContactoBooksId = ctl.fn_Texto(m.customer_id)) THEN ctl.fn_Texto(m.customer_id) END"},
                extra_from="""OUTER APPLY (SELECT CASE WHEN COUNT(DISTINCT o.ClienteId) = 1 THEN MIN(o.ClienteId) END AS ClienteId
             FROM core.ClienteOrigen o WHERE o.Sistema = 'ZohoBooks' AND o.LlaveOrigen = ctl.fn_Texto(m.customer_id)) co""",
                auxiliares_extra=["o_ClienteBooks"],
                anomalias_extra=[Anomalia("IN-01", "ClienteId", "s.o_ClienteBooks", "s.o_ClienteBooks IS NOT NULL",
                                          "Contacto de Books que no es cliente con correspondencia ni proveedor")],
                fecha_dato="TODATETIMEOFFSET(CAST(ctl.fn_FechaDia(m.[date]) AS datetime2), '-06:00')",
                fecha_tc="q.Fecha", depende=["core_CuentaBancaria", "core_ClienteOrigen", "core_Proveedor"],
                descripcion="Movimientos bancarios de Books. El cliente se liga por la tabla de correspondencia (ID-06). Los "
                            "movimientos de proveedores no son anomalía (el contacto es un proveedor de core.Proveedor)."),

    paso_matriz("core_Factura", 410, "core.Factura", _B, "ZBooks_Mirror", "invoices", "f", llave="invoice_id",
                **_cliente_servicio("f"),
                fecha_tc="q.Fecha", excluir_atributos=("line_items",),
                depende=["core_ClienteOrigen", "ref_TipoCambio"],
                descripcion="Facturas de Books, depuradas por la versión más reciente (DD-02). Cliente y servicio por la tabla "
                            "de correspondencia (ID-06). El detalle de líneas va en core.FacturaLinea."),
    paso_matriz("core_FacturaLinea", 411, "core.FacturaLinea", _B, "ZBooks_Mirror", "invoices_items", "l", llave="line_item_id",
                override={"Moneda": "f.Moneda"}, fecha_dato=_FECHA_FACTURA, tc_respaldo="f.TipoCambio",
                extra_from="LEFT JOIN core.Factura f ON f.FacturaBooksId = ctl.fn_Texto(l.invoice_id)",
                depende=["core_Factura", "core_Producto_BooksVinculo"],
                descripcion="Líneas de factura de Books; heredan moneda y fecha de su factura (D5). Sin factura → descarte IN-01."),
    paso_matriz("core_FacturaRecurrente", 412, "core.FacturaRecurrente", _B, "ZBooks_Mirror", "recurringinvoices", "r",
                llave="recurring_invoice_id", depende=["core_ClienteOrigen"], **_cliente_servicio("r"),
                descripcion="Perfiles de facturación recurrente de Books."),

    paso_matriz("core_Pago", 420, "core.Pago", _B, "ZBooks_Mirror", "customerpayments", "p", llave="payment_id",
                **_cliente_servicio("p"),
                moneda="CASE WHEN ctl.fn_Monto(p.amount) IS NULL OR ctl.fn_Monto(p.bcy_amount) IS NULL THEN NULL "
                       "WHEN ctl.fn_Monto(p.amount) = ctl.fn_Monto(p.bcy_amount) THEN 'CRC' ELSE 'USD' END",
                fecha_tc="q.Fecha", excluir_atributos=("invoice_numbers",),
                depende=["core_CuentaBancaria", "core_ClienteOrigen"],
                descripcion="Pagos de clientes en Books. El espejo no trae la moneda del pago: es CRC si el monto coincide con el monto en "
                            "moneda base (bcy_amount) y USD si no. Los montos en colones son los de moneda base de Books (bcy_*)."),
    Paso(
        nombre="core_PagoFactura", orden=421, destino="core.PagoFactura", depende=["core_Pago", "core_Factura"],
        fuente=(_B, "SQLServer", "ZBooks_Mirror", "customerpayments"), llave_origen="",
        descripcion="Facturas que cubre cada pago: una fila por número de factura de customerpayments.invoice_numbers. "
                    "La factura se liga por número solo si el número es único.",
        reglas=["IN-01", "IN-05", "DD-04"], columnas=["PagoId", "FacturaId", "NumeroFactura"],
        auxiliares=["o_NumeroFactura"],
        anomalias=[Anomalia(
            "IN-01", "FacturaId", "s.o_NumeroFactura", "s.FacturaId IS NULL", "Número de factura sin correspondencia única en core.Factura")],
        select="""
SELECT 'ZohoBooks' AS FuenteSistema, N'ZBooks_Mirror' AS FuenteBase, N'customerpayments' AS FuenteTabla,
       CONCAT(ctl.fn_Texto(p.payment_id), N'|', n.Numero) AS FuenteLlave, pg.FechaCreacionOrigen AS FechaDato,
       pg.PagoId, fa.Id AS FacturaId, n.Numero AS NumeroFactura, n.Numero AS o_NumeroFactura
FROM (SELECT x.payment_id, x.invoice_numbers,
             ROW_NUMBER() OVER (PARTITION BY x.payment_id ORDER BY ctl.fn_FechaCR(x.last_modified_time) DESC) AS rn
      FROM ZBooks_Mirror.dbo.customerpayments x) p
CROSS APPLY (SELECT DISTINCT CAST(ctl.fn_Texto(v.value) AS nvarchar(50)) AS Numero
             FROM STRING_SPLIT(REPLACE(CONVERT(nvarchar(max), p.invoice_numbers), N';', N','), N',') v
             WHERE ctl.fn_Texto(v.value) IS NOT NULL) n
JOIN core.Pago pg ON pg.PagoBooksId = ctl.fn_Texto(p.payment_id)
OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(f.FacturaId) END AS Id FROM core.Factura f WHERE f.Numero = n.Numero) fa
WHERE p.rn = 1
"""),

    paso_matriz("core_Gasto", 430, "core.Gasto", _B, "ZBooks_Mirror", "expenses", "e", llave="expense_id",
                override={"Etiquetas": """(SELECT ctl.fn_Texto(t.tag_name) AS Etiqueta, ctl.fn_Texto(t.tag_option) AS Opcion
                 FROM ZBooks_Mirror.dbo.expense_tags t WHERE t.expense_id = TRY_CONVERT(bigint, e.expense_id)
                 FOR JSON PATH)"""},
                fecha_tc="q.Fecha", depende=["core_Proveedor", "core_ClienteOrigen"],
                descripcion="Gastos de Books con sus etiquetas (expense_tags) en JSON. Totales en colones de moneda base (bcy_*)."),
    paso_matriz("core_OrdenCompra", 431, "core.OrdenCompra", _B, "ZBooks_Mirror", "purchaseorders", "o", llave="purchaseorder_id",
                fecha_tc="COALESCE(q.Fecha, CAST(q.FechaCreacionOrigen AS date))", depende=["core_Proveedor"],
                descripcion="Órdenes de compra a proveedores en Books."),

    paso_matriz("core_HistorialEstadoCliente", 440, "core.HistorialEstadoCliente", "HistoryTables", "History_Tables",
                "customer_status_zbooks", "h",
                llave_expr="CONCAT(ctl.fn_Texto(h.custome_id), N'|', CONVERT(nvarchar(30), h.modification_date, 126), N'|', ctl.fn_Texto(h.customer_status))",
                override={"ClienteId": "co.ClienteId"},
                extra_from="""OUTER APPLY (SELECT CASE WHEN COUNT(DISTINCT o.ClienteId) = 1 THEN MIN(o.ClienteId) END AS ClienteId
             FROM core.ClienteOrigen o WHERE o.Sistema = 'ZohoBooks' AND o.LlaveOrigen = ctl.fn_Texto(h.custome_id)) co""",
                fecha_dato="ctl.fn_FechaCR(CONVERT(nvarchar(30), h.modification_date, 126))",
                depende=["core_ClienteOrigen"],
                descripcion="Histórico de cambios de estado de clientes de Books (History_Tables). custome_id es el id del "
                            "contacto de Books: se liga por la tabla de correspondencia (ID-10). La tabla no tiene llave: se "
                            "usa contacto + fecha + estado."),
    paso_matriz("core_FacturaElectronicaProveedor", 450, "core.FacturaElectronicaProveedor", "AppDataCR", "ADNApp",
                "XMLEngine_invoicexmlfiles", "x", llave="invoice_number",
                descripcion="Facturas electrónicas de proveedores leídas por app.data.cr (XMLEngine)."),
]
