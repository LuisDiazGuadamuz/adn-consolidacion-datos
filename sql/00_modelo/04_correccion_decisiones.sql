/* Corrección del modelo ADN_Unificado (versión 1.2): decisiones de José Hernández del 12/10/2026
   - Crea core.MinutosContratadosHistorico (decisión 1B / D11).
   - Registra en ctl.Regla las decisiones D10 (moneda de llamadas según destino), D11 y D12 (fuentes históricas).
   Se puede ejecutar más de una vez: si los objetos ya existen, no hace nada. Ejecutar en el sandbox.
   Resultado esperado: core 55, ctl 6, ref 14 tablas; 170 llaves foráneas; 42 reglas. */
USE ADN_Unificado;
GO
IF OBJECT_ID(N'core.MinutosContratadosHistorico', N'U') IS NULL
BEGIN
    EXEC(N'/* core.MinutosContratadosHistorico: Minutos contratados registrados a mano en 2022 (histórico, decisión del 12/10/2026). Grano: Una fila por registro de origen. */
CREATE TABLE core.MinutosContratadosHistorico (
    [MinutosContratadosHistoricoId] int IDENTITY(1,1) NOT NULL,
    [ClienteId] int NULL,
    [ServicioId] int NULL,
    [TablaOrigen] varchar(30) NOT NULL,
    [ClienteVoIPOrigenId] bigint NULL,
    [CedulaOriginal] nvarchar(50) NULL,
    [Descripcion] nvarchar(200) NULL,
    [Minutos] decimal(12,2) NULL,
    [MinutosFijo] decimal(12,2) NULL,
    [MinutosCelular] decimal(12,2) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_MinutosContratadosHistorico_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), ''-06:00'')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_MinutosContratadosHistorico] PRIMARY KEY CLUSTERED ([MinutosContratadosHistoricoId])
);
CREATE INDEX [IX_MinutosContratadosHistorico_Linaje] ON core.MinutosContratadosHistorico ([FuenteSistema], [FuenteTabla], [FuenteLlave]);');
    EXEC(N'ALTER TABLE core.MinutosContratadosHistorico ADD CONSTRAINT [FK_MinutosContratadosHistorico_ClienteId] FOREIGN KEY ([ClienteId]) REFERENCES core.Cliente ([ClienteId]);');
    EXEC(N'CREATE INDEX [IX_MinutosContratadosHistorico_ClienteId] ON core.MinutosContratadosHistorico ([ClienteId]);');
    EXEC(N'ALTER TABLE core.MinutosContratadosHistorico ADD CONSTRAINT [FK_MinutosContratadosHistorico_ServicioId] FOREIGN KEY ([ServicioId]) REFERENCES core.Servicio ([ServicioId]);');
    EXEC(N'CREATE INDEX [IX_MinutosContratadosHistorico_ServicioId] ON core.MinutosContratadosHistorico ([ServicioId]);');
    EXEC(N'ALTER TABLE core.MinutosContratadosHistorico ADD CONSTRAINT [FK_MinutosContratadosHistorico_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);');
END
GO
IF NOT EXISTS (SELECT 1 FROM ctl.Regla WHERE ReglaId = N'D10')
    INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'D10', N'Decisión', N'Moneda de tarifas y costos de llamadas según el destino: códigos 506 en colones, el resto en dólares.', N'Crítica', N'C', N'1.1', '2026-10-12', N'José Hernández');
IF NOT EXISTS (SELECT 1 FROM ctl.Regla WHERE ReglaId = N'D11')
    INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'D11', N'Decisión', N'Minutos_Customer y MinutosLegalId se conservan como histórico en core.MinutosContratadosHistorico.', N'Estándar', N'B', N'1.1', '2026-10-12', N'José Hernández');
IF NOT EXISTS (SELECT 1 FROM ctl.Regla WHERE ReglaId = N'D12')
    INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'D12', N'Decisión', N'Tickets de Trengo y conexiones/desconexiones se cargan como fuentes históricas; los tickets sin ID del CRM quedan sin correspondencia (ID-05 sin excepción).', N'Estándar', N'A', N'1.1', '2026-10-12', N'José Hernández');
GO
SELECT s.name AS Esquema, COUNT(DISTINCT t.object_id) AS Tablas FROM sys.tables t JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE s.name IN ('core', 'ref', 'ctl') GROUP BY s.name ORDER BY s.name;
SELECT COUNT(*) AS LlavesForaneas FROM sys.foreign_keys;
SELECT COUNT(*) AS Reglas FROM ctl.Regla;
