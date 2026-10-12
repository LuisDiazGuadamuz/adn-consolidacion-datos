/* =====================================================================
   Objetos de control del ETL (Sprint 3) - ADN_Unificado
   - Esquemas etl (procedimientos de carga) y stg (copias de MongoDB)
   - ctl.Lote ampliado (paso, modo, conteos, archivo de rollback)
   - ctl.Bitacora: bitácora por registro (inserción, actualización con valores anteriores)
   - Funciones de normalización de las reglas aprobadas (ID-01, ID-02, ES-01, ES-02, ES-05, ES-07)
   - ctl.usp_IniciarLote / ctl.usp_CerrarLote
   Idempotente: se puede ejecutar varias veces. SOLO sandbox.
   ===================================================================== */
SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON;
USE ADN_Unificado;
GO
IF SCHEMA_ID(N'etl') IS NULL EXEC(N'CREATE SCHEMA etl');
IF SCHEMA_ID(N'stg') IS NULL EXEC(N'CREATE SCHEMA stg');
GO

/* ---------------- ctl.Lote: columnas adicionales ---------------- */
IF COL_LENGTH(N'ctl.Lote', N'Paso') IS NULL              ALTER TABLE ctl.Lote ADD Paso nvarchar(100) NULL;
IF COL_LENGTH(N'ctl.Lote', N'Modo') IS NULL              ALTER TABLE ctl.Lote ADD Modo varchar(10) NULL;
IF COL_LENGTH(N'ctl.Lote', N'FilasActualizadas') IS NULL ALTER TABLE ctl.Lote ADD FilasActualizadas bigint NULL;
IF COL_LENGTH(N'ctl.Lote', N'FilasSinCambio') IS NULL    ALTER TABLE ctl.Lote ADD FilasSinCambio bigint NULL;
IF COL_LENGTH(N'ctl.Lote', N'Anomalias') IS NULL         ALTER TABLE ctl.Lote ADD Anomalias bigint NULL;
IF COL_LENGTH(N'ctl.Lote', N'Parametros') IS NULL        ALTER TABLE ctl.Lote ADD Parametros nvarchar(400) NULL;
IF COL_LENGTH(N'ctl.Lote', N'ArchivoRollback') IS NULL   ALTER TABLE ctl.Lote ADD ArchivoRollback nvarchar(400) NULL;
IF COL_LENGTH(N'ctl.Lote', N'Mensaje') IS NULL           ALTER TABLE ctl.Lote ADD Mensaje nvarchar(2000) NULL;
IF COL_LENGTH(N'ctl.Lote', N'Equipo') IS NULL            ALTER TABLE ctl.Lote ADD Equipo nvarchar(128) NULL;
GO

/* ---------------- ctl.Bitacora: una fila por registro afectado ---------------- */
IF OBJECT_ID(N'ctl.Bitacora', N'U') IS NULL
CREATE TABLE ctl.Bitacora (
    BitacoraId          bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_ctl_Bitacora PRIMARY KEY CLUSTERED,
    LoteId              int NOT NULL CONSTRAINT FK_Bitacora_LoteId REFERENCES ctl.Lote (LoteId),
    TablaModelo         nvarchar(128) NOT NULL,
    RegistroId          bigint NOT NULL,
    Accion              char(1) NOT NULL CONSTRAINT CK_Bitacora_Accion CHECK (Accion IN ('I', 'U')),
    FuenteLlave         nvarchar(200) NULL,
    ValoresAnteriores   nvarchar(max) NULL CONSTRAINT CK_Bitacora_JSON CHECK (ValoresAnteriores IS NULL OR ISJSON(ValoresAnteriores) = 1),
    Fecha               datetimeoffset(0) NOT NULL CONSTRAINT DF_Bitacora_Fecha DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00'))
);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Bitacora_Lote' AND object_id = OBJECT_ID(N'ctl.Bitacora'))
    CREATE INDEX IX_Bitacora_Lote ON ctl.Bitacora (LoteId, TablaModelo, Accion) INCLUDE (RegistroId);
GO

