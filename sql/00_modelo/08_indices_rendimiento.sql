/* =====================================================================
   Corrección 08 · Índices de rendimiento (Sprint 4, pruebas de rendimiento)
   Las cargas de Books (facturas, pagos, movimientos bancarios, facturas recurrentes, historial de estados, notas,
   conexiones) buscan el cliente de cada fila con core.ClienteOrigen WHERE Sistema = X AND LlaveOrigen = Y.
   La restricción única existente es (Sistema, TablaOrigen, LlaveOrigen): sin TablaOrigen, SQL Server solo puede
   buscar por Sistema y recorre los ~12.000 contactos de Books por cada fila. Este índice permite la búsqueda directa.
   Solo agrega un índice: no cambia datos. Idempotente. SOLO sandbox.
   ===================================================================== */
SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON;
USE ADN_Unificado;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_ClienteOrigen_Sistema_Llave' AND object_id = OBJECT_ID(N'core.ClienteOrigen'))
    CREATE INDEX IX_ClienteOrigen_Sistema_Llave ON core.ClienteOrigen (Sistema, LlaveOrigen) INCLUDE (ClienteId, ServicioId);
GO
PRINT 'Corrección 08 aplicada: IX_ClienteOrigen_Sistema_Llave';
GO
