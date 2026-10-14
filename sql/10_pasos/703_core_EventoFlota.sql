USE ADN_Unificado;
GO
/* Paso 703 · core_EventoFlota → core.EventoFlota
   Eventos de las unidades (sin llave en el origen: huella de dispositivo, fecha, evento y posición).
   Reglas: DD-01, ES-01, IN-01, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_EventoFlota @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT CAST(q.[Evento] AS nvarchar(100)) COLLATE DATABASE_DEFAULT AS [Evento],
           CAST(q.[Mensaje] AS nvarchar(500)) COLLATE DATABASE_DEFAULT AS [Mensaje],
           q.[FechaHora],
           q.[Latitud],
           q.[Longitud],
           CAST(q.[Lugar] AS nvarchar(500)) COLLATE DATABASE_DEFAULT AS [Lugar],
           CAST(q.[Regla] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [Regla],
           q.[UnidadFlotaId],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[Evento]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Mensaje]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaHora], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Latitud]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Longitud]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Lugar]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Regla]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[UnidadFlotaId]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_UnidadFlotaId],
           CONCAT_WS(N',', CASE WHEN LEN(q.[Evento]) > 100 THEN N'Evento' END, CASE WHEN LEN(q.[Mensaje]) > 500 THEN N'Mensaje' END, CASE WHEN LEN(q.[Lugar]) > 500 THEN N'Lugar' END, CASE WHEN LEN(q.[Regla]) > 200 THEN N'Regla' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT 'Navsat' AS FuenteSistema,
               N'Navsat' AS FuenteBase,
               N'eventos' AS FuenteTabla,
               CONVERT(nvarchar(66), HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(4000), e.[dispositivo]), N'~'), ISNULL(CONVERT(nvarchar(30), e.[fecha], 126), N'~'), ISNULL(CONVERT(nvarchar(4000), e.[evento]), N'~'), ISNULL(CONVERT(nvarchar(4000), e.[regla]), N'~'), ISNULL(CONVERT(nvarchar(4000), e.[latitude]), N'~'), ISNULL(CONVERT(nvarchar(4000), e.[longitude]), N'~'))), 2) AS FuenteLlave,
               ctl.fn_FechaCR(CONVERT(nvarchar(30), e.[fecha], 126)) AS FechaDato,
               ctl.fn_Texto(CONVERT(nvarchar(max), e.[evento])) AS [Evento],
               ctl.fn_Texto(CONVERT(nvarchar(max), e.[mensaje])) AS [Mensaje],
               ctl.fn_FechaCR(CONVERT(nvarchar(30), e.[fecha], 126)) AS [FechaHora],
               ctl.fn_CoordenadaSola(CONVERT(nvarchar(60), e.[latitude]), 1) AS [Latitud],
               ctl.fn_CoordenadaSola(CONVERT(nvarchar(60), e.[longitude]), 2) AS [Longitud],
               ctl.fn_Texto(CONVERT(nvarchar(max), e.[lugar])) AS [Lugar],
               ctl.fn_Texto(CONVERT(nvarchar(max), e.[regla])) AS [Regla],
               fk_UnidadFlotaId_0.Id AS [UnidadFlotaId],
               ctl.fn_Texto(CONVERT(nvarchar(400), e.[dispositivo])) AS [o_UnidadFlotaId]
        FROM Navsat.dbo.[eventos] e
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[UnidadFlotaId]) END AS Id FROM ref.UnidadFlota zref WHERE zref.[Dispositivo] = ctl.fn_Texto(CONVERT(nvarchar(max), e.[dispositivo]))) fk_UnidadFlotaId_0
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);
    /* Conciliación: llaves leídas, para comprobar al final que toda fila excluida tiene su motivo en ctl.Descarte */
    DROP TABLE IF EXISTS #leidas;
    SELECT DISTINCT FuenteTabla, FuenteLlave INTO #leidas FROM #src;

    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FechaHora obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FechaHora] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'IN-01', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'UnidadFlotaId obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[UnidadFlotaId] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'IN-01' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FuenteLlave obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FuenteLlave] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE FROM #src WHERE [FechaHora] IS NULL OR [UnidadFlotaId] IS NULL OR [FuenteLlave] IS NULL;

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
    SELECT t.[EventoFlotaId] AS RegistroId, t.FuenteLlave, (SELECT t.[UnidadFlotaId], t.[FechaHora], t.[Evento], t.[Mensaje], t.[Regla], t.[Latitud], t.[Longitud], t.[Lugar], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.EventoFlota t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato);

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.EventoFlota WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato)) THEN
        UPDATE SET t.[Evento] = s.[Evento], t.[Mensaje] = s.[Mensaje], t.[FechaHora] = s.[FechaHora], t.[Latitud] = s.[Latitud], t.[Longitud] = s.[Longitud], t.[Lugar] = s.[Lugar], t.[Regla] = s.[Regla], t.[UnidadFlotaId] = s.[UnidadFlotaId], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([Evento], [Mensaje], [FechaHora], [Latitud], [Longitud], [Lugar], [Regla], [UnidadFlotaId], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[Evento], s.[Mensaje], s.[FechaHora], s.[Latitud], s.[Longitud], s.[Lugar], s.[Regla], s.[UnidadFlotaId], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[EventoFlotaId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.EventoFlota', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.EventoFlota', t.[EventoFlotaId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.EventoFlota t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.EventoFlota', t.[EventoFlotaId], N'UnidadFlotaId', LEFT(CONVERT(nvarchar(400), s.o_UnidadFlotaId), 400), N'Referencia sin correspondencia única en ref.UnidadFlota'
    FROM #src s JOIN core.EventoFlota t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_UnidadFlotaId IS NOT NULL AND s.[UnidadFlotaId] IS NULL;

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