/* ---------------- Marca de entorno: el ETL se niega a ejecutar si no existe ---------------- */
IF OBJECT_ID(N'ctl.Entorno', N'U') IS NULL
CREATE TABLE ctl.Entorno (Nombre varchar(20) NOT NULL CONSTRAINT PK_ctl_Entorno PRIMARY KEY, FechaRegistro datetimeoffset(0) NOT NULL, Nota nvarchar(400) NULL);
GO
IF NOT EXISTS (SELECT 1 FROM ctl.Entorno WHERE Nombre = 'SANDBOX')
    INSERT ctl.Entorno VALUES ('SANDBOX', SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00'), N'Copia controlada para desarrollo y pruebas del ETL. Nunca crear esta marca en producción.');
GO

/* ---------------- Funciones de normalización ---------------- */
/* Las funciones que dependen de otras (WITH SCHEMABINDING) se eliminan primero para que la instalación se pueda repetir */
DROP FUNCTION IF EXISTS ctl.fn_TipoIdentificacion;
DROP FUNCTION IF EXISTS ctl.fn_EsFechaFicticia;
DROP FUNCTION IF EXISTS ctl.fn_Coordenada;
GO

/* ES-05: recorta espacios; vacío pasa a NULL */
CREATE OR ALTER FUNCTION ctl.fn_Texto (@v nvarchar(max))
RETURNS nvarchar(max) WITH SCHEMABINDING, RETURNS NULL ON NULL INPUT
AS BEGIN
    RETURN NULLIF(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(@v, CHAR(9), N' '), CHAR(13), N' '), CHAR(10), N' '))), N'');
END;
GO

/* ID-02: cédula con solo dígitos. Quita separadores comunes; si queda algún carácter no numérico la
   cédula es inválida y se devuelve NULL (el valor original se conserva aparte, ES-08).
   Una cédula de 10 dígitos que empieza con 0 es física con cero a la izquierda: se quita el cero. */
CREATE OR ALTER FUNCTION ctl.fn_Cedula (@v nvarchar(100))
RETURNS varchar(12) WITH SCHEMABINDING, RETURNS NULL ON NULL INPUT
AS BEGIN
    DECLARE @d nvarchar(100) = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@v)),
                               N'-', N''), N' ', N''), N'.', N''), N'/', N''), N'_', N''), N',', N'');
    IF @d = N'' OR @d LIKE N'%[^0-9]%' RETURN NULL;
    IF LEN(@d) = 10 AND LEFT(@d, 1) = N'0' SET @d = SUBSTRING(@d, 2, 9);
    IF LEN(@d) NOT IN (9, 10, 12) RETURN NULL;
    RETURN CAST(@d AS varchar(12));
END;
GO

/* ID-02: tipo de identificación a partir del valor original */
CREATE OR ALTER FUNCTION ctl.fn_TipoIdentificacion (@v nvarchar(100))
RETURNS varchar(10) WITH SCHEMABINDING
AS BEGIN
    IF NULLIF(LTRIM(RTRIM(@v)), N'') IS NULL RETURN 'SIN_DATO';
    DECLARE @c varchar(12) = ctl.fn_Cedula(@v);
    RETURN CASE LEN(@c) WHEN 9 THEN 'FISICA' WHEN 10 THEN 'JURIDICA' WHEN 12 THEN 'DIMEX' ELSE 'INVALIDA' END;
END;
GO

/* ID-01: circuito normalizado (mayúsculas, sin espacios, guiones ni puntos; 3 letras + 4 a 9 dígitos).
   Si no cumple el patrón devuelve NULL (el original se conserva aparte, ES-08). */
CREATE OR ALTER FUNCTION ctl.fn_Circuito (@v nvarchar(100))
RETURNS varchar(12) WITH SCHEMABINDING, RETURNS NULL ON NULL INPUT
AS BEGIN
    DECLARE @c nvarchar(100) = UPPER(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@v)), N' ', N''), N'-', N''), N'.', N''), N'_', N''));
    IF LEN(@c) BETWEEN 7 AND 12
       AND LEFT(@c, 3) COLLATE Latin1_General_BIN LIKE N'[A-Z][A-Z][A-Z]'
       AND SUBSTRING(@c, 4, 20) NOT LIKE N'%[^0-9]%'
        RETURN CAST(@c AS varchar(12));
    RETURN NULL;
END;
GO

/* ES-01 / ES-02 / D4: fecha con hora en -06:00. Acepta datetime2 o texto (con o sin zona).
   Fechas anteriores a 1990 (p. ej. 1900-01-01) se consideran ficticias y devuelven NULL. */
