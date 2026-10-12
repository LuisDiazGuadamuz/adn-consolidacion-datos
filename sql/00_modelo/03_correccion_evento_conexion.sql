/* Corrección del modelo ADN_Unificado (versión 1.1) - core.EventoConexion
   La evidencia del 12/10/2026 mostró que customer_name de History_Tables.Conexiones_desconexiones_realizadas
   contiene el ID del contacto de Zoho Books (5.350 de 5.350 coinciden), no un nombre.
   El evento se vincula al cliente por esa llave (ID-04) y no al servicio.
   La tabla está vacía (aún no hay cargas), por lo que el cambio es seguro. Ejecutar una vez en el sandbox. */
USE ADN_Unificado;
IF COL_LENGTH(N'core.EventoConexion', N'NombreCliente') IS NOT NULL
BEGIN
    IF OBJECT_ID(N'core.FK_EventoConexion_ServicioId', N'F') IS NOT NULL
        ALTER TABLE core.EventoConexion DROP CONSTRAINT FK_EventoConexion_ServicioId;
    IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_EventoConexion_ServicioId' AND object_id = OBJECT_ID(N'core.EventoConexion'))
        DROP INDEX IX_EventoConexion_ServicioId ON core.EventoConexion;
    ALTER TABLE core.EventoConexion DROP COLUMN ServicioId, NombreCliente;
    ALTER TABLE core.EventoConexion ADD ClienteId int NULL, ContactoBooksId nvarchar(30) NULL;
END
GO
IF OBJECT_ID(N'core.FK_EventoConexion_ClienteId', N'F') IS NULL
BEGIN
    ALTER TABLE core.EventoConexion ADD CONSTRAINT FK_EventoConexion_ClienteId FOREIGN KEY (ClienteId) REFERENCES core.Cliente (ClienteId);
    CREATE INDEX IX_EventoConexion_ClienteId ON core.EventoConexion (ClienteId);
END
GO
SELECT c.column_id AS Orden, c.name AS Columna, TYPE_NAME(c.user_type_id) AS Tipo
FROM sys.columns c WHERE c.object_id = OBJECT_ID(N'core.EventoConexion') AND c.name IN (N'ClienteId', N'ContactoBooksId', N'ServicioId', N'NombreCliente');
SELECT COUNT(*) AS LlavesForaneas FROM sys.foreign_keys;
