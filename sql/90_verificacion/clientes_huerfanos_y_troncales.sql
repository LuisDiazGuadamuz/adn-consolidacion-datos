/* Diagnóstico (Sprint 3) - SOLO LECTURA. Conteos.
   1) ¿Qué registros siguen apuntando a los clientes sin origen vigente (anomalía ID-04)?
   2) Llamadas de MongoDB con troncales ambiguas: ¿las dos troncales son del mismo cliente? ¿qué tipo de llamada son? */
SET NOCOUNT ON; SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_WARNINGS ON;
USE ADN_Unificado;

DROP TABLE IF EXISTS #h;
SELECT DISTINCT RegistroId AS ClienteId INTO #h FROM ctl.vw_AnomaliaVigente WHERE Paso = 'core_Cliente' AND ReglaId = 'ID-04';
PRINT '== 1. Referencias a los clientes sin origen vigente';
SELECT Referencia, Filas FROM (
SELECT N'core.ClienteOrigen.ClienteId' AS Referencia, COUNT(*) AS Filas FROM core.ClienteOrigen x JOIN #h h ON h.ClienteId = x.[ClienteId]
UNION ALL SELECT N'core.Servicio.ClienteId' AS Referencia, COUNT(*) AS Filas FROM core.Servicio x JOIN #h h ON h.ClienteId = x.[ClienteId]
UNION ALL SELECT N'core.Contacto.ClienteId' AS Referencia, COUNT(*) AS Filas FROM core.Contacto x JOIN #h h ON h.ClienteId = x.[ClienteId]
UNION ALL SELECT N'core.Prospecto.ClienteId' AS Referencia, COUNT(*) AS Filas FROM core.Prospecto x JOIN #h h ON h.ClienteId = x.[ClienteId]
UNION ALL SELECT N'core.Nota.ClienteId' AS Referencia, COUNT(*) AS Filas FROM core.Nota x JOIN #h h ON h.ClienteId = x.[ClienteId]
UNION ALL SELECT N'core.Factura.ClienteId' AS Referencia, COUNT(*) AS Filas FROM core.Factura x JOIN #h h ON h.ClienteId = x.[ClienteId]
UNION ALL SELECT N'core.FacturaRecurrente.ClienteId' AS Referencia, COUNT(*) AS Filas FROM core.FacturaRecurrente x JOIN #h h ON h.ClienteId = x.[ClienteId]
UNION ALL SELECT N'core.Pago.ClienteId' AS Referencia, COUNT(*) AS Filas FROM core.Pago x JOIN #h h ON h.ClienteId = x.[ClienteId]
UNION ALL SELECT N'core.MovimientoBancario.ClienteId' AS Referencia, COUNT(*) AS Filas FROM core.MovimientoBancario x JOIN #h h ON h.ClienteId = x.[ClienteId]
UNION ALL SELECT N'core.Gasto.ClienteId' AS Referencia, COUNT(*) AS Filas FROM core.Gasto x JOIN #h h ON h.ClienteId = x.[ClienteId]
UNION ALL SELECT N'core.HistorialEstadoCliente.ClienteId' AS Referencia, COUNT(*) AS Filas FROM core.HistorialEstadoCliente x JOIN #h h ON h.ClienteId = x.[ClienteId]
UNION ALL SELECT N'core.MinutosContratadosHistorico.ClienteId' AS Referencia, COUNT(*) AS Filas FROM core.MinutosContratadosHistorico x JOIN #h h ON h.ClienteId = x.[ClienteId]
UNION ALL SELECT N'core.CorteVoIP.ClienteId' AS Referencia, COUNT(*) AS Filas FROM core.CorteVoIP x JOIN #h h ON h.ClienteId = x.[ClienteId]
UNION ALL SELECT N'core.ConsumoVoIP.ClienteId' AS Referencia, COUNT(*) AS Filas FROM core.ConsumoVoIP x JOIN #h h ON h.ClienteId = x.[ClienteId]
UNION ALL SELECT N'core.SolicitudEnLinea.ClienteId' AS Referencia, COUNT(*) AS Filas FROM core.SolicitudEnLinea x JOIN #h h ON h.ClienteId = x.[ClienteId]
UNION ALL SELECT N'core.EventoConexion.ClienteId' AS Referencia, COUNT(*) AS Filas FROM core.EventoConexion x JOIN #h h ON h.ClienteId = x.[ClienteId]
) r WHERE Filas > 0 ORDER BY Filas DESC;

PRINT '== 2. Llamadas por fuente: troncal de entrada y de salida con servicio';
;WITH x AS (
    SELECT l.FuenteTabla, l.TipoCDR, te.ServicioId AS SE, ts.ServicioId AS SS, se.ClienteId AS CE, ss.ClienteId AS CS
    FROM core.Llamada l
    LEFT JOIN core.Troncal te ON te.TroncalId = l.TroncalEntradaId
    LEFT JOIN core.Troncal ts ON ts.TroncalId = l.TroncalSalidaId
    LEFT JOIN core.Servicio se ON se.ServicioId = te.ServicioId
    LEFT JOIN core.Servicio ss ON ss.ServicioId = ts.ServicioId)
SELECT FuenteTabla, TipoCDR,
       CASE WHEN SE IS NULL AND SS IS NULL THEN 'ninguna troncal de cliente'
            WHEN SE IS NULL OR SS IS NULL THEN 'una troncal de cliente'
            WHEN SE = SS THEN 'ambas, mismo servicio'
            WHEN CE = CS THEN 'ambas, servicios distintos del mismo cliente'
            ELSE 'ambas, clientes distintos' END AS Caso,
       COUNT_BIG(*) AS Llamadas
FROM x GROUP BY FuenteTabla, TipoCDR,
       CASE WHEN SE IS NULL AND SS IS NULL THEN 'ninguna troncal de cliente'
            WHEN SE IS NULL OR SS IS NULL THEN 'una troncal de cliente'
            WHEN SE = SS THEN 'ambas, mismo servicio'
            WHEN CE = CS THEN 'ambas, servicios distintos del mismo cliente'
            ELSE 'ambas, clientes distintos' END
ORDER BY FuenteTabla, TipoCDR, Llamadas DESC;

PRINT '== 3. MongoDB vs SQL: troncales de entrada más usadas (código y si es de cliente o proveedor), top 10 por fuente';
;WITH t AS (
    SELECT 'MongoDB' AS Fuente, IngressTrunk AS Codigo, COUNT_BIG(*) AS n FROM stg.mongo_Telephony_cdr WHERE StartDateTime >= '2026-10-01' GROUP BY IngressTrunk
    UNION ALL
    SELECT 'SQL abr-2026', IngressTrunk, COUNT_BIG(*) FROM ADNApp.dbo.Telephony_cdr WHERE StartDateTime >= '2026-04-01' AND StartDateTime < '2026-05-01' GROUP BY IngressTrunk),
r AS (SELECT *, ROW_NUMBER() OVER (PARTITION BY Fuente ORDER BY n DESC) AS rn FROM t)
SELECT r.Fuente, r.Codigo, r.n AS Llamadas,
       CASE WHEN EXISTS (SELECT 1 FROM core.Troncal c WHERE TRY_CONVERT(int, c.CodigoTroncal) = r.Codigo) THEN 'cliente'
            WHEN EXISTS (SELECT 1 FROM ref.TroncalProveedor p WHERE TRY_CONVERT(int, p.CodigoTroncal) = r.Codigo) THEN 'proveedor'
            ELSE 'desconocida' END AS Tipo
FROM r WHERE rn <= 10 ORDER BY r.Fuente, r.n DESC;
