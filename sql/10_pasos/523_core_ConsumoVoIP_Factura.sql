USE ADN_Unificado;
GO
/* Paso 523 · core_ConsumoVoIP_Factura → core.ConsumoVoIP
   Consumo VoIP facturado (invoicevoip). Servicio por circuito (ID-01) y cliente por cédula (ID-02).
   Reglas: D5, ES-01, ES-04, ES-07, ID-01, ID-02, IN-01, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_ConsumoVoIP_Factura @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT CAST(q.[TipoServicioVoIP] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [TipoServicioVoIP],
           q.[FechaInicio],
           q.[FechaFin],
           q.[Llamadas],
           q.[Minutos],
           q.[Costo],
           CAST(q.[RutaArchivo] AS nvarchar(1000)) COLLATE DATABASE_DEFAULT AS [RutaArchivo],
           q.[Procesado],
           q.[ClienteId],
           q.[ServicioId],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[TipoServicioVoIP]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaInicio], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaFin], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Llamadas]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Minutos]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Costo]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[RutaArchivo]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Procesado]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ClienteId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ServicioId]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_ClienteId],
           q.[o_ServicioId],
           CONCAT_WS(N',', CASE WHEN LEN(q.[TipoServicioVoIP]) > 50 THEN N'TipoServicioVoIP' END, CASE WHEN LEN(q.[RutaArchivo]) > 1000 THEN N'RutaArchivo' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT 'AppDataCR' AS FuenteSistema,
               N'ADNApp' AS FuenteBase,
               N'ZohoEngine_invoicevoip' AS FuenteTabla,
               ctl.fn_Texto(CONVERT(nvarchar(200), i.[id])) AS FuenteLlave,
               CAST(i.[invoice_start_date] AS date) AS FechaDato,
               ctl.fn_Texto(CONVERT(nvarchar(max), i.[voip_service])) AS [TipoServicioVoIP],
               CAST(i.[invoice_start_date] AS date) AS [FechaInicio],
               CAST(i.[invoice_end_date] AS date) AS [FechaFin],
               TRY_CONVERT(int, ctl.fn_PrimerNumero(CONVERT(nvarchar(255), i.[voip_calls]))) AS [Llamadas],
               TRY_CONVERT(decimal(12,2), ctl.fn_PrimerNumero(CONVERT(nvarchar(255), i.[voip_minutes]))) AS [Minutos],
               TRY_CONVERT(decimal(19,4), i.[voip_cost]) AS [Costo],
               ctl.fn_Texto(CONVERT(nvarchar(max), CONVERT(nvarchar(max), i.[filepath]))) AS [RutaArchivo],
               ctl.fn_Bit(CONVERT(nvarchar(20), i.[is_processed])) AS [Procesado],
               fk_ClienteId_0.Id AS [ClienteId],
               ctl.fn_Texto(CONVERT(nvarchar(400), i.[legal_id])) AS [o_ClienteId],
               fk_ServicioId_0.Id AS [ServicioId],
               ctl.fn_Texto(CONVERT(nvarchar(400), i.[circuit_number])) AS [o_ServicioId]
        FROM ADNApp.dbo.[ZohoEngine_invoicevoip] i
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[ClienteId]) END AS Id FROM core.Cliente zref WHERE zref.FuenteTabla = N'Cedula' AND zref.FuenteLlave = ctl.fn_Cedula(CONVERT(nvarchar(100), i.[legal_id])) AND EXISTS (SELECT 1 FROM core.ClienteOrigen vo WHERE vo.ClienteId = zref.ClienteId AND vo.Sistema IN ('ZohoCRM', 'ZohoBooks', 'ADNPayV2'))) fk_ClienteId_0
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[ServicioId]) END AS Id FROM core.Servicio zref WHERE zref.Circuito = ctl.fn_Circuito(CONVERT(nvarchar(100), i.[circuit_number]))) fk_ServicioId_0
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);
    /* Conciliación: llaves leídas, para comprobar al final que toda fila excluida tiene su motivo en ctl.Descarte */
    DROP TABLE IF EXISTS #leidas;
    SELECT DISTINCT FuenteTabla, FuenteLlave INTO #leidas FROM #src;

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
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato);

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.ConsumoVoIP WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato)) THEN
        UPDATE SET t.[TipoServicioVoIP] = s.[TipoServicioVoIP], t.[FechaInicio] = s.[FechaInicio], t.[FechaFin] = s.[FechaFin], t.[Llamadas] = s.[Llamadas], t.[Minutos] = s.[Minutos], t.[Costo] = s.[Costo], t.[RutaArchivo] = s.[RutaArchivo], t.[Procesado] = s.[Procesado], t.[ClienteId] = s.[ClienteId], t.[ServicioId] = s.[ServicioId], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([TipoServicioVoIP], [FechaInicio], [FechaFin], [Llamadas], [Minutos], [Costo], [RutaArchivo], [Procesado], [ClienteId], [ServicioId], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[TipoServicioVoIP], s.[FechaInicio], s.[FechaFin], s.[Llamadas], s.[Minutos], s.[Costo], s.[RutaArchivo], s.[Procesado], s.[ClienteId], s.[ServicioId], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
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
    SELECT @LoteId, 'IN-01', N'core.ConsumoVoIP', t.[ConsumoVoIPId], N'ClienteId', LEFT(CONVERT(nvarchar(400), s.o_ClienteId), 400), N'Referencia sin correspondencia única en core.Cliente'
    FROM #src s JOIN core.ConsumoVoIP t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_ClienteId IS NOT NULL AND s.[ClienteId] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.ConsumoVoIP', t.[ConsumoVoIPId], N'ServicioId', LEFT(CONVERT(nvarchar(400), s.o_ServicioId), 400), N'Referencia sin correspondencia única en core.Servicio'
    FROM #src s JOIN core.ConsumoVoIP t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
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
