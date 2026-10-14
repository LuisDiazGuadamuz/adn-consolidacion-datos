USE ADN_Unificado;
GO
/* Paso 338 · core_Adjunto → core.Adjunto
   Metadatos de los adjuntos del CRM (el archivo queda en la nube; solo se guarda la ruta).
   Reglas: ES-01, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_Adjunto @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT CAST(q.[AdjuntoCrmId] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [AdjuntoCrmId],
           CAST(q.[Modulo] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Modulo],
           CAST(q.[RegistroCrmId] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [RegistroCrmId],
           CAST(q.[NombreArchivo] AS nvarchar(500)) COLLATE DATABASE_DEFAULT AS [NombreArchivo],
           q.[TamanoBytes],
           CAST(q.[TipoArchivo] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [TipoArchivo],
           q.[FechaCreacionOrigen],
           q.[FechaModificacionOrigen],
           CAST(q.[RutaNube] AS nvarchar(1000)) COLLATE DATABASE_DEFAULT AS [RutaNube],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[AdjuntoCrmId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Modulo]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[RegistroCrmId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[NombreArchivo]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TamanoBytes]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TipoArchivo]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaCreacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaModificacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[RutaNube]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           CONCAT_WS(N',', CASE WHEN LEN(q.[AdjuntoCrmId]) > 30 THEN N'AdjuntoCrmId' END, CASE WHEN LEN(q.[Modulo]) > 50 THEN N'Modulo' END, CASE WHEN LEN(q.[RegistroCrmId]) > 30 THEN N'RegistroCrmId' END, CASE WHEN LEN(q.[NombreArchivo]) > 500 THEN N'NombreArchivo' END, CASE WHEN LEN(q.[TipoArchivo]) > 50 THEN N'TipoArchivo' END, CASE WHEN LEN(q.[RutaNube]) > 1000 THEN N'RutaNube' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT 'ZohoCRM' AS FuenteSistema,
               N'Zoho_Mirror' AS FuenteBase,
               N'Zoho_Attachments' AS FuenteTabla,
               ctl.fn_Texto(CONVERT(nvarchar(200), a.[AttachmentId])) AS FuenteLlave,
               ctl.fn_FechaCR(CONVERT(nvarchar(30), a.[CreatedTime], 126)) AS FechaDato,
               ctl.fn_Texto(CONVERT(nvarchar(max), a.[AttachmentId])) AS [AdjuntoCrmId],
               ctl.fn_Texto(CONVERT(nvarchar(max), a.[ModuleName])) AS [Modulo],
               ctl.fn_Texto(CONVERT(nvarchar(max), a.[RecordId])) AS [RegistroCrmId],
               ctl.fn_Texto(CONVERT(nvarchar(max), a.[FileName])) AS [NombreArchivo],
               TRY_CONVERT(bigint, a.[FileSize]) AS [TamanoBytes],
               ctl.fn_Texto(CONVERT(nvarchar(max), a.[FileType])) AS [TipoArchivo],
               ctl.fn_FechaCR(CONVERT(nvarchar(30), a.[CreatedTime], 126)) AS [FechaCreacionOrigen],
               ctl.fn_FechaCR(CONVERT(nvarchar(30), a.[ModifiedTime], 126)) AS [FechaModificacionOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(max), a.[CloudPath])) AS [RutaNube]
        FROM Zoho_Mirror.dbo.[Zoho_Attachments] a
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);
    /* Conciliación: llaves leídas, para comprobar al final que toda fila excluida tiene su motivo en ctl.Descarte */
    DROP TABLE IF EXISTS #leidas;
    SELECT DISTINCT FuenteTabla, FuenteLlave INTO #leidas FROM #src;

    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'AdjuntoCrmId obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[AdjuntoCrmId] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FuenteLlave obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FuenteLlave] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE FROM #src WHERE [AdjuntoCrmId] IS NULL OR [FuenteLlave] IS NULL;

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
    SELECT t.[AdjuntoId] AS RegistroId, t.FuenteLlave, (SELECT t.[AdjuntoCrmId], t.[Modulo], t.[RegistroCrmId], t.[NombreArchivo], t.[TamanoBytes], t.[TipoArchivo], t.[RutaNube], t.[FechaCreacionOrigen], t.[FechaModificacionOrigen], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.Adjunto t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato);

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.Adjunto WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato)) THEN
        UPDATE SET t.[AdjuntoCrmId] = s.[AdjuntoCrmId], t.[Modulo] = s.[Modulo], t.[RegistroCrmId] = s.[RegistroCrmId], t.[NombreArchivo] = s.[NombreArchivo], t.[TamanoBytes] = s.[TamanoBytes], t.[TipoArchivo] = s.[TipoArchivo], t.[FechaCreacionOrigen] = s.[FechaCreacionOrigen], t.[FechaModificacionOrigen] = s.[FechaModificacionOrigen], t.[RutaNube] = s.[RutaNube], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([AdjuntoCrmId], [Modulo], [RegistroCrmId], [NombreArchivo], [TamanoBytes], [TipoArchivo], [FechaCreacionOrigen], [FechaModificacionOrigen], [RutaNube], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[AdjuntoCrmId], s.[Modulo], s.[RegistroCrmId], s.[NombreArchivo], s.[TamanoBytes], s.[TipoArchivo], s.[FechaCreacionOrigen], s.[FechaModificacionOrigen], s.[RutaNube], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[AdjuntoId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.Adjunto', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.Adjunto', t.[AdjuntoId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.Adjunto t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    -- sin reglas de anomalía en este paso

    /* 7. Conciliación: leídas = válidas + excluidas; cada llave excluida debe tener su motivo en ctl.Descarte
       (de este lote o de un lote exitoso anterior). Las repetidas (DD) conservan su llave en una fila válida. */
    DECLARE @SinMotivo bigint = (
        SELECT COUNT_BIG(*) FROM #leidas r
        WHERE NOT EXISTS (SELECT 1 FROM #src s WHERE s.FuenteTabla = r.FuenteTabla
                          AND (s.FuenteLlave = r.FuenteLlave OR (s.FuenteLlave IS NULL AND r.FuenteLlave IS NULL)))
          AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x LEFT JOIN ctl.Lote l ON l.LoteId = x.LoteId
                          WHERE x.FuenteTabla = r.FuenteTabla
                            AND (x.FuenteLlave = r.FuenteLlave OR (x.FuenteLlave IS NULL AND r.FuenteLlave IS NULL AND x.LoteId = @LoteId))
                            AND (x.LoteId = @LoteId OR l.Estado = 'Exitoso')));
    SELECT @Leidas AS FilasLeidas, @Validas - (SELECT COUNT_BIG(*) FROM #cambios) AS FilasSinCambio,
           @Leidas - @Validas AS FilasExcluidas, @SinMotivo AS LlavesSinMotivo;
END;
GO
