USE ADN_Unificado;
GO
/* Paso 331 · core_OrdenServicioVoIP → core.OrdenServicioVoIP
   Órdenes de servicio de voz IP. El servicio se vincula por circuito con correspondencia única (ID-01).
   Reglas: DD-06, ES-01, ES-02, ID-01, IN-01, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_OrdenServicioVoIP @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT CAST(q.[TipoServicio] AS nvarchar(100)) COLLATE DATABASE_DEFAULT AS [TipoServicio],
           CAST(q.[TipoSolicitud] AS nvarchar(100)) COLLATE DATABASE_DEFAULT AS [TipoSolicitud],
           q.[FechaSolicitud],
           q.[FechaDesinstalacion],
           q.[FechaCreacionOrigen],
           CAST(q.[OrdenCrmId] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [OrdenCrmId],
           CAST(q.[Estado] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Estado],
           CAST(q.[Nombre] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [Nombre],
           q.[FechaInstalacion],
           q.[ServicioId],
           q.[AtributosExtendidos] COLLATE DATABASE_DEFAULT AS [AtributosExtendidos],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[TipoServicio]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TipoSolicitud]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaSolicitud], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaDesinstalacion], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaCreacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[OrdenCrmId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Estado]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Nombre]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaInstalacion], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ServicioId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[AtributosExtendidos]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_ServicioId],
           q.[o_FechaSolicitud],
           q.[o_FechaDesinstalacion],
           q.[o_FechaCreacionOrigen],
           q.[o_FechaInstalacion],
           q.[o_Eliminado],
           CONCAT_WS(N',', CASE WHEN LEN(q.[TipoServicio]) > 100 THEN N'TipoServicio' END, CASE WHEN LEN(q.[TipoSolicitud]) > 100 THEN N'TipoSolicitud' END, CASE WHEN LEN(q.[OrdenCrmId]) > 30 THEN N'OrdenCrmId' END, CASE WHEN LEN(q.[Estado]) > 50 THEN N'Estado' END, CASE WHEN LEN(q.[Nombre]) > 200 THEN N'Nombre' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT 'ZohoCRM' AS FuenteSistema,
               N'Zoho_Mirror' AS FuenteBase,
               N'Orden_de_Servicio_Voz_IP' AS FuenteTabla,
               ctl.fn_Texto(CONVERT(nvarchar(200), v.[id])) AS FuenteLlave,
               ctl.fn_FechaCR(CONVERT(nvarchar(60), v.[Created_Time])) AS FechaDato,
               ctl.fn_Texto(CONVERT(nvarchar(max), v.[Tipo_Servicio])) AS [TipoServicio],
               ctl.fn_Texto(CONVERT(nvarchar(max), v.[Tipo_Solicitud])) AS [TipoSolicitud],
               ctl.fn_FechaDia(CONVERT(nvarchar(60), v.[Fecha_de_Solicitud])) AS [FechaSolicitud],
               ctl.fn_FechaDia(CONVERT(nvarchar(60), v.[Fecha_de_Desinstalacion])) AS [FechaDesinstalacion],
               ctl.fn_FechaCR(CONVERT(nvarchar(60), v.[Created_Time])) AS [FechaCreacionOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(max), v.[id])) AS [OrdenCrmId],
               ctl.fn_Texto(CONVERT(nvarchar(max), v.[Estado])) AS [Estado],
               ctl.fn_Texto(CONVERT(nvarchar(max), v.[Name])) AS [Nombre],
               ctl.fn_FechaDia(CONVERT(nvarchar(60), v.[Fecha_Instalacion])) AS [FechaInstalacion],
               fk_ServicioId_0.Id AS [ServicioId],
               ctl.fn_Texto(CONVERT(nvarchar(400), v.[N_mero_Circuito])) AS [o_ServicioId],
               ctl.fn_Texto(CONVERT(nvarchar(400), v.[Fecha_de_Solicitud])) AS [o_FechaSolicitud],
               ctl.fn_Texto(CONVERT(nvarchar(400), v.[Fecha_de_Desinstalacion])) AS [o_FechaDesinstalacion],
               ctl.fn_Texto(CONVERT(nvarchar(400), v.[Created_Time])) AS [o_FechaCreacionOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(400), v.[Fecha_Instalacion])) AS [o_FechaInstalacion],
               NULLIF((SELECT ctl.fn_Texto(CONVERT(nvarchar(max), v.[Tag])) AS [Tag], ctl.fn_Texto(CONVERT(nvarchar(max), v.[Created_By])) AS [Created_By], ctl.fn_Texto(CONVERT(nvarchar(max), v.[Layout])) AS [Layout], ctl.fn_Texto(CONVERT(nvarchar(max), v.[Contrato])) AS [Contrato], ctl.fn_Texto(CONVERT(nvarchar(max), v.[Cliente])) AS [Cliente], ctl.fn_Texto(CONVERT(nvarchar(max), v.[Unsubscribed_Mode])) AS [Unsubscribed_Mode], ctl.fn_Texto(CONVERT(nvarchar(max), v.[Last_Activity_Time])) AS [Last_Activity_Time], ctl.fn_Texto(CONVERT(nvarchar(max), v.[Proveedor_IPTV])) AS [Proveedor_IPTV], ctl.fn_Texto(CONVERT(nvarchar(max), v.[Descripci_n])) AS [Descripci_n], ctl.fn_Texto(CONVERT(nvarchar(max), v.[Contacto_1])) AS [Contacto_1], ctl.fn_Texto(CONVERT(nvarchar(max), v.[Owner])) AS [Owner] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER), N'{}') AS [AtributosExtendidos],
               CAST(ISNULL(v.[deleted], 0) AS int) AS [o_Eliminado]
        FROM Zoho_Mirror.dbo.[Orden_de_Servicio_Voz_IP] v
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[ServicioId]) END AS Id FROM core.Servicio zref WHERE zref.Circuito = ctl.fn_Circuito(CONVERT(nvarchar(100), v.[N_mero_Circuito]))) fk_ServicioId_0
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);
    /* Conciliación: llaves leídas, para comprobar al final que toda fila excluida tiene su motivo en ctl.Descarte */
    DROP TABLE IF EXISTS #leidas;
    SELECT DISTINCT FuenteTabla, FuenteLlave INTO #leidas FROM #src;

    /* 2. Filtros de carga: filas excluidas con la regla que las excluye (DD-06) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'DD-06', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'Registro marcado como eliminado en el origen (deleted = 1)', @Ahora FROM #src s WHERE s.o_Eliminado = 1
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'DD-06' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE s FROM #src s WHERE s.o_Eliminado = 1;
    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'OrdenCrmId obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[OrdenCrmId] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FuenteLlave obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FuenteLlave] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE FROM #src WHERE [OrdenCrmId] IS NULL OR [FuenteLlave] IS NULL;

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
    SELECT t.[OrdenServicioVoIPId] AS RegistroId, t.FuenteLlave, (SELECT t.[OrdenCrmId], t.[ServicioId], t.[Nombre], t.[TipoServicio], t.[TipoSolicitud], t.[Estado], t.[FechaSolicitud], t.[FechaInstalacion], t.[FechaDesinstalacion], t.[AtributosExtendidos], t.[FechaCreacionOrigen], t.[FechaModificacionOrigen], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.OrdenServicioVoIP t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato);

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.OrdenServicioVoIP WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato)) THEN
        UPDATE SET t.[TipoServicio] = s.[TipoServicio], t.[TipoSolicitud] = s.[TipoSolicitud], t.[FechaSolicitud] = s.[FechaSolicitud], t.[FechaDesinstalacion] = s.[FechaDesinstalacion], t.[FechaCreacionOrigen] = s.[FechaCreacionOrigen], t.[OrdenCrmId] = s.[OrdenCrmId], t.[Estado] = s.[Estado], t.[Nombre] = s.[Nombre], t.[FechaInstalacion] = s.[FechaInstalacion], t.[ServicioId] = s.[ServicioId], t.[AtributosExtendidos] = s.[AtributosExtendidos], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([TipoServicio], [TipoSolicitud], [FechaSolicitud], [FechaDesinstalacion], [FechaCreacionOrigen], [OrdenCrmId], [Estado], [Nombre], [FechaInstalacion], [ServicioId], [AtributosExtendidos], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[TipoServicio], s.[TipoSolicitud], s.[FechaSolicitud], s.[FechaDesinstalacion], s.[FechaCreacionOrigen], s.[OrdenCrmId], s.[Estado], s.[Nombre], s.[FechaInstalacion], s.[ServicioId], s.[AtributosExtendidos], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[OrdenServicioVoIPId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.OrdenServicioVoIP', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.OrdenServicioVoIP', t.[OrdenServicioVoIPId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.OrdenServicioVoIP t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.OrdenServicioVoIP', t.[OrdenServicioVoIPId], N'ServicioId', LEFT(CONVERT(nvarchar(400), s.o_ServicioId), 400), N'Referencia sin correspondencia única en core.Servicio'
    FROM #src s JOIN core.OrdenServicioVoIP t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_ServicioId IS NOT NULL AND s.[ServicioId] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.OrdenServicioVoIP', t.[OrdenServicioVoIPId], N'FechaSolicitud', LEFT(CONVERT(nvarchar(400), s.o_FechaSolicitud), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.OrdenServicioVoIP t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaSolicitud IS NOT NULL AND s.[FechaSolicitud] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.OrdenServicioVoIP', t.[OrdenServicioVoIPId], N'FechaDesinstalacion', LEFT(CONVERT(nvarchar(400), s.o_FechaDesinstalacion), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.OrdenServicioVoIP t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaDesinstalacion IS NOT NULL AND s.[FechaDesinstalacion] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.OrdenServicioVoIP', t.[OrdenServicioVoIPId], N'FechaCreacionOrigen', LEFT(CONVERT(nvarchar(400), s.o_FechaCreacionOrigen), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.OrdenServicioVoIP t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaCreacionOrigen IS NOT NULL AND s.[FechaCreacionOrigen] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.OrdenServicioVoIP', t.[OrdenServicioVoIPId], N'FechaInstalacion', LEFT(CONVERT(nvarchar(400), s.o_FechaInstalacion), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.OrdenServicioVoIP t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaInstalacion IS NOT NULL AND s.[FechaInstalacion] IS NULL;

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
