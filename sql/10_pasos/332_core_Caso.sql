USE ADN_Unificado;
GO
/* Paso 332 · core_Caso → core.Caso
   Casos de soporte: Cases_Extended es la fuente principal (D2).
   Reglas: ES-01, ES-07, ID-01, IN-01, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_Caso @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT CAST(q.[CasoCrmId] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [CasoCrmId],
           CAST(q.[Asunto] AS nvarchar(500)) COLLATE DATABASE_DEFAULT AS [Asunto],
           q.[Descripcion] COLLATE DATABASE_DEFAULT AS [Descripcion],
           CAST(q.[Estado] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Estado],
           CAST(q.[Origen] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Origen],
           CAST(q.[Segmento] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Segmento],
           CAST(q.[Circuito] AS varchar(12)) COLLATE DATABASE_DEFAULT AS [Circuito],
           q.[VisitaTecnica],
           q.[Escalado],
           CAST(q.[ProveedorExterno] AS nvarchar(100)) COLLATE DATABASE_DEFAULT AS [ProveedorExterno],
           CAST(q.[DepartamentoOrigen] AS nvarchar(100)) COLLATE DATABASE_DEFAULT AS [DepartamentoOrigen],
           CAST(q.[TipoMantenimiento] AS nvarchar(100)) COLLATE DATABASE_DEFAULT AS [TipoMantenimiento],
           q.[FechaSolicitud],
           q.[FechaAfectacion],
           q.[FechaEscalamiento],
           q.[FechaFinMantenimiento],
           q.[FechaFinalizacion],
           q.[FechaCreacionOrigen],
           q.[FechaModificacionOrigen],
           q.[PropietarioUsuarioId],
           q.[ServicioId],
           q.[AtributosExtendidos] COLLATE DATABASE_DEFAULT AS [AtributosExtendidos],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[CasoCrmId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Asunto]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Descripcion]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Estado]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Origen]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Segmento]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Circuito]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[VisitaTecnica]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Escalado]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ProveedorExterno]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[DepartamentoOrigen]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TipoMantenimiento]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaSolicitud], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaAfectacion], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaEscalamiento], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaFinMantenimiento], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaFinalizacion], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaCreacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaModificacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[PropietarioUsuarioId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ServicioId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[AtributosExtendidos]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_PropietarioUsuarioId],
           q.[o_ServicioId],
           q.[o_Circuito],
           CONCAT_WS(N',', CASE WHEN LEN(q.[CasoCrmId]) > 30 THEN N'CasoCrmId' END, CASE WHEN LEN(q.[Asunto]) > 500 THEN N'Asunto' END, CASE WHEN LEN(q.[Estado]) > 50 THEN N'Estado' END, CASE WHEN LEN(q.[Origen]) > 50 THEN N'Origen' END, CASE WHEN LEN(q.[Segmento]) > 50 THEN N'Segmento' END, CASE WHEN LEN(q.[Circuito]) > 12 THEN N'Circuito' END, CASE WHEN LEN(q.[ProveedorExterno]) > 100 THEN N'ProveedorExterno' END, CASE WHEN LEN(q.[DepartamentoOrigen]) > 100 THEN N'DepartamentoOrigen' END, CASE WHEN LEN(q.[TipoMantenimiento]) > 100 THEN N'TipoMantenimiento' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT 'ZohoCRM' AS FuenteSistema,
               N'Zoho_Mirror' AS FuenteBase,
               N'Cases_Extended' AS FuenteTabla,
               ctl.fn_Texto(CONVERT(nvarchar(200), c.[CaseId])) AS FuenteLlave,
               ctl.fn_FechaCR(CONVERT(nvarchar(30), c.[CreatedTime], 126)) AS FechaDato,
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[CaseId])) AS [CasoCrmId],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[Subject])) AS [Asunto],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[Description])) AS [Descripcion],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[Status])) AS [Estado],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[CaseOrigin])) AS [Origen],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[Segmento])) AS [Segmento],
               ctl.fn_Circuito(CONVERT(nvarchar(100), c.[NumeroCircuito])) AS [Circuito],
               c.[VisitaTecnica] AS [VisitaTecnica],
               c.[Escalated] AS [Escalado],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[ProveedorExterno])) AS [ProveedorExterno],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[DepartamenteOrigen])) AS [DepartamentoOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[TipoMantenimiento])) AS [TipoMantenimiento],
               ctl.fn_FechaCR(CONVERT(nvarchar(30), c.[FechaHoraDeSolicitud], 126)) AS [FechaSolicitud],
               ctl.fn_FechaCR(CONVERT(nvarchar(30), c.[FechaHoraAfectacion], 126)) AS [FechaAfectacion],
               ctl.fn_FechaCR(CONVERT(nvarchar(30), c.[FechaHoraDeEscalamiento], 126)) AS [FechaEscalamiento],
               ctl.fn_FechaCR(CONVERT(nvarchar(30), c.[FechaHoraFinMant], 126)) AS [FechaFinMantenimiento],
               ctl.fn_FechaCR(CONVERT(nvarchar(30), c.[FechaHoraFinalizacion], 126)) AS [FechaFinalizacion],
               ctl.fn_FechaCR(CONVERT(nvarchar(30), c.[CreatedTime], 126)) AS [FechaCreacionOrigen],
               ctl.fn_FechaCR(CONVERT(nvarchar(30), c.[ModifiedTime], 126)) AS [FechaModificacionOrigen],
               fk_PropietarioUsuarioId_0.Id AS [PropietarioUsuarioId],
               ctl.fn_Texto(CONVERT(nvarchar(400), c.[OwnerId])) AS [o_PropietarioUsuarioId],
               fk_ServicioId_0.Id AS [ServicioId],
               ctl.fn_Texto(CONVERT(nvarchar(400), c.[AccountId])) AS [o_ServicioId],
               ctl.fn_Texto(CONVERT(nvarchar(400), c.[NumeroCircuito])) AS [o_Circuito],
               NULLIF((SELECT ctl.fn_Texto(CONVERT(nvarchar(max), c.[AsignadoA])) AS [AsignadoA], ctl.fn_Texto(CONVERT(nvarchar(max), c.[CreadoPor])) AS [CreadoPor], ctl.fn_Texto(CONVERT(nvarchar(max), c.[SupervisadoPor])) AS [SupervisadoPor], ctl.fn_Texto(CONVERT(nvarchar(max), c.[CerradoPor2])) AS [CerradoPor2], ctl.fn_Texto(CONVERT(nvarchar(max), c.[RevisionING])) AS [RevisionING], ctl.fn_Texto(CONVERT(nvarchar(max), c.[CerradoSupervision])) AS [CerradoSupervision], ctl.fn_Texto(CONVERT(nvarchar(max), c.[TickedIdProveedorExterno])) AS [TickedIdProveedorExterno], ctl.fn_Texto(CONVERT(nvarchar(max), c.[ApoyoAdicional])) AS [ApoyoAdicional], ctl.fn_Texto(CONVERT(nvarchar(max), c.[RazonStandBy])) AS [RazonStandBy], ctl.fn_Texto(CONVERT(nvarchar(max), c.[FechaHoraPreCierre])) AS [FechaHoraPreCierre], ctl.fn_Texto(CONVERT(nvarchar(max), c.[LastActivityTime])) AS [LastActivityTime], ctl.fn_Texto(CONVERT(nvarchar(max), c.[LayoutId])) AS [LayoutId] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER), N'{}') AS [AtributosExtendidos]
        FROM Zoho_Mirror.dbo.[Cases_Extended] c
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[UsuarioId]) END AS Id FROM ref.Usuario zref WHERE zref.[ZohoUsuarioId] = ctl.fn_Texto(CONVERT(nvarchar(max), c.[OwnerId])) OR zref.[NombreCompleto] = ctl.fn_Texto(CONVERT(nvarchar(max), c.[OwnerId]))) fk_PropietarioUsuarioId_0
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[ServicioId]) END AS Id FROM core.Servicio zref WHERE zref.[CuentaCrmId] = ctl.fn_Texto(CONVERT(nvarchar(max), c.[AccountId]))) fk_ServicioId_0
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'CasoCrmId obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[CasoCrmId] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FuenteLlave obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FuenteLlave] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE FROM #src WHERE [CasoCrmId] IS NULL OR [FuenteLlave] IS NULL;

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
    SELECT t.[CasoId] AS RegistroId, t.FuenteLlave, (SELECT t.[CasoCrmId], t.[ServicioId], t.[Circuito], t.[NumeroTicket], t.[Asunto], t.[Descripcion], t.[Estado], t.[Origen], t.[Segmento], t.[TipoMantenimiento], t.[DepartamentoOrigen], t.[ProveedorExterno], t.[VisitaTecnica], t.[Escalado], t.[PropietarioUsuarioId], t.[FechaSolicitud], t.[FechaAfectacion], t.[FechaEscalamiento], t.[FechaFinMantenimiento], t.[FechaFinalizacion], t.[AtributosExtendidos], t.[FechaCreacionOrigen], t.[FechaModificacionOrigen], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.Caso t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido;

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.Caso WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido) THEN
        UPDATE SET t.[CasoCrmId] = s.[CasoCrmId], t.[Asunto] = s.[Asunto], t.[Descripcion] = s.[Descripcion], t.[Estado] = s.[Estado], t.[Origen] = s.[Origen], t.[Segmento] = s.[Segmento], t.[Circuito] = s.[Circuito], t.[VisitaTecnica] = s.[VisitaTecnica], t.[Escalado] = s.[Escalado], t.[ProveedorExterno] = s.[ProveedorExterno], t.[DepartamentoOrigen] = s.[DepartamentoOrigen], t.[TipoMantenimiento] = s.[TipoMantenimiento], t.[FechaSolicitud] = s.[FechaSolicitud], t.[FechaAfectacion] = s.[FechaAfectacion], t.[FechaEscalamiento] = s.[FechaEscalamiento], t.[FechaFinMantenimiento] = s.[FechaFinMantenimiento], t.[FechaFinalizacion] = s.[FechaFinalizacion], t.[FechaCreacionOrigen] = s.[FechaCreacionOrigen], t.[FechaModificacionOrigen] = s.[FechaModificacionOrigen], t.[PropietarioUsuarioId] = s.[PropietarioUsuarioId], t.[ServicioId] = s.[ServicioId], t.[AtributosExtendidos] = s.[AtributosExtendidos], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([CasoCrmId], [Asunto], [Descripcion], [Estado], [Origen], [Segmento], [Circuito], [VisitaTecnica], [Escalado], [ProveedorExterno], [DepartamentoOrigen], [TipoMantenimiento], [FechaSolicitud], [FechaAfectacion], [FechaEscalamiento], [FechaFinMantenimiento], [FechaFinalizacion], [FechaCreacionOrigen], [FechaModificacionOrigen], [PropietarioUsuarioId], [ServicioId], [AtributosExtendidos], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[CasoCrmId], s.[Asunto], s.[Descripcion], s.[Estado], s.[Origen], s.[Segmento], s.[Circuito], s.[VisitaTecnica], s.[Escalado], s.[ProveedorExterno], s.[DepartamentoOrigen], s.[TipoMantenimiento], s.[FechaSolicitud], s.[FechaAfectacion], s.[FechaEscalamiento], s.[FechaFinMantenimiento], s.[FechaFinalizacion], s.[FechaCreacionOrigen], s.[FechaModificacionOrigen], s.[PropietarioUsuarioId], s.[ServicioId], s.[AtributosExtendidos], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[CasoId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.Caso', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.Caso', t.[CasoId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.Caso t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.Caso', t.[CasoId], N'PropietarioUsuarioId', LEFT(CONVERT(nvarchar(400), s.o_PropietarioUsuarioId), 400), N'Referencia sin correspondencia única en ref.Usuario'
    FROM #src s JOIN core.Caso t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_PropietarioUsuarioId IS NOT NULL AND s.[PropietarioUsuarioId] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.Caso', t.[CasoId], N'ServicioId', LEFT(CONVERT(nvarchar(400), s.o_ServicioId), 400), N'Referencia sin correspondencia única en core.Servicio'
    FROM #src s JOIN core.Caso t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_ServicioId IS NOT NULL AND s.[ServicioId] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ID-01', N'core.Caso', t.[CasoId], N'Circuito', LEFT(CONVERT(nvarchar(400), s.o_Circuito), 400), N'Circuito que no cumple el patrón aprobado'
    FROM #src s JOIN core.Caso t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Circuito IS NOT NULL AND s.[Circuito] IS NULL;

    SELECT @Leidas AS FilasLeidas, @Validas - (SELECT COUNT_BIG(*) FROM #cambios) AS FilasSinCambio;
END;
GO
