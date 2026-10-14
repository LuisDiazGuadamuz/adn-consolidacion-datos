USE ADN_Unificado;
GO
/* Paso 334 · core_Nota_Servicio → core.Nota
   Notas de las cuentas del CRM (Entidad = SERVICIO).
   Reglas: D6, ES-01, ES-07, IN-01, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_Nota_Servicio @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT CAST(q.[NotaOrigenId] AS nvarchar(40)) COLLATE DATABASE_DEFAULT AS [NotaOrigenId],
           CAST(q.[Titulo] AS nvarchar(500)) COLLATE DATABASE_DEFAULT AS [Titulo],
           q.[Contenido] COLLATE DATABASE_DEFAULT AS [Contenido],
           q.[CompartidaConCliente],
           q.[FechaCreacionOrigen],
           q.[FechaModificacionOrigen],
           q.[ServicioId],
           q.[AutorUsuarioId],
           CAST(q.[Entidad] AS varchar(15)) COLLATE DATABASE_DEFAULT AS [Entidad],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[NotaOrigenId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Titulo]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Contenido]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[CompartidaConCliente]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaCreacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaModificacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ServicioId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[AutorUsuarioId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Entidad]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_ServicioId],
           q.[o_AutorUsuarioId],
           CONCAT_WS(N',', CASE WHEN LEN(q.[NotaOrigenId]) > 40 THEN N'NotaOrigenId' END, CASE WHEN LEN(q.[Titulo]) > 500 THEN N'Titulo' END, CASE WHEN LEN(q.[Entidad]) > 15 THEN N'Entidad' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT 'ZohoCRM' AS FuenteSistema,
               N'Zoho_Mirror' AS FuenteBase,
               N'Accounts_Notes' AS FuenteTabla,
               ctl.fn_Texto(CONVERT(nvarchar(200), n.[NoteId])) AS FuenteLlave,
               ctl.fn_FechaCR(CONVERT(nvarchar(30), n.[CreatedTime], 126)) AS FechaDato,
               ctl.fn_Texto(CONVERT(nvarchar(max), n.[NoteId])) AS [NotaOrigenId],
               ctl.fn_Texto(CONVERT(nvarchar(max), n.[NoteTitle])) AS [Titulo],
               ctl.fn_Texto(CONVERT(nvarchar(max), n.[NoteContent])) AS [Contenido],
               n.[IsSharedToClient] AS [CompartidaConCliente],
               ctl.fn_FechaCR(CONVERT(nvarchar(30), n.[CreatedTime], 126)) AS [FechaCreacionOrigen],
               ctl.fn_FechaCR(CONVERT(nvarchar(30), n.[ModifiedTime], 126)) AS [FechaModificacionOrigen],
               fk_ServicioId_0.Id AS [ServicioId],
               ctl.fn_Texto(CONVERT(nvarchar(400), n.[AccountId])) AS [o_ServicioId],
               fk_AutorUsuarioId_0.Id AS [AutorUsuarioId],
               ctl.fn_Texto(CONVERT(nvarchar(400), n.[OwnerId])) AS [o_AutorUsuarioId],
               'SERVICIO' AS [Entidad]
        FROM Zoho_Mirror.dbo.[Accounts_Notes] n
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[ServicioId]) END AS Id FROM core.Servicio zref WHERE zref.[CuentaCrmId] = ctl.fn_Texto(CONVERT(nvarchar(max), n.[AccountId]))) fk_ServicioId_0
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[UsuarioId]) END AS Id FROM ref.Usuario zref WHERE zref.[ZohoUsuarioId] = ctl.fn_Texto(CONVERT(nvarchar(max), n.[OwnerId])) OR zref.[NombreCompleto] = ctl.fn_Texto(CONVERT(nvarchar(max), n.[OwnerId]))) fk_AutorUsuarioId_0
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);
    /* Conciliación: llaves leídas, para comprobar al final que toda fila excluida tiene su motivo en ctl.Descarte */
    DROP TABLE IF EXISTS #leidas;
    SELECT DISTINCT FuenteTabla, FuenteLlave INTO #leidas FROM #src;

    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'NotaOrigenId obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[NotaOrigenId] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'Entidad obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[Entidad] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FuenteLlave obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FuenteLlave] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE FROM #src WHERE [NotaOrigenId] IS NULL OR [Entidad] IS NULL OR [FuenteLlave] IS NULL;

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
    SELECT t.[NotaId] AS RegistroId, t.FuenteLlave, (SELECT t.[NotaOrigenId], t.[Entidad], t.[ServicioId], t.[CasoId], t.[ClienteId], t.[Titulo], t.[Contenido], t.[CompartidaConCliente], t.[AutorUsuarioId], t.[Autor], t.[FechaCreacionOrigen], t.[FechaModificacionOrigen], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.Nota t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato);

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.Nota WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato)) THEN
        UPDATE SET t.[NotaOrigenId] = s.[NotaOrigenId], t.[Titulo] = s.[Titulo], t.[Contenido] = s.[Contenido], t.[CompartidaConCliente] = s.[CompartidaConCliente], t.[FechaCreacionOrigen] = s.[FechaCreacionOrigen], t.[FechaModificacionOrigen] = s.[FechaModificacionOrigen], t.[ServicioId] = s.[ServicioId], t.[AutorUsuarioId] = s.[AutorUsuarioId], t.[Entidad] = s.[Entidad], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([NotaOrigenId], [Titulo], [Contenido], [CompartidaConCliente], [FechaCreacionOrigen], [FechaModificacionOrigen], [ServicioId], [AutorUsuarioId], [Entidad], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[NotaOrigenId], s.[Titulo], s.[Contenido], s.[CompartidaConCliente], s.[FechaCreacionOrigen], s.[FechaModificacionOrigen], s.[ServicioId], s.[AutorUsuarioId], s.[Entidad], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[NotaId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.Nota', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.Nota', t.[NotaId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.Nota t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.Nota', t.[NotaId], N'ServicioId', LEFT(CONVERT(nvarchar(400), s.o_ServicioId), 400), N'Referencia sin correspondencia única en core.Servicio'
    FROM #src s JOIN core.Nota t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_ServicioId IS NOT NULL AND s.[ServicioId] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.Nota', t.[NotaId], N'AutorUsuarioId', LEFT(CONVERT(nvarchar(400), s.o_AutorUsuarioId), 400), N'Referencia sin correspondencia única en ref.Usuario'
    FROM #src s JOIN core.Nota t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_AutorUsuarioId IS NOT NULL AND s.[AutorUsuarioId] IS NULL;

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
