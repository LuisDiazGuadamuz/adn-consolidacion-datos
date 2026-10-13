USE ADN_Unificado;
GO
/* Paso 801 · core_EventoConexion → core.EventoConexion
   Conexiones y desconexiones realizadas (histórico, D12). customer_name es el id del contacto de Books: el cliente se liga por la tabla de correspondencia (ID-04). Sin llave: huella de la fila.
   Reglas: D12, DD-01, ES-01, ES-02, ID-04, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_EventoConexion @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT q.[DireccionesIP] COLLATE DATABASE_DEFAULT AS [DireccionesIP],
           CAST(q.[Tipo] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Tipo],
           CAST(q.[RealizadoPor] AS nvarchar(100)) COLLATE DATABASE_DEFAULT AS [RealizadoPor],
           q.[Fecha],
           q.[ErroresIP] COLLATE DATABASE_DEFAULT AS [ErroresIP],
           CAST(q.[TipoDesconexionReconexion] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [TipoDesconexionReconexion],
           q.[FechaDesconexionReconexion],
           CAST(q.[ContactoBooksId] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [ContactoBooksId],
           q.[ClienteId],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[DireccionesIP]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Tipo]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[RealizadoPor]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Fecha], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ErroresIP]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TipoDesconexionReconexion]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaDesconexionReconexion], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ContactoBooksId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ClienteId]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_FechaDesc],
           CONCAT_WS(N',', CASE WHEN LEN(q.[Tipo]) > 50 THEN N'Tipo' END, CASE WHEN LEN(q.[RealizadoPor]) > 100 THEN N'RealizadoPor' END, CASE WHEN LEN(q.[TipoDesconexionReconexion]) > 50 THEN N'TipoDesconexionReconexion' END, CASE WHEN LEN(q.[ContactoBooksId]) > 30 THEN N'ContactoBooksId' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT 'HistoryTables' AS FuenteSistema,
               N'History_Tables' AS FuenteBase,
               N'Conexiones_desconexiones_realizadas' AS FuenteTabla,
               CONVERT(nvarchar(66), HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(4000), x.[customer_name]), N'~'), ISNULL(CONVERT(nvarchar(4000), x.[type]), N'~'), ISNULL(CONVERT(nvarchar(30), x.[date], 126), N'~'), ISNULL(CONVERT(nvarchar(4000), x.[realized_by]), N'~'), ISNULL(CONVERT(nvarchar(4000), x.[type_desc_rec]), N'~'), ISNULL(CONVERT(nvarchar(30), x.[date_desc_rec], 126), N'~'))), 2) AS FuenteLlave,
               CAST(NULL AS datetimeoffset(0)) AS FechaDato,
               ctl.fn_Texto(CONVERT(nvarchar(max), CONVERT(nvarchar(max), x.[ip]))) AS [DireccionesIP],
               ctl.fn_Texto(CONVERT(nvarchar(max), x.[type])) AS [Tipo],
               ctl.fn_Texto(CONVERT(nvarchar(max), x.[realized_by])) AS [RealizadoPor],
               ctl.fn_FechaCR(CONVERT(nvarchar(30), x.[date], 126)) AS [Fecha],
               ctl.fn_Texto(CONVERT(nvarchar(max), CONVERT(nvarchar(max), x.[ip_errors]))) AS [ErroresIP],
               ctl.fn_Texto(CONVERT(nvarchar(max), x.[type_desc_rec])) AS [TipoDesconexionReconexion],
               ctl.fn_FechaCR(CONVERT(nvarchar(30), x.[date_desc_rec], 126)) AS [FechaDesconexionReconexion],
               ctl.fn_Texto(x.customer_name) AS [ContactoBooksId],
               co.ClienteId AS [ClienteId],
               CASE WHEN x.date_desc_rec IS NOT NULL THEN CONVERT(nvarchar(30), x.date_desc_rec, 126) END AS [o_FechaDesc]
        FROM History_Tables.dbo.[Conexiones_desconexiones_realizadas] x
        OUTER APPLY (SELECT CASE WHEN COUNT(DISTINCT o.ClienteId) = 1 THEN MIN(o.ClienteId) END AS ClienteId
                     FROM core.ClienteOrigen o WHERE o.Sistema = 'ZohoBooks' AND o.LlaveOrigen = ctl.fn_Texto(x.customer_name)) co
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FuenteLlave obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FuenteLlave] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE FROM #src WHERE [FuenteLlave] IS NULL;

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
    SELECT t.[EventoConexionId] AS RegistroId, t.FuenteLlave, (SELECT t.[ClienteId], t.[ContactoBooksId], t.[Tipo], t.[RealizadoPor], t.[Fecha], t.[TipoDesconexionReconexion], t.[FechaDesconexionReconexion], t.[DireccionesIP], t.[ErroresIP], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.EventoConexion t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido;

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.EventoConexion WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido) THEN
        UPDATE SET t.[DireccionesIP] = s.[DireccionesIP], t.[Tipo] = s.[Tipo], t.[RealizadoPor] = s.[RealizadoPor], t.[Fecha] = s.[Fecha], t.[ErroresIP] = s.[ErroresIP], t.[TipoDesconexionReconexion] = s.[TipoDesconexionReconexion], t.[FechaDesconexionReconexion] = s.[FechaDesconexionReconexion], t.[ContactoBooksId] = s.[ContactoBooksId], t.[ClienteId] = s.[ClienteId], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([DireccionesIP], [Tipo], [RealizadoPor], [Fecha], [ErroresIP], [TipoDesconexionReconexion], [FechaDesconexionReconexion], [ContactoBooksId], [ClienteId], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[DireccionesIP], s.[Tipo], s.[RealizadoPor], s.[Fecha], s.[ErroresIP], s.[TipoDesconexionReconexion], s.[FechaDesconexionReconexion], s.[ContactoBooksId], s.[ClienteId], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[EventoConexionId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.EventoConexion', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.EventoConexion', t.[EventoConexionId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.EventoConexion t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.EventoConexion', t.[EventoConexionId], N'FechaDesconexionReconexion', LEFT(CONVERT(nvarchar(400), s.o_FechaDesc), 400), N'Fecha de desconexión/reconexión ficticia o fuera de rango'
    FROM #src s JOIN core.EventoConexion t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaDesc IS NOT NULL AND s.FechaDesconexionReconexion IS NULL;

    SELECT @Leidas AS FilasLeidas, @Validas - (SELECT COUNT_BIG(*) FROM #cambios) AS FilasSinCambio;
END;
GO
