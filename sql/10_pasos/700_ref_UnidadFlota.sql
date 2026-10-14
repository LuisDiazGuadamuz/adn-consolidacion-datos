USE ADN_Unificado;
GO
/* Paso 700 · ref_UnidadFlota → ref.UnidadFlota
   Unidades de flota derivadas de todas las tablas de Navsat (una por dispositivo, con la placa más reciente). Clasificación ES-09: placa → VEHICULO_EMPRESA; 'propio' → VEHICULO_PROPIO; otro texto → COLABORADOR.
   Reglas: ES-05, ES-09, IN-05, DD-04
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_ref_UnidadFlota @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT CAST(q.[Dispositivo] AS nvarchar(100)) COLLATE DATABASE_DEFAULT AS [Dispositivo],
           CAST(q.[Placa] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [Placa],
           CAST(q.[TipoUnidad] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [TipoUnidad],
           CAST(q.[Descripcion] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [Descripcion],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[Dispositivo]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Placa]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TipoUnidad]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Descripcion]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           CONCAT_WS(N',', CASE WHEN LEN(q.[Dispositivo]) > 100 THEN N'Dispositivo' END, CASE WHEN LEN(q.[Placa]) > 30 THEN N'Placa' END, CASE WHEN LEN(q.[TipoUnidad]) > 20 THEN N'TipoUnidad' END, CASE WHEN LEN(q.[Descripcion]) > 200 THEN N'Descripcion' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT 'Navsat' AS FuenteSistema, N'Navsat' AS FuenteBase, N'Dispositivo' AS FuenteTabla, u.Dispositivo AS FuenteLlave,
               CAST(NULL AS datetimeoffset(0)) AS FechaDato, u.Dispositivo,
               CASE WHEN t.Tipo = 'VEHICULO_EMPRESA' THEN p.PlacaNorm END AS Placa, t.Tipo AS TipoUnidad, u.Texto AS Descripcion
        FROM (
            SELECT Dispositivo, Texto, ROW_NUMBER() OVER (PARTITION BY Dispositivo ORDER BY Fecha DESC, Texto) AS rn FROM (
                SELECT CAST(ctl.fn_Texto(deviceName) AS nvarchar(100)) AS Dispositivo, ctl.fn_Texto(plateNumber) AS Texto, ctl.fn_FechaCR(crDateTime) AS Fecha FROM Navsat.dbo.Ultima_ubicacion
                UNION ALL SELECT CAST(ctl.fn_Texto(DeviceName) AS nvarchar(100)), ctl.fn_Texto(PlateNumber), TODATETIMEOFFSET(FechaInicio, '-06:00') FROM Navsat.dbo.viajes_ayer_finalizado
                UNION ALL SELECT CAST(ctl.fn_Texto(dispositivo) AS nvarchar(100)), ctl.fn_Texto(placa), TODATETIMEOFFSET(fecha, '-06:00') FROM Navsat.dbo.eventos
                UNION ALL SELECT CAST(ctl.fn_Texto(dispositivo) AS nvarchar(100)), ctl.fn_Texto(placa_vehiculo), TODATETIMEOFFSET(fecha_hora_incidente, '-06:00') FROM Navsat.dbo.Eco_Driving
            ) x WHERE Dispositivo IS NOT NULL) u
        CROSS APPLY (SELECT UPPER(REPLACE(REPLACE(u.Texto, N'-', N''), N' ', N'')) AS PlacaNorm) p
        CROSS APPLY (SELECT CASE WHEN u.Texto LIKE N'%propio%' THEN 'VEHICULO_PROPIO'
                                 WHEN p.PlacaNorm COLLATE Latin1_General_BIN LIKE '[A-Z][A-Z][A-Z][0-9][0-9][0-9]'
                                   OR p.PlacaNorm LIKE '[0-9][0-9][0-9][0-9][0-9][0-9]'
                                   OR p.PlacaNorm LIKE '[0-9][0-9][0-9][0-9][0-9]'
                                   OR p.PlacaNorm COLLATE Latin1_General_BIN LIKE '[A-Z][A-Z][0-9]%' AND LEN(p.PlacaNorm) <= 8 THEN 'VEHICULO_EMPRESA'
                                 ELSE 'COLABORADOR' END AS Tipo) t
        WHERE u.rn = 1
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);
    /* Conciliación: llaves leídas, para comprobar al final que toda fila excluida tiene su motivo en ctl.Descarte */
    DROP TABLE IF EXISTS #leidas;
    SELECT DISTINCT FuenteTabla, FuenteLlave INTO #leidas FROM #src;

    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'Dispositivo obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[Dispositivo] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'TipoUnidad obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[TipoUnidad] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FuenteLlave obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FuenteLlave] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE FROM #src WHERE [Dispositivo] IS NULL OR [TipoUnidad] IS NULL OR [FuenteLlave] IS NULL;

    /* 2b. Duplicados por la llave del paso (DD-04); el orden es determinista */
    ;WITH r AS (
        SELECT s.FuenteSistema, s.FuenteTabla, s.FuenteLlave,
               ROW_NUMBER() OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.FuenteLlave) AS rn,
               FIRST_VALUE(s.FuenteLlave) OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.FuenteLlave ROWS UNBOUNDED PRECEDING) AS Conservada
        FROM #src s)
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, LlaveConservada, Motivo, FechaDescarte)
    SELECT @LoteId, 'DD-04', r.FuenteSistema, r.FuenteTabla, r.FuenteLlave, r.Conservada, N'Registro repetido por la llave del paso; se conserva uno según el orden definido', @Ahora
    FROM r WHERE r.rn > 1
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'DD-04' AND x.FuenteTabla = r.FuenteTabla AND x.FuenteLlave = r.FuenteLlave);
    ;WITH r AS (
        SELECT ROW_NUMBER() OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.FuenteLlave) AS rn FROM #src s)
    DELETE FROM r WHERE rn > 1;
    DECLARE @Validas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 3. Imagen previa de las filas que van a cambiar (para el rollback) */
    DROP TABLE IF EXISTS #antes;
    SELECT t.[UnidadFlotaId] AS RegistroId, t.FuenteLlave, (SELECT t.[Dispositivo], t.[Placa], t.[TipoUnidad], t.[Descripcion], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM ref.UnidadFlota t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato);

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE ref.UnidadFlota WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato)) THEN
        UPDATE SET t.[Dispositivo] = s.[Dispositivo], t.[Placa] = s.[Placa], t.[TipoUnidad] = s.[TipoUnidad], t.[Descripcion] = s.[Descripcion], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([Dispositivo], [Placa], [TipoUnidad], [Descripcion], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[Dispositivo], s.[Placa], s.[TipoUnidad], s.[Descripcion], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[UnidadFlotaId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'ref.UnidadFlota', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'ref.UnidadFlota', t.[UnidadFlotaId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN ref.UnidadFlota t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
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
