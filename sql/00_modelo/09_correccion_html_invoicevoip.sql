/* =====================================================================
   Corrección 09 · HTML completo de las facturas VoIP (Sprint 4)
   Decisión de Josué Pérez (26/10/2026, en ausencia de José Hernández): el HTML de las facturas VoIP
   (ADNApp.ZohoEngine_invoicevoip.filepath) se conserva en la base unificada por si se usa en el futuro.
   core.ConsumoVoIP.RutaArchivo era nvarchar(1000): el HTML (hasta ~930 KB) se recortaba (20.955 anomalías ES-05).
   Se amplía a nvarchar(max); después se recarga el paso core_ConsumoVoIP_Factura para guardar el HTML entero.
   Idempotente. SOLO sandbox.
   ===================================================================== */
SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON;
USE ADN_Unificado;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'core.ConsumoVoIP') AND name = N'RutaArchivo' AND max_length <> -1)
    ALTER TABLE core.ConsumoVoIP ALTER COLUMN RutaArchivo nvarchar(max) NULL;
GO
SELECT c.name AS Columna, TYPE_NAME(c.user_type_id) AS Tipo, CASE WHEN c.max_length = -1 THEN 'max' ELSE CAST(c.max_length / 2 AS varchar(10)) END AS Largo
FROM sys.columns c WHERE c.object_id = OBJECT_ID(N'core.ConsumoVoIP') AND c.name = N'RutaArchivo';
PRINT 'Corrección 09 aplicada: core.ConsumoVoIP.RutaArchivo nvarchar(max)';
GO
