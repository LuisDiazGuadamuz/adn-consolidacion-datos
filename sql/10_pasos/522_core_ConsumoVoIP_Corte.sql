USE ADN_Unificado;
GO
/* Paso 522 · core_ConsumoVoIP_Corte → core.ConsumoVoIP
   Consumo VoIP por tipo de servicio dentro de cada corte; hereda servicio, cliente y período del corte.
   Reglas: D5, ES-04, IN-01, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_ConsumoVoIP_Corte @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT CAST(q.[TipoServicioVoIP] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [TipoServicioVoIP],
           q.[Llamadas],
           q.[Minutos],
           q.[Costo],
           q.[CorteVoIPId],
           q.[ServicioId],
           q.[ClienteId],
           q.[FechaInicio],
           q.[FechaFin],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[TipoServicioVoIP]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Llamadas]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Minutos]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Costo]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[CorteVoIPId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ServicioId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ClienteId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaInicio], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaFin], 126), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_CorteVoIPId],
           CONCAT_WS(N',', CASE WHEN LEN(q.[TipoServicioVoIP]) > 50 THEN N'TipoServicioVoIP' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT 'AppDataCR' AS FuenteSistema,
               N'ADNApp' AS FuenteBase,
               N'ZohoEngine_zohocustomervoipbillservice' AS FuenteTabla,
               ctl.fn_Texto(CONVERT(nvarchar(200), s.[id])) AS FuenteLlave,
               TODATETIMEOFFSET(CAST(cv.FechaInicio AS datetime2), '-06:00') AS FechaDato,
               ctl.fn_Texto(CONVERT(nvarchar(max), s.[voip_service])) AS [TipoServicioVoIP],
               TRY_CONVERT(int, s.[voip_calls]) AS [Llamadas],
               TRY_CONVERT(decimal(12,2), s.[voip_minutes]) AS [Minutos],
               TRY_CONVERT(decimal(19,4), s.[voip_cost]) AS [Costo],
               fk_CorteVoIPId_0.Id AS [CorteVoIPId],
               ctl.fn_Texto(CONVERT(nvarchar(400), s.[zoho_customer_voip_bill_id])) AS [o_CorteVoIPId],
               cv.ServicioId AS [ServicioId],
               cv.ClienteId AS [ClienteId],
               cv.FechaInicio AS [FechaInicio],
               cv.FechaFin AS [FechaFin]
        FROM ADNApp.dbo.[ZohoEngine_zohocustomervoipbillservice] s
        LEFT JOIN core.CorteVoIP cv ON cv.FuenteBase = N'ADNApp' AND cv.FuenteLlave = CAST(s.zoho_customer_voip_bill_id AS nvarchar(200))
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[CorteVoIPId]) END AS Id FROM core.CorteVoIP zref WHERE zref.FuenteBase = N'ADNApp' AND zref.FuenteLlave = ctl.fn_Texto(CONVERT(nvarchar(max), s.[zoho_customer_voip_bill_id]))) fk_CorteVoIPId_0
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
    SELECT t.[ConsumoVoIPId] AS RegistroId, t.FuenteLlave, (SELECT t.[CorteVoIPId], t.[ServicioId], t.[ClienteId], t.[TipoServicioVoIP], t.[FechaInicio], t.[FechaFin], t.[Llamadas], t.[Minutos], t.[Moneda], t.[TipoCambio], t.[Costo], t.[CostoCRC], t.[RutaArchivo], t.[Procesado], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.ConsumoVoIP t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido;

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.ConsumoVoIP WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido) THEN
        UPDATE SET t.[TipoServicioVoIP] = s.[TipoServicioVoIP], t.[Llamadas] = s.[Llamadas], t.[Minutos] = s.[Minutos], t.[Costo] = s.[Costo], t.[CorteVoIPId] = s.[CorteVoIPId], t.[ServicioId] = s.[ServicioId], t.[ClienteId] = s.[ClienteId], t.[FechaInicio] = s.[FechaInicio], t.[FechaFin] = s.[FechaFin], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([TipoServicioVoIP], [Llamadas], [Minutos], [Costo], [CorteVoIPId], [ServicioId], [ClienteId], [FechaInicio], [FechaFin], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[TipoServicioVoIP], s.[Llamadas], s.[Minutos], s.[Costo], s.[CorteVoIPId], s.[ServicioId], s.[ClienteId], s.[FechaInicio], s.[FechaFin], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[ConsumoVoIPId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.ConsumoVoIP', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.ConsumoVoIP', t.[ConsumoVoIPId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.ConsumoVoIP t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.ConsumoVoIP', t.[ConsumoVoIPId], N'CorteVoIPId', LEFT(CONVERT(nvarchar(400), s.o_CorteVoIPId), 400), N'Referencia sin correspondencia única en core.CorteVoIP'
    FROM #src s JOIN core.ConsumoVoIP t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_CorteVoIPId IS NOT NULL AND s.[CorteVoIPId] IS NULL;

    SELECT @Leidas AS FilasLeidas, @Validas - (SELECT COUNT_BIG(*) FROM #cambios) AS FilasSinCambio;
END;
GO
