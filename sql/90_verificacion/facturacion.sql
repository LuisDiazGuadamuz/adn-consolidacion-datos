/* Diagnóstico de los pasos de facturación (Sprint 3) - SOLO LECTURA. Solo conteos; no muestra datos de clientes. */
SET NOCOUNT ON; SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_WARNINGS ON;
USE ADN_Unificado;

PRINT '== 1. Anomalías vigentes de los pasos 400-450 por columna';
SELECT a.Paso, a.ReglaId, a.Columna, COUNT(*) AS Anomalias
FROM ctl.vw_AnomaliaVigente a
WHERE a.Paso IN ('core_CuentaBancaria', 'core_MovimientoBancario', 'core_Factura', 'core_FacturaLinea', 'core_FacturaRecurrente',
                 'core_Pago', 'core_PagoFactura', 'core_Gasto', 'core_OrdenCompra', 'core_HistorialEstadoCliente', 'core_FacturaElectronicaProveedor')
GROUP BY a.Paso, a.ReglaId, a.Columna ORDER BY a.Paso, Anomalias DESC;

PRINT '== 2. Facturas y pagos: cliente y servicio según el estado del cliente';
SELECT 'Factura' AS Tabla, ISNULL(c.EstadoCorrespondencia, '(sin cliente)') AS EstadoCliente,
       COUNT(*) AS Registros, SUM(CASE WHEN f.ServicioId IS NULL THEN 1 ELSE 0 END) AS SinServicio
FROM core.Factura f LEFT JOIN core.Cliente c ON c.ClienteId = f.ClienteId
GROUP BY ISNULL(c.EstadoCorrespondencia, '(sin cliente)')
UNION ALL
SELECT 'Pago', ISNULL(c.EstadoCorrespondencia, '(sin cliente)'), COUNT(*), SUM(CASE WHEN p.ServicioId IS NULL THEN 1 ELSE 0 END)
FROM core.Pago p LEFT JOIN core.Cliente c ON c.ClienteId = p.ClienteId
GROUP BY ISNULL(c.EstadoCorrespondencia, '(sin cliente)')
ORDER BY 1, 3 DESC;

PRINT '== 3. Movimientos bancarios y pagos sin cliente: ¿el contacto de Books es un proveedor?';
SELECT a.Paso, CASE WHEN pv.ProveedorId IS NOT NULL THEN 'proveedor' ELSE 'otro contacto' END AS Contacto, COUNT(*) AS Registros
FROM ctl.vw_AnomaliaVigente a
LEFT JOIN core.Proveedor pv ON pv.ContactoBooksId = CAST(a.ValorOriginal AS nvarchar(30))
WHERE a.Paso IN ('core_MovimientoBancario', 'core_Pago', 'core_Factura') AND a.Columna = N'ClienteId'
GROUP BY a.Paso, CASE WHEN pv.ProveedorId IS NOT NULL THEN 'proveedor' ELSE 'otro contacto' END;

PRINT '== 4. Montos en colones: cuántos vienen del valor contable de Books y cuántos se calcularon';
SELECT f.Moneda, COUNT(*) AS Facturas, SUM(CASE WHEN f.TotalCRC IS NULL THEN 1 ELSE 0 END) AS SinTotalCRC,
       SUM(CASE WHEN f.TipoCambio IS NULL THEN 1 ELSE 0 END) AS SinTipoCambio
FROM core.Factura f GROUP BY f.Moneda;
SELECT p.Moneda, COUNT(*) AS Pagos, SUM(CASE WHEN p.MontoCRC IS NULL THEN 1 ELSE 0 END) AS SinMontoCRC FROM core.Pago p GROUP BY p.Moneda;
