USE ADN_Unificado;
GO
/* Paso 337 · core_Tarea → core.Tarea
   Tareas del CRM. El registro relacionado (What_Id) puede ser una cuenta, oportunidad, caso, orden de venta, cotización o prospecto: el servicio se toma de la cuenta o del registro relacionado. Solo se marca anomalía si el relacionado no está en ninguno de esos módulos.
   Reglas: DD-06, ES-01, ES-02, IN-01, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_Tarea @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT CAST(q.[RelacionadoCrmId] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [RelacionadoCrmId],
           CAST(q.[Tipo] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Tipo],
           CAST(q.[Asunto] AS nvarchar(500)) COLLATE DATABASE_DEFAULT AS [Asunto],
           q.[FechaCreacionOrigen],
           CAST(q.[Prioridad] AS nvarchar(20)) COLLATE DATABASE_DEFAULT AS [Prioridad],
           q.[FechaVencimiento],
           q.[FechaModificacionOrigen],
           CAST(q.[Estado] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Estado],
           CAST(q.[TareaCrmId] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [TareaCrmId],
           q.[FechaCierre],
           q.[Descripcion] COLLATE DATABASE_DEFAULT AS [Descripcion],
           q.[ContactoId],
           q.[AsignadoUsuarioId],
           q.[ServicioId],
           q.[AtributosExtendidos] COLLATE DATABASE_DEFAULT AS [AtributosExtendidos],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[RelacionadoCrmId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Tipo]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Asunto]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaCreacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Prioridad]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaVencimiento], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaModificacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Estado]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TareaCrmId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaCierre], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Descripcion]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ContactoId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[AsignadoUsuarioId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ServicioId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[AtributosExtendidos]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_Relacionado],
           q.[o_ContactoId],
           q.[o_AsignadoUsuarioId],
           q.[o_FechaCreacionOrigen],
           q.[o_FechaVencimiento],
           q.[o_FechaModificacionOrigen],
           q.[o_FechaCierre],
           q.[o_Eliminado],
           CONCAT_WS(N',', CASE WHEN LEN(q.[RelacionadoCrmId]) > 30 THEN N'RelacionadoCrmId' END, CASE WHEN LEN(q.[Tipo]) > 50 THEN N'Tipo' END, CASE WHEN LEN(q.[Asunto]) > 500 THEN N'Asunto' END, CASE WHEN LEN(q.[Prioridad]) > 20 THEN N'Prioridad' END, CASE WHEN LEN(q.[Estado]) > 50 THEN N'Estado' END, CASE WHEN LEN(q.[TareaCrmId]) > 30 THEN N'TareaCrmId' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT 'ZohoCRM' AS FuenteSistema,
               N'Zoho_Mirror' AS FuenteBase,
               N'Tasks' AS FuenteTabla,
               ctl.fn_Texto(CONVERT(nvarchar(200), t.[id])) AS FuenteLlave,
               ctl.fn_FechaCR(CONVERT(nvarchar(60), t.[Created_Time])) AS FechaDato,
               ctl.fn_Texto(CONVERT(nvarchar(max), t.[What_Id])) AS [RelacionadoCrmId],
               ctl.fn_Texto(CONVERT(nvarchar(max), t.[Tipo])) AS [Tipo],
               ctl.fn_Texto(CONVERT(nvarchar(max), t.[Subject])) AS [Asunto],
               ctl.fn_FechaCR(CONVERT(nvarchar(60), t.[Created_Time])) AS [FechaCreacionOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(max), t.[Priority])) AS [Prioridad],
               ctl.fn_FechaDia(CONVERT(nvarchar(60), t.[Due_Date])) AS [FechaVencimiento],
               ctl.fn_FechaCR(CONVERT(nvarchar(60), t.[Modified_Time])) AS [FechaModificacionOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(max), t.[Status])) AS [Estado],
               ctl.fn_Texto(CONVERT(nvarchar(max), t.[id])) AS [TareaCrmId],
               ctl.fn_FechaCR(CONVERT(nvarchar(60), t.[Closed_Time])) AS [FechaCierre],
               ctl.fn_Texto(CONVERT(nvarchar(max), CONVERT(nvarchar(max), t.[Description]))) AS [Descripcion],
               fk_ContactoId_0.Id AS [ContactoId],
               ctl.fn_Texto(CONVERT(nvarchar(400), t.[Who_Id])) AS [o_ContactoId],
               fk_AsignadoUsuarioId_0.Id AS [AsignadoUsuarioId],
               ctl.fn_Texto(CONVERT(nvarchar(400), t.[Asignado_a])) AS [o_AsignadoUsuarioId],
               COALESCE(r1.Id, r2.Id, r3.Id, r4.Id, r5.Id) AS [ServicioId],
               CASE WHEN w.Id IS NOT NULL AND r1.n + r2.n + r3.n + r4.n + r5.n + r6.n = 0 THEN w.Id END AS [o_Relacionado],
               ctl.fn_Texto(CONVERT(nvarchar(400), t.[Created_Time])) AS [o_FechaCreacionOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(400), t.[Due_Date])) AS [o_FechaVencimiento],
               ctl.fn_Texto(CONVERT(nvarchar(400), t.[Modified_Time])) AS [o_FechaModificacionOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(400), t.[Closed_Time])) AS [o_FechaCierre],
               NULLIF((SELECT ctl.fn_Texto(CONVERT(nvarchar(max), t.[Created_By])) AS [Created_By], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Tag])) AS [Tag], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Capacidad_Actual])) AS [Capacidad_Actual], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Llamada_Seguimiento_30D])) AS [Llamada_Seguimiento_30D], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Remind_At])) AS [Remind_At], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Capacidad_Nueva])) AS [Capacidad_Nueva], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Actualizaci_n_de_Tarea])) AS [Actualizaci_n_de_Tarea], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Modified_By])) AS [Modified_By], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Send_Notification_Email])) AS [Send_Notification_Email], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Owner])) AS [Owner] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER), N'{}') AS [AtributosExtendidos],
               CAST(ISNULL(t.[deleted], 0) AS int) AS [o_Eliminado]
        FROM Zoho_Mirror.dbo.[Tasks] t
        CROSS APPLY (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(max), t.What_Id)) AS nvarchar(30)) AS Id) w
        OUTER APPLY (SELECT MIN(x.ServicioId) AS Id, COUNT(*) AS n FROM core.Servicio x WHERE x.CuentaCrmId = w.Id) r1
        OUTER APPLY (SELECT MIN(x.ServicioId) AS Id, COUNT(*) AS n FROM core.Oportunidad x WHERE x.OportunidadCrmId = w.Id) r2
        OUTER APPLY (SELECT MIN(x.ServicioId) AS Id, COUNT(*) AS n FROM core.Caso x WHERE x.CasoCrmId = w.Id) r3
        OUTER APPLY (SELECT MIN(x.ServicioId) AS Id, COUNT(*) AS n FROM core.OrdenVenta x WHERE x.OrdenVentaCrmId = w.Id) r4
        OUTER APPLY (SELECT MIN(x.ServicioId) AS Id, COUNT(*) AS n FROM core.Cotizacion x WHERE x.CotizacionCrmId = w.Id) r5
        OUTER APPLY (SELECT COUNT(*) AS n FROM core.Prospecto x WHERE x.FuenteSistema = 'ZohoCRM' AND x.FuenteTabla = N'Leads' AND x.FuenteLlave = w.Id) r6
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(r.[ContactoId]) END AS Id FROM core.Contacto r WHERE r.[ContactoCrmId] = ctl.fn_Texto(CONVERT(nvarchar(max), t.[Who_Id]))) fk_ContactoId_0
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(r.[UsuarioId]) END AS Id FROM ref.Usuario r WHERE r.[ZohoUsuarioId] = ctl.fn_Texto(CONVERT(nvarchar(max), t.[Asignado_a])) OR r.[NombreCompleto] = ctl.fn_Texto(CONVERT(nvarchar(max), t.[Asignado_a]))) fk_AsignadoUsuarioId_0
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
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'TareaCrmId obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[TareaCrmId] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FuenteLlave obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FuenteLlave] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE FROM #src WHERE [TareaCrmId] IS NULL OR [FuenteLlave] IS NULL;

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
    SELECT t.[TareaId] AS RegistroId, t.FuenteLlave, (SELECT t.[TareaCrmId], t.[RelacionadoCrmId], t.[ServicioId], t.[ContactoId], t.[Asunto], t.[Tipo], t.[Estado], t.[Prioridad], t.[Descripcion], t.[FechaVencimiento], t.[FechaCierre], t.[AsignadoUsuarioId], t.[AtributosExtendidos], t.[FechaCreacionOrigen], t.[FechaModificacionOrigen], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.Tarea t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido;

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.Tarea WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido) THEN
        UPDATE SET t.[RelacionadoCrmId] = s.[RelacionadoCrmId], t.[Tipo] = s.[Tipo], t.[Asunto] = s.[Asunto], t.[FechaCreacionOrigen] = s.[FechaCreacionOrigen], t.[Prioridad] = s.[Prioridad], t.[FechaVencimiento] = s.[FechaVencimiento], t.[FechaModificacionOrigen] = s.[FechaModificacionOrigen], t.[Estado] = s.[Estado], t.[TareaCrmId] = s.[TareaCrmId], t.[FechaCierre] = s.[FechaCierre], t.[Descripcion] = s.[Descripcion], t.[ContactoId] = s.[ContactoId], t.[AsignadoUsuarioId] = s.[AsignadoUsuarioId], t.[ServicioId] = s.[ServicioId], t.[AtributosExtendidos] = s.[AtributosExtendidos], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([RelacionadoCrmId], [Tipo], [Asunto], [FechaCreacionOrigen], [Prioridad], [FechaVencimiento], [FechaModificacionOrigen], [Estado], [TareaCrmId], [FechaCierre], [Descripcion], [ContactoId], [AsignadoUsuarioId], [ServicioId], [AtributosExtendidos], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[RelacionadoCrmId], s.[Tipo], s.[Asunto], s.[FechaCreacionOrigen], s.[Prioridad], s.[FechaVencimiento], s.[FechaModificacionOrigen], s.[Estado], s.[TareaCrmId], s.[FechaCierre], s.[Descripcion], s.[ContactoId], s.[AsignadoUsuarioId], s.[ServicioId], s.[AtributosExtendidos], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[TareaId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.Tarea', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.Tarea', t.[TareaId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.Tarea t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.Tarea', t.[TareaId], N'RelacionadoCrmId', LEFT(CONVERT(nvarchar(400), s.o_Relacionado), 400), N'Registro relacionado que no está en los módulos cargados (cuenta, oportunidad, caso, orden, cotización, prospecto)'
    FROM #src s JOIN core.Tarea t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Relacionado IS NOT NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.Tarea', t.[TareaId], N'ContactoId', LEFT(CONVERT(nvarchar(400), s.o_ContactoId), 400), N'Referencia sin correspondencia única en core.Contacto'
    FROM #src s JOIN core.Tarea t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_ContactoId IS NOT NULL AND s.[ContactoId] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.Tarea', t.[TareaId], N'AsignadoUsuarioId', LEFT(CONVERT(nvarchar(400), s.o_AsignadoUsuarioId), 400), N'Referencia sin correspondencia única en ref.Usuario'
    FROM #src s JOIN core.Tarea t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_AsignadoUsuarioId IS NOT NULL AND s.[AsignadoUsuarioId] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.Tarea', t.[TareaId], N'FechaCreacionOrigen', LEFT(CONVERT(nvarchar(400), s.o_FechaCreacionOrigen), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.Tarea t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaCreacionOrigen IS NOT NULL AND s.[FechaCreacionOrigen] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.Tarea', t.[TareaId], N'FechaVencimiento', LEFT(CONVERT(nvarchar(400), s.o_FechaVencimiento), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.Tarea t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaVencimiento IS NOT NULL AND s.[FechaVencimiento] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.Tarea', t.[TareaId], N'FechaModificacionOrigen', LEFT(CONVERT(nvarchar(400), s.o_FechaModificacionOrigen), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.Tarea t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaModificacionOrigen IS NOT NULL AND s.[FechaModificacionOrigen] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.Tarea', t.[TareaId], N'FechaCierre', LEFT(CONVERT(nvarchar(400), s.o_FechaCierre), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.Tarea t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaCierre IS NOT NULL AND s.[FechaCierre] IS NULL;

    SELECT @Leidas AS FilasLeidas, @Validas - (SELECT COUNT_BIG(*) FROM #cambios) AS FilasSinCambio;
END;
GO
