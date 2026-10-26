:on error exit
/* =====================================================================
   Respaldo completo de ADN_Unificado (Sprint 5) · SOLO sandbox
   1. Muestra el tamaño de la base y el espacio libre del disco del contenedor.
   2. BACKUP DATABASE ... WITH COPY_ONLY, CHECKSUM, INIT (no altera la cadena de respaldos de nadie).
   3. RESTORE VERIFYONLY: comprueba que el archivo se puede leer y que las sumas de verificación coinciden.
   El archivo queda en la carpeta de respaldos de la instancia (o en /var/opt/mssql/data si no hay una definida)
   con el nombre ADN_Unificado_respaldo.bak; cada ejecución lo reemplaza.
   OJO: el respaldo contiene datos de clientes. No se sube al repositorio ni se comparte; se guarda solo en el
   equipo del sandbox (docker cp ... C:\Sandbox\respaldos\).
   Uso:
     docker cp sql\95_mantenimiento\respaldo_adn_unificado.sql sandbox-sql:/tmp/r.sql
     docker exec -it sandbox-sql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -C -I -i /tmp/r.sql
   ===================================================================== */
SET NOCOUNT ON;
USE ADN_Unificado;
GO
IF NOT EXISTS (SELECT 1 FROM ctl.Entorno WHERE Nombre = 'SANDBOX')
    THROW 50010, N'La base no tiene la marca SANDBOX: no se ejecuta.', 1;
GO
USE master;
GO
DECLARE @dir nvarchar(400) = ISNULL(CONVERT(nvarchar(400), SERVERPROPERTY('InstanceDefaultBackupPath')), N'/var/opt/mssql/data');
IF RIGHT(@dir, 1) NOT IN (N'/', N'\') SET @dir += N'/';
DECLARE @archivo nvarchar(500) = @dir + N'ADN_Unificado_respaldo.bak';

SELECT CONVERT(varchar(19), SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00'), 120) AS Inicio,
       CAST(SUM(CAST(mf.size AS bigint)) * 8 / 1024.0 AS decimal(12,1)) AS MB_Base,
       CAST(MIN(vs.available_bytes) / 1048576.0 AS decimal(12,1)) AS MB_LibresDisco,
       @archivo AS Archivo
FROM sys.master_files mf
CROSS APPLY sys.dm_os_volume_stats(mf.database_id, mf.file_id) vs
WHERE mf.database_id = DB_ID(N'ADN_Unificado');

DECLARE @comprimir bit = CASE WHEN CONVERT(int, SERVERPROPERTY('EngineEdition')) IN (2, 3) THEN 1 ELSE 0 END; -- Standard / Enterprise / Developer
DECLARE @sql nvarchar(max) = N'BACKUP DATABASE ADN_Unificado TO DISK = @a WITH COPY_ONLY, CHECKSUM, INIT, STATS = 10'
    + CASE WHEN @comprimir = 1 THEN N', COMPRESSION' ELSE N'' END
    + N', NAME = N''ADN_Unificado - respaldo completo (sandbox)'';';
EXEC sp_executesql @sql, N'@a nvarchar(500)', @a = @archivo;

RESTORE VERIFYONLY FROM DISK = @archivo WITH CHECKSUM;

SELECT TOP (1) CONVERT(varchar(19), bs.backup_start_date, 120) AS InicioRespaldo,
       CONVERT(varchar(19), bs.backup_finish_date, 120) AS FinRespaldo,
       DATEDIFF(SECOND, bs.backup_start_date, bs.backup_finish_date) AS Segundos,
       CAST(bs.backup_size / 1048576.0 AS decimal(12,1)) AS MB_Datos,
       CAST(bs.compressed_backup_size / 1048576.0 AS decimal(12,1)) AS MB_Archivo,
       bs.has_backup_checksums AS ConChecksum, bs.is_copy_only AS CopyOnly
FROM msdb.dbo.backupset bs
WHERE bs.database_name = N'ADN_Unificado'
ORDER BY bs.backup_set_id DESC;
PRINT N'Respaldo verificado: ' + @archivo;
GO
