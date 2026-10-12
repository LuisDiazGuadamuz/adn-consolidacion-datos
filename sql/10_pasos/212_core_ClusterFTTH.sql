USE ADN_Unificado;
GO
/* Paso 212 · core_ClusterFTTH → core.ClusterFTTH
   Clústeres FTTH. El nodo viene como nombre: se vincula solo si el nombre corresponde a un único nodo.
   Reglas: ES-01, ES-05, DD-02, DD-06, IN-01, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_ClusterFTTH @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT CAST(q.[ClusterCrmId] AS nvarchar(30)) AS [ClusterCrmId],
           CAST(q.[Nombre] AS nvarchar(200)) AS [Nombre],
           CAST(q.[CodigoCluster] AS nvarchar(50)) AS [CodigoCluster],
           q.[NodoId],
           CAST(q.[Fase] AS nvarchar(50)) AS [Fase],
           q.[CapacidadRed],
           q.[CantidadClientes],
           CAST(q.[Provincia] AS nvarchar(60)) AS [Provincia],
           CAST(q.[Canton] AS nvarchar(80)) AS [Canton],
           CAST(q.[Distrito] AS nvarchar(80)) AS [Distrito],
           q.[FechaInstalacion],
           q.[AtributosExtendidos],
           q.[FechaCreacionOrigen],
           q.[FechaModificacionOrigen],
           CAST(q.[FuenteSistema] AS varchar(20)) AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[ClusterCrmId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Nombre]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[CodigoCluster]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[NodoId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Fase]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[CapacidadRed]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[CantidadClientes]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Provincia]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Canton]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Distrito]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaInstalacion], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[AtributosExtendidos]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaCreacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaModificacionOrigen], 126), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_Eliminado],
           q.[o_Nodo],
           CONCAT_WS(N',', CASE WHEN LEN(q.[ClusterCrmId]) > 30 THEN N'ClusterCrmId' END, CASE WHEN LEN(q.[Nombre]) > 200 THEN N'Nombre' END, CASE WHEN LEN(q.[CodigoCluster]) > 50 THEN N'CodigoCluster' END, CASE WHEN LEN(q.[Fase]) > 50 THEN N'Fase' END, CASE WHEN LEN(q.[Provincia]) > 60 THEN N'Provincia' END, CASE WHEN LEN(q.[Canton]) > 80 THEN N'Canton' END, CASE WHEN LEN(q.[Distrito]) > 80 THEN N'Distrito' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT 'ZohoCRM' AS FuenteSistema, N'Zoho_Mirror' AS FuenteBase, N'FTTHs' AS FuenteTabla, ctl.fn_Texto(f.id) AS FuenteLlave,
               ctl.fn_FechaCR(f.Created_Time) AS FechaDato,
               ctl.fn_Texto(f.id) AS ClusterCrmId, ctl.fn_Texto(f.Name) AS Nombre, ctl.fn_Texto(f.Codigo_Cluster) AS CodigoCluster,
               nd.NodoId, ctl.fn_Texto(f.Fase) AS Fase, TRY_CONVERT(int, ctl.fn_PrimerNumero(f.Capacidad_de_la_Red)) AS CapacidadRed,
               TRY_CONVERT(int, ctl.fn_PrimerNumero(f.Cantidad_de_Clientes)) AS CantidadClientes,
               ctl.fn_Texto(f.Provincia) AS Provincia, ctl.fn_Texto(f.Cant_n) AS Canton, ctl.fn_Texto(f.Distrito) AS Distrito,
               ctl.fn_FechaDia(f.Fecha_de_Instalaci_n) AS FechaInstalacion,
               NULLIF((SELECT ctl.fn_Texto(CONVERT(nvarchar(max), f.[Penetraci_n])) AS [Penetraci_n], ctl.fn_Texto(CONVERT(nvarchar(max), f.[Tag])) AS [Tag], ctl.fn_Texto(CONVERT(nvarchar(max), f.[Created_By])) AS [Created_By], ctl.fn_Texto(CONVERT(nvarchar(max), f.[Locked__s])) AS [Locked__s], ctl.fn_Texto(CONVERT(nvarchar(max), f.[Construy])) AS [Construy], ctl.fn_Texto(CONVERT(nvarchar(max), f.[Unsubscribed_Mode])) AS [Unsubscribed_Mode], ctl.fn_Texto(CONVERT(nvarchar(max), f.[Modified_By])) AS [Modified_By], ctl.fn_Texto(CONVERT(nvarchar(max), f.[Last_Activity_Time])) AS [Last_Activity_Time], ctl.fn_Texto(CONVERT(nvarchar(max), f.[Empalm])) AS [Empalm], ctl.fn_Texto(CONVERT(nvarchar(max), f.[Coordenadas_del_Cluster])) AS [Coordenadas_del_Cluster], ctl.fn_Texto(CONVERT(nvarchar(max), f.[Owner])) AS [Owner], ctl.fn_Texto(CONVERT(nvarchar(max), f.[Proyecto_Principal])) AS [Proyecto_Principal], ctl.fn_Texto(CONVERT(nvarchar(max), f.[Zona_de_Cobertura])) AS [Zona_de_Cobertura] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER), N'{}') AS AtributosExtendidos,
               ctl.fn_FechaCR(f.Created_Time) AS FechaCreacionOrigen, ctl.fn_FechaCR(f.Modified_Time) AS FechaModificacionOrigen,
               CAST(ISNULL(f.deleted, 0) AS int) AS o_Eliminado, ctl.fn_Texto(f.Nodo) AS o_Nodo
        FROM Zoho_Mirror.dbo.FTTHs f
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(n.NodoId) END AS NodoId FROM core.Nodo n WHERE n.Nombre = ctl.fn_Texto(f.Nodo)) nd
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 2. Filtros de carga: filas excluidas con la regla que las excluye (DD-06) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'DD-06', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'Registro marcado como eliminado en Zoho (deleted = 1)', @Ahora FROM #src s WHERE s.o_Eliminado = 1
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'DD-06' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE s FROM #src s WHERE s.o_Eliminado = 1;
    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'ClusterCrmId obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[ClusterCrmId] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FuenteLlave obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FuenteLlave] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE FROM #src WHERE [ClusterCrmId] IS NULL OR [FuenteLlave] IS NULL;

    /* 2b. Duplicados por la llave del paso (DD-02); el orden es determinista */
    ;WITH r AS (
        SELECT s.FuenteSistema, s.FuenteTabla, s.FuenteLlave,
               ROW_NUMBER() OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.FechaModificacionOrigen DESC, s.HashContenido) AS rn,
               FIRST_VALUE(s.FuenteLlave) OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.FechaModificacionOrigen DESC, s.HashContenido ROWS UNBOUNDED PRECEDING) AS Conservada
        FROM #src s)
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, LlaveConservada, Motivo, FechaDescarte)
    SELECT @LoteId, 'DD-02', r.FuenteSistema, r.FuenteTabla, r.FuenteLlave, r.Conservada, N'Versión anterior del mismo clúster en el espejo de Zoho', @Ahora
    FROM r WHERE r.rn > 1
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'DD-02' AND x.FuenteTabla = r.FuenteTabla AND x.FuenteLlave = r.FuenteLlave);
    ;WITH r AS (
        SELECT ROW_NUMBER() OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.FechaModificacionOrigen DESC, s.HashContenido) AS rn FROM #src s)
    DELETE FROM r WHERE rn > 1;
    DECLARE @Validas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 3. Imagen previa de las filas que van a cambiar (para el rollback) */
    DROP TABLE IF EXISTS #antes;
    SELECT t.[ClusterFTTHId] AS RegistroId, t.FuenteLlave, (SELECT t.[ClusterCrmId], t.[Nombre], t.[CodigoCluster], t.[NodoId], t.[Fase], t.[CapacidadRed], t.[CantidadClientes], t.[Provincia], t.[Canton], t.[Distrito], t.[FechaInstalacion], t.[AtributosExtendidos], t.[FechaCreacionOrigen], t.[FechaModificacionOrigen], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.ClusterFTTH t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido;

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.ClusterFTTH WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido) THEN
        UPDATE SET t.[ClusterCrmId] = s.[ClusterCrmId], t.[Nombre] = s.[Nombre], t.[CodigoCluster] = s.[CodigoCluster], t.[NodoId] = s.[NodoId], t.[Fase] = s.[Fase], t.[CapacidadRed] = s.[CapacidadRed], t.[CantidadClientes] = s.[CantidadClientes], t.[Provincia] = s.[Provincia], t.[Canton] = s.[Canton], t.[Distrito] = s.[Distrito], t.[FechaInstalacion] = s.[FechaInstalacion], t.[AtributosExtendidos] = s.[AtributosExtendidos], t.[FechaCreacionOrigen] = s.[FechaCreacionOrigen], t.[FechaModificacionOrigen] = s.[FechaModificacionOrigen], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([ClusterCrmId], [Nombre], [CodigoCluster], [NodoId], [Fase], [CapacidadRed], [CantidadClientes], [Provincia], [Canton], [Distrito], [FechaInstalacion], [AtributosExtendidos], [FechaCreacionOrigen], [FechaModificacionOrigen], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[ClusterCrmId], s.[Nombre], s.[CodigoCluster], s.[NodoId], s.[Fase], s.[CapacidadRed], s.[CantidadClientes], s.[Provincia], s.[Canton], s.[Distrito], s.[FechaInstalacion], s.[AtributosExtendidos], s.[FechaCreacionOrigen], s.[FechaModificacionOrigen], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[ClusterFTTHId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.ClusterFTTH', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías de las filas afectadas */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.ClusterFTTH', c.RegistroId, LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #cambios c JOIN core.ClusterFTTH t ON t.[ClusterFTTHId] = c.RegistroId JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.ClusterFTTH', c.RegistroId, N'NodoId', LEFT(CONVERT(nvarchar(400), s.o_Nodo), 400), N'Nodo sin correspondencia única por nombre'
    FROM #cambios c JOIN core.ClusterFTTH t ON t.[ClusterFTTHId] = c.RegistroId JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Nodo IS NOT NULL AND s.NodoId IS NULL;

    SELECT @Leidas AS FilasLeidas, @Validas - (SELECT COUNT_BIG(*) FROM #cambios) AS FilasSinCambio;
END;
GO
