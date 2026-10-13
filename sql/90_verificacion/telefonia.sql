/* Diagnóstico de telefonía (Sprint 3) - SOLO LECTURA. Solo conteos y códigos de troncal (configuración técnica). */
SET NOCOUNT ON; SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_WARNINGS ON;
USE ADN_Unificado;

PRINT '== 1. Anomalías vigentes de los pasos de telefonía';
SELECT a.Paso, a.ReglaId, a.Columna, COUNT(*) AS Anomalias
FROM ctl.vw_AnomaliaVigente a
WHERE a.Paso LIKE 'core[_]Llamada%' OR a.Paso IN ('core_Troncal', 'core_CorteVoIP', 'core_ConsumoVoIP_Factura', 'core_ConsumoVoIP_Corte',
      'core_LineaGratuita', 'core_ServicioPaqueteMinutos', 'core_MinutosHistorico_Cedula')
GROUP BY a.Paso, a.ReglaId, a.Columna ORDER BY a.Paso, Anomalias DESC;

PRINT '== 2. Troncales de las llamadas sin correspondencia: ¿son troncales de proveedores (carriers)?';
SELECT a.Columna, CASE WHEN tp.Codigo IS NOT NULL THEN 'troncal de proveedor' ELSE 'desconocida' END AS Tipo,
       COUNT(DISTINCT a.ValorOriginal) AS Codigos, COUNT(*) AS Llamadas
FROM ctl.vw_AnomaliaVigente a
LEFT JOIN (SELECT DISTINCT TRY_CONVERT(int, CodigoTroncal) AS Codigo FROM ref.TroncalProveedor) tp ON tp.Codigo = TRY_CONVERT(int, a.ValorOriginal)
WHERE a.Paso LIKE 'core[_]Llamada%' AND a.Columna IN (N'TroncalEntradaId', N'TroncalSalidaId')
GROUP BY a.Columna, CASE WHEN tp.Codigo IS NOT NULL THEN 'troncal de proveedor' ELSE 'desconocida' END;

PRINT '== 3. Recortes de texto en el consumo VoIP facturado (columna afectada)';
SELECT a.Columna AS ColumnasRecortadas, COUNT(*) AS Registros
FROM ctl.vw_AnomaliaVigente a WHERE a.Paso = 'core_ConsumoVoIP_Factura' AND a.ReglaId = 'ES-05'
GROUP BY a.Columna;

PRINT '== 4. Llamadas por mes en cada fuente (para planear D7: 24 meses en línea)';
SELECT 'Telephony_cdr_historico' AS Fuente, CONVERT(char(7), StartDateTime, 120) AS Mes, COUNT_BIG(*) AS Llamadas
FROM ADNApp.dbo.Telephony_cdr_historico GROUP BY CONVERT(char(7), StartDateTime, 120)
UNION ALL
SELECT 'Telephony_cdr', CONVERT(char(7), StartDateTime, 120), COUNT_BIG(*) FROM ADNApp.dbo.Telephony_cdr GROUP BY CONVERT(char(7), StartDateTime, 120)
UNION ALL
SELECT 'MongoDB (copia)', CONVERT(char(7), StartDateTime, 120), COUNT_BIG(*) FROM stg.mongo_Telephony_cdr GROUP BY CONVERT(char(7), StartDateTime, 120)
ORDER BY 2, 1;

PRINT '== 5. Espacio usado por la base del modelo';
EXEC sp_spaceused;
