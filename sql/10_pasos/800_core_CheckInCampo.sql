USE ADN_Unificado;
GO
/* Paso 800 · core_CheckInCampo → core.CheckInCampo
   Registros de visita en campo de los colaboradores (History_Tables).
   Reglas: D6, ES-01, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_CheckInCampo @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT q.[FechaHora],
           CAST(q.[Direccion] AS nvarchar(500)) COLLATE DATABASE_DEFAULT AS [Direccion],
           q.[Longitud],
           CAST(q.[RutaArchivo] AS nvarchar(1000)) COLLATE DATABASE_DEFAULT AS [RutaArchivo],
           CAST(q.[UrlDescarga] AS nvarchar(1000)) COLLATE DATABASE_DEFAULT AS [UrlDescarga],
           CAST(q.[Empleado] AS nvarchar(150)) COLLATE DATABASE_DEFAULT AS [Empleado],
           CAST(q.[Comentario] AS nvarchar(1000)) COLLATE DATABASE_DEFAULT AS [Comentario],
           q.[Latitud],
           q.[ArchivoId],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[FechaHora], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Direccion]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Longitud]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[RutaArchivo]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[UrlDescarga]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Empleado]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Comentario]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Latitud]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ArchivoId]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           CONCAT_WS(N',', CASE WHEN LEN(q.[Direccion]) > 500 THEN N'Direccion' END, CASE WHEN LEN(q.[RutaArchivo]) > 1000 THEN N'RutaArchivo' END, CASE WHEN LEN(q.[UrlDescarga]) > 1000 THEN N'UrlDescarga' END, CASE WHEN LEN(q.[Empleado]) > 150 THEN N'Empleado' END, CASE WHEN LEN(q.[Comentario]) > 1000 THEN N'Comentario' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT 'HistoryTables' AS FuenteSistema,
               N'History_Tables' AS FuenteBase,
               N'check_in_navsat' AS FuenteTabla,
               ctl.fn_Texto(CONVERT(nvarchar(200), c.[Id])) AS FuenteLlave,
               ctl.fn_FechaCR(CONVERT(nvarchar(30), c.[fecha], 126)) AS FechaDato,
               ctl.fn_FechaCR(CONVERT(nvarchar(30), c.[fecha], 126)) AS [FechaHora],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[address])) AS [Direccion],
               ctl.fn_CoordenadaSola(CONVERT(nvarchar(60), c.[longitud]), 2) AS [Longitud],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[relative_path])) AS [RutaArchivo],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[download_url])) AS [UrlDescarga],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[Empleado])) AS [Empleado],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[comentario])) AS [Comentario],
               ctl.fn_CoordenadaSola(CONVERT(nvarchar(60), c.[latitud]), 1) AS [Latitud],
               TRY_CONVERT(int, c.[file_id]) AS [ArchivoId]
        FROM History_Tables.dbo.[check_in_navsat] c
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
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FuenteLlave obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FuenteLlave] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE FROM #src WHERE [FechaHora] IS NULL OR [FuenteLlave] IS NULL;

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
    SELECT t.[CheckInCampoId] AS RegistroId, t.FuenteLlave, (SELECT t.[Empleado], t.[FechaHora], t.[Direccion], t.[Latitud], t.[Longitud], t.[Comentario], t.[RutaArchivo], t.[UrlDescarga], t.[ArchivoId], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.CheckInCampo t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato);

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.CheckInCampo WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato)) THEN
        UPDATE SET t.[FechaHora] = s.[FechaHora], t.[Direccion] = s.[Direccion], t.[Longitud] = s.[Longitud], t.[RutaArchivo] = s.[RutaArchivo], t.[UrlDescarga] = s.[UrlDescarga], t.[Empleado] = s.[Empleado], t.[Comentario] = s.[Comentario], t.[Latitud] = s.[Latitud], t.[ArchivoId] = s.[ArchivoId], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([FechaHora], [Direccion], [Longitud], [RutaArchivo], [UrlDescarga], [Empleado], [Comentario], [Latitud], [ArchivoId], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[FechaHora], s.[Direccion], s.[Longitud], s.[RutaArchivo], s.[UrlDescarga], s.[Empleado], s.[Comentario], s.[Latitud], s.[ArchivoId], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[CheckInCampoId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.CheckInCampo', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.CheckInCampo', t.[CheckInCampoId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.CheckInCampo t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
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
