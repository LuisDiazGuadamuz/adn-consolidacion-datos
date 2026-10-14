USE ADN_Unificado;
GO
/* Paso 410 · core_Factura → core.Factura
   Facturas de Books, depuradas por la versión más reciente (DD-02). Cliente y servicio por la tabla de correspondencia (ID-06). El detalle de líneas va en core.FacturaLinea.
   Reglas: D5, DD-02, ES-01, ES-02, ES-04, ID-04, ID-06, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_Factura @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT CAST(q.[FacturaBooksId] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [FacturaBooksId],
           CAST(q.[ContactoBooksId] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [ContactoBooksId],
           CAST(q.[Estado] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [Estado],
           CAST(q.[Numero] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Numero],
           CAST(q.[Referencia] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [Referencia],
           q.[Fecha],
           q.[FechaVencimiento],
           CAST(q.[Moneda] AS char(3)) COLLATE DATABASE_DEFAULT AS [Moneda],
           CAST(q.[Sucursal] AS nvarchar(100)) COLLATE DATABASE_DEFAULT AS [Sucursal],
           q.[Total],
           q.[Saldo],
           q.[FechaCreacionOrigen],
           q.[FechaModificacionOrigen],
           q.[FechaUltimoPago],
           CAST(q.[Vendedor] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [Vendedor],
           q.[CargoEnvio],
           q.[Ajuste],
           q.[MontoCancelado],
           q.[ClienteId],
           q.[ServicioId],
           q.[AtributosExtendidos] COLLATE DATABASE_DEFAULT AS [AtributosExtendidos],
           q.[TotalCRC],
           q.[SaldoCRC],
           q.[AjusteCRC],
           q.[CargoEnvioCRC],
           q.[MontoCanceladoCRC],
           q.[TipoCambio],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[FacturaBooksId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ContactoBooksId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Estado]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Numero]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Referencia]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Fecha], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaVencimiento], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Moneda]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Sucursal]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Total]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Saldo]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaCreacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaModificacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaUltimoPago], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Vendedor]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[CargoEnvio]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Ajuste]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[MontoCancelado]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ClienteId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ServicioId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[AtributosExtendidos]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TotalCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[SaldoCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[AjusteCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[CargoEnvioCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[MontoCanceladoCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TipoCambio]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_ServicioVarios],
           q.[o_ClienteBooks],
           q.[o_Fecha],
           q.[o_FechaVencimiento],
           q.[o_Total],
           q.[o_Saldo],
           q.[o_FechaCreacionOrigen],
           q.[o_FechaModificacionOrigen],
           q.[o_FechaUltimoPago],
           q.[o_CargoEnvio],
           q.[o_Ajuste],
           q.[o_MontoCancelado],
           CONCAT_WS(N',', CASE WHEN LEN(q.[FacturaBooksId]) > 30 THEN N'FacturaBooksId' END, CASE WHEN LEN(q.[ContactoBooksId]) > 30 THEN N'ContactoBooksId' END, CASE WHEN LEN(q.[Estado]) > 30 THEN N'Estado' END, CASE WHEN LEN(q.[Numero]) > 50 THEN N'Numero' END, CASE WHEN LEN(q.[Referencia]) > 200 THEN N'Referencia' END, CASE WHEN LEN(q.[Moneda]) > 3 THEN N'Moneda' END, CASE WHEN LEN(q.[Sucursal]) > 100 THEN N'Sucursal' END, CASE WHEN LEN(q.[Vendedor]) > 200 THEN N'Vendedor' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT q.*,
               tx.Tasa AS TipoCambio,
               CASE q.Moneda WHEN 'CRC' THEN q.[Total] WHEN 'USD' THEN CAST(q.[Total] * tx.Tasa AS decimal(19,4)) END AS [TotalCRC],
               CASE q.Moneda WHEN 'CRC' THEN q.[Saldo] WHEN 'USD' THEN CAST(q.[Saldo] * tx.Tasa AS decimal(19,4)) END AS [SaldoCRC],
               CASE q.Moneda WHEN 'CRC' THEN q.[Ajuste] WHEN 'USD' THEN CAST(q.[Ajuste] * tx.Tasa AS decimal(19,4)) END AS [AjusteCRC],
               CASE q.Moneda WHEN 'CRC' THEN q.[CargoEnvio] WHEN 'USD' THEN CAST(q.[CargoEnvio] * tx.Tasa AS decimal(19,4)) END AS [CargoEnvioCRC],
               CASE q.Moneda WHEN 'CRC' THEN q.[MontoCancelado] WHEN 'USD' THEN CAST(q.[MontoCancelado] * tx.Tasa AS decimal(19,4)) END AS [MontoCanceladoCRC]
        FROM (
        SELECT 'ZohoBooks' AS FuenteSistema,
               N'ZBooks_Mirror' AS FuenteBase,
               N'invoices' AS FuenteTabla,
               ctl.fn_Texto(CONVERT(nvarchar(200), f.[invoice_id])) AS FuenteLlave,
               ctl.fn_FechaCR(CONVERT(nvarchar(60), f.[created_time])) AS FechaDato,
               ctl.fn_Texto(CONVERT(nvarchar(max), f.[invoice_id])) AS [FacturaBooksId],
               ctl.fn_Texto(CONVERT(nvarchar(max), f.[customer_id])) AS [ContactoBooksId],
               ctl.fn_Texto(CONVERT(nvarchar(max), f.[status])) AS [Estado],
               ctl.fn_Texto(CONVERT(nvarchar(max), f.[invoice_number])) AS [Numero],
               ctl.fn_Texto(CONVERT(nvarchar(max), f.[reference_number])) AS [Referencia],
               ctl.fn_FechaDia(CONVERT(nvarchar(60), f.[date])) AS [Fecha],
               ctl.fn_FechaDia(CONVERT(nvarchar(60), f.[due_date])) AS [FechaVencimiento],
               ctl.fn_Moneda(CONVERT(nvarchar(20), f.[currency_code])) AS [Moneda],
               ctl.fn_Texto(CONVERT(nvarchar(max), f.[branch_name])) AS [Sucursal],
               ctl.fn_Monto(CONVERT(nvarchar(60), f.[total])) AS [Total],
               ctl.fn_Monto(CONVERT(nvarchar(60), f.[balance])) AS [Saldo],
               ctl.fn_FechaCR(CONVERT(nvarchar(60), f.[created_time])) AS [FechaCreacionOrigen],
               ctl.fn_FechaCR(CONVERT(nvarchar(60), f.[last_modified_time])) AS [FechaModificacionOrigen],
               ctl.fn_FechaDia(CONVERT(nvarchar(60), f.[last_payment_date])) AS [FechaUltimoPago],
               ctl.fn_Texto(CONVERT(nvarchar(max), f.[salesperson_name])) AS [Vendedor],
               ctl.fn_Monto(CONVERT(nvarchar(60), f.[shipping_charge])) AS [CargoEnvio],
               ctl.fn_Monto(CONVERT(nvarchar(60), f.[adjustment])) AS [Ajuste],
               ctl.fn_Monto(CONVERT(nvarchar(60), f.[write_off_amount])) AS [MontoCancelado],
               co.ClienteId AS [ClienteId],
               COALESCE(co.ServicioId, CASE WHEN sc.n = 1 THEN sc.ServicioId END) AS [ServicioId],
               CASE WHEN co.ServicioId IS NULL AND sc.n > 1 THEN ctl.fn_Texto(f.customer_id) END AS [o_ServicioVarios],
               CASE WHEN co.ClienteId IS NULL THEN ctl.fn_Texto(f.customer_id) END AS [o_ClienteBooks],
               ctl.fn_Texto(CONVERT(nvarchar(400), f.[date])) AS [o_Fecha],
               ctl.fn_Texto(CONVERT(nvarchar(400), f.[due_date])) AS [o_FechaVencimiento],
               ctl.fn_Texto(CONVERT(nvarchar(400), f.[total])) AS [o_Total],
               ctl.fn_Texto(CONVERT(nvarchar(400), f.[balance])) AS [o_Saldo],
               ctl.fn_Texto(CONVERT(nvarchar(400), f.[created_time])) AS [o_FechaCreacionOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(400), f.[last_modified_time])) AS [o_FechaModificacionOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(400), f.[last_payment_date])) AS [o_FechaUltimoPago],
               ctl.fn_Texto(CONVERT(nvarchar(400), f.[shipping_charge])) AS [o_CargoEnvio],
               ctl.fn_Texto(CONVERT(nvarchar(400), f.[adjustment])) AS [o_Ajuste],
               ctl.fn_Texto(CONVERT(nvarchar(400), f.[write_off_amount])) AS [o_MontoCancelado],
               NULLIF((SELECT ctl.fn_Texto(CONVERT(nvarchar(max), f.[ach_payment_initiated])) AS [ach_payment_initiated], ctl.fn_Texto(CONVERT(nvarchar(max), f.[zcrm_potential_name])) AS [zcrm_potential_name], ctl.fn_Texto(CONVERT(nvarchar(max), f.[company_name])) AS [company_name], ctl.fn_Texto(CONVERT(nvarchar(max), f.[color_code])) AS [color_code], ctl.fn_Texto(CONVERT(nvarchar(max), f.[current_sub_status])) AS [current_sub_status], ctl.fn_Texto(CONVERT(nvarchar(max), f.[due_days])) AS [due_days], ctl.fn_Texto(CONVERT(nvarchar(max), f.[currency_id])) AS [currency_id], ctl.fn_Texto(CONVERT(nvarchar(max), f.[email])) AS [email], ctl.fn_Texto(CONVERT(nvarchar(max), f.[currency_symbol])) AS [currency_symbol], ctl.fn_Texto(CONVERT(nvarchar(max), f.[template_type])) AS [template_type], ctl.fn_Texto(CONVERT(nvarchar(max), f.[no_of_copies])) AS [no_of_copies], ctl.fn_Texto(CONVERT(nvarchar(max), f.[show_no_of_copies])) AS [show_no_of_copies], ctl.fn_Texto(CONVERT(nvarchar(max), f.[is_viewed_by_client])) AS [is_viewed_by_client], ctl.fn_Texto(CONVERT(nvarchar(max), f.[has_attachment])) AS [has_attachment], ctl.fn_Texto(CONVERT(nvarchar(max), f.[client_viewed_time])) AS [client_viewed_time], ctl.fn_Texto(CONVERT(nvarchar(max), f.[invoice_url])) AS [invoice_url], ctl.fn_Texto(CONVERT(nvarchar(max), f.[project_name])) AS [project_name], ctl.fn_Texto(CONVERT(nvarchar(max), f.[branch_id])) AS [branch_id], ctl.fn_Texto(CONVERT(nvarchar(max), f.[billing_address])) AS [billing_address], ctl.fn_Texto(CONVERT(nvarchar(max), f.[shipping_address])) AS [shipping_address], ctl.fn_Texto(CONVERT(nvarchar(max), f.[country])) AS [country], ctl.fn_Texto(CONVERT(nvarchar(max), f.[phone])) AS [phone], ctl.fn_Texto(CONVERT(nvarchar(max), f.[created_by])) AS [created_by], ctl.fn_Texto(CONVERT(nvarchar(max), f.[updated_time])) AS [updated_time], ctl.fn_Texto(CONVERT(nvarchar(max), f.[transaction_type])) AS [transaction_type], ctl.fn_Texto(CONVERT(nvarchar(max), f.[is_emailed])) AS [is_emailed], ctl.fn_Texto(CONVERT(nvarchar(max), f.[reminders_sent])) AS [reminders_sent], ctl.fn_Texto(CONVERT(nvarchar(max), f.[last_reminder_sent_date])) AS [last_reminder_sent_date], ctl.fn_Texto(CONVERT(nvarchar(max), f.[custom_fields])) AS [custom_fields], ctl.fn_Texto(CONVERT(nvarchar(max), f.[cf_envio_facturas_unformatted])) AS [cf_envio_facturas_unformatted], ctl.fn_Texto(CONVERT(nvarchar(max), f.[cf_ship_date_unformatted])) AS [cf_ship_date_unformatted], ctl.fn_Texto(CONVERT(nvarchar(max), f.[customer_cf_tipo_fiscal_unformatted])) AS [customer_cf_tipo_fiscal_unformatted], ctl.fn_Texto(CONVERT(nvarchar(max), f.[customer_cf_exonerado_unformatted])) AS [customer_cf_exonerado_unformatted], ctl.fn_Texto(CONVERT(nvarchar(max), f.[template_id])) AS [template_id], ctl.fn_Texto(CONVERT(nvarchar(max), f.[documents])) AS [documents], ctl.fn_Texto(CONVERT(nvarchar(max), f.[salesperson_id])) AS [salesperson_id] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER), N'{}') AS [AtributosExtendidos],
               TRY_CONVERT(decimal(19,6), TRY_CONVERT(decimal(19,6), ctl.fn_PrimerNumero(CONVERT(nvarchar(255), f.[exchange_rate])))) AS [d_TipoCambio]
        FROM ZBooks_Mirror.dbo.[invoices] f
        OUTER APPLY (SELECT CASE WHEN COUNT(DISTINCT o.ClienteId) = 1 THEN MIN(o.ClienteId) END AS ClienteId,
                            CASE WHEN COUNT(DISTINCT o.ServicioId) = 1 THEN MIN(o.ServicioId) END AS ServicioId
                     FROM core.ClienteOrigen o WHERE o.Sistema = 'ZohoBooks' AND o.LlaveOrigen = ctl.fn_Texto(f.customer_id)) co
        OUTER APPLY (SELECT COUNT(*) AS n, MIN(sv.ServicioId) AS ServicioId FROM core.Servicio sv WHERE sv.ClienteId = co.ClienteId) sc
        ) q
        OUTER APPLY (SELECT TOP 1 t.Venta FROM ref.TipoCambio t WHERE t.Fecha <= CAST(q.Fecha AS date) ORDER BY t.Fecha DESC) tc
        CROSS APPLY (SELECT CASE q.Moneda WHEN 'CRC' THEN CAST(1 AS decimal(19,6)) WHEN 'USD' THEN COALESCE(tc.Venta, CASE WHEN q.d_TipoCambio > 1 THEN q.d_TipoCambio END) END AS Tasa) tx
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);
    /* Conciliación: llaves leídas, para comprobar al final que toda fila excluida tiene su motivo en ctl.Descarte */
    DROP TABLE IF EXISTS #leidas;
    SELECT DISTINCT FuenteTabla, FuenteLlave INTO #leidas FROM #src;

    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FacturaBooksId obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FacturaBooksId] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'ContactoBooksId obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[ContactoBooksId] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'Fecha obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[Fecha] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FuenteLlave obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FuenteLlave] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE FROM #src WHERE [FacturaBooksId] IS NULL OR [ContactoBooksId] IS NULL OR [Fecha] IS NULL OR [FuenteLlave] IS NULL;

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
    SELECT t.[FacturaId] AS RegistroId, t.FuenteLlave, (SELECT t.[FacturaBooksId], t.[ClienteId], t.[ServicioId], t.[ContactoBooksId], t.[Numero], t.[Referencia], t.[Estado], t.[Fecha], t.[FechaVencimiento], t.[Moneda], t.[TipoCambio], t.[Total], t.[TotalCRC], t.[Saldo], t.[SaldoCRC], t.[Ajuste], t.[AjusteCRC], t.[CargoEnvio], t.[CargoEnvioCRC], t.[MontoCancelado], t.[MontoCanceladoCRC], t.[Sucursal], t.[Vendedor], t.[FechaUltimoPago], t.[AtributosExtendidos], t.[FechaCreacionOrigen], t.[FechaModificacionOrigen], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.Factura t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato);

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.Factura WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato)) THEN
        UPDATE SET t.[FacturaBooksId] = s.[FacturaBooksId], t.[ContactoBooksId] = s.[ContactoBooksId], t.[Estado] = s.[Estado], t.[Numero] = s.[Numero], t.[Referencia] = s.[Referencia], t.[Fecha] = s.[Fecha], t.[FechaVencimiento] = s.[FechaVencimiento], t.[Moneda] = s.[Moneda], t.[Sucursal] = s.[Sucursal], t.[Total] = s.[Total], t.[Saldo] = s.[Saldo], t.[FechaCreacionOrigen] = s.[FechaCreacionOrigen], t.[FechaModificacionOrigen] = s.[FechaModificacionOrigen], t.[FechaUltimoPago] = s.[FechaUltimoPago], t.[Vendedor] = s.[Vendedor], t.[CargoEnvio] = s.[CargoEnvio], t.[Ajuste] = s.[Ajuste], t.[MontoCancelado] = s.[MontoCancelado], t.[ClienteId] = s.[ClienteId], t.[ServicioId] = s.[ServicioId], t.[AtributosExtendidos] = s.[AtributosExtendidos], t.[TotalCRC] = s.[TotalCRC], t.[SaldoCRC] = s.[SaldoCRC], t.[AjusteCRC] = s.[AjusteCRC], t.[CargoEnvioCRC] = s.[CargoEnvioCRC], t.[MontoCanceladoCRC] = s.[MontoCanceladoCRC], t.[TipoCambio] = s.[TipoCambio], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([FacturaBooksId], [ContactoBooksId], [Estado], [Numero], [Referencia], [Fecha], [FechaVencimiento], [Moneda], [Sucursal], [Total], [Saldo], [FechaCreacionOrigen], [FechaModificacionOrigen], [FechaUltimoPago], [Vendedor], [CargoEnvio], [Ajuste], [MontoCancelado], [ClienteId], [ServicioId], [AtributosExtendidos], [TotalCRC], [SaldoCRC], [AjusteCRC], [CargoEnvioCRC], [MontoCanceladoCRC], [TipoCambio], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[FacturaBooksId], s.[ContactoBooksId], s.[Estado], s.[Numero], s.[Referencia], s.[Fecha], s.[FechaVencimiento], s.[Moneda], s.[Sucursal], s.[Total], s.[Saldo], s.[FechaCreacionOrigen], s.[FechaModificacionOrigen], s.[FechaUltimoPago], s.[Vendedor], s.[CargoEnvio], s.[Ajuste], s.[MontoCancelado], s.[ClienteId], s.[ServicioId], s.[AtributosExtendidos], s.[TotalCRC], s.[SaldoCRC], s.[AjusteCRC], s.[CargoEnvioCRC], s.[MontoCanceladoCRC], s.[TipoCambio], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[FacturaId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.Factura', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.Factura', t.[FacturaId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.Factura t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.Factura', t.[FacturaId], N'ServicioId', LEFT(CONVERT(nvarchar(400), s.o_ServicioVarios), 400), N'Cliente con varios servicios: el documento de Books no indica a cuál corresponde (ID-03)'
    FROM #src s JOIN core.Factura t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_ServicioVarios IS NOT NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.Factura', t.[FacturaId], N'ClienteId', LEFT(CONVERT(nvarchar(400), s.o_ClienteBooks), 400), N'Contacto de Books sin correspondencia en core.ClienteOrigen'
    FROM #src s JOIN core.Factura t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_ClienteBooks IS NOT NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.Factura', t.[FacturaId], N'Fecha', LEFT(CONVERT(nvarchar(400), s.o_Fecha), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.Factura t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Fecha IS NOT NULL AND s.[Fecha] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.Factura', t.[FacturaId], N'FechaVencimiento', LEFT(CONVERT(nvarchar(400), s.o_FechaVencimiento), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.Factura t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaVencimiento IS NOT NULL AND s.[FechaVencimiento] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-04', N'core.Factura', t.[FacturaId], N'Total', LEFT(CONVERT(nvarchar(400), s.o_Total), 400), N'Monto ilegible; se conserva el texto original'
    FROM #src s JOIN core.Factura t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Total IS NOT NULL AND s.[Total] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-04', N'core.Factura', t.[FacturaId], N'Saldo', LEFT(CONVERT(nvarchar(400), s.o_Saldo), 400), N'Monto ilegible; se conserva el texto original'
    FROM #src s JOIN core.Factura t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Saldo IS NOT NULL AND s.[Saldo] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.Factura', t.[FacturaId], N'FechaCreacionOrigen', LEFT(CONVERT(nvarchar(400), s.o_FechaCreacionOrigen), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.Factura t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaCreacionOrigen IS NOT NULL AND s.[FechaCreacionOrigen] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.Factura', t.[FacturaId], N'FechaModificacionOrigen', LEFT(CONVERT(nvarchar(400), s.o_FechaModificacionOrigen), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.Factura t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaModificacionOrigen IS NOT NULL AND s.[FechaModificacionOrigen] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.Factura', t.[FacturaId], N'FechaUltimoPago', LEFT(CONVERT(nvarchar(400), s.o_FechaUltimoPago), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.Factura t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaUltimoPago IS NOT NULL AND s.[FechaUltimoPago] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-04', N'core.Factura', t.[FacturaId], N'CargoEnvio', LEFT(CONVERT(nvarchar(400), s.o_CargoEnvio), 400), N'Monto ilegible; se conserva el texto original'
    FROM #src s JOIN core.Factura t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_CargoEnvio IS NOT NULL AND s.[CargoEnvio] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-04', N'core.Factura', t.[FacturaId], N'Ajuste', LEFT(CONVERT(nvarchar(400), s.o_Ajuste), 400), N'Monto ilegible; se conserva el texto original'
    FROM #src s JOIN core.Factura t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Ajuste IS NOT NULL AND s.[Ajuste] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-04', N'core.Factura', t.[FacturaId], N'MontoCancelado', LEFT(CONVERT(nvarchar(400), s.o_MontoCancelado), 400), N'Monto ilegible; se conserva el texto original'
    FROM #src s JOIN core.Factura t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_MontoCancelado IS NOT NULL AND s.[MontoCancelado] IS NULL;

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
