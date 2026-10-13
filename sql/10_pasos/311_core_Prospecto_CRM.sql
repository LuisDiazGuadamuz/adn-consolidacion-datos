USE ADN_Unificado;
GO
/* Paso 311 · core_Prospecto_CRM → core.Prospecto
   Prospectos del CRM. Si la cédula ya es de un cliente consolidado, se vincula (ID-02).
   Reglas: DD-06, ES-01, ES-02, ID-02, IN-01, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_Prospecto_CRM @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT CAST(q.[Cedula] AS varchar(12)) COLLATE DATABASE_DEFAULT AS [Cedula],
           CAST(q.[Origen] AS nvarchar(100)) COLLATE DATABASE_DEFAULT AS [Origen],
           CAST(q.[Apellido] AS nvarchar(100)) COLLATE DATABASE_DEFAULT AS [Apellido],
           CAST(q.[Segmento] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Segmento],
           CAST(q.[Movil] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [Movil],
           CAST(q.[Canton] AS nvarchar(80)) COLLATE DATABASE_DEFAULT AS [Canton],
           q.[FechaConversion],
           q.[FechaModificacionOrigen],
           CAST(q.[Provincia] AS nvarchar(60)) COLLATE DATABASE_DEFAULT AS [Provincia],
           CAST(q.[Telefono] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [Telefono],
           CAST(q.[Nombre] AS nvarchar(100)) COLLATE DATABASE_DEFAULT AS [Nombre],
           CAST(q.[Estado] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Estado],
           q.[FechaCreacionOrigen],
           CAST(q.[Correo] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [Correo],
           CAST(q.[Empresa] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [Empresa],
           q.[PropietarioUsuarioId],
           q.[ClienteId],
           q.[AtributosExtendidos] COLLATE DATABASE_DEFAULT AS [AtributosExtendidos],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[Cedula]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Origen]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Apellido]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Segmento]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Movil]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Canton]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaConversion], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaModificacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Provincia]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Telefono]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Nombre]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Estado]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaCreacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Correo]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Empresa]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[PropietarioUsuarioId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ClienteId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[AtributosExtendidos]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_PropietarioUsuarioId],
           q.[o_FechaConversion],
           q.[o_FechaModificacionOrigen],
           q.[o_FechaCreacionOrigen],
           q.[o_Eliminado],
           CONCAT_WS(N',', CASE WHEN LEN(q.[Cedula]) > 12 THEN N'Cedula' END, CASE WHEN LEN(q.[Origen]) > 100 THEN N'Origen' END, CASE WHEN LEN(q.[Apellido]) > 100 THEN N'Apellido' END, CASE WHEN LEN(q.[Segmento]) > 50 THEN N'Segmento' END, CASE WHEN LEN(q.[Movil]) > 30 THEN N'Movil' END, CASE WHEN LEN(q.[Canton]) > 80 THEN N'Canton' END, CASE WHEN LEN(q.[Provincia]) > 60 THEN N'Provincia' END, CASE WHEN LEN(q.[Telefono]) > 30 THEN N'Telefono' END, CASE WHEN LEN(q.[Nombre]) > 100 THEN N'Nombre' END, CASE WHEN LEN(q.[Estado]) > 50 THEN N'Estado' END, CASE WHEN LEN(q.[Correo]) > 200 THEN N'Correo' END, CASE WHEN LEN(q.[Empresa]) > 200 THEN N'Empresa' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT 'ZohoCRM' AS FuenteSistema,
               N'Zoho_Mirror' AS FuenteBase,
               N'Leads' AS FuenteTabla,
               ctl.fn_Texto(CONVERT(nvarchar(200), l.[id])) AS FuenteLlave,
               ctl.fn_FechaCR(CONVERT(nvarchar(60), l.[Created_Time])) AS FechaDato,
               ctl.fn_Cedula(CONVERT(nvarchar(100), l.[Legal_ID])) AS [Cedula],
               ctl.fn_Texto(CONVERT(nvarchar(max), l.[Lead_Source])) AS [Origen],
               ctl.fn_Texto(CONVERT(nvarchar(max), l.[Last_Name])) AS [Apellido],
               ctl.fn_Texto(CONVERT(nvarchar(max), l.[Segmento])) AS [Segmento],
               ctl.fn_Texto(CONVERT(nvarchar(max), l.[Mobile])) AS [Movil],
               ctl.fn_Texto(CONVERT(nvarchar(max), l.[Cant_n])) AS [Canton],
               ctl.fn_FechaCR(CONVERT(nvarchar(60), l.[Fecha_Conversion])) AS [FechaConversion],
               ctl.fn_FechaCR(CONVERT(nvarchar(60), l.[Modified_Time])) AS [FechaModificacionOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(max), l.[Provincia])) AS [Provincia],
               ctl.fn_Texto(CONVERT(nvarchar(max), l.[Phone])) AS [Telefono],
               ctl.fn_Texto(CONVERT(nvarchar(max), l.[First_Name])) AS [Nombre],
               ctl.fn_Texto(CONVERT(nvarchar(max), l.[Lead_Status])) AS [Estado],
               ctl.fn_FechaCR(CONVERT(nvarchar(60), l.[Created_Time])) AS [FechaCreacionOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(max), l.[Email])) AS [Correo],
               ctl.fn_Texto(CONVERT(nvarchar(max), l.[Company])) AS [Empresa],
               fk_PropietarioUsuarioId_0.Id AS [PropietarioUsuarioId],
               ctl.fn_Texto(CONVERT(nvarchar(400), l.[Owner])) AS [o_PropietarioUsuarioId],
               cl.ClienteId AS [ClienteId],
               ctl.fn_Texto(CONVERT(nvarchar(400), l.[Fecha_Conversion])) AS [o_FechaConversion],
               ctl.fn_Texto(CONVERT(nvarchar(400), l.[Modified_Time])) AS [o_FechaModificacionOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(400), l.[Created_Time])) AS [o_FechaCreacionOrigen],
               NULLIF((SELECT ctl.fn_Texto(CONVERT(nvarchar(max), l.[Last_Enriched_Time__s])) AS [Last_Enriched_Time__s], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Reason_for_Conversion_Failure])) AS [Reason_for_Conversion_Failure], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Tag])) AS [Tag], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Referrer])) AS [Referrer], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Ad_Campaign_Name])) AS [Ad_Campaign_Name], ctl.fn_Texto(CONVERT(nvarchar(max), l.[woztellfull__WhatsApp_Opt_Out])) AS [woztellfull__WhatsApp_Opt_Out], ctl.fn_Texto(CONVERT(nvarchar(max), l.[s])) AS [s], ctl.fn_Texto(CONVERT(nvarchar(max), l.[First_Visited_Time])) AS [First_Visited_Time], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Direcci_n_Exacta])) AS [Direcci_n_Exacta], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Fecha_Estimada_Cobertura])) AS [Fecha_Estimada_Cobertura], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Device_Type])) AS [Device_Type], ctl.fn_Texto(CONVERT(nvarchar(max), l.[woztellfull__WhatsApp])) AS [woztellfull__WhatsApp], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Keyword])) AS [Keyword], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Distritos])) AS [Distritos], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Tipo_de_Prospecto])) AS [Tipo_de_Prospecto], ctl.fn_Texto(CONVERT(nvarchar(max), l.[From_Odoo])) AS [From_Odoo], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Categoria])) AS [Categoria], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Condominio_Aprobado])) AS [Condominio_Aprobado], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Modified_By])) AS [Modified_By], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Cost_per_Conversion])) AS [Cost_per_Conversion], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Telefono_Adicional])) AS [Telefono_Adicional], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Conversion_Export_Status])) AS [Conversion_Export_Status], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Full_Name])) AS [Full_Name], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Salutation])) AS [Salutation], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Referencia])) AS [Referencia], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Average_Time_Spent_Minutes])) AS [Average_Time_Spent_Minutes], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Search_Partner_Network])) AS [Search_Partner_Network], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Number_Of_Chats])) AS [Number_Of_Chats], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Ad])) AS [Ad], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Description])) AS [Description], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Created_By])) AS [Created_By], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Last_Visited_Time])) AS [Last_Visited_Time], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Zona_Cobertura])) AS [Zona_Cobertura], ctl.fn_Texto(CONVERT(nvarchar(max), l.[AdGroup_Name])) AS [AdGroup_Name], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Enrich_Status__s])) AS [Enrich_Status__s], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Click_Type])) AS [Click_Type], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Days_Visited])) AS [Days_Visited], ctl.fn_Texto(CONVERT(nvarchar(max), l.[First_Visited_URL])) AS [First_Visited_URL], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Cost_per_Click])) AS [Cost_per_Click], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Coordenadas_GPS])) AS [Coordenadas_GPS], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Conversion_Exported_On])) AS [Conversion_Exported_On], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Ad_Network])) AS [Ad_Network], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Motivo_descarte])) AS [Motivo_descarte], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Currency])) AS [Currency], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Odoo_Sync])) AS [Odoo_Sync], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Exchange_Rate])) AS [Exchange_Rate], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Unsubscribed_Mode])) AS [Unsubscribed_Mode], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Industry])) AS [Industry], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Last_Activity_Time])) AS [Last_Activity_Time], ctl.fn_Texto(CONVERT(nvarchar(max), l.[woztellfull__WhatsApp_message])) AS [woztellfull__WhatsApp_message], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Lead_Agent])) AS [Lead_Agent], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Tiempo_Atencion])) AS [Tiempo_Atencion], ctl.fn_Texto(CONVERT(nvarchar(max), l.[woztellfull__No_WhatsApp])) AS [woztellfull__No_WhatsApp], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Visitor_Score])) AS [Visitor_Score], ctl.fn_Texto(CONVERT(nvarchar(max), l.[GCLID])) AS [GCLID], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Estrategia_Segmento])) AS [Estrategia_Segmento], ctl.fn_Texto(CONVERT(nvarchar(max), l.[Referido_por])) AS [Referido_por] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER), N'{}') AS [AtributosExtendidos],
               CAST(ISNULL(l.[deleted], 0) AS int) AS [o_Eliminado]
        FROM Zoho_Mirror.dbo.[Leads] l
        LEFT JOIN core.Cliente cl ON cl.FuenteTabla = N'Cedula' AND cl.FuenteLlave = ctl.fn_Cedula(l.Legal_ID)
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[UsuarioId]) END AS Id FROM ref.Usuario zref WHERE zref.[ZohoUsuarioId] = ctl.fn_Texto(CONVERT(nvarchar(max), l.[Owner])) OR zref.[NombreCompleto] = ctl.fn_Texto(CONVERT(nvarchar(max), l.[Owner]))) fk_PropietarioUsuarioId_0
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 2. Filtros de carga: filas excluidas con la regla que las excluye (DD-06) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'DD-06', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'Registro marcado como eliminado en el origen (deleted = 1)', @Ahora FROM #src s WHERE s.o_Eliminado = 1
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'DD-06' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE s FROM #src s WHERE s.o_Eliminado = 1;
    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FuenteLlave obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FuenteLlave] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE FROM #src WHERE [FuenteLlave] IS NULL;

    /* 2b. Duplicados por la llave del paso (DD-02); el orden es determinista */
    ;WITH r AS (
        SELECT s.FuenteSistema, s.FuenteTabla, s.FuenteLlave,
               ROW_NUMBER() OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.FechaModificacionOrigen DESC, s.HashContenido) AS rn,
               FIRST_VALUE(s.FuenteLlave) OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.FechaModificacionOrigen DESC, s.HashContenido ROWS UNBOUNDED PRECEDING) AS Conservada
        FROM #src s)
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, LlaveConservada, Motivo, FechaDescarte)
    SELECT @LoteId, 'DD-02', r.FuenteSistema, r.FuenteTabla, r.FuenteLlave, r.Conservada, N'Versión anterior del mismo registro en el espejo; se conserva la modificación más reciente', @Ahora
    FROM r WHERE r.rn > 1
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'DD-02' AND x.FuenteTabla = r.FuenteTabla AND x.FuenteLlave = r.FuenteLlave);
    ;WITH r AS (
        SELECT ROW_NUMBER() OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.FechaModificacionOrigen DESC, s.HashContenido) AS rn FROM #src s)
    DELETE FROM r WHERE rn > 1;
    DECLARE @Validas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 3. Imagen previa de las filas que van a cambiar (para el rollback) */
    DROP TABLE IF EXISTS #antes;
    SELECT t.[ProspectoId] AS RegistroId, t.FuenteLlave, (SELECT t.[ClienteId], t.[Cedula], t.[Nombre], t.[Apellido], t.[Empresa], t.[Correo], t.[Telefono], t.[Movil], t.[Estado], t.[Origen], t.[Segmento], t.[CondominioSolicitado], t.[DireccionId], t.[Provincia], t.[Canton], t.[FechaRegistro], t.[FechaConversion], t.[CompraRealizada], t.[PropietarioUsuarioId], t.[AtributosExtendidos], t.[FechaCreacionOrigen], t.[FechaModificacionOrigen], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.Prospecto t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato);

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.Prospecto WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato)) THEN
        UPDATE SET t.[Cedula] = s.[Cedula], t.[Origen] = s.[Origen], t.[Apellido] = s.[Apellido], t.[Segmento] = s.[Segmento], t.[Movil] = s.[Movil], t.[Canton] = s.[Canton], t.[FechaConversion] = s.[FechaConversion], t.[FechaModificacionOrigen] = s.[FechaModificacionOrigen], t.[Provincia] = s.[Provincia], t.[Telefono] = s.[Telefono], t.[Nombre] = s.[Nombre], t.[Estado] = s.[Estado], t.[FechaCreacionOrigen] = s.[FechaCreacionOrigen], t.[Correo] = s.[Correo], t.[Empresa] = s.[Empresa], t.[PropietarioUsuarioId] = s.[PropietarioUsuarioId], t.[ClienteId] = s.[ClienteId], t.[AtributosExtendidos] = s.[AtributosExtendidos], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([Cedula], [Origen], [Apellido], [Segmento], [Movil], [Canton], [FechaConversion], [FechaModificacionOrigen], [Provincia], [Telefono], [Nombre], [Estado], [FechaCreacionOrigen], [Correo], [Empresa], [PropietarioUsuarioId], [ClienteId], [AtributosExtendidos], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[Cedula], s.[Origen], s.[Apellido], s.[Segmento], s.[Movil], s.[Canton], s.[FechaConversion], s.[FechaModificacionOrigen], s.[Provincia], s.[Telefono], s.[Nombre], s.[Estado], s.[FechaCreacionOrigen], s.[Correo], s.[Empresa], s.[PropietarioUsuarioId], s.[ClienteId], s.[AtributosExtendidos], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[ProspectoId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.Prospecto', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.Prospecto', t.[ProspectoId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.Prospecto t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.Prospecto', t.[ProspectoId], N'PropietarioUsuarioId', LEFT(CONVERT(nvarchar(400), s.o_PropietarioUsuarioId), 400), N'Referencia sin correspondencia única en ref.Usuario'
    FROM #src s JOIN core.Prospecto t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_PropietarioUsuarioId IS NOT NULL AND s.[PropietarioUsuarioId] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.Prospecto', t.[ProspectoId], N'FechaConversion', LEFT(CONVERT(nvarchar(400), s.o_FechaConversion), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.Prospecto t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaConversion IS NOT NULL AND s.[FechaConversion] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.Prospecto', t.[ProspectoId], N'FechaModificacionOrigen', LEFT(CONVERT(nvarchar(400), s.o_FechaModificacionOrigen), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.Prospecto t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaModificacionOrigen IS NOT NULL AND s.[FechaModificacionOrigen] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.Prospecto', t.[ProspectoId], N'FechaCreacionOrigen', LEFT(CONVERT(nvarchar(400), s.o_FechaCreacionOrigen), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.Prospecto t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaCreacionOrigen IS NOT NULL AND s.[FechaCreacionOrigen] IS NULL;

    SELECT @Leidas AS FilasLeidas, @Validas - (SELECT COUNT_BIG(*) FROM #cambios) AS FilasSinCambio;
END;
GO
