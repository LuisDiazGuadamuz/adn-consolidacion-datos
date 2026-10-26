/* ¿El HTML de las facturas VoIP quedó entero en el modelo? - SOLO LECTURA. Solo conteos y tamaños. */
SET NOCOUNT ON; SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_WARNINGS ON;
USE ADN_Unificado;
SELECT COUNT_BIG(*) AS Facturas,
       SUM(CASE WHEN m.RutaArchivo IS NULL THEN 1 ELSE 0 END) AS SinHtml,
       SUM(CASE WHEN DATALENGTH(m.RutaArchivo) = 2000 THEN 1 ELSE 0 END) AS Con1000Caracteres,
       SUM(CASE WHEN ISNULL(m.RutaArchivo, N'~') = ISNULL(ctl.fn_Texto(CONVERT(nvarchar(max), o.filepath)) COLLATE DATABASE_DEFAULT, N'~') THEN 1 ELSE 0 END) AS IgualAlOrigen,
       SUM(CAST(DATALENGTH(m.RutaArchivo) AS bigint)) / 1048576 AS MB_EnModelo,
       MAX(DATALENGTH(m.RutaArchivo)) / 1024 AS KB_Maximo
FROM core.ConsumoVoIP m
LEFT JOIN ADNApp.dbo.ZohoEngine_invoicevoip o ON ctl.fn_Texto(CONVERT(nvarchar(200), o.id)) COLLATE DATABASE_DEFAULT = m.FuenteLlave
WHERE m.FuenteBase = N'ADNApp' AND m.FuenteTabla = N'ZohoEngine_invoicevoip';
