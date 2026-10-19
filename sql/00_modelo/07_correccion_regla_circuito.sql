:on error exit
/* Corrección del modelo ADN_Unificado - regla ID-01 v1.1 (José Hernández: 1A el 13/10/2026, 2B el 19/10/2026).
   El circuito conserva los guiones, como lo escriben todas las fuentes: 3 letras, guion, bloque de 1 a 6 dígitos y,
   opcionalmente, guion y bloque de 1 a 3 dígitos; 2 a 9 dígitos en total. El valor válido más largo tiene 14 caracteres.
   Cambia: Circuito varchar(12) → varchar(14) en 5 tablas, la restricción CK_Servicio_Circuito y la regla en ctl.Regla.
   La función ctl.fn_Circuito se actualiza con `./etl.ps1 instalar` (sql/01_control).
   Uso: ejecutar ANTES de recargar (amplía columnas; la restricción queda sin validar contra los datos viejos) y
   OTRA VEZ DESPUÉS de recargar (valida la restricción contra los circuitos nuevos). Idempotente. Solo sandbox. */
SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON;
USE ADN_Unificado;
IF NOT EXISTS (SELECT 1 FROM ctl.Entorno WHERE Nombre = 'SANDBOX')
    THROW 50001, 'Este script solo se ejecuta en el sandbox.', 1;
GO

/* 1. Restricción e índice que dependen de core.Servicio.Circuito */
IF OBJECT_ID(N'core.CK_Servicio_Circuito', N'C') IS NOT NULL
    ALTER TABLE core.Servicio DROP CONSTRAINT CK_Servicio_Circuito;
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Servicio_Circuito' AND object_id = OBJECT_ID(N'core.Servicio'))
    DROP INDEX IX_Servicio_Circuito ON core.Servicio;
GO

/* 2. Ampliar la columna en las 5 tablas */
DECLARE @t sysname, @sql nvarchar(400);
DECLARE c CURSOR LOCAL FAST_FORWARD FOR
    SELECT QUOTENAME(SCHEMA_NAME(t.schema_id)) + N'.' + QUOTENAME(t.name)
    FROM sys.columns col JOIN sys.tables t ON t.object_id = col.object_id
    WHERE col.name = N'Circuito' AND SCHEMA_NAME(t.schema_id) = N'core' AND col.max_length < 14;
OPEN c; FETCH NEXT FROM c INTO @t;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'ALTER TABLE ' + @t + N' ALTER COLUMN [Circuito] varchar(14) NULL;';
    EXEC (@sql);
    PRINT 'Ampliada ' + @t;
    FETCH NEXT FROM c INTO @t;
END;
CLOSE c; DEALLOCATE c;
GO

/* 3. Índice y restricción de nuevo. Con circuitos viejos (sin guion) la restricción se crea sin validar;
      al ejecutar el script después de la recarga queda validada (WITH CHECK). */
CREATE INDEX IX_Servicio_Circuito ON core.Servicio (Circuito);
IF EXISTS (SELECT 1 FROM core.Servicio WHERE Circuito IS NOT NULL AND Circuito NOT LIKE '[A-Z][A-Z][A-Z]-[0-9]%')
BEGIN
    ALTER TABLE core.Servicio WITH NOCHECK ADD CONSTRAINT CK_Servicio_Circuito
        CHECK ([Circuito] IS NULL OR [Circuito] LIKE '[A-Z][A-Z][A-Z]-[0-9]%');
    PRINT 'CK_Servicio_Circuito creada SIN validar: hay circuitos con la regla anterior. Recargue y ejecute este script otra vez.';
END
ELSE
BEGIN
    ALTER TABLE core.Servicio WITH CHECK ADD CONSTRAINT CK_Servicio_Circuito
        CHECK ([Circuito] IS NULL OR [Circuito] LIKE '[A-Z][A-Z][A-Z]-[0-9]%');
    PRINT 'CK_Servicio_Circuito validada contra todos los circuitos.';
END
GO

/* 4. Regla en el catálogo */
UPDATE ctl.Regla
SET Descripcion = N'El servicio se identifica por el número de circuito normalizado (v1.1: mayúsculas, sin espacios, conservando los guiones; 3 letras, guion, bloque de dígitos y bloque opcional tras guion; 2 a 9 dígitos).',
    OpcionAprobada = '1A+2B', Version = N'1.1', FechaAprobacion = '2026-10-19', AprobadoPor = N'José Hernández'
WHERE ReglaId = N'ID-01';

SELECT SCHEMA_NAME(t.schema_id) + '.' + t.name AS Tabla, col.max_length AS LargoCircuito
FROM sys.columns col JOIN sys.tables t ON t.object_id = col.object_id WHERE col.name = N'Circuito' ORDER BY 1;
SELECT name, is_not_trusted AS SinValidar, definition FROM sys.check_constraints WHERE name = N'CK_Servicio_Circuito';
SELECT ReglaId, Version, OpcionAprobada FROM ctl.Regla WHERE ReglaId = N'ID-01';
