USE ADN_Unificado;
GO
/* Paso 701 · core_UbicacionFlota → core.UbicacionFlota
   Posiciones reportadas por las unidades (sin llave en el origen: huella de dispositivo, fecha y coordenadas). 2,5 millones de filas: se carga por período (--desde/--hasta, hasta exclusivo).
   Reglas: DD-01, ES-01, ES-02, IN-01, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_UbicacionFlota @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT q.[FechaHora],
           q.[Latitud],
           q.[Longitud],
           q.[Odometro],
           q.[Velocidad],
           CAST(q.[Lugar] AS nvarchar(500)) COLLATE DATABASE_DEFAULT AS [Lugar],
           CAST(q.[Estado] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Estado],
           q.[UnidadFlotaId],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[FechaHora], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Latitud]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Longitud]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Odometro]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Velocidad]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Lugar]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Estado]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[UnidadFlotaId]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_UnidadFlotaId],
           q.[o_FechaHora],
           CONCAT_WS(N',', CASE WHEN LEN(q.[Lugar]) > 500 THEN N'Lugar' END, CASE WHEN LEN(q.[Estado]) > 50 THEN N'Estado' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT 'Navsat' AS FuenteSistema,
               N'Navsat' AS FuenteBase,
               N'Ultima_ubicacion' AS FuenteTabla,
               CONVERT(nvarchar(66), HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(4000), u.[deviceName]), N'~'), ISNULL(CONVERT(nvarchar(4000), u.[crDateTime]), N'~'), ISNULL(CONVERT(nvarchar(4000), u.[latitude]), N'~'), ISNULL(CONVERT(nvarchar(4000), u.[longitude]), N'~'))), 2) AS FuenteLlave,
               ctl.fn_FechaCR(CONVERT(nvarchar(60), u.[crDateTime])) AS FechaDato,
               ctl.fn_FechaCR(CONVERT(nvarchar(60), u.[crDateTime])) AS [FechaHora],
               ctl.fn_CoordenadaSola(CONVERT(nvarchar(60), u.[latitude]), 1) AS [Latitud],
               ctl.fn_CoordenadaSola(CONVERT(nvarchar(60), u.[longitude]), 2) AS [Longitud],
               TRY_CONVERT(decimal(12,2), u.[odometer]) AS [Odometro],
               TRY_CONVERT(decimal(7,2), u.[speed]) AS [Velocidad],
               ctl.fn_Texto(CONVERT(nvarchar(max), u.[lugar])) AS [Lugar],
               ctl.fn_Texto(CONVERT(nvarchar(max), u.[estado])) AS [Estado],
               fk_UnidadFlotaId_0.Id AS [UnidadFlotaId],
               ctl.fn_Texto(CONVERT(nvarchar(400), u.[deviceName])) AS [o_UnidadFlotaId],
               ctl.fn_Texto(CONVERT(nvarchar(400), u.[crDateTime])) AS [o_FechaHora]
        FROM Navsat.dbo.[Ultima_ubicacion] u
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[UnidadFlotaId]) END AS Id FROM ref.UnidadFlota zref WHERE zref.[Dispositivo] = ctl.fn_Texto(CONVERT(nvarchar(max), u.[deviceName]))) fk_UnidadFlotaId_0
        WHERE (@Desde IS NULL OR ctl.fn_FechaCR(u.crDateTime) >= TODATETIMEOFFSET(CAST(@Desde AS datetime2), '-06:00')) AND (@Hasta IS NULL OR ctl.fn_FechaCR(u.crDateTime) < TODATETIMEOFFSET(CAST(@Hasta AS datetime2), '-06:00'))
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);

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
    SELECT t.[UbicacionFlotaId] AS RegistroId, t.FuenteLlave, (SELECT t.[UnidadFlotaId], t.[FechaHora], t.[Latitud], t.[Longitud], t.[Odometro], t.[Velocidad], t.[Lugar], t.[Estado], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.UbicacionFlota t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato);

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.UbicacionFlota WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato)) THEN
        UPDATE SET t.[FechaHora] = s.[FechaHora], t.[Latitud] = s.[Latitud], t.[Longitud] = s.[Longitud], t.[Odometro] = s.[Odometro], t.[Velocidad] = s.[Velocidad], t.[Lugar] = s.[Lugar], t.[Estado] = s.[Estado], t.[UnidadFlotaId] = s.[UnidadFlotaId], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([FechaHora], [Latitud], [Longitud], [Odometro], [Velocidad], [Lugar], [Estado], [UnidadFlotaId], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[FechaHora], s.[Latitud], s.[Longitud], s.[Odometro], s.[Velocidad], s.[Lugar], s.[Estado], s.[UnidadFlotaId], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[UbicacionFlotaId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.UbicacionFlota', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.UbicacionFlota', t.[UbicacionFlotaId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.UbicacionFlota t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.UbicacionFlota', t.[UbicacionFlotaId], N'UnidadFlotaId', LEFT(CONVERT(nvarchar(400), s.o_UnidadFlotaId), 400), N'Referencia sin correspondencia única en ref.UnidadFlota'
    FROM #src s JOIN core.UbicacionFlota t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_UnidadFlotaId IS NOT NULL AND s.[UnidadFlotaId] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.UbicacionFlota', t.[UbicacionFlotaId], N'FechaHora', LEFT(CONVERT(nvarchar(400), s.o_FechaHora), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.UbicacionFlota t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaHora IS NOT NULL AND s.[FechaHora] IS NULL;

    SELECT @Leidas AS FilasLeidas, @Validas - (SELECT COUNT_BIG(*) FROM #cambios) AS FilasSinCambio;
END;
GO
