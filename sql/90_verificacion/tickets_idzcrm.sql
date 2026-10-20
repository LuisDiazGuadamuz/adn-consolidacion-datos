/* ¿Por qué ningún ticket de Trengo quedó ligado a un contacto (cobertura 0 %)? - SOLO LECTURA. Solo conteos.
   El paso core_TicketAtencion liga el ticket al contacto del CRM con el ID_ZCRM que trae custom_data. */
SET NOCOUNT ON; SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_WARNINGS ON;
USE ADN_Unificado;

;WITH t AS (
    SELECT CONVERT(nvarchar(max), x.custom_data) COLLATE DATABASE_DEFAULT AS cd FROM ZCRM2Trengo.dbo.trengo_data_tickets x)
SELECT COUNT_BIG(*) AS Tickets,
       SUM(CASE WHEN NULLIF(LTRIM(cd), N'') IS NULL THEN 1 ELSE 0 END) AS CustomDataVacio,
       SUM(CASE WHEN cd IN (N'[]', N'{}', N'null') THEN 1 ELSE 0 END) AS CustomDataSinContenido,
       SUM(CASE WHEN CHARINDEX(N'ID_ZCRM', cd) > 0 THEN 1 ELSE 0 END) AS ConIdZcrm,
       SUM(CASE WHEN CHARINDEX(N'zcrm', LOWER(cd)) > 0 OR CHARINDEX(N'zoho', LOWER(cd)) > 0 THEN 1 ELSE 0 END) AS MencionaZoho
FROM t;

PRINT '== Nombres de campo más comunes en custom_data (solo nombres, sin valores)';
;WITH t AS (
    SELECT CONVERT(nvarchar(max), x.custom_data) COLLATE DATABASE_DEFAULT AS cd FROM ZCRM2Trengo.dbo.trengo_data_tickets x
    WHERE ISJSON(CONVERT(nvarchar(max), x.custom_data)) = 1)
SELECT TOP 20 j.[key] AS Campo, COUNT_BIG(*) AS Tickets
FROM t CROSS APPLY OPENJSON(t.cd) j
GROUP BY j.[key] ORDER BY 2 DESC;

PRINT '== custom_data que no es JSON';
SELECT COUNT_BIG(*) AS NoJson FROM ZCRM2Trengo.dbo.trengo_data_tickets x
WHERE NULLIF(LTRIM(CONVERT(nvarchar(max), x.custom_data)), N'') IS NOT NULL AND ISJSON(CONVERT(nvarchar(max), x.custom_data)) = 0;
