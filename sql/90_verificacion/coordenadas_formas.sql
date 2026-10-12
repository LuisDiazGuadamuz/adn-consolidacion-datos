/* Forma de las coordenadas que no se pudieron interpretar en servicios (Sprint 3) - SOLO LECTURA.
   Cada dígito se reemplaza por 9 y las secuencias de dígitos se colapsan: no se ve ninguna ubicación real. */
SET NOCOUNT ON; SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_WARNINGS ON;
USE ADN_Unificado;

DECLARE @L int = (SELECT MAX(LoteId) FROM ctl.Lote WHERE Paso = 'core_Servicio' AND Modo = 'CONFIRM' AND Estado = 'Exitoso');

PRINT '== Formas más frecuentes (9 = uno o más dígitos)';
;WITH m AS (
    SELECT TRANSLATE(a.ValorOriginal, N'0123456789', N'9999999999') AS t FROM ctl.Anomalia a
    WHERE a.LoteId = @L AND a.ReglaId = 'ES-05' AND a.Columna = N'Latitud'),
      c AS (
    SELECT REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(t, N'99', N'9'), N'99', N'9'), N'99', N'9'), N'99', N'9'), N'99', N'9') AS Forma FROM m)
SELECT TOP 25 LEFT(Forma, 80) AS Forma, COUNT(*) AS Servicios FROM c GROUP BY LEFT(Forma, 80) ORDER BY Servicios DESC;

PRINT '== Servicios rechazados que sí traen latitud/longitud en campos separados (Accounts_Extended)';
SELECT COUNT(*) AS Rechazados,
       SUM(CASE WHEN NULLIF(LTRIM(CONVERT(nvarchar(60), e.latitude)), N'') IS NOT NULL THEN 1 ELSE 0 END) AS ConLatitudSeparada,
       SUM(CASE WHEN NULLIF(LTRIM(CONVERT(nvarchar(60), e.longitude)), N'') IS NOT NULL THEN 1 ELSE 0 END) AS ConLongitudSeparada
FROM ctl.Anomalia a
JOIN core.Servicio s ON s.ServicioId = a.RegistroId
LEFT JOIN Zoho_Mirror.dbo.Accounts_Extended e ON e.id = s.CuentaCrmId COLLATE SQL_Latin1_General_CP1_CI_AS
WHERE a.LoteId = @L AND a.ReglaId = 'ES-05' AND a.Columna = N'Latitud';

PRINT '== Forma de latitude/longitude separados en esos servicios';
SELECT TOP 10 REPLACE(REPLACE(REPLACE(REPLACE(TRANSLATE(CONVERT(nvarchar(60), e.latitude), N'0123456789', N'9999999999'), N'99', N'9'), N'99', N'9'), N'99', N'9'), N'99', N'9') AS FormaLatitud,
       REPLACE(REPLACE(REPLACE(REPLACE(TRANSLATE(CONVERT(nvarchar(60), e.longitude), N'0123456789', N'9999999999'), N'99', N'9'), N'99', N'9'), N'99', N'9'), N'99', N'9') AS FormaLongitud,
       COUNT(*) AS Servicios
FROM ctl.Anomalia a
JOIN core.Servicio s ON s.ServicioId = a.RegistroId
JOIN Zoho_Mirror.dbo.Accounts_Extended e ON e.id = s.CuentaCrmId COLLATE SQL_Latin1_General_CP1_CI_AS
WHERE a.LoteId = @L AND a.ReglaId = 'ES-05' AND a.Columna = N'Latitud'
GROUP BY REPLACE(REPLACE(REPLACE(REPLACE(TRANSLATE(CONVERT(nvarchar(60), e.latitude), N'0123456789', N'9999999999'), N'99', N'9'), N'99', N'9'), N'99', N'9'), N'99', N'9'),
         REPLACE(REPLACE(REPLACE(REPLACE(TRANSLATE(CONVERT(nvarchar(60), e.longitude), N'0123456789', N'9999999999'), N'99', N'9'), N'99', N'9'), N'99', N'9'), N'99', N'9')
ORDER BY Servicios DESC;