CREATE OR ALTER FUNCTION ctl.fn_FechaCR (@v nvarchar(60))
RETURNS datetimeoffset(0) WITH SCHEMABINDING, RETURNS NULL ON NULL INPUT
AS BEGIN
    DECLARE @t nvarchar(60) = LTRIM(RTRIM(@v)), @r datetimeoffset(0);
    IF @t = N'' RETURN NULL;
    /* Zona sin dos puntos, como la usa Zoho Books: ...T10:22:33-0600 → ...T10:22:33-06:00 */
    IF @t LIKE N'%T%[+-][0-9][0-9][0-9][0-9]' SET @t = STUFF(@t, LEN(@t) - 1, 0, N':');
    IF @t LIKE N'%[+-][0-9][0-9]:[0-9][0-9]' OR @t LIKE N'%Z'
        SET @r = SWITCHOFFSET(TRY_CONVERT(datetimeoffset(0), REPLACE(@t, N'Z', N'+00:00')), '-06:00');
    ELSE
        SET @r = TODATETIMEOFFSET(TRY_CONVERT(datetime2(0), @t, 126), '-06:00');
    IF @r IS NULL SET @r = TODATETIMEOFFSET(TRY_CONVERT(datetime2(0), @t), '-06:00');
    IF @r < '1990-01-01T00:00:00-06:00' RETURN NULL;
    RETURN @r;
END;
GO

/* Fecha sin hora (ES-02 aplica igual) */
CREATE OR ALTER FUNCTION ctl.fn_FechaDia (@v nvarchar(60))
RETURNS date WITH SCHEMABINDING, RETURNS NULL ON NULL INPUT
AS BEGIN
    DECLARE @d date = TRY_CONVERT(date, LEFT(LTRIM(RTRIM(@v)), 10), 23);
    IF @d IS NULL SET @d = TRY_CONVERT(date, LTRIM(RTRIM(@v)));
    IF @d < '1990-01-01' RETURN NULL;
    RETURN @d;
END;
GO

/* ES-02: indica si un valor de fecha no vacío es ficticio o inválido (para registrar la anomalía) */
CREATE OR ALTER FUNCTION ctl.fn_EsFechaFicticia (@v nvarchar(60))
RETURNS bit WITH SCHEMABINDING
AS BEGIN
    IF NULLIF(LTRIM(RTRIM(@v)), N'') IS NULL RETURN 0;
    RETURN CASE WHEN ctl.fn_FechaDia(@v) IS NULL THEN 1 ELSE 0 END;
END;
GO

/* ES-07: booleano en texto a bit */
CREATE OR ALTER FUNCTION ctl.fn_Bit (@v nvarchar(20))
RETURNS bit WITH SCHEMABINDING, RETURNS NULL ON NULL INPUT
AS BEGIN
    DECLARE @t nvarchar(20) = LOWER(LTRIM(RTRIM(@v)));
    RETURN CASE WHEN @t IN (N'1', N'true', N'si', N'sí', N'yes', N'y', N's', N'verdadero') THEN 1
                WHEN @t IN (N'0', N'false', N'no', N'n', N'falso') THEN 0 END;
END;
GO

/* ES-04: monto en texto o número a decimal(19,4).
   Acepta números simples y la forma de Books 'CRC 25,000.00' / 'USD 1,234.50' (coma = miles, punto = decimales). */
CREATE OR ALTER FUNCTION ctl.fn_Monto (@v nvarchar(60))
RETURNS decimal(19,4) WITH SCHEMABINDING, RETURNS NULL ON NULL INPUT
AS BEGIN
    DECLARE @t nvarchar(60) = UPPER(LTRIM(RTRIM(@v)));
    IF @t LIKE N'[A-Z][A-Z][A-Z] %' SET @t = SUBSTRING(@t, 5, 60);
    SET @t = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@t, N',', N''), N'$', N''), N'₡', N''), N'¢', N''), N' ', N'');
    RETURN TRY_CONVERT(decimal(19,4), TRY_CONVERT(float, @t));
END;
GO

/* ES-04: monto escrito a mano (p. ej. la mensualidad del CRM: '$45', '₡25000', '45.50 dólares').
   Solo devuelve el monto si la forma no es ambigua; '25.000 colones' o '25 000' (separador de miles dudoso) → NULL. */
