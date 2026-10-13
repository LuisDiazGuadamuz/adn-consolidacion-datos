USE ADN_Unificado;
GO
/* Paso 412 · core_FacturaRecurrente → core.FacturaRecurrente
   Perfiles de facturación recurrente de Books.
   Reglas: D5, DD-02, ES-01, ES-02, ES-04, ID-06, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_FacturaRecurrente @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT CAST(q.[RecurrenteBooksId] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [RecurrenteBooksId],
           CAST(q.[Nombre] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [Nombre],
           CAST(q.[Estado] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [Estado],
           q.[Total],
           CAST(q.[ContactoBooksId] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [ContactoBooksId],
           q.[FechaInicio],
           q.[FechaFin],
           q.[FechaUltimoEnvio],
           q.[FechaProximaFactura],
           CAST(q.[Frecuencia] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [Frecuencia],
           q.[RepetirCada],
           q.[FechaCreacionOrigen],
           q.[FechaModificacionOrigen],
           CAST(q.[Vendedor] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [Vendedor],
           CAST(q.[MedioPago] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [MedioPago],
           q.[ClienteId],
           q.[ServicioId],
           q.[AtributosExtendidos] COLLATE DATABASE_DEFAULT AS [AtributosExtendidos],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[RecurrenteBooksId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Nombre]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Estado]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Total]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ContactoBooksId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaInicio], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaFin], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaUltimoEnvio], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaProximaFactura], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Frecuencia]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[RepetirCada]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaCreacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaModificacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Vendedor]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[MedioPago]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ClienteId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ServicioId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[AtributosExtendidos]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_ServicioVarios],
           q.[o_ClienteBooks],
           q.[o_Total],
           q.[o_FechaInicio],
           q.[o_FechaFin],
           q.[o_FechaUltimoEnvio],
           q.[o_FechaProximaFactura],
           q.[o_FechaCreacionOrigen],
           q.[o_FechaModificacionOrigen],
           CONCAT_WS(N',', CASE WHEN LEN(q.[RecurrenteBooksId]) > 30 THEN N'RecurrenteBooksId' END, CASE WHEN LEN(q.[Nombre]) > 200 THEN N'Nombre' END, CASE WHEN LEN(q.[Estado]) > 30 THEN N'Estado' END, CASE WHEN LEN(q.[ContactoBooksId]) > 30 THEN N'ContactoBooksId' END, CASE WHEN LEN(q.[Frecuencia]) > 30 THEN N'Frecuencia' END, CASE WHEN LEN(q.[Vendedor]) > 200 THEN N'Vendedor' END, CASE WHEN LEN(q.[MedioPago]) > 50 THEN N'MedioPago' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT 'ZohoBooks' AS FuenteSistema,
               N'ZBooks_Mirror' AS FuenteBase,
               N'recurringinvoices' AS FuenteTabla,
               ctl.fn_Texto(CONVERT(nvarchar(200), r.[recurring_invoice_id])) AS FuenteLlave,
               ctl.fn_FechaCR(CONVERT(nvarchar(60), r.[created_time])) AS FechaDato,
               ctl.fn_Texto(CONVERT(nvarchar(max), r.[recurring_invoice_id])) AS [RecurrenteBooksId],
               ctl.fn_Texto(CONVERT(nvarchar(max), r.[recurrence_name])) AS [Nombre],
               ctl.fn_Texto(CONVERT(nvarchar(max), r.[status])) AS [Estado],
               ctl.fn_Monto(CONVERT(nvarchar(60), r.[total])) AS [Total],
               ctl.fn_Texto(CONVERT(nvarchar(max), r.[customer_id])) AS [ContactoBooksId],
               ctl.fn_FechaDia(CONVERT(nvarchar(60), r.[start_date])) AS [FechaInicio],
               ctl.fn_FechaDia(CONVERT(nvarchar(60), r.[end_date])) AS [FechaFin],
               ctl.fn_FechaDia(CONVERT(nvarchar(60), r.[last_sent_date])) AS [FechaUltimoEnvio],
               ctl.fn_FechaDia(CONVERT(nvarchar(60), r.[next_invoice_date])) AS [FechaProximaFactura],
               ctl.fn_Texto(CONVERT(nvarchar(max), r.[recurrence_frequency])) AS [Frecuencia],
               TRY_CONVERT(int, ctl.fn_PrimerNumero(CONVERT(nvarchar(255), r.[repeat_every]))) AS [RepetirCada],
               ctl.fn_FechaCR(CONVERT(nvarchar(60), r.[created_time])) AS [FechaCreacionOrigen],
               ctl.fn_FechaCR(CONVERT(nvarchar(60), r.[last_modified_time])) AS [FechaModificacionOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(max), r.[salesperson_name])) AS [Vendedor],
               ctl.fn_Texto(CONVERT(nvarchar(max), r.[cf_medio_de_pago_unformatted])) AS [MedioPago],
               co.ClienteId AS [ClienteId],
               COALESCE(co.ServicioId, CASE WHEN sc.n = 1 THEN sc.ServicioId END) AS [ServicioId],
               CASE WHEN co.ServicioId IS NULL AND sc.n > 1 THEN ctl.fn_Texto(r.customer_id) END AS [o_ServicioVarios],
               CASE WHEN co.ClienteId IS NULL THEN ctl.fn_Texto(r.customer_id) END AS [o_ClienteBooks],
               ctl.fn_Texto(CONVERT(nvarchar(400), r.[total])) AS [o_Total],
               ctl.fn_Texto(CONVERT(nvarchar(400), r.[start_date])) AS [o_FechaInicio],
               ctl.fn_Texto(CONVERT(nvarchar(400), r.[end_date])) AS [o_FechaFin],
               ctl.fn_Texto(CONVERT(nvarchar(400), r.[last_sent_date])) AS [o_FechaUltimoEnvio],
               ctl.fn_Texto(CONVERT(nvarchar(400), r.[next_invoice_date])) AS [o_FechaProximaFactura],
               ctl.fn_Texto(CONVERT(nvarchar(400), r.[created_time])) AS [o_FechaCreacionOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(400), r.[last_modified_time])) AS [o_FechaModificacionOrigen],
               NULLIF((SELECT ctl.fn_Texto(CONVERT(nvarchar(max), r.[reference_number])) AS [reference_number], ctl.fn_Texto(CONVERT(nvarchar(max), r.[customer_name])) AS [customer_name], ctl.fn_Texto(CONVERT(nvarchar(max), r.[child_entity_type])) AS [child_entity_type], ctl.fn_Texto(CONVERT(nvarchar(max), r.[salesperson_id])) AS [salesperson_id], ctl.fn_Texto(CONVERT(nvarchar(max), r.[cf_condici_n_de_venta_unformatted])) AS [cf_condici_n_de_venta_unformatted], ctl.fn_Texto(CONVERT(nvarchar(max), r.[cf_actividad_econ_mica_unformatted])) AS [cf_actividad_econ_mica_unformatted], ctl.fn_Texto(CONVERT(nvarchar(max), r.[cf_envio_facturas_unformatted])) AS [cf_envio_facturas_unformatted], ctl.fn_Texto(CONVERT(nvarchar(max), r.[cf_tipo_id_unformatted])) AS [cf_tipo_id_unformatted], ctl.fn_Texto(CONVERT(nvarchar(max), r.[cf_exencion_unformatted])) AS [cf_exencion_unformatted], ctl.fn_Texto(CONVERT(nvarchar(max), r.[cf_emisor_exencion_unformatted])) AS [cf_emisor_exencion_unformatted], ctl.fn_Texto(CONVERT(nvarchar(max), r.[cf_ship_date_unformatted])) AS [cf_ship_date_unformatted], ctl.fn_Texto(CONVERT(nvarchar(max), r.[cf_generado_zm_telefonia_unformatted])) AS [cf_generado_zm_telefonia_unformatted], ctl.fn_Texto(CONVERT(nvarchar(max), r.[cf_zm_special_identifier_unformatted])) AS [cf_zm_special_identifier_unformatted], ctl.fn_Texto(CONVERT(nvarchar(max), r.[branch_id])) AS [branch_id], ctl.fn_Texto(CONVERT(nvarchar(max), r.[branch_name])) AS [branch_name] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER), N'{}') AS [AtributosExtendidos]
        FROM ZBooks_Mirror.dbo.[recurringinvoices] r
        OUTER APPLY (SELECT CASE WHEN COUNT(DISTINCT o.ClienteId) = 1 THEN MIN(o.ClienteId) END AS ClienteId,
                            CASE WHEN COUNT(DISTINCT o.ServicioId) = 1 THEN MIN(o.ServicioId) END AS ServicioId
                     FROM core.ClienteOrigen o WHERE o.Sistema = 'ZohoBooks' AND o.LlaveOrigen = ctl.fn_Texto(r.customer_id)) co
        OUTER APPLY (SELECT COUNT(*) AS n, MIN(sv.ServicioId) AS ServicioId FROM core.Servicio sv WHERE sv.ClienteId = co.ClienteId) sc
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'RecurrenteBooksId obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[RecurrenteBooksId] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'ContactoBooksId obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[ContactoBooksId] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FuenteLlave obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FuenteLlave] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE FROM #src WHERE [RecurrenteBooksId] IS NULL OR [ContactoBooksId] IS NULL OR [FuenteLlave] IS NULL;

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
    SELECT t.[FacturaRecurrenteId] AS RegistroId, t.FuenteLlave, (SELECT t.[RecurrenteBooksId], t.[ClienteId], t.[ServicioId], t.[ContactoBooksId], t.[Nombre], t.[Estado], t.[Frecuencia], t.[RepetirCada], t.[Moneda], t.[TipoCambio], t.[Total], t.[TotalCRC], t.[FechaInicio], t.[FechaFin], t.[FechaUltimoEnvio], t.[FechaProximaFactura], t.[MedioPago], t.[Vendedor], t.[AtributosExtendidos], t.[FechaCreacionOrigen], t.[FechaModificacionOrigen], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.FacturaRecurrente t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato);

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.FacturaRecurrente WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato)) THEN
        UPDATE SET t.[RecurrenteBooksId] = s.[RecurrenteBooksId], t.[Nombre] = s.[Nombre], t.[Estado] = s.[Estado], t.[Total] = s.[Total], t.[ContactoBooksId] = s.[ContactoBooksId], t.[FechaInicio] = s.[FechaInicio], t.[FechaFin] = s.[FechaFin], t.[FechaUltimoEnvio] = s.[FechaUltimoEnvio], t.[FechaProximaFactura] = s.[FechaProximaFactura], t.[Frecuencia] = s.[Frecuencia], t.[RepetirCada] = s.[RepetirCada], t.[FechaCreacionOrigen] = s.[FechaCreacionOrigen], t.[FechaModificacionOrigen] = s.[FechaModificacionOrigen], t.[Vendedor] = s.[Vendedor], t.[MedioPago] = s.[MedioPago], t.[ClienteId] = s.[ClienteId], t.[ServicioId] = s.[ServicioId], t.[AtributosExtendidos] = s.[AtributosExtendidos], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([RecurrenteBooksId], [Nombre], [Estado], [Total], [ContactoBooksId], [FechaInicio], [FechaFin], [FechaUltimoEnvio], [FechaProximaFactura], [Frecuencia], [RepetirCada], [FechaCreacionOrigen], [FechaModificacionOrigen], [Vendedor], [MedioPago], [ClienteId], [ServicioId], [AtributosExtendidos], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[RecurrenteBooksId], s.[Nombre], s.[Estado], s.[Total], s.[ContactoBooksId], s.[FechaInicio], s.[FechaFin], s.[FechaUltimoEnvio], s.[FechaProximaFactura], s.[Frecuencia], s.[RepetirCada], s.[FechaCreacionOrigen], s.[FechaModificacionOrigen], s.[Vendedor], s.[MedioPago], s.[ClienteId], s.[ServicioId], s.[AtributosExtendidos], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[FacturaRecurrenteId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.FacturaRecurrente', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.FacturaRecurrente', t.[FacturaRecurrenteId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.FacturaRecurrente t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.FacturaRecurrente', t.[FacturaRecurrenteId], N'ServicioId', LEFT(CONVERT(nvarchar(400), s.o_ServicioVarios), 400), N'Cliente con varios servicios: el documento de Books no indica a cuál corresponde (ID-03)'
    FROM #src s JOIN core.FacturaRecurrente t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_ServicioVarios IS NOT NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.FacturaRecurrente', t.[FacturaRecurrenteId], N'ClienteId', LEFT(CONVERT(nvarchar(400), s.o_ClienteBooks), 400), N'Contacto de Books sin correspondencia en core.ClienteOrigen'
    FROM #src s JOIN core.FacturaRecurrente t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_ClienteBooks IS NOT NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-04', N'core.FacturaRecurrente', t.[FacturaRecurrenteId], N'Total', LEFT(CONVERT(nvarchar(400), s.o_Total), 400), N'Monto ilegible; se conserva el texto original'
    FROM #src s JOIN core.FacturaRecurrente t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Total IS NOT NULL AND s.[Total] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.FacturaRecurrente', t.[FacturaRecurrenteId], N'FechaInicio', LEFT(CONVERT(nvarchar(400), s.o_FechaInicio), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.FacturaRecurrente t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaInicio IS NOT NULL AND s.[FechaInicio] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.FacturaRecurrente', t.[FacturaRecurrenteId], N'FechaFin', LEFT(CONVERT(nvarchar(400), s.o_FechaFin), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.FacturaRecurrente t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaFin IS NOT NULL AND s.[FechaFin] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.FacturaRecurrente', t.[FacturaRecurrenteId], N'FechaUltimoEnvio', LEFT(CONVERT(nvarchar(400), s.o_FechaUltimoEnvio), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.FacturaRecurrente t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaUltimoEnvio IS NOT NULL AND s.[FechaUltimoEnvio] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.FacturaRecurrente', t.[FacturaRecurrenteId], N'FechaProximaFactura', LEFT(CONVERT(nvarchar(400), s.o_FechaProximaFactura), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.FacturaRecurrente t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaProximaFactura IS NOT NULL AND s.[FechaProximaFactura] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.FacturaRecurrente', t.[FacturaRecurrenteId], N'FechaCreacionOrigen', LEFT(CONVERT(nvarchar(400), s.o_FechaCreacionOrigen), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.FacturaRecurrente t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaCreacionOrigen IS NOT NULL AND s.[FechaCreacionOrigen] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.FacturaRecurrente', t.[FacturaRecurrenteId], N'FechaModificacionOrigen', LEFT(CONVERT(nvarchar(400), s.o_FechaModificacionOrigen), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.FacturaRecurrente t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaModificacionOrigen IS NOT NULL AND s.[FechaModificacionOrigen] IS NULL;

    SELECT @Leidas AS FilasLeidas, @Validas - (SELECT COUNT_BIG(*) FROM #cambios) AS FilasSinCambio;
END;
GO
