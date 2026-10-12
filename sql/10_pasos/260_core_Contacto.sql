USE ADN_Unificado;
GO
/* Paso 260 · core_Contacto → core.Contacto
   Contactos del CRM; heredan el servicio y el cliente de su cuenta.
   Reglas: ID-02, ID-04, ES-01, ES-05, ES-08, DD-02, DD-06, IN-01, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_Contacto @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT q.[ClienteId],
           q.[ServicioId],
           CAST(q.[ContactoCrmId] AS nvarchar(30)) AS [ContactoCrmId],
           CAST(q.[Nombre] AS nvarchar(100)) AS [Nombre],
           CAST(q.[Apellido] AS nvarchar(100)) AS [Apellido],
           CAST(q.[NombreCompleto] AS nvarchar(200)) AS [NombreCompleto],
           CAST(q.[Cedula] AS varchar(12)) AS [Cedula],
           CAST(q.[Correo] AS nvarchar(200)) AS [Correo],
           CAST(q.[Telefono] AS nvarchar(30)) AS [Telefono],
           CAST(q.[Movil] AS nvarchar(30)) AS [Movil],
           CAST(q.[TipoContacto] AS nvarchar(50)) AS [TipoContacto],
           q.[PropietarioUsuarioId],
           q.[AtributosExtendidos],
           q.[FechaCreacionOrigen],
           q.[FechaModificacionOrigen],
           CAST(q.[FuenteSistema] AS varchar(20)) AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[ClienteId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ServicioId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ContactoCrmId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Nombre]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Apellido]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[NombreCompleto]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Cedula]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Correo]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Telefono]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Movil]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TipoContacto]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[PropietarioUsuarioId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[AtributosExtendidos]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaCreacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaModificacionOrigen], 126), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_Eliminado],
           q.[o_Cuenta],
           CONCAT_WS(N',', CASE WHEN LEN(q.[ContactoCrmId]) > 30 THEN N'ContactoCrmId' END, CASE WHEN LEN(q.[Nombre]) > 100 THEN N'Nombre' END, CASE WHEN LEN(q.[Apellido]) > 100 THEN N'Apellido' END, CASE WHEN LEN(q.[NombreCompleto]) > 200 THEN N'NombreCompleto' END, CASE WHEN LEN(q.[Cedula]) > 12 THEN N'Cedula' END, CASE WHEN LEN(q.[Correo]) > 200 THEN N'Correo' END, CASE WHEN LEN(q.[Telefono]) > 30 THEN N'Telefono' END, CASE WHEN LEN(q.[Movil]) > 30 THEN N'Movil' END, CASE WHEN LEN(q.[TipoContacto]) > 50 THEN N'TipoContacto' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT 'ZohoCRM' AS FuenteSistema, N'Zoho_Mirror' AS FuenteBase, N'Contacts' AS FuenteTabla, ctl.fn_Texto(k.id) AS FuenteLlave,
               ctl.fn_FechaCR(k.Created_Time) AS FechaDato,
               sv.ClienteId, sv.ServicioId, ctl.fn_Texto(k.id) AS ContactoCrmId, ctl.fn_Texto(k.First_Name) AS Nombre,
               ctl.fn_Texto(k.Last_Name) AS Apellido, ctl.fn_Texto(k.Full_Name) AS NombreCompleto,
               COALESCE(ctl.fn_Cedula(k.N_mero_Cedula_Pasaporte), ctl.fn_Cedula(k.Cedula_Juridica)) AS Cedula,
               ctl.fn_Texto(k.Email) AS Correo, ctl.fn_Texto(k.Phone) AS Telefono, ctl.fn_Texto(k.Mobile) AS Movil,
               ctl.fn_Texto(k.Tipo_de_Contacto) AS TipoContacto, us.UsuarioId AS PropietarioUsuarioId,
               NULLIF((SELECT ctl.fn_Texto(CONVERT(nvarchar(max), k.[Tel_fono_Empresa])) AS [Tel_fono_Empresa], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Last_Enriched_Time__s])) AS [Last_Enriched_Time__s], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Reason_for_Conversion_Failure])) AS [Reason_for_Conversion_Failure], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Fax])) AS [Fax], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Tag])) AS [Tag], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Referrer])) AS [Referrer], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Ad_Campaign_Name])) AS [Ad_Campaign_Name], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Nombre_de_la_Empresa])) AS [Nombre_de_la_Empresa], ctl.fn_Texto(CONVERT(nvarchar(max), k.[woztellfull__WhatsApp_Opt_Out])) AS [woztellfull__WhatsApp_Opt_Out], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Tel_fonos_Empresa])) AS [Tel_fonos_Empresa], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Profesi_n_Ocupaci_n])) AS [Profesi_n_Ocupaci_n], ctl.fn_Texto(CONVERT(nvarchar(max), k.[s])) AS [s], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Direcci_n_Exacta])) AS [Direcci_n_Exacta], ctl.fn_Texto(CONVERT(nvarchar(max), k.[First_Visited_Time])) AS [First_Visited_Time], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Cant_n])) AS [Cant_n], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Device_Type])) AS [Device_Type], ctl.fn_Texto(CONVERT(nvarchar(max), k.[woztellfull__WhatsApp])) AS [woztellfull__WhatsApp], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Keyword])) AS [Keyword], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Provincia])) AS [Provincia], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Pais])) AS [Pais], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Categoria])) AS [Categoria], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Cost_per_Conversion])) AS [Cost_per_Conversion], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Conversion_Export_Status])) AS [Conversion_Export_Status], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Record_Image])) AS [Record_Image], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Salutation])) AS [Salutation], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Average_Time_Spent_Minutes])) AS [Average_Time_Spent_Minutes], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Search_Partner_Network])) AS [Search_Partner_Network], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Number_Of_Chats])) AS [Number_Of_Chats], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Ad])) AS [Ad], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Description])) AS [Description], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Estado_Civil])) AS [Estado_Civil], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Last_Visited_Time])) AS [Last_Visited_Time], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Nacionalidad])) AS [Nacionalidad], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Direcci_n_Empresa])) AS [Direcci_n_Empresa], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Home_Phone])) AS [Home_Phone], ctl.fn_Texto(CONVERT(nvarchar(max), k.[AdGroup_Name])) AS [AdGroup_Name], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Cube_Status])) AS [Cube_Status], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Click_Type])) AS [Click_Type], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Days_Visited])) AS [Days_Visited], ctl.fn_Texto(CONVERT(nvarchar(max), k.[First_Visited_URL])) AS [First_Visited_URL], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Enrich_Status__s])) AS [Enrich_Status__s], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Cost_per_Click])) AS [Cost_per_Click], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Conversion_Exported_On])) AS [Conversion_Exported_On], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Razon_Social])) AS [Razon_Social], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Nodo_Principal])) AS [Nodo_Principal], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Ad_Network])) AS [Ad_Network], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Currency])) AS [Currency], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Exchange_Rate])) AS [Exchange_Rate], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Unsubscribed_Mode])) AS [Unsubscribed_Mode], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Last_Activity_Time])) AS [Last_Activity_Time], ctl.fn_Texto(CONVERT(nvarchar(max), k.[woztellfull__WhatsApp_message])) AS [woztellfull__WhatsApp_message], ctl.fn_Texto(CONVERT(nvarchar(max), k.[woztellfull__No_WhatsApp])) AS [woztellfull__No_WhatsApp], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Other_Phone])) AS [Other_Phone], ctl.fn_Texto(CONVERT(nvarchar(max), k.[Visitor_Score])) AS [Visitor_Score] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER), N'{}') AS AtributosExtendidos,
               ctl.fn_FechaCR(k.Created_Time) AS FechaCreacionOrigen, ctl.fn_FechaCR(k.Modified_Time) AS FechaModificacionOrigen,
               CAST(ISNULL(k.deleted, 0) AS int) AS o_Eliminado, ctl.fn_Texto(k.Account_Name) AS o_Cuenta
        FROM Zoho_Mirror.dbo.Contacts k
        LEFT JOIN core.Servicio sv ON sv.CuentaCrmId = ctl.fn_Texto(k.Account_Name)
        LEFT JOIN ref.Usuario us ON us.ZohoUsuarioId = ctl.fn_Texto(k.Owner)
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 2. Filtros de carga: filas excluidas con la regla que las excluye (DD-06) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'DD-06', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'Contacto marcado como eliminado en Zoho (deleted = 1)', @Ahora FROM #src s WHERE s.o_Eliminado = 1
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'DD-06' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE s FROM #src s WHERE s.o_Eliminado = 1;
    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'ContactoCrmId obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[ContactoCrmId] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FuenteLlave obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FuenteLlave] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE FROM #src WHERE [ContactoCrmId] IS NULL OR [FuenteLlave] IS NULL;

    /* 2b. Duplicados por la llave del paso (DD-02); el orden es determinista */
    ;WITH r AS (
        SELECT s.FuenteSistema, s.FuenteTabla, s.FuenteLlave,
               ROW_NUMBER() OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.FechaModificacionOrigen DESC, s.HashContenido) AS rn,
               FIRST_VALUE(s.FuenteLlave) OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.FechaModificacionOrigen DESC, s.HashContenido ROWS UNBOUNDED PRECEDING) AS Conservada
        FROM #src s)
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, LlaveConservada, Motivo, FechaDescarte)
    SELECT @LoteId, 'DD-02', r.FuenteSistema, r.FuenteTabla, r.FuenteLlave, r.Conservada, N'Versión anterior del mismo contacto en el espejo de Zoho', @Ahora
    FROM r WHERE r.rn > 1
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'DD-02' AND x.FuenteTabla = r.FuenteTabla AND x.FuenteLlave = r.FuenteLlave);
    ;WITH r AS (
        SELECT ROW_NUMBER() OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.FechaModificacionOrigen DESC, s.HashContenido) AS rn FROM #src s)
    DELETE FROM r WHERE rn > 1;
    DECLARE @Validas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 3. Imagen previa de las filas que van a cambiar (para el rollback) */
    DROP TABLE IF EXISTS #antes;
    SELECT t.[ContactoId] AS RegistroId, t.FuenteLlave, (SELECT t.[ClienteId], t.[ServicioId], t.[ContactoCrmId], t.[Nombre], t.[Apellido], t.[NombreCompleto], t.[Cedula], t.[Correo], t.[Telefono], t.[Movil], t.[TipoContacto], t.[PropietarioUsuarioId], t.[AtributosExtendidos], t.[FechaCreacionOrigen], t.[FechaModificacionOrigen], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.Contacto t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido;

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.Contacto WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido) THEN
        UPDATE SET t.[ClienteId] = s.[ClienteId], t.[ServicioId] = s.[ServicioId], t.[ContactoCrmId] = s.[ContactoCrmId], t.[Nombre] = s.[Nombre], t.[Apellido] = s.[Apellido], t.[NombreCompleto] = s.[NombreCompleto], t.[Cedula] = s.[Cedula], t.[Correo] = s.[Correo], t.[Telefono] = s.[Telefono], t.[Movil] = s.[Movil], t.[TipoContacto] = s.[TipoContacto], t.[PropietarioUsuarioId] = s.[PropietarioUsuarioId], t.[AtributosExtendidos] = s.[AtributosExtendidos], t.[FechaCreacionOrigen] = s.[FechaCreacionOrigen], t.[FechaModificacionOrigen] = s.[FechaModificacionOrigen], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([ClienteId], [ServicioId], [ContactoCrmId], [Nombre], [Apellido], [NombreCompleto], [Cedula], [Correo], [Telefono], [Movil], [TipoContacto], [PropietarioUsuarioId], [AtributosExtendidos], [FechaCreacionOrigen], [FechaModificacionOrigen], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[ClienteId], s.[ServicioId], s.[ContactoCrmId], s.[Nombre], s.[Apellido], s.[NombreCompleto], s.[Cedula], s.[Correo], s.[Telefono], s.[Movil], s.[TipoContacto], s.[PropietarioUsuarioId], s.[AtributosExtendidos], s.[FechaCreacionOrigen], s.[FechaModificacionOrigen], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[ContactoId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.Contacto', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías de las filas afectadas */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.Contacto', c.RegistroId, LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #cambios c JOIN core.Contacto t ON t.[ContactoId] = c.RegistroId JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.Contacto', c.RegistroId, N'ServicioId', LEFT(CONVERT(nvarchar(400), s.o_Cuenta), 400), N'Cuenta del contacto sin correspondencia'
    FROM #cambios c JOIN core.Contacto t ON t.[ContactoId] = c.RegistroId JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Cuenta IS NOT NULL AND s.ServicioId IS NULL;

    SELECT @Leidas AS FilasLeidas, @Validas - (SELECT COUNT_BIG(*) FROM #cambios) AS FilasSinCambio;
END;
GO
