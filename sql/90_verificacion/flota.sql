/* Volumen de las fuentes de flota e históricos (Sprint 3) - SOLO LECTURA. Solo conteos por tabla y por mes. */
SET NOCOUNT ON; SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_WARNINGS ON;
USE ADN_Unificado;

PRINT '== 1. Filas por tabla de origen (metadatos, sin recorrer las tablas)';
SELECT 'Navsat' AS Base, t.name AS Tabla, SUM(p.rows) AS Filas
FROM Navsat.sys.tables t JOIN Navsat.sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0, 1)
GROUP BY t.name
UNION ALL
SELECT 'History_Tables', t.name, SUM(p.rows)
FROM History_Tables.sys.tables t JOIN History_Tables.sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0, 1)
WHERE t.name IN ('check_in_navsat', 'Conexiones_desconexiones_realizadas')
GROUP BY t.name
ORDER BY 1, 3 DESC;

PRINT '== 2. Ultima_ubicacion por mes (para decidir si se carga por período)';
SELECT x.Mes, COUNT_BIG(*) AS Filas
FROM Navsat.dbo.Ultima_ubicacion u
CROSS APPLY (SELECT CONVERT(char(7), ctl.fn_FechaCR(u.crDateTime), 120) AS Mes) x
GROUP BY x.Mes ORDER BY x.Mes;

PRINT '== 3. Lotes que quedaron EnCurso (caídas de Docker)';
SELECT LoteId, Paso, Modo, FechaInicio FROM ctl.Lote WHERE Estado = 'EnCurso' ORDER BY LoteId;

PRINT '== 4. Espacio de la base del modelo';
EXEC sp_spaceused;
