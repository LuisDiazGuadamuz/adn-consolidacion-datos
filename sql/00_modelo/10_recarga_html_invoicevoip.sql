/* =====================================================================
   Corrección 10 · Forzar la recarga del HTML recortado de las facturas VoIP (Sprint 4)
   Después de la corrección 09 la columna admite el HTML entero, pero el paso core_ConsumoVoIP_Factura no actualizó
   nada: su HashContenido ya se calculaba sobre el HTML completo del origen, así que para el MERGE "no hubo cambio"
   y las filas siguen con el texto recortado a 1.000 caracteres.
   Este script solo vacía HashContenido de esas filas (las que tienen exactamente 1.000 caracteres en RutaArchivo).
   La recarga la hace después el ETL (confirm), con bitácora y archivo de rollback como cualquier lote.
   Idempotente. SOLO sandbox.
   ===================================================================== */
SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON;
USE ADN_Unificado;
GO
SET NOCOUNT ON;
DECLARE @n int;
UPDATE core.ConsumoVoIP SET HashContenido = NULL
WHERE FuenteBase = N'ADNApp' AND FuenteTabla = N'ZohoEngine_invoicevoip' AND LEN(RutaArchivo) = 1000;
SET @n = @@ROWCOUNT;
PRINT CONCAT('Corrección 10: ', @n, ' filas marcadas para recargar el HTML completo');
GO
