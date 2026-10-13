USE ADN_Unificado;
GO
/* Paso 802 · core_TicketAtencion → core.TicketAtencion
   Tickets de Trengo (histórico, D12). Se ligan al contacto del CRM solo si custom_data trae ID_ZCRM (ID-09) y, por él, al servicio. Nunca por teléfono (ID-05).
   Reglas: D12, D6, ES-01, ID-05, ID-09, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_TicketAtencion @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT CAST(q.[TicketTrengoId] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [TicketTrengoId],
           q.[FechaCreacion],
           q.[FechaActualizacion],
           q.[FechaCierre],
           q.[DuracionMinutos],
           q.[FechaAsignacion],
           CAST(q.[Responsable] AS nvarchar(100)) COLLATE DATABASE_DEFAULT AS [Responsable],
           CAST(q.[Departamento] AS nvarchar(100)) COLLATE DATABASE_DEFAULT AS [Departamento],
           CAST(q.[Telefono] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [Telefono],
           CAST(q.[Canal] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Canal],
           q.[Etiquetas] COLLATE DATABASE_DEFAULT AS [Etiquetas],
           q.[DatosAdicionales] COLLATE DATABASE_DEFAULT AS [DatosAdicionales],
           q.[ContactoId],
           q.[ServicioId],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[TicketTrengoId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaCreacion], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaActualizacion], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaCierre], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[DuracionMinutos]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaAsignacion], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Responsable]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Departamento]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Telefono]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Canal]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Etiquetas]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[DatosAdicionales]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ContactoId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ServicioId]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_IdZcrm],
           CONCAT_WS(N',', CASE WHEN LEN(q.[TicketTrengoId]) > 50 THEN N'TicketTrengoId' END, CASE WHEN LEN(q.[Responsable]) > 100 THEN N'Responsable' END, CASE WHEN LEN(q.[Departamento]) > 100 THEN N'Departamento' END, CASE WHEN LEN(q.[Telefono]) > 30 THEN N'Telefono' END, CASE WHEN LEN(q.[Canal]) > 50 THEN N'Canal' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT 'Trengo' AS FuenteSistema,
               N'ZCRM2Trengo' AS FuenteBase,
               N'trengo_data_tickets' AS FuenteTabla,
               ctl.fn_Texto(CONVERT(nvarchar(200), t.[id_case])) AS FuenteLlave,
               ctl.fn_FechaCR(CONVERT(nvarchar(30), t.[created_at], 126)) AS FechaDato,
               ctl.fn_Texto(CONVERT(nvarchar(max), t.[id_case])) AS [TicketTrengoId],
               ctl.fn_FechaCR(CONVERT(nvarchar(30), t.[created_at], 126)) AS [FechaCreacion],
               ctl.fn_FechaCR(CONVERT(nvarchar(30), t.[updated_at], 126)) AS [FechaActualizacion],
               ctl.fn_FechaCR(CONVERT(nvarchar(30), t.[closed_at], 126)) AS [FechaCierre],
               TRY_CONVERT(decimal(12,2), t.[duration]) AS [DuracionMinutos],
               ctl.fn_FechaCR(CONVERT(nvarchar(30), t.[assigned_at], 126)) AS [FechaAsignacion],
               ctl.fn_Texto(CONVERT(nvarchar(max), t.[owner])) AS [Responsable],
               ctl.fn_Texto(CONVERT(nvarchar(max), t.[department])) AS [Departamento],
               ctl.fn_Texto(CONVERT(nvarchar(max), t.[phone])) AS [Telefono],
               ctl.fn_Texto(CONVERT(nvarchar(max), t.[channel])) AS [Canal],
               ctl.fn_Texto(CONVERT(nvarchar(max), CONVERT(nvarchar(max), t.[labels]))) AS [Etiquetas],
               ctl.fn_Texto(CONVERT(nvarchar(max), CONVERT(nvarchar(max), t.[custom_data]))) AS [DatosAdicionales],
               ct.ContactoId AS [ContactoId],
               ct.ServicioId AS [ServicioId],
               z.IdZcrm AS [o_IdZcrm]
        FROM ZCRM2Trengo.dbo.[trengo_data_tickets] t
        CROSS APPLY (SELECT CONVERT(nvarchar(max), t.custom_data) COLLATE DATABASE_DEFAULT AS cd) d0
        CROSS APPLY (SELECT CASE WHEN CHARINDEX(N'ID_ZCRM', d0.cd) > 0 THEN
                            NULLIF(LEFT(LTRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(d0.cd, CHARINDEX(N'ID_ZCRM', d0.cd) + 7, 60), N'''', N''), N'"', N''), N':', N'')), 19), N'')
                        END COLLATE DATABASE_DEFAULT AS IdZcrm) z
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(k.ContactoId) END AS ContactoId,
                            CASE WHEN COUNT(*) = 1 THEN MIN(k.ServicioId) END AS ServicioId
                     FROM core.Contacto k WHERE k.ContactoCrmId = z.IdZcrm) ct
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'TicketTrengoId obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[TicketTrengoId] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FuenteLlave obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FuenteLlave] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE FROM #src WHERE [TicketTrengoId] IS NULL OR [FuenteLlave] IS NULL;

    /* 2b. Duplicados por la llave del paso (DD-04); el orden es determinista */
    ;WITH r AS (
        SELECT s.FuenteSistema, s.FuenteTabla, s.FuenteLlave,
               ROW_NUMBER() OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.HashContenido, s.FuenteLlave) AS rn,
               FIRST_VALUE(s.FuenteLlave) OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.HashContenido, s.FuenteLlave ROWS UNBOUNDED PRECEDING) AS Conservada
        FROM #src s)
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, LlaveConservada, Motivo, FechaDescarte)
    SELECT @LoteId, 'DD-04', r.FuenteSistema, r.FuenteTabla, r.FuenteLlave, r.Conservada, N'Registro repetido por la llave del paso; se conserva uno según el orden definido', @Ahora
    FROM r WHERE r.rn > 1
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'DD-04' AND x.FuenteTabla = r.FuenteTabla AND x.FuenteLlave = r.FuenteLlave);
    ;WITH r AS (
        SELECT ROW_NUMBER() OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.HashContenido, s.FuenteLlave) AS rn FROM #src s)
    DELETE FROM r WHERE rn > 1;
    DECLARE @Validas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 3. Imagen previa de las filas que van a cambiar (para el rollback) */
    DROP TABLE IF EXISTS #antes;
    SELECT t.[TicketAtencionId] AS RegistroId, t.FuenteLlave, (SELECT t.[TicketTrengoId], t.[ContactoId], t.[ServicioId], t.[Canal], t.[Departamento], t.[Responsable], t.[Telefono], t.[Etiquetas], t.[DatosAdicionales], t.[DuracionMinutos], t.[FechaCreacion], t.[FechaAsignacion], t.[FechaCierre], t.[FechaActualizacion], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.TicketAtencion t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato);

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.TicketAtencion WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato)) THEN
        UPDATE SET t.[TicketTrengoId] = s.[TicketTrengoId], t.[FechaCreacion] = s.[FechaCreacion], t.[FechaActualizacion] = s.[FechaActualizacion], t.[FechaCierre] = s.[FechaCierre], t.[DuracionMinutos] = s.[DuracionMinutos], t.[FechaAsignacion] = s.[FechaAsignacion], t.[Responsable] = s.[Responsable], t.[Departamento] = s.[Departamento], t.[Telefono] = s.[Telefono], t.[Canal] = s.[Canal], t.[Etiquetas] = s.[Etiquetas], t.[DatosAdicionales] = s.[DatosAdicionales], t.[ContactoId] = s.[ContactoId], t.[ServicioId] = s.[ServicioId], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([TicketTrengoId], [FechaCreacion], [FechaActualizacion], [FechaCierre], [DuracionMinutos], [FechaAsignacion], [Responsable], [Departamento], [Telefono], [Canal], [Etiquetas], [DatosAdicionales], [ContactoId], [ServicioId], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[TicketTrengoId], s.[FechaCreacion], s.[FechaActualizacion], s.[FechaCierre], s.[DuracionMinutos], s.[FechaAsignacion], s.[Responsable], s.[Departamento], s.[Telefono], s.[Canal], s.[Etiquetas], s.[DatosAdicionales], s.[ContactoId], s.[ServicioId], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[TicketAtencionId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.TicketAtencion', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.TicketAtencion', t.[TicketAtencionId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.TicketAtencion t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ID-09', N'core.TicketAtencion', t.[TicketAtencionId], N'ContactoId', LEFT(CONVERT(nvarchar(400), s.o_IdZcrm), 400), N'ID_ZCRM del ticket sin contacto en el CRM'
    FROM #src s JOIN core.TicketAtencion t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_IdZcrm IS NOT NULL AND s.ContactoId IS NULL;

    SELECT @Leidas AS FilasLeidas, @Validas - (SELECT COUNT_BIG(*) FROM #cambios) AS FilasSinCambio;
END;
GO
