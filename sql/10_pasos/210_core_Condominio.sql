USE ADN_Unificado;
GO
/* Paso 210 · core_Condominio → core.Condominio
   Condominios. Coordenadas validadas dentro de Costa Rica; capacidad máxima en Mbps (1GB = 1000).
   Reglas: ES-01, ES-02, ES-05, ES-07, DD-02, DD-06, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_Condominio @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT CAST(q.[CondominioCrmId] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [CondominioCrmId],
           CAST(q.[Nombre] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [Nombre],
           CAST(q.[Tipo] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Tipo],
           CAST(q.[TipoConstruccion] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [TipoConstruccion],
           q.[CantidadCasas],
           q.[CapacidadMaxima],
           q.[AplicaFTTH],
           CAST(q.[Provincia] AS nvarchar(60)) COLLATE DATABASE_DEFAULT AS [Provincia],
           CAST(q.[Canton] AS nvarchar(80)) COLLATE DATABASE_DEFAULT AS [Canton],
           CAST(q.[Distrito] AS nvarchar(80)) COLLATE DATABASE_DEFAULT AS [Distrito],
           CAST(q.[Direccion] AS nvarchar(1000)) COLLATE DATABASE_DEFAULT AS [Direccion],
           q.[Latitud],
           q.[Longitud],
           q.[FechaInstalacion],
           q.[AtributosExtendidos] COLLATE DATABASE_DEFAULT AS [AtributosExtendidos],
           q.[FechaCreacionOrigen],
           q.[FechaModificacionOrigen],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[CondominioCrmId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Nombre]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Tipo]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TipoConstruccion]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[CantidadCasas]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[CapacidadMaxima]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[AplicaFTTH]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Provincia]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Canton]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Distrito]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Direccion]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Latitud]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Longitud]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaInstalacion], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[AtributosExtendidos]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaCreacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaModificacionOrigen], 126), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_Eliminado],
           q.[o_Coordenadas],
           CONCAT_WS(N',', CASE WHEN LEN(q.[CondominioCrmId]) > 30 THEN N'CondominioCrmId' END, CASE WHEN LEN(q.[Nombre]) > 200 THEN N'Nombre' END, CASE WHEN LEN(q.[Tipo]) > 50 THEN N'Tipo' END, CASE WHEN LEN(q.[TipoConstruccion]) > 50 THEN N'TipoConstruccion' END, CASE WHEN LEN(q.[Provincia]) > 60 THEN N'Provincia' END, CASE WHEN LEN(q.[Canton]) > 80 THEN N'Canton' END, CASE WHEN LEN(q.[Distrito]) > 80 THEN N'Distrito' END, CASE WHEN LEN(q.[Direccion]) > 1000 THEN N'Direccion' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT 'ZohoCRM' AS FuenteSistema, N'Zoho_Mirror' AS FuenteBase, N'Condominios' AS FuenteTabla, ctl.fn_Texto(c.id) AS FuenteLlave,
               ctl.fn_FechaCR(c.Created_Time) AS FechaDato,
               ctl.fn_Texto(c.id) AS CondominioCrmId, COALESCE(ctl.fn_Texto(c.Name), ctl.fn_Texto(c.Nombre)) AS Nombre,
               ctl.fn_Texto(c.Tipo_de_Condominio) AS Tipo, ctl.fn_Texto(c.Tipo_de_Construcci_n) AS TipoConstruccion,
               TRY_CONVERT(int, ctl.fn_PrimerNumero(c.Canitdad_de_Casas)) AS CantidadCasas,
               TRY_CONVERT(int, ctl.fn_PrimerNumero(c.Capacidad_Maxima) * CASE WHEN UPPER(c.Capacidad_Maxima) LIKE N'%G%' THEN 1000 ELSE 1 END) AS CapacidadMaxima,
               ctl.fn_Bit(c.Aplica_FTTH) AS AplicaFTTH,
               ctl.fn_Texto(c.Provincia) AS Provincia, ctl.fn_Texto(c.Cant_n) AS Canton, ctl.fn_Texto(c.Distritos) AS Distrito,
               ctl.fn_Texto(CONVERT(nvarchar(max), c.Direcci_n)) AS Direccion,
               ctl.fn_Coordenada(c.Coordenadas, 1) AS Latitud, ctl.fn_Coordenada(c.Coordenadas, 2) AS Longitud,
               ctl.fn_FechaDia(c.Fecha_de_Instalaci_n) AS FechaInstalacion,
               NULLIF((SELECT ctl.fn_Texto(CONVERT(nvarchar(max), c.[Tag])) AS [Tag], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Created_By])) AS [Created_By], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Tel_fono])) AS [Tel_fono], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Unsubscribed_Mode])) AS [Unsubscribed_Mode], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Modified_By])) AS [Modified_By], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Record_Image])) AS [Record_Image], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Last_Activity_Time])) AS [Last_Activity_Time], ctl.fn_Texto(CONVERT(nvarchar(max), c.[N_A_Cortes_a])) AS [N_A_Cortes_a], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Cortes_a])) AS [Cortes_a], ctl.fn_Texto(CONVERT(nvarchar(max), c.[CPO])) AS [CPO], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Email])) AS [Email], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Owner])) AS [Owner], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Fases])) AS [Fases], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Estado_de_Construncion])) AS [Estado_de_Construncion] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER), N'{}') AS AtributosExtendidos,
               ctl.fn_FechaCR(c.Created_Time) AS FechaCreacionOrigen, ctl.fn_FechaCR(c.Modified_Time) AS FechaModificacionOrigen,
               CAST(ISNULL(c.deleted, 0) AS int) AS o_Eliminado, ctl.fn_CoordenadaTexto(c.Coordenadas) AS o_Coordenadas
        FROM Zoho_Mirror.dbo.Condominios c
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
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'CondominioCrmId obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[CondominioCrmId] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FuenteLlave obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FuenteLlave] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE FROM #src WHERE [CondominioCrmId] IS NULL OR [FuenteLlave] IS NULL;

    /* 2b. Duplicados por la llave del paso (DD-02); el orden es determinista */
    ;WITH r AS (
        SELECT s.FuenteSistema, s.FuenteTabla, s.FuenteLlave,
               ROW_NUMBER() OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.FechaModificacionOrigen DESC, s.HashContenido) AS rn,
               FIRST_VALUE(s.FuenteLlave) OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.FechaModificacionOrigen DESC, s.HashContenido ROWS UNBOUNDED PRECEDING) AS Conservada
        FROM #src s)
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, LlaveConservada, Motivo, FechaDescarte)
    SELECT @LoteId, 'DD-02', r.FuenteSistema, r.FuenteTabla, r.FuenteLlave, r.Conservada, N'Versión anterior del mismo condominio en el espejo de Zoho', @Ahora
    FROM r WHERE r.rn > 1
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'DD-02' AND x.FuenteTabla = r.FuenteTabla AND x.FuenteLlave = r.FuenteLlave);
    ;WITH r AS (
        SELECT ROW_NUMBER() OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.FechaModificacionOrigen DESC, s.HashContenido) AS rn FROM #src s)
    DELETE FROM r WHERE rn > 1;
    DECLARE @Validas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 3. Imagen previa de las filas que van a cambiar (para el rollback) */
    DROP TABLE IF EXISTS #antes;
    SELECT t.[CondominioId] AS RegistroId, t.FuenteLlave, (SELECT t.[CondominioCrmId], t.[Nombre], t.[Tipo], t.[TipoConstruccion], t.[CantidadCasas], t.[CapacidadMaxima], t.[AplicaFTTH], t.[Provincia], t.[Canton], t.[Distrito], t.[Direccion], t.[Latitud], t.[Longitud], t.[FechaInstalacion], t.[AtributosExtendidos], t.[FechaCreacionOrigen], t.[FechaModificacionOrigen], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.Condominio t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato);

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.Condominio WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato)) THEN
        UPDATE SET t.[CondominioCrmId] = s.[CondominioCrmId], t.[Nombre] = s.[Nombre], t.[Tipo] = s.[Tipo], t.[TipoConstruccion] = s.[TipoConstruccion], t.[CantidadCasas] = s.[CantidadCasas], t.[CapacidadMaxima] = s.[CapacidadMaxima], t.[AplicaFTTH] = s.[AplicaFTTH], t.[Provincia] = s.[Provincia], t.[Canton] = s.[Canton], t.[Distrito] = s.[Distrito], t.[Direccion] = s.[Direccion], t.[Latitud] = s.[Latitud], t.[Longitud] = s.[Longitud], t.[FechaInstalacion] = s.[FechaInstalacion], t.[AtributosExtendidos] = s.[AtributosExtendidos], t.[FechaCreacionOrigen] = s.[FechaCreacionOrigen], t.[FechaModificacionOrigen] = s.[FechaModificacionOrigen], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([CondominioCrmId], [Nombre], [Tipo], [TipoConstruccion], [CantidadCasas], [CapacidadMaxima], [AplicaFTTH], [Provincia], [Canton], [Distrito], [Direccion], [Latitud], [Longitud], [FechaInstalacion], [AtributosExtendidos], [FechaCreacionOrigen], [FechaModificacionOrigen], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[CondominioCrmId], s.[Nombre], s.[Tipo], s.[TipoConstruccion], s.[CantidadCasas], s.[CapacidadMaxima], s.[AplicaFTTH], s.[Provincia], s.[Canton], s.[Distrito], s.[Direccion], s.[Latitud], s.[Longitud], s.[FechaInstalacion], s.[AtributosExtendidos], s.[FechaCreacionOrigen], s.[FechaModificacionOrigen], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[CondominioId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.Condominio', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.Condominio', t.[CondominioId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.Condominio t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.Condominio', t.[CondominioId], N'Latitud', LEFT(CONVERT(nvarchar(400), s.o_Coordenadas), 400), N'Coordenadas ilegibles o fuera de Costa Rica'
    FROM #src s JOIN core.Condominio t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Coordenadas IS NOT NULL AND s.Latitud IS NULL;

    SELECT @Leidas AS FilasLeidas, @Validas - (SELECT COUNT_BIG(*) FROM #cambios) AS FilasSinCambio;
END;
GO
