USE ADN_Unificado;
GO
/* Paso 702 · core_ViajeFlota → core.ViajeFlota
   Viajes finalizados de las unidades; la duración (time) se pasa a minutos. Id viene nulo en el origen (IN-05): la llave es la huella de dispositivo, inicio, fin y kilómetros.
   Reglas: DD-01, ES-01, IN-01, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_ViajeFlota @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT q.[FechaInicio],
           q.[FechaFin],
           q.[Kilometros],
           CAST(q.[LugarInicio] AS nvarchar(500)) COLLATE DATABASE_DEFAULT AS [LugarInicio],
           CAST(q.[LugarFin] AS nvarchar(500)) COLLATE DATABASE_DEFAULT AS [LugarFin],
           CAST(q.[Estado] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Estado],
           q.[UnidadFlotaId],
           q.[DuracionMinutos],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[FechaInicio], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaFin], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Kilometros]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[LugarInicio]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[LugarFin]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Estado]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[UnidadFlotaId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[DuracionMinutos]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_UnidadFlotaId],
           CONCAT_WS(N',', CASE WHEN LEN(q.[LugarInicio]) > 500 THEN N'LugarInicio' END, CASE WHEN LEN(q.[LugarFin]) > 500 THEN N'LugarFin' END, CASE WHEN LEN(q.[Estado]) > 50 THEN N'Estado' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT 'Navsat' AS FuenteSistema,
               N'Navsat' AS FuenteBase,
               N'viajes_ayer_finalizado' AS FuenteTabla,
               CONVERT(nvarchar(66), HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(4000), v.[DeviceName]), N'~'), ISNULL(CONVERT(nvarchar(30), v.[FechaInicio], 126), N'~'), ISNULL(CONVERT(nvarchar(30), v.[FechaFin], 126), N'~'), ISNULL(CONVERT(nvarchar(4000), v.[KilometrosRecorridos]), N'~'))), 2) AS FuenteLlave,
               CAST(NULL AS datetimeoffset(0)) AS FechaDato,
               ctl.fn_FechaCR(CONVERT(nvarchar(30), v.[FechaInicio], 126)) AS [FechaInicio],
               ctl.fn_FechaCR(CONVERT(nvarchar(30), v.[FechaFin], 126)) AS [FechaFin],
               TRY_CONVERT(decimal(10,2), v.[KilometrosRecorridos]) AS [Kilometros],
               ctl.fn_Texto(CONVERT(nvarchar(max), v.[LugarInicio])) AS [LugarInicio],
               ctl.fn_Texto(CONVERT(nvarchar(max), v.[LugarFin])) AS [LugarFin],
               ctl.fn_Texto(CONVERT(nvarchar(max), v.[Estado])) AS [Estado],
               fk_UnidadFlotaId_0.Id AS [UnidadFlotaId],
               ctl.fn_Texto(CONVERT(nvarchar(400), v.[DeviceName])) AS [o_UnidadFlotaId],
               CAST(DATEDIFF(SECOND, CAST('00:00:00' AS time), v.Duracion) / 60.0 AS decimal(12,2)) AS [DuracionMinutos]
        FROM Navsat.dbo.[viajes_ayer_finalizado] v
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[UnidadFlotaId]) END AS Id FROM ref.UnidadFlota zref WHERE zref.[Dispositivo] = ctl.fn_Texto(CONVERT(nvarchar(max), v.[DeviceName]))) fk_UnidadFlotaId_0
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FechaInicio obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FechaInicio] IS NULL
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
    DELETE FROM #src WHERE [FechaInicio] IS NULL OR [UnidadFlotaId] IS NULL OR [FuenteLlave] IS NULL;

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
    SELECT t.[ViajeFlotaId] AS RegistroId, t.FuenteLlave, (SELECT t.[UnidadFlotaId], t.[FechaInicio], t.[FechaFin], t.[Kilometros], t.[DuracionMinutos], t.[LugarInicio], t.[LugarFin], t.[Estado], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.ViajeFlota t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido;

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.ViajeFlota WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido) THEN
        UPDATE SET t.[FechaInicio] = s.[FechaInicio], t.[FechaFin] = s.[FechaFin], t.[Kilometros] = s.[Kilometros], t.[LugarInicio] = s.[LugarInicio], t.[LugarFin] = s.[LugarFin], t.[Estado] = s.[Estado], t.[UnidadFlotaId] = s.[UnidadFlotaId], t.[DuracionMinutos] = s.[DuracionMinutos], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([FechaInicio], [FechaFin], [Kilometros], [LugarInicio], [LugarFin], [Estado], [UnidadFlotaId], [DuracionMinutos], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[FechaInicio], s.[FechaFin], s.[Kilometros], s.[LugarInicio], s.[LugarFin], s.[Estado], s.[UnidadFlotaId], s.[DuracionMinutos], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[ViajeFlotaId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.ViajeFlota', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.ViajeFlota', t.[ViajeFlotaId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.ViajeFlota t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.ViajeFlota', t.[ViajeFlotaId], N'UnidadFlotaId', LEFT(CONVERT(nvarchar(400), s.o_UnidadFlotaId), 400), N'Referencia sin correspondencia única en ref.UnidadFlota'
    FROM #src s JOIN core.ViajeFlota t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_UnidadFlotaId IS NOT NULL AND s.[UnidadFlotaId] IS NULL;

    SELECT @Leidas AS FilasLeidas, @Validas - (SELECT COUNT_BIG(*) FROM #cambios) AS FilasSinCambio;
END;
GO
