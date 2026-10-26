:on error exit
/* =====================================================================
   Prueba de restauración del respaldo de ADN_Unificado (Sprint 5) · SOLO sandbox
   Restaura ADN_Unificado_respaldo.bak como una base APARTE (ADN_Unificado_Prueba), compara la cantidad de filas
   de cada tabla de core, ref y ctl contra ADN_Unificado y borra la base de prueba al final.
   No toca ADN_Unificado. Necesita espacio libre al menos igual al tamaño de la base (el script lo comprueba).
   Ejecutar después de respaldo_adn_unificado.sql y sin cargas en marcha (si no, los conteos pueden diferir).
   Uso:
     docker cp sql\95_mantenimiento\prueba_restauracion.sql sandbox-sql:/tmp/p.sql
     docker exec -it sandbox-sql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -C -I -i /tmp/p.sql
   Resultado esperado: TablasDistintas = 0 y "Restauración verificada".
   ===================================================================== */
SET NOCOUNT ON;
USE master;
GO
DECLARE @dir nvarchar(400) = ISNULL(CONVERT(nvarchar(400), SERVERPROPERTY('InstanceDefaultBackupPath')), N'/var/opt/mssql/data');
IF RIGHT(@dir, 1) NOT IN (N'/', N'\') SET @dir += N'/';
DECLARE @archivo nvarchar(500) = @dir + N'ADN_Unificado_respaldo.bak';
DECLARE @datos nvarchar(400) = CONVERT(nvarchar(400), SERVERPROPERTY('InstanceDefaultDataPath'));
IF RIGHT(@datos, 1) NOT IN (N'/', N'\') SET @datos += N'/';

IF DB_ID(N'ADN_Unificado_Prueba') IS NOT NULL
    THROW 50020, N'Ya existe ADN_Unificado_Prueba: bórrela antes de repetir la prueba.', 1;

DECLARE @mbBase decimal(12,1), @mbLibres decimal(12,1);
SELECT @mbBase = SUM(CAST(mf.size AS bigint)) * 8 / 1024.0, @mbLibres = MIN(vs.available_bytes) / 1048576.0
FROM sys.master_files mf CROSS APPLY sys.dm_os_volume_stats(mf.database_id, mf.file_id) vs
WHERE mf.database_id = DB_ID(N'ADN_Unificado');
SELECT @mbBase AS MB_Base, @mbLibres AS MB_LibresDisco;
IF @mbLibres < @mbBase * 1.1
    THROW 50021, N'No hay espacio libre suficiente para restaurar una copia: libere espacio o restaure en otro equipo.', 1;

/* Archivos lógicos del respaldo, para moverlos a nombres nuevos */
DECLARE @f TABLE (LogicalName nvarchar(128), PhysicalName nvarchar(260), Type char(1), FileGroupName nvarchar(128), Size numeric(20,0),
    MaxSize numeric(20,0), FileId bigint, CreateLSN numeric(25,0), DropLSN numeric(25,0), UniqueId uniqueidentifier,
    ReadOnlyLSN numeric(25,0), ReadWriteLSN numeric(25,0), BackupSizeInBytes bigint, SourceBlockSize int, FileGroupId int,
    LogGroupGUID uniqueidentifier, DifferentialBaseLSN numeric(25,0), DifferentialBaseGUID uniqueidentifier, IsReadOnly bit,
    IsPresent bit, TDEThumbprint varbinary(32), SnapshotUrl nvarchar(360));
INSERT @f EXEC (N'RESTORE FILELISTONLY FROM DISK = N''' + @archivo + N'''');

DECLARE @mover nvarchar(max) = N'';
SELECT @mover += N', MOVE N''' + LogicalName + N''' TO N''' + @datos + N'ADN_Unificado_Prueba_' + CONVERT(nvarchar(10), FileId)
                 + CASE Type WHEN 'L' THEN N'.ldf' ELSE N'.mdf' END + N''''
FROM @f;
DECLARE @t0 datetime2 = SYSDATETIME();
DECLARE @sql nvarchar(max) = N'RESTORE DATABASE ADN_Unificado_Prueba FROM DISK = N''' + @archivo + N''' WITH CHECKSUM, STATS = 10' + @mover + N';';
EXEC (@sql);
SELECT DATEDIFF(SECOND, @t0, SYSDATETIME()) AS SegundosRestauracion;
GO

/* Comparación de filas por tabla (core, ref, ctl) */
WITH o AS (
    SELECT s.name + N'.' + t.name AS Tabla, SUM(p.rows) AS Filas
    FROM ADN_Unificado.sys.tables t JOIN ADN_Unificado.sys.schemas s ON s.schema_id = t.schema_id
    JOIN ADN_Unificado.sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0, 1)
    WHERE s.name IN (N'core', N'ref', N'ctl') GROUP BY s.name, t.name),
r AS (
    SELECT s.name + N'.' + t.name AS Tabla, SUM(p.rows) AS Filas
    FROM ADN_Unificado_Prueba.sys.tables t JOIN ADN_Unificado_Prueba.sys.schemas s ON s.schema_id = t.schema_id
    JOIN ADN_Unificado_Prueba.sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0, 1)
    WHERE s.name IN (N'core', N'ref', N'ctl') GROUP BY s.name, t.name)
SELECT COUNT(*) AS Tablas,
       SUM(CASE WHEN o.Filas = r.Filas THEN 1 ELSE 0 END) AS TablasIguales,
       SUM(CASE WHEN o.Filas = r.Filas THEN 0 ELSE 1 END) AS TablasDistintas,
       SUM(ISNULL(o.Filas, 0)) AS FilasOriginal,
       SUM(ISNULL(r.Filas, 0)) AS FilasRestaurada
FROM o FULL JOIN r ON r.Tabla = o.Tabla;

SELECT (SELECT COUNT(*) FROM ADN_Unificado_Prueba.sys.foreign_keys) AS LlavesForaneas,
       (SELECT COUNT(*) FROM ADN_Unificado_Prueba.ctl.Lote) AS Lotes,
       (SELECT TOP (1) Nombre FROM ADN_Unificado_Prueba.ctl.Entorno) AS Entorno;
GO
USE master;
GO
DROP DATABASE ADN_Unificado_Prueba;
PRINT N'Restauración verificada; base de prueba eliminada.';
GO
