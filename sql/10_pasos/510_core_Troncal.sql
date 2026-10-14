USE ADN_Unificado;
GO
/* Paso 510 · core_Troncal → core.Troncal
   Troncales de los clientes VoIP. El servicio se toma del cliente VoIP en la tabla de correspondencia (ID-07). El permiso SinRestriccion viene de Telephony_trunkpermissions (se fusiona aquí). El código de troncal es único en el modelo: si se repite en el origen se conserva el registro más reciente (DD-04).
   Reglas: ID-07, IN-01, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_Troncal @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT CAST(q.[CodigoTroncal] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [CodigoTroncal],
           CAST(q.[Tipo] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [Tipo],
           q.[TollFreeEntrante],
           q.[DIDEntrante],
           CAST(q.[Estado] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [Estado],
           CAST(q.[CodigoEstadoPredeterminado] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [CodigoEstadoPredeterminado],
           CAST(q.[EstadoSIP] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [EstadoSIP],
           q.[ServicioId],
           q.[SinRestriccion],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[CodigoTroncal]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Tipo]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TollFreeEntrante]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[DIDEntrante]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Estado]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[CodigoEstadoPredeterminado]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[EstadoSIP]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ServicioId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[SinRestriccion]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_Repetido],
           q.[o_ServicioId],
           CONCAT_WS(N',', CASE WHEN LEN(q.[CodigoTroncal]) > 50 THEN N'CodigoTroncal' END, CASE WHEN LEN(q.[Tipo]) > 30 THEN N'Tipo' END, CASE WHEN LEN(q.[Estado]) > 30 THEN N'Estado' END, CASE WHEN LEN(q.[CodigoEstadoPredeterminado]) > 30 THEN N'CodigoEstadoPredeterminado' END, CASE WHEN LEN(q.[EstadoSIP]) > 30 THEN N'EstadoSIP' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT 'AppDataCR' AS FuenteSistema,
               N'ADNApp' AS FuenteBase,
               N'Telephony_trunk' AS FuenteTabla,
               ctl.fn_Texto(CONVERT(nvarchar(200), t.[id])) AS FuenteLlave,
               CAST(NULL AS datetimeoffset(0)) AS FechaDato,
               ctl.fn_Texto(CONVERT(nvarchar(max), t.[TrunkID])) AS [CodigoTroncal],
               ctl.fn_Texto(CONVERT(nvarchar(max), t.[TrunkType])) AS [Tipo],
               t.[IncomingTollFree] AS [TollFreeEntrante],
               t.[IncomingDID] AS [DIDEntrante],
               ctl.fn_Texto(CONVERT(nvarchar(max), t.[State])) AS [Estado],
               ctl.fn_Texto(CONVERT(nvarchar(max), t.[StateDefaultCode])) AS [CodigoEstadoPredeterminado],
               ctl.fn_Texto(CONVERT(nvarchar(max), t.[StateSIP])) AS [EstadoSIP],
               fk_ServicioId_0.Id AS [ServicioId],
               ctl.fn_Texto(CONVERT(nvarchar(400), t.[CustomerID_id])) AS [o_ServicioId],
               (SELECT TOP 1 tp.NoRestriction FROM ADNApp.dbo.Telephony_trunkpermissions tp WHERE tp.TrunkID_id = t.id ORDER BY tp.id DESC) AS [SinRestriccion],
               ROW_NUMBER() OVER (PARTITION BY ctl.fn_Texto(t.TrunkID) ORDER BY t.id DESC) AS [o_Repetido]
        FROM ADNApp.dbo.[Telephony_trunk] t
        OUTER APPLY (SELECT CASE WHEN COUNT(DISTINCT zref.[ServicioId]) = 1 THEN MIN(zref.[ServicioId]) END AS Id FROM core.ClienteOrigen zref WHERE zref.Sistema = 'AppDataCR' AND zref.LlaveOrigen = ctl.fn_Texto(CONVERT(nvarchar(max), t.[CustomerID_id]))) fk_ServicioId_0
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);
    /* Conciliación: llaves leídas, para comprobar al final que toda fila excluida tiene su motivo en ctl.Descarte */
    DROP TABLE IF EXISTS #leidas;
    SELECT DISTINCT FuenteTabla, FuenteLlave INTO #leidas FROM #src;

    /* 2. Filtros de carga: filas excluidas con la regla que las excluye (DD-06) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'DD-04', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'Código de troncal repetido en Telephony_trunk: se conserva el registro más reciente (id mayor)', @Ahora FROM #src s WHERE s.o_Repetido > 1
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'DD-04' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE s FROM #src s WHERE s.o_Repetido > 1;
    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'CodigoTroncal obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[CodigoTroncal] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FuenteLlave obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FuenteLlave] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE FROM #src WHERE [CodigoTroncal] IS NULL OR [FuenteLlave] IS NULL;

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
    SELECT t.[TroncalId] AS RegistroId, t.FuenteLlave, (SELECT t.[ServicioId], t.[CodigoTroncal], t.[Tipo], t.[TollFreeEntrante], t.[DIDEntrante], t.[Estado], t.[CodigoEstadoPredeterminado], t.[EstadoSIP], t.[SinRestriccion], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.Troncal t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato);

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.Troncal WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato)) THEN
        UPDATE SET t.[CodigoTroncal] = s.[CodigoTroncal], t.[Tipo] = s.[Tipo], t.[TollFreeEntrante] = s.[TollFreeEntrante], t.[DIDEntrante] = s.[DIDEntrante], t.[Estado] = s.[Estado], t.[CodigoEstadoPredeterminado] = s.[CodigoEstadoPredeterminado], t.[EstadoSIP] = s.[EstadoSIP], t.[ServicioId] = s.[ServicioId], t.[SinRestriccion] = s.[SinRestriccion], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([CodigoTroncal], [Tipo], [TollFreeEntrante], [DIDEntrante], [Estado], [CodigoEstadoPredeterminado], [EstadoSIP], [ServicioId], [SinRestriccion], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[CodigoTroncal], s.[Tipo], s.[TollFreeEntrante], s.[DIDEntrante], s.[Estado], s.[CodigoEstadoPredeterminado], s.[EstadoSIP], s.[ServicioId], s.[SinRestriccion], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[TroncalId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.Troncal', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.Troncal', t.[TroncalId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.Troncal t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.Troncal', t.[TroncalId], N'ServicioId', LEFT(CONVERT(nvarchar(400), s.o_ServicioId), 400), N'Referencia sin correspondencia única en core.Servicio'
    FROM #src s JOIN core.Troncal t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_ServicioId IS NOT NULL AND s.[ServicioId] IS NULL;

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