CREATE OR ALTER FUNCTION ctl.fn_MontoLibre (@v nvarchar(255))
RETURNS decimal(19,4) WITH SCHEMABINDING, RETURNS NULL ON NULL INPUT
AS BEGIN
    DECLARE @t nvarchar(255) = LOWER(LTRIM(RTRIM(@v)));
    SET @t = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@t,
             N'colones', N''), N'colón', N''), N'dólares', N''), N'dolares', N''), N'crc', N''), N'usd', N''), N'$', N''), N'₡', N''), N'¢', N'');
    SET @t = LTRIM(RTRIM(@t));
    IF @t = N'' OR @t LIKE N'%[^0-9.,]%' RETURN NULL;                 -- quedan letras o espacios internos: ambiguo
    IF @t LIKE N'%.[0-9][0-9][0-9]' OR @t LIKE N'%,[0-9][0-9]' RETURN NULL;   -- '25.000' o '45,50': separador dudoso
    RETURN TRY_CONVERT(decimal(19,4), TRY_CONVERT(float, REPLACE(@t, N',', N'')));
END;
GO

/* Moneda indicada en un monto escrito a mano */
CREATE OR ALTER FUNCTION ctl.fn_MonedaTexto (@v nvarchar(255))
RETURNS char(3) WITH SCHEMABINDING
AS BEGIN
    DECLARE @t nvarchar(255) = LOWER(@v);
    RETURN CASE WHEN @t LIKE N'%$%' OR @t LIKE N'%usd%' OR @t LIKE N'%dólar%' OR @t LIKE N'%dolar%' THEN 'USD'
                WHEN @t LIKE N'%₡%' OR @t LIKE N'%¢%' OR @t LIKE N'%crc%' OR @t LIKE N'%colon%' OR @t LIKE N'%colón%' THEN 'CRC' END;
END;
GO

/* ES-04: código de moneda admitido por el modelo (CRC, USD, EUR); otro valor → NULL */
CREATE OR ALTER FUNCTION ctl.fn_Moneda (@v nvarchar(20))
RETURNS char(3) WITH SCHEMABINDING
AS BEGIN
    DECLARE @t nvarchar(20) = UPPER(LTRIM(RTRIM(@v)));
    RETURN CASE WHEN @t IN (N'CRC', N'USD', N'EUR') THEN CAST(@t AS char(3)) END;
END;
GO

/* Coordenadas 'lat,lon' (con o sin espacio). @Parte = 1 latitud, 2 longitud.
   Solo acepta valores dentro de Costa Rica (lat 5 a 12, lon -88 a -82); fuera de rango o '0,0' → NULL. */
/* Una coordenada en grados, minutos y segundos (p. ej. 9°56'12.3"N) → grados decimales con signo */
CREATE OR ALTER FUNCTION ctl.fn_GradosDecimales (@p nvarchar(60))
RETURNS float WITH SCHEMABINDING
AS BEGIN
    DECLARE @t nvarchar(60) = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@p, N'″', N'"'), N'”', N'"'), N'′', N''''), N'’', N''''), N'''''', N'"');
    DECLARE @g int = CHARINDEX(N'°', @t), @m int = CHARINDEX(N'''', @t), @s int = CHARINDEX(N'"', @t);
    DECLARE @h nchar(1) = UPPER(RIGHT(@t, 1)), @d float, @mi float = 0, @se float = 0;
    IF @g < 2 OR @h NOT IN (N'N', N'S', N'E', N'W', N'O') RETURN NULL;
    SET @d = TRY_CONVERT(float, LEFT(@t, @g - 1));
    IF @m > @g + 1 SET @mi = TRY_CONVERT(float, SUBSTRING(@t, @g + 1, @m - @g - 1));
    IF @s > @m + 1 AND @m > 0 SET @se = TRY_CONVERT(float, SUBSTRING(@t, @m + 1, @s - @m - 1));
    IF @d IS NULL OR @mi IS NULL OR @se IS NULL OR @mi >= 60 OR @se >= 60 RETURN NULL;
    RETURN (@d + @mi / 60.0 + @se / 3600.0) * CASE WHEN @h IN (N'S', N'W', N'O') THEN -1 ELSE 1 END;
END;
GO

/* Coordenadas "lat,lon" en un solo texto, validadas dentro de Costa Rica. Formas aceptadas:
   "9.93,-84.08" · "(9.93, -84.08)" · enlace de Google Maps con q=lat,lon · grados 9°56'12.3"N 84°4'48"W ·
   invertidas "-84.08,9.93" (sin ambigüedad en Costa Rica: la latitud es positiva y la longitud negativa) */
