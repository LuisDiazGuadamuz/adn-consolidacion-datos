/* =====================================================================
   Verificación del diccionario de datos (Sprint 5): compara la base del sandbox con
   docs/Diccionario_Matriz_ADN_Unificado.xlsx. Solo conteos de objetos; no lee datos.
   Esperado (diccionario v2.0):
     core 55 tablas · 1.326 columnas | ref 14 tablas · 199 columnas | ctl 10 tablas · 104 columnas
     Llaves foráneas: 171 · Tablas con las 9 columnas de linaje: 69
   ===================================================================== */
USE ADN_Unificado;
GO
SELECT s.name AS Esquema, COUNT(DISTINCT t.object_id) AS Tablas, COUNT(c.column_id) AS Columnas
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
WHERE s.name IN (N'core', N'ref', N'ctl')
GROUP BY s.name
ORDER BY s.name;

SELECT COUNT(*) AS LlavesForaneas
FROM sys.foreign_keys fk
WHERE SCHEMA_NAME(fk.schema_id) IN (N'core', N'ref', N'ctl');

SELECT COUNT(*) AS TablasConLinaje
FROM sys.tables t
WHERE SCHEMA_NAME(t.schema_id) IN (N'core', N'ref')
  AND (SELECT COUNT(*) FROM sys.columns c WHERE c.object_id = t.object_id
       AND c.name IN (N'FuenteSistema', N'FuenteBase', N'FuenteTabla', N'FuenteLlave', N'FechaDato',
                      N'PeriodoDato', N'LoteId', N'FechaCarga', N'HashContenido')) = 9;
GO
