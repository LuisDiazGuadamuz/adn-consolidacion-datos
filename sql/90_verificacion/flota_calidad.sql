/* Calidad de las cargas de flota (Sprint 3) - SOLO LECTURA. Solo conteos. */
SET NOCOUNT ON; SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_WARNINGS ON;
USE ADN_Unificado;

PRINT '== 1. Viajes: motivo de los descartes del último lote CONFIRM';
SELECT d.ReglaId, d.Motivo, COUNT(*) AS Filas
FROM ctl.Descarte d
WHERE d.LoteId = (SELECT MAX(LoteId) FROM ctl.Lote WHERE Paso = 'core_ViajeFlota' AND Modo = 'CONFIRM')
GROUP BY d.ReglaId, d.Motivo;

PRINT '== 2. Viajes: llave y fechas en el origen';
SELECT COUNT_BIG(*) AS Filas, SUM(CASE WHEN Id IS NULL THEN 1 ELSE 0 END) AS IdNulo, COUNT(DISTINCT Id) AS IdDistintos,
       SUM(CASE WHEN FechaInicio IS NULL THEN 1 ELSE 0 END) AS FechaInicioNula,
       SUM(CASE WHEN FechaInicio IS NOT NULL AND ctl.fn_FechaCR(CONVERT(nvarchar(30), FechaInicio, 126)) IS NULL THEN 1 ELSE 0 END) AS FechaInicioIlegible,
       MIN(FechaInicio) AS FechaMin, MAX(FechaInicio) AS FechaMax
FROM Navsat.dbo.viajes_ayer_finalizado;

PRINT '== 3. Ubicaciones: repetición de la misma posición (dispositivo + fecha + coordenadas)';
WITH g AS (
    SELECT COUNT_BIG(*) AS Veces
    FROM Navsat.dbo.Ultima_ubicacion
    GROUP BY deviceName, crDateTime, latitude, longitude)
SELECT CASE WHEN Veces = 1 THEN '1' WHEN Veces <= 10 THEN '2-10' WHEN Veces <= 100 THEN '11-100'
            WHEN Veces <= 1000 THEN '101-1000' ELSE 'mas de 1000' END AS VecesRepetida,
       COUNT_BIG(*) AS Posiciones, SUM(Veces) AS Filas
FROM g GROUP BY CASE WHEN Veces = 1 THEN '1' WHEN Veces <= 10 THEN '2-10' WHEN Veces <= 100 THEN '11-100'
            WHEN Veces <= 1000 THEN '101-1000' ELSE 'mas de 1000' END
ORDER BY 1;

PRINT '== 4. Ubicaciones nov-dic 2023: filas, dispositivos y fechas distintas';
SELECT COUNT_BIG(*) AS Filas, COUNT(DISTINCT deviceName) AS Dispositivos, COUNT(DISTINCT crDateTime) AS FechasDistintas,
       SUM(CASE WHEN crDateTime IS NULL OR LTRIM(CONVERT(nvarchar(100), crDateTime)) = N'' THEN 1 ELSE 0 END) AS FechaVacia
FROM Navsat.dbo.Ultima_ubicacion
WHERE ctl.fn_FechaCR(crDateTime) < TODATETIMEOFFSET(CAST('2024-01-01' AS datetime2), '-06:00');

PRINT '== 5. Correcciones del modelo aplicadas en el sandbox';
SELECT '03 EventoConexion.ClienteId' AS Correccion, CASE WHEN COL_LENGTH(N'core.EventoConexion', N'ClienteId') IS NULL THEN 'NO' ELSE 'si' END AS Aplicada;
