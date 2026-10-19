USE ADN_Unificado;
GO
/* Paso 600 · core_SolicitudEnLinea → core.SolicitudEnLinea
   Solicitudes de contratación en línea (ADNPayV2.Customer). Cliente por la tabla de correspondencia o por cédula (ID-02); plan por el catálogo de servicios de ADNPayV2. Montos en colones.
   Reglas: D5, ES-01, ES-04, ES-07, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_SolicitudEnLinea @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT CAST(q.[TipoCliente] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [TipoCliente],
           CAST(q.[Condominio] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [Condominio],
           CAST(q.[CodigoFTTH] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [CodigoFTTH],
           CAST(q.[Provincia] AS nvarchar(60)) COLLATE DATABASE_DEFAULT AS [Provincia],
           CAST(q.[Canton] AS nvarchar(80)) COLLATE DATABASE_DEFAULT AS [Canton],
           CAST(q.[Distrito] AS nvarchar(80)) COLLATE DATABASE_DEFAULT AS [Distrito],
           CAST(q.[Direccion] AS nvarchar(1000)) COLLATE DATABASE_DEFAULT AS [Direccion],
           CAST(q.[Estado] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Estado],
           CAST(q.[Referencia] AS varchar(50)) COLLATE DATABASE_DEFAULT AS [Referencia],
           q.[FechaSolicitud],
           q.[EnviadoCRM],
           q.[Telefonia],
           q.[IPPublica],
           q.[TienePromocion],
           CAST(q.[TipoPromocion] AS varchar(50)) COLLATE DATABASE_DEFAULT AS [TipoPromocion],
           q.[FechaPromocion],
           CAST(q.[TipoPago] AS varchar(30)) COLLATE DATABASE_DEFAULT AS [TipoPago],
           q.[Total],
           CAST(q.[IntentoPagoId] AS varchar(100)) COLLATE DATABASE_DEFAULT AS [IntentoPagoId],
           q.[Referido],
           CAST(q.[ReferidoPor] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [ReferidoPor],
           q.[DatosInvalidos],
           CAST(q.[RutaContrato] AS nvarchar(1000)) COLLATE DATABASE_DEFAULT AS [RutaContrato],
           q.[CantidadFirestick],
           q.[ClienteId],
           q.[ProductoId],
           q.[Latitud],
           q.[Longitud],
           q.[IPTVAdicionales],
           CAST(q.[CodigoPromocion] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [CodigoPromocion],
           q.[AtributosExtendidos] COLLATE DATABASE_DEFAULT AS [AtributosExtendidos],
           CAST(q.[Moneda] AS char(3)) COLLATE DATABASE_DEFAULT AS [Moneda],
           q.[TotalCRC],
           q.[TipoCambio],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[TipoCliente]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Condominio]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[CodigoFTTH]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Provincia]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Canton]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Distrito]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Direccion]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Estado]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Referencia]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaSolicitud], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[EnviadoCRM]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Telefonia]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[IPPublica]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TienePromocion]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TipoPromocion]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaPromocion], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TipoPago]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Total]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[IntentoPagoId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Referido]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ReferidoPor]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[DatosInvalidos]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[RutaContrato]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[CantidadFirestick]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ClienteId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ProductoId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Latitud]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Longitud]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[IPTVAdicionales]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[CodigoPromocion]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[AtributosExtendidos]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Moneda]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TotalCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TipoCambio]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_Total],
           CONCAT_WS(N',', CASE WHEN LEN(q.[TipoCliente]) > 30 THEN N'TipoCliente' END, CASE WHEN LEN(q.[Condominio]) > 200 THEN N'Condominio' END, CASE WHEN LEN(q.[CodigoFTTH]) > 50 THEN N'CodigoFTTH' END, CASE WHEN LEN(q.[Provincia]) > 60 THEN N'Provincia' END, CASE WHEN LEN(q.[Canton]) > 80 THEN N'Canton' END, CASE WHEN LEN(q.[Distrito]) > 80 THEN N'Distrito' END, CASE WHEN LEN(q.[Direccion]) > 1000 THEN N'Direccion' END, CASE WHEN LEN(q.[Estado]) > 50 THEN N'Estado' END, CASE WHEN LEN(q.[Referencia]) > 50 THEN N'Referencia' END, CASE WHEN LEN(q.[TipoPromocion]) > 50 THEN N'TipoPromocion' END, CASE WHEN LEN(q.[TipoPago]) > 30 THEN N'TipoPago' END, CASE WHEN LEN(q.[IntentoPagoId]) > 100 THEN N'IntentoPagoId' END, CASE WHEN LEN(q.[ReferidoPor]) > 200 THEN N'ReferidoPor' END, CASE WHEN LEN(q.[RutaContrato]) > 1000 THEN N'RutaContrato' END, CASE WHEN LEN(q.[CodigoPromocion]) > 50 THEN N'CodigoPromocion' END, CASE WHEN LEN(q.[Moneda]) > 3 THEN N'Moneda' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT q.*,
               tx.Tasa AS TipoCambio,
               CASE q.Moneda WHEN 'CRC' THEN q.[Total] WHEN 'USD' THEN CAST(q.[Total] * tx.Tasa AS decimal(19,4)) END AS [TotalCRC]
        FROM (
        SELECT 'ADNPayV2' AS FuenteSistema,
               N'ADNPayV2' AS FuenteBase,
               N'Customer' AS FuenteTabla,
               ctl.fn_Texto(CONVERT(nvarchar(200), c.[index])) AS FuenteLlave,
               ctl.fn_FechaCR(CONVERT(nvarchar(30), c.[create_time], 126)) AS FechaDato,
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[type])) AS [TipoCliente],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[condominium])) AS [Condominio],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[ftth])) AS [CodigoFTTH],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[province])) AS [Provincia],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[canton])) AS [Canton],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[district])) AS [Distrito],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[address])) AS [Direccion],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[status])) AS [Estado],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[reference])) AS [Referencia],
               ctl.fn_FechaCR(CONVERT(nvarchar(30), c.[create_time], 126)) AS [FechaSolicitud],
               c.[crm_status] AS [EnviadoCRM],
               c.[telephony] AS [Telefonia],
               c.[public_ip] AS [IPPublica],
               c.[promotion] AS [TienePromocion],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[promotion_type])) AS [TipoPromocion],
               CAST(c.[promotion_date] AS date) AS [FechaPromocion],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[pay_type])) AS [TipoPago],
               ctl.fn_Monto(CONVERT(nvarchar(60), c.[total_price])) AS [Total],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[payment_intent_id])) AS [IntentoPagoId],
               c.[is_referred] AS [Referido],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[referred_dat])) AS [ReferidoPor],
               c.[invalid_data] AS [DatosInvalidos],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[contract_s3_path])) AS [RutaContrato],
               TRY_CONVERT(int, c.[firestick_quantity]) AS [CantidadFirestick],
               COALESCE(co.ClienteId, cl.ClienteId) AS [ClienteId],
               (SELECT MIN(pr.ProductoId) FROM core.Producto pr WHERE pr.FuenteBase = N'ADNPayV2' AND pr.FuenteTabla = N'Service' AND pr.FuenteLlave = CAST(c.[plan] AS nvarchar(200))) AS [ProductoId],
               COALESCE(ctl.fn_Coordenada(c.coordinates, 1), ctl.fn_Coordenada(c.coordinate, 1)) AS [Latitud],
               COALESCE(ctl.fn_Coordenada(c.coordinates, 2), ctl.fn_Coordenada(c.coordinate, 2)) AS [Longitud],
               COALESCE(c.extra_iptv, TRY_CONVERT(int, ctl.fn_PrimerNumero(c.additional_iptv))) AS [IPTVAdicionales],
               COALESCE(ctl.fn_Texto(c.promotion_code), ctl.fn_Texto(c.promcode)) AS [CodigoPromocion],
               ctl.fn_Texto(CONVERT(nvarchar(400), c.[total_price])) AS [o_Total],
               NULLIF((SELECT ctl.fn_Texto(CONVERT(nvarchar(max), c.[error_reference])) AS [error_reference], ctl.fn_Texto(CONVERT(nvarchar(max), c.[mobile])) AS [mobile] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER), N'{}') AS [AtributosExtendidos],
               'CRC' AS [Moneda]
        FROM ADNPayV2.dbo.[Customer] c
        OUTER APPLY (SELECT MIN(o.ClienteId) AS ClienteId FROM core.ClienteOrigen o
                     WHERE o.Sistema = 'ADNPayV2' AND o.LlaveOrigen = CAST(c.[index] AS nvarchar(200))) co
        LEFT JOIN core.Cliente cl ON cl.FuenteTabla = N'Cedula' AND cl.FuenteLlave = ctl.fn_Cedula(c.id)
            AND EXISTS (SELECT 1 FROM core.ClienteOrigen vo WHERE vo.ClienteId = cl.ClienteId AND vo.Sistema IN ('ZohoCRM', 'ZohoBooks', 'ADNPayV2'))
        ) q
        OUTER APPLY (SELECT TOP 1 t.Venta FROM ref.TipoCambio t WHERE t.Fecha <= CAST(CAST(q.FechaSolicitud AS date) AS date) ORDER BY t.Fecha DESC) tc
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
    SELECT t.[SolicitudEnLineaId] AS RegistroId, t.FuenteLlave, (SELECT t.[ClienteId], t.[ProductoId], t.[Referencia], t.[Estado], t.[TipoCliente], t.[Condominio], t.[CodigoFTTH], t.[Provincia], t.[Canton], t.[Distrito], t.[Direccion], t.[Latitud], t.[Longitud], t.[IPTVAdicionales], t.[CantidadFirestick], t.[Telefonia], t.[IPPublica], t.[TienePromocion], t.[TipoPromocion], t.[CodigoPromocion], t.[FechaPromocion], t.[TipoPago], t.[Moneda], t.[TipoCambio], t.[Total], t.[TotalCRC], t.[Referido], t.[ReferidoPor], t.[DatosInvalidos], t.[EnviadoCRM], t.[RutaContrato], t.[IntentoPagoId], t.[FechaSolicitud], t.[AtributosExtendidos], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.SolicitudEnLinea t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato);

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.SolicitudEnLinea WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato)) THEN
        UPDATE SET t.[TipoCliente] = s.[TipoCliente], t.[Condominio] = s.[Condominio], t.[CodigoFTTH] = s.[CodigoFTTH], t.[Provincia] = s.[Provincia], t.[Canton] = s.[Canton], t.[Distrito] = s.[Distrito], t.[Direccion] = s.[Direccion], t.[Estado] = s.[Estado], t.[Referencia] = s.[Referencia], t.[FechaSolicitud] = s.[FechaSolicitud], t.[EnviadoCRM] = s.[EnviadoCRM], t.[Telefonia] = s.[Telefonia], t.[IPPublica] = s.[IPPublica], t.[TienePromocion] = s.[TienePromocion], t.[TipoPromocion] = s.[TipoPromocion], t.[FechaPromocion] = s.[FechaPromocion], t.[TipoPago] = s.[TipoPago], t.[Total] = s.[Total], t.[IntentoPagoId] = s.[IntentoPagoId], t.[Referido] = s.[Referido], t.[ReferidoPor] = s.[ReferidoPor], t.[DatosInvalidos] = s.[DatosInvalidos], t.[RutaContrato] = s.[RutaContrato], t.[CantidadFirestick] = s.[CantidadFirestick], t.[ClienteId] = s.[ClienteId], t.[ProductoId] = s.[ProductoId], t.[Latitud] = s.[Latitud], t.[Longitud] = s.[Longitud], t.[IPTVAdicionales] = s.[IPTVAdicionales], t.[CodigoPromocion] = s.[CodigoPromocion], t.[AtributosExtendidos] = s.[AtributosExtendidos], t.[Moneda] = s.[Moneda], t.[TotalCRC] = s.[TotalCRC], t.[TipoCambio] = s.[TipoCambio], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([TipoCliente], [Condominio], [CodigoFTTH], [Provincia], [Canton], [Distrito], [Direccion], [Estado], [Referencia], [FechaSolicitud], [EnviadoCRM], [Telefonia], [IPPublica], [TienePromocion], [TipoPromocion], [FechaPromocion], [TipoPago], [Total], [IntentoPagoId], [Referido], [ReferidoPor], [DatosInvalidos], [RutaContrato], [CantidadFirestick], [ClienteId], [ProductoId], [Latitud], [Longitud], [IPTVAdicionales], [CodigoPromocion], [AtributosExtendidos], [Moneda], [TotalCRC], [TipoCambio], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[TipoCliente], s.[Condominio], s.[CodigoFTTH], s.[Provincia], s.[Canton], s.[Distrito], s.[Direccion], s.[Estado], s.[Referencia], s.[FechaSolicitud], s.[EnviadoCRM], s.[Telefonia], s.[IPPublica], s.[TienePromocion], s.[TipoPromocion], s.[FechaPromocion], s.[TipoPago], s.[Total], s.[IntentoPagoId], s.[Referido], s.[ReferidoPor], s.[DatosInvalidos], s.[RutaContrato], s.[CantidadFirestick], s.[ClienteId], s.[ProductoId], s.[Latitud], s.[Longitud], s.[IPTVAdicionales], s.[CodigoPromocion], s.[AtributosExtendidos], s.[Moneda], s.[TotalCRC], s.[TipoCambio], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[SolicitudEnLineaId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.SolicitudEnLinea', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.SolicitudEnLinea', t.[SolicitudEnLineaId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.SolicitudEnLinea t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-04', N'core.SolicitudEnLinea', t.[SolicitudEnLineaId], N'Total', LEFT(CONVERT(nvarchar(400), s.o_Total), 400), N'Monto ilegible; se conserva el texto original'
    FROM #src s JOIN core.SolicitudEnLinea t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Total IS NOT NULL AND s.[Total] IS NULL;

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
