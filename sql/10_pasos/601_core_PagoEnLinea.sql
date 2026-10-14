USE ADN_Unificado;
GO
/* Paso 601 · core_PagoEnLinea → core.PagoEnLinea
   Sesiones de pago de la pasarela Onvo.
   Reglas: D5, ES-01, ES-04, ES-07, IN-01, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_PagoEnLinea @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT CAST(q.[SesionId] AS nvarchar(100)) COLLATE DATABASE_DEFAULT AS [SesionId],
           CAST(q.[IntentoPagoId] AS nvarchar(100)) COLLATE DATABASE_DEFAULT AS [IntentoPagoId],
           q.[Monto],
           CAST(q.[Modo] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [Modo],
           CAST(q.[EstadoPago] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [EstadoPago],
           CAST(q.[Moneda] AS char(3)) COLLATE DATABASE_DEFAULT AS [Moneda],
           CAST(q.[PrecioId] AS nvarchar(100)) COLLATE DATABASE_DEFAULT AS [PrecioId],
           q.[FechaCreacion],
           q.[FechaExpiracion],
           q.[Expirada],
           q.[SolicitudEnLineaId],
           q.[MontoCRC],
           q.[TipoCambio],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[SesionId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[IntentoPagoId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Monto]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Modo]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[EstadoPago]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Moneda]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[PrecioId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaCreacion], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaExpiracion], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Expirada]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[SolicitudEnLineaId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[MontoCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TipoCambio]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_SolicitudEnLineaId],
           CONCAT_WS(N',', CASE WHEN LEN(q.[SesionId]) > 100 THEN N'SesionId' END, CASE WHEN LEN(q.[IntentoPagoId]) > 100 THEN N'IntentoPagoId' END, CASE WHEN LEN(q.[Modo]) > 30 THEN N'Modo' END, CASE WHEN LEN(q.[EstadoPago]) > 30 THEN N'EstadoPago' END, CASE WHEN LEN(q.[Moneda]) > 3 THEN N'Moneda' END, CASE WHEN LEN(q.[PrecioId]) > 100 THEN N'PrecioId' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT q.*,
               tx.Tasa AS TipoCambio,
               CASE q.Moneda WHEN 'CRC' THEN q.[Monto] WHEN 'USD' THEN CAST(q.[Monto] * tx.Tasa AS decimal(19,4)) END AS [MontoCRC]
        FROM (
        SELECT 'ADNPayV2' AS FuenteSistema,
               N'ADNPayV2' AS FuenteBase,
               N'OnvoCheckoutSession' AS FuenteTabla,
               ctl.fn_Texto(CONVERT(nvarchar(200), s.[session_index])) AS FuenteLlave,
               ctl.fn_FechaCR(CONVERT(nvarchar(30), s.[created_at], 126)) AS FechaDato,
               ctl.fn_Texto(CONVERT(nvarchar(max), s.[session_id])) AS [SesionId],
               ctl.fn_Texto(CONVERT(nvarchar(max), s.[payment_intent_id])) AS [IntentoPagoId],
               TRY_CONVERT(decimal(19,4), s.[amount_total]) AS [Monto],
               ctl.fn_Texto(CONVERT(nvarchar(max), s.[payment_mode])) AS [Modo],
               ctl.fn_Texto(CONVERT(nvarchar(max), s.[payment_status])) AS [EstadoPago],
               ctl.fn_Moneda(CONVERT(nvarchar(20), s.[currency])) AS [Moneda],
               ctl.fn_Texto(CONVERT(nvarchar(max), s.[price_id])) AS [PrecioId],
               ctl.fn_FechaCR(CONVERT(nvarchar(30), s.[created_at], 126)) AS [FechaCreacion],
               ctl.fn_FechaCR(CONVERT(nvarchar(30), s.[expires_at], 126)) AS [FechaExpiracion],
               s.[expired] AS [Expirada],
               fk_SolicitudEnLineaId_0.Id AS [SolicitudEnLineaId],
               ctl.fn_Texto(CONVERT(nvarchar(400), s.[customer_index])) AS [o_SolicitudEnLineaId]
        FROM ADNPayV2.dbo.[OnvoCheckoutSession] s
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[SolicitudEnLineaId]) END AS Id FROM core.SolicitudEnLinea zref WHERE zref.FuenteBase = N'ADNPayV2' AND zref.FuenteLlave = ctl.fn_Texto(CONVERT(nvarchar(max), s.[customer_index]))) fk_SolicitudEnLineaId_0
        ) q
        OUTER APPLY (SELECT TOP 1 t.Venta FROM ref.TipoCambio t WHERE t.Fecha <= CAST(CAST(q.FechaCreacion AS date) AS date) ORDER BY t.Fecha DESC) tc
        CROSS APPLY (SELECT CASE q.Moneda WHEN 'CRC' THEN CAST(1 AS decimal(19,6)) WHEN 'USD' THEN COALESCE(tc.Venta, NULL) END AS Tasa) tx
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
    SELECT t.[PagoEnLineaId] AS RegistroId, t.FuenteLlave, (SELECT t.[SolicitudEnLineaId], t.[SesionId], t.[IntentoPagoId], t.[Modo], t.[EstadoPago], t.[Expirada], t.[Moneda], t.[TipoCambio], t.[Monto], t.[MontoCRC], t.[PrecioId], t.[FechaCreacion], t.[FechaExpiracion], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.PagoEnLinea t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato);

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.PagoEnLinea WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato)) THEN
        UPDATE SET t.[SesionId] = s.[SesionId], t.[IntentoPagoId] = s.[IntentoPagoId], t.[Monto] = s.[Monto], t.[Modo] = s.[Modo], t.[EstadoPago] = s.[EstadoPago], t.[Moneda] = s.[Moneda], t.[PrecioId] = s.[PrecioId], t.[FechaCreacion] = s.[FechaCreacion], t.[FechaExpiracion] = s.[FechaExpiracion], t.[Expirada] = s.[Expirada], t.[SolicitudEnLineaId] = s.[SolicitudEnLineaId], t.[MontoCRC] = s.[MontoCRC], t.[TipoCambio] = s.[TipoCambio], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([SesionId], [IntentoPagoId], [Monto], [Modo], [EstadoPago], [Moneda], [PrecioId], [FechaCreacion], [FechaExpiracion], [Expirada], [SolicitudEnLineaId], [MontoCRC], [TipoCambio], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[SesionId], s.[IntentoPagoId], s.[Monto], s.[Modo], s.[EstadoPago], s.[Moneda], s.[PrecioId], s.[FechaCreacion], s.[FechaExpiracion], s.[Expirada], s.[SolicitudEnLineaId], s.[MontoCRC], s.[TipoCambio], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[PagoEnLineaId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.PagoEnLinea', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.PagoEnLinea', t.[PagoEnLineaId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.PagoEnLinea t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.PagoEnLinea', t.[PagoEnLineaId], N'SolicitudEnLineaId', LEFT(CONVERT(nvarchar(400), s.o_SolicitudEnLineaId), 400), N'Referencia sin correspondencia única en core.SolicitudEnLinea'
    FROM #src s JOIN core.PagoEnLinea t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_SolicitudEnLineaId IS NOT NULL AND s.[SolicitudEnLineaId] IS NULL;

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
