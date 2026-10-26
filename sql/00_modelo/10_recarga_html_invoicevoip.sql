/* =====================================================================
   Corrección 10 · Forzar la recarga del HTML recortado de las facturas VoIP (Sprint 4)
   Después de la corrección 09 la columna admite el HTML entero, pero el paso core_ConsumoVoIP_Factura no actualizó
   nada: su HashContenido ya se calculaba sobre el HTML completo del origen, así que para el MERGE "no hubo cambio"
   y las filas siguen con el texto recortado a 1.000 caracteres.
   Este script solo vacía HashContenido de las filas cuyo RutaArchivo no es igual al HTML del origen (comparación
   directa; la primera versión usaba LEN = 1000, pero LEN no cuenta los espacios finales y dejó fuera la mitad).
   La recarga la hace después el ETL (confirm), con bitácora y archivo de rollback como cualquier lote.
   Idempotente. SOLO sandbox.
   ===================================================================== */
SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON;
USE ADN_Unificado;
GO
SET NOCOUNT ON;
DECLARE @n int;
UPDATE m SET HashContenido = NULL
FROM core.ConsumoVoIP m
JOIN ADNApp.dbo.ZohoEngine_invoicevoip o ON ctl.fn_Texto(CONVERT(nvarchar(200), o.id)) COLLATE DATABASE_DEFAULT = m.FuenteLlave
WHERE m.FuenteBase = N'ADNApp' AND m.FuenteTabla = N'ZohoEngine_invoicevoip'
  AND ISNULL(m.RutaArchivo, N'~') <> ISNULL(ctl.fn_Texto(CONVERT(nvarchar(max), o.filepath)) COLLATE DATABASE_DEFAULT, N'~');
SET @n = @@ROWCOUNT;
PRINT CONCAT('Corrección 10: ', @n, ' filas marcadas para recargar el HTML completo');
GO