CREATE OR ALTER FUNCTION ctl.fn_Coordenada (@v nvarchar(255), @Parte tinyint)
RETURNS decimal(10,7) WITH SCHEMABINDING
AS BEGIN
    DECLARE @t nvarchar(255) = REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@v)), N' ', N''), N'(', N''), N')', N''), @p int, @lat float, @lon float, @x float;
    IF @t IS NULL OR @t NOT LIKE N'%[0-9]%' RETURN NULL;
    IF CHARINDEX(N'q=', @t) > 0 SET @t = SUBSTRING(@t, CHARINDEX(N'q=', @t) + 2, 255);
    IF CHARINDEX(N'&', @t) > 0 SET @t = LEFT(@t, CHARINDEX(N'&', @t) - 1);
    IF CHARINDEX(N'°', @t) > 0
    BEGIN
        SET @p = PATINDEX(N'%[NS]%', @t);
        IF @p = 0 RETURN NULL;
        SET @lat = ctl.fn_GradosDecimales(LEFT(@t, @p));
        SET @lon = ctl.fn_GradosDecimales(REPLACE(SUBSTRING(@t, @p + 1, 255), N',', N''));
    END
    ELSE
    BEGIN
        SET @p = CHARINDEX(N',', @t);
        IF @p < 2 RETURN NULL;
        SET @lat = TRY_CONVERT(float, LEFT(@t, @p - 1));
        SET @lon = TRY_CONVERT(float, SUBSTRING(@t, @p + 1, 255));
        IF @lat BETWEEN -88 AND -82 AND @lon BETWEEN 5 AND 12 SELECT @x = @lat, @lat = @lon, @lon = @x;
    END
    IF @lat IS NULL OR @lon IS NULL OR @lat NOT BETWEEN 5 AND 12 OR @lon NOT BETWEEN -88 AND -82 RETURN NULL;
    RETURN CAST(CASE @Parte WHEN 1 THEN @lat ELSE @lon END AS decimal(10,7));
END;
GO

/* Texto original de coordenadas para la anomalía: sin dígitos ("null,null", "no brinda") cuenta como vacío */
CREATE OR ALTER FUNCTION ctl.fn_CoordenadaTexto (@v nvarchar(255))
RETURNS nvarchar(255) WITH SCHEMABINDING
AS BEGIN
    DECLARE @t nvarchar(255) = NULLIF(LTRIM(RTRIM(@v)), N'');
    RETURN CASE WHEN @t LIKE N'%[0-9]%' THEN @t END;
END;
GO

/* Coordenada suelta (latitud o longitud por separado) con validación de rango de Costa Rica */
CREATE OR ALTER FUNCTION ctl.fn_CoordenadaSola (@v nvarchar(60), @Parte tinyint)
RETURNS decimal(10,7) WITH SCHEMABINDING
AS BEGIN
    DECLARE @x float = TRY_CONVERT(float, REPLACE(LTRIM(RTRIM(@v)), N',', N'.'));
    IF @x IS NULL OR (@Parte = 1 AND @x NOT BETWEEN 5 AND 12) OR (@Parte = 2 AND @x NOT BETWEEN -88 AND -82) RETURN NULL;
    RETURN CAST(@x AS decimal(10,7));
END;
GO

/* Primer número de un texto (p. ej. capacidad '100/100', '50 Mbps') */
CREATE OR ALTER FUNCTION ctl.fn_PrimerNumero (@v nvarchar(255))
RETURNS decimal(19,4) WITH SCHEMABINDING, RETURNS NULL ON NULL INPUT
AS BEGIN
    DECLARE @i int = PATINDEX(N'%[0-9]%', @v);
    IF @i = 0 RETURN NULL;
    DECLARE @r nvarchar(255) = SUBSTRING(@v, @i, 255);
    DECLARE @j int = PATINDEX(N'%[^0-9.]%', @r);
    IF @j > 0 SET @r = LEFT(@r, @j - 1);
    RETURN TRY_CONVERT(decimal(19,4), @r);
END;
GO

/* D10: moneda de tarifas y costos de llamadas según el destino */
CREATE OR ALTER FUNCTION ctl.fn_MonedaLlamada (@codigoDestino nvarchar(30))
RETURNS char(3) WITH SCHEMABINDING
AS BEGIN
    RETURN CASE WHEN LTRIM(@codigoDestino) LIKE N'506%' THEN 'CRC' ELSE 'USD' END;
END;
GO

