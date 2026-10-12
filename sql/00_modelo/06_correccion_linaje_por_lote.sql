/* Corrección del modelo ADN_Unificado (versión 1.3) - ctl.LinajeCampo guarda el linaje por lote.
   La restricción única pasa de (TablaModelo, RegistroId, Columna) a (TablaModelo, RegistroId, Columna, LoteId):
   cada carga registra el origen de los valores que cambió y el rollback de un lote deja vigente el linaje anterior.
   El linaje vigente de un campo es el de mayor LoteId no revertido. Idempotente. Ejecutar en el sandbox. */
SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON;
USE ADN_Unificado;
IF EXISTS (SELECT 1 FROM sys.key_constraints WHERE name = N'UQ_LinajeCampo_TablaModelo_RegistroId_Columna')
    ALTER TABLE ctl.LinajeCampo DROP CONSTRAINT UQ_LinajeCampo_TablaModelo_RegistroId_Columna;
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE name = N'UQ_LinajeCampo_TablaModelo_RegistroId_Columna_LoteId')
    ALTER TABLE ctl.LinajeCampo ADD CONSTRAINT UQ_LinajeCampo_TablaModelo_RegistroId_Columna_LoteId UNIQUE (TablaModelo, RegistroId, Columna, LoteId);
SELECT name AS Restriccion FROM sys.key_constraints WHERE parent_object_id = OBJECT_ID(N'ctl.LinajeCampo') AND type = 'UQ';
