USE ADN_Unificado;
GO
/* Paso 200 · ref_Usuario → ref.Usuario
   Usuarios de Zoho (ejecutivos, técnicos, agentes). Varias versiones del mismo usuario: se conserva la más reciente (DD-02).
   Reglas: ES-01, ES-05, DD-02, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_ref_Usuario @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT CAST(q.[ZohoUsuarioId] AS nvarchar(30)) AS [ZohoUsuarioId],
           CAST(q.[NombreCompleto] AS nvarchar(200)) AS [NombreCompleto],
           CAST(q.[Correo] AS nvarchar(200)) AS [Correo],
           CAST(q.[Telefono] AS nvarchar(30)) AS [Telefono],
           CAST(q.[Rol] AS nvarchar(100)) AS [Rol],
           CAST(q.[Perfil] AS nvarchar(100)) AS [Perfil],
           CAST(q.[Division] AS nvarchar(100)) AS [Division],
           CAST(q.[Estado] AS nvarchar(30)) AS [Estado],
           q.[AtributosExtendidos],
           q.[FechaCreacionOrigen],
           q.[FechaModificacionOrigen],
           CAST(q.[FuenteSistema] AS varchar(20)) AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[ZohoUsuarioId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[NombreCompleto]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Correo]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Telefono]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Rol]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Perfil]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Division]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Estado]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[AtributosExtendidos]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaCreacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaModificacionOrigen], 126), N'~'))) AS HashContenido,
           CONCAT_WS(N',', CASE WHEN LEN(q.[ZohoUsuarioId]) > 30 THEN N'ZohoUsuarioId' END, CASE WHEN LEN(q.[NombreCompleto]) > 200 THEN N'NombreCompleto' END, CASE WHEN LEN(q.[Correo]) > 200 THEN N'Correo' END, CASE WHEN LEN(q.[Telefono]) > 30 THEN N'Telefono' END, CASE WHEN LEN(q.[Rol]) > 100 THEN N'Rol' END, CASE WHEN LEN(q.[Perfil]) > 100 THEN N'Perfil' END, CASE WHEN LEN(q.[Division]) > 100 THEN N'Division' END, CASE WHEN LEN(q.[Estado]) > 30 THEN N'Estado' END) AS _Recortadas
    INTO #src
    FROM (
        SELECT 'ZohoCRM' AS FuenteSistema, N'Zoho_Mirror' AS FuenteBase, N'Users' AS FuenteTabla, ctl.fn_Texto(u.id) AS FuenteLlave,
               ctl.fn_FechaCR(u.Created_Time) AS FechaDato,
               ctl.fn_Texto(u.id) AS ZohoUsuarioId, ctl.fn_Texto(u.full_name) AS NombreCompleto, ctl.fn_Texto(u.email) AS Correo,
               ctl.fn_Texto(u.phone) AS Telefono, ctl.fn_Texto(u.role) AS Rol, ctl.fn_Texto(u.profile) AS Perfil,
               ctl.fn_Texto(u.Division) AS Division, ctl.fn_Texto(u.status) AS Estado,
               NULLIF((SELECT ctl.fn_Texto(CONVERT(nvarchar(max), u.[date_format])) AS [date_format], ctl.fn_Texto(CONVERT(nvarchar(max), u.[territories])) AS [territories], ctl.fn_Texto(CONVERT(nvarchar(max), u.[confirm])) AS [confirm], ctl.fn_Texto(CONVERT(nvarchar(max), u.[zuid])) AS [zuid], ctl.fn_Texto(CONVERT(nvarchar(max), u.[Extension_Number])) AS [Extension_Number], ctl.fn_Texto(CONVERT(nvarchar(max), u.[Shift_Effective_From])) AS [Shift_Effective_From], ctl.fn_Texto(CONVERT(nvarchar(max), u.[time_zone])) AS [time_zone], ctl.fn_Texto(CONVERT(nvarchar(max), u.[last_name])) AS [last_name], ctl.fn_Texto(CONVERT(nvarchar(max), u.[Next_Shift])) AS [Next_Shift], ctl.fn_Texto(CONVERT(nvarchar(max), u.[mobile])) AS [mobile], ctl.fn_Texto(CONVERT(nvarchar(max), u.[offset])) AS [offset], ctl.fn_Texto(CONVERT(nvarchar(max), u.[time_format])) AS [time_format], ctl.fn_Texto(CONVERT(nvarchar(max), u.[status_reason__s])) AS [status_reason__s], ctl.fn_Texto(CONVERT(nvarchar(max), u.[decimal_separator])) AS [decimal_separator], ctl.fn_Texto(CONVERT(nvarchar(max), u.[zip])) AS [zip], ctl.fn_Texto(CONVERT(nvarchar(max), u.[Reporting_To])) AS [Reporting_To], ctl.fn_Texto(CONVERT(nvarchar(max), u.[first_name])) AS [first_name], ctl.fn_Texto(CONVERT(nvarchar(max), u.[sandboxDeveloper])) AS [sandboxDeveloper], ctl.fn_Texto(CONVERT(nvarchar(max), u.[country_locale])) AS [country_locale], ctl.fn_Texto(CONVERT(nvarchar(max), u.[state])) AS [state], ctl.fn_Texto(CONVERT(nvarchar(max), u.[theme])) AS [theme], ctl.fn_Texto(CONVERT(nvarchar(max), u.[Currency])) AS [Currency], ctl.fn_Texto(CONVERT(nvarchar(max), u.[street])) AS [street], ctl.fn_Texto(CONVERT(nvarchar(max), u.[Modified_By])) AS [Modified_By], ctl.fn_Texto(CONVERT(nvarchar(max), u.[default_tab_group])) AS [default_tab_group], ctl.fn_Texto(CONVERT(nvarchar(max), u.[Isonline])) AS [Isonline], ctl.fn_Texto(CONVERT(nvarchar(max), u.[personal_account])) AS [personal_account], ctl.fn_Texto(CONVERT(nvarchar(max), u.[locale])) AS [locale], ctl.fn_Texto(CONVERT(nvarchar(max), u.[microsoft])) AS [microsoft], ctl.fn_Texto(CONVERT(nvarchar(max), u.[language])) AS [language], ctl.fn_Texto(CONVERT(nvarchar(max), u.[name_format])) AS [name_format], ctl.fn_Texto(CONVERT(nvarchar(max), u.[Current_Shift])) AS [Current_Shift], ctl.fn_Texto(CONVERT(nvarchar(max), u.[city])) AS [city], ctl.fn_Texto(CONVERT(nvarchar(max), u.[customize_info])) AS [customize_info], ctl.fn_Texto(CONVERT(nvarchar(max), u.[country])) AS [country] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER), N'{}') AS AtributosExtendidos,
               ctl.fn_FechaCR(u.Created_Time) AS FechaCreacionOrigen, ctl.fn_FechaCR(u.Modified_Time) AS FechaModificacionOrigen
        FROM Zoho_Mirror.dbo.Users u
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'ZohoUsuarioId obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[ZohoUsuarioId] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FuenteLlave obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FuenteLlave] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE FROM #src WHERE [ZohoUsuarioId] IS NULL OR [FuenteLlave] IS NULL;

    /* 2b. Duplicados por la llave del paso (DD-02); el orden es determinista */
    ;WITH r AS (
        SELECT s.FuenteSistema, s.FuenteTabla, s.FuenteLlave,
               ROW_NUMBER() OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.FechaModificacionOrigen DESC, s.HashContenido) AS rn,
               FIRST_VALUE(s.FuenteLlave) OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.FechaModificacionOrigen DESC, s.HashContenido ROWS UNBOUNDED PRECEDING) AS Conservada
        FROM #src s)
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, LlaveConservada, Motivo, FechaDescarte)
    SELECT @LoteId, 'DD-02', r.FuenteSistema, r.FuenteTabla, r.FuenteLlave, r.Conservada, N'Versión anterior del mismo usuario en el espejo de Zoho', @Ahora
    FROM r WHERE r.rn > 1
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'DD-02' AND x.FuenteTabla = r.FuenteTabla AND x.FuenteLlave = r.FuenteLlave);
    ;WITH r AS (
        SELECT ROW_NUMBER() OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.FechaModificacionOrigen DESC, s.HashContenido) AS rn FROM #src s)
    DELETE FROM r WHERE rn > 1;
    DECLARE @Validas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 3. Imagen previa de las filas que van a cambiar (para el rollback) */
    DROP TABLE IF EXISTS #antes;
    SELECT t.[UsuarioId] AS RegistroId, t.FuenteLlave, (SELECT t.[ZohoUsuarioId], t.[NombreCompleto], t.[Correo], t.[Telefono], t.[Rol], t.[Perfil], t.[Division], t.[Estado], t.[AtributosExtendidos], t.[FechaCreacionOrigen], t.[FechaModificacionOrigen], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM ref.Usuario t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido;

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE ref.Usuario WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido) THEN
        UPDATE SET t.[ZohoUsuarioId] = s.[ZohoUsuarioId], t.[NombreCompleto] = s.[NombreCompleto], t.[Correo] = s.[Correo], t.[Telefono] = s.[Telefono], t.[Rol] = s.[Rol], t.[Perfil] = s.[Perfil], t.[Division] = s.[Division], t.[Estado] = s.[Estado], t.[AtributosExtendidos] = s.[AtributosExtendidos], t.[FechaCreacionOrigen] = s.[FechaCreacionOrigen], t.[FechaModificacionOrigen] = s.[FechaModificacionOrigen], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([ZohoUsuarioId], [NombreCompleto], [Correo], [Telefono], [Rol], [Perfil], [Division], [Estado], [AtributosExtendidos], [FechaCreacionOrigen], [FechaModificacionOrigen], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[ZohoUsuarioId], s.[NombreCompleto], s.[Correo], s.[Telefono], s.[Rol], s.[Perfil], s.[Division], s.[Estado], s.[AtributosExtendidos], s.[FechaCreacionOrigen], s.[FechaModificacionOrigen], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[UsuarioId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'ref.Usuario', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías de las filas afectadas */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'ref.Usuario', c.RegistroId, LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #cambios c JOIN ref.Usuario t ON t.[UsuarioId] = c.RegistroId JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    -- sin reglas de anomalía en este paso

    SELECT @Leidas AS FilasLeidas, @Validas - (SELECT COUNT_BIG(*) FROM #cambios) AS FilasSinCambio;
END;
GO