/* ---------------- Inicio y cierre de lote ---------------- */
CREATE OR ALTER PROCEDURE ctl.usp_IniciarLote
    @Paso nvarchar(100), @Sistema varchar(20), @Motor varchar(20), @Base nvarchar(128), @Tabla nvarchar(128),
    @Modo varchar(10), @Usuario nvarchar(100), @Parametros nvarchar(400) = NULL, @LoteId int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @FuenteId int = (SELECT FuenteId FROM ctl.Fuente WHERE Motor = @Motor AND Base = @Base AND Tabla = @Tabla);
    IF @FuenteId IS NULL
    BEGIN
        INSERT ctl.Fuente (Sistema, Motor, Base, Tabla, Disposicion) VALUES (@Sistema, @Motor, @Base, @Tabla, 'Cargada');
        SET @FuenteId = SCOPE_IDENTITY();
    END
    INSERT ctl.Lote (FuenteId, FechaInicio, Estado, VersionReglas, Usuario, Paso, Modo, Parametros, Equipo)
    VALUES (@FuenteId, SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00'), 'EnCurso', '1.1', @Usuario, @Paso, @Modo, @Parametros, HOST_NAME());
    SET @LoteId = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE ctl.usp_CerrarLote @LoteId int, @Estado varchar(15), @FilasLeidas bigint = NULL, @FilasSinCambio bigint = NULL, @Mensaje nvarchar(2000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE l SET
        FechaFin = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00'),
        Estado = @Estado,
        FilasLeidas = COALESCE(@FilasLeidas, l.FilasLeidas),
        FilasCargadas = (SELECT COUNT_BIG(*) FROM ctl.Bitacora b WHERE b.LoteId = @LoteId AND b.Accion = 'I'),
        FilasActualizadas = (SELECT COUNT_BIG(*) FROM ctl.Bitacora b WHERE b.LoteId = @LoteId AND b.Accion = 'U'),
        FilasDescartadas = (SELECT COUNT_BIG(*) FROM ctl.Descarte d WHERE d.LoteId = @LoteId),
        Anomalias = (SELECT COUNT_BIG(*) FROM ctl.Anomalia a WHERE a.LoteId = @LoteId),
        FilasSinCambio = COALESCE(@FilasSinCambio, l.FilasSinCambio),
        Mensaje = COALESCE(@Mensaje, l.Mensaje)
    FROM ctl.Lote l WHERE l.LoteId = @LoteId;
END;
GO

/* Resumen de un lote (lo usa el runner para el informe de dry-run y de confirmación) */
CREATE OR ALTER PROCEDURE ctl.usp_ResumenLote @LoteId int
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TablaModelo, Accion, COUNT_BIG(*) AS Filas FROM ctl.Bitacora WHERE LoteId = @LoteId GROUP BY TablaModelo, Accion
    UNION ALL
    SELECT N'ctl.Descarte (' + ReglaId + N')', 'D', COUNT_BIG(*) FROM ctl.Descarte WHERE LoteId = @LoteId GROUP BY ReglaId
    UNION ALL
    SELECT N'ctl.Anomalia (' + ReglaId + N')', 'A', COUNT_BIG(*) FROM ctl.Anomalia WHERE LoteId = @LoteId GROUP BY ReglaId
    ORDER BY 1, 2;
END;
GO

/* Verificación */
SELECT N'Objetos de control instalados' AS Resultado,
       (SELECT COUNT(*) FROM sys.objects WHERE schema_id = SCHEMA_ID(N'ctl') AND type IN ('FN', 'IF', 'TF')) AS Funciones,
       (SELECT COUNT(*) FROM sys.procedures WHERE schema_id = SCHEMA_ID(N'ctl')) AS Procedimientos,
       CASE WHEN OBJECT_ID(N'ctl.Bitacora') IS NOT NULL THEN 'Sí' ELSE 'No' END AS Bitacora;
GO

/* Anomalías vigentes: las del último lote confirmado y exitoso de cada paso. Los lotes anteriores quedan como
   historia (y los revertidos no cuentan). Es la vista que se usa para informes de calidad. */
CREATE OR ALTER VIEW ctl.vw_AnomaliaVigente
AS
SELECT a.*, l.Paso
FROM ctl.Anomalia a
JOIN ctl.Lote l ON l.LoteId = a.LoteId
WHERE l.LoteId = (SELECT MAX(x.LoteId) FROM ctl.Lote x WHERE x.Paso = l.Paso AND x.Modo = 'CONFIRM' AND x.Estado = 'Exitoso');
GO
