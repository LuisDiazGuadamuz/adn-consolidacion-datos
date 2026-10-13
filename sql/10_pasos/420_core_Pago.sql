USE ADN_Unificado;
GO
/* Paso 420 · core_Pago → core.Pago
   Pagos de clientes en Books. El espejo no trae la moneda del pago: es CRC si el monto coincide con el monto en moneda base (bcy_amount) y USD si no. Los montos en colones son los de moneda base de Books (bcy_*).
   Reglas: D5, DD-02, ES-01, ES-02, ES-03, ES-04, ID-06, IN-01, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_Pago @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT CAST(q.[PagoBooksId] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [PagoBooksId],
           CAST(q.[Numero] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Numero],
           q.[Fecha],
           CAST(q.[MedioPago] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [MedioPago],
           q.[Monto],
           q.[MontoNoAplicado],
           CAST(q.[Descripcion] AS nvarchar(1000)) COLLATE DATABASE_DEFAULT AS [Descripcion],
           CAST(q.[Referencia] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [Referencia],
           CAST(q.[Sucursal] AS nvarchar(100)) COLLATE DATABASE_DEFAULT AS [Sucursal],
           CAST(q.[ContactoBooksId] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [ContactoBooksId],
           q.[FechaCreacionOrigen],
           q.[FechaModificacionOrigen],
           q.[ImpuestoRetenido],
           q.[CuentaBancariaId],
           q.[ClienteId],
           q.[ServicioId],
           q.[AtributosExtendidos] COLLATE DATABASE_DEFAULT AS [AtributosExtendidos],
           CAST(q.[Moneda] AS char(3)) COLLATE DATABASE_DEFAULT AS [Moneda],
           q.[MontoCRC],
           q.[MontoNoAplicadoCRC],
           q.[ImpuestoRetenidoCRC],
           q.[MontoReembolsadoCRC],
           q.[TipoCambio],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[PagoBooksId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Numero]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Fecha], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[MedioPago]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Monto]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[MontoNoAplicado]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Descripcion]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Referencia]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Sucursal]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ContactoBooksId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaCreacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaModificacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ImpuestoRetenido]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[CuentaBancariaId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ClienteId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ServicioId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[AtributosExtendidos]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Moneda]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[MontoCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[MontoNoAplicadoCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ImpuestoRetenidoCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[MontoReembolsadoCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TipoCambio]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_ServicioVarios],
           q.[o_ClienteBooks],
           q.[o_CuentaBancariaId],
           q.[o_Fecha],
           q.[o_Monto],
           q.[o_MontoNoAplicado],
           q.[o_FechaCreacionOrigen],
           q.[o_FechaModificacionOrigen],
           q.[o_ImpuestoRetenido],
           CONCAT_WS(N',', CASE WHEN LEN(q.[PagoBooksId]) > 30 THEN N'PagoBooksId' END, CASE WHEN LEN(q.[Numero]) > 50 THEN N'Numero' END, CASE WHEN LEN(q.[MedioPago]) > 50 THEN N'MedioPago' END, CASE WHEN LEN(q.[Descripcion]) > 1000 THEN N'Descripcion' END, CASE WHEN LEN(q.[Referencia]) > 200 THEN N'Referencia' END, CASE WHEN LEN(q.[Sucursal]) > 100 THEN N'Sucursal' END, CASE WHEN LEN(q.[ContactoBooksId]) > 30 THEN N'ContactoBooksId' END, CASE WHEN LEN(q.[Moneda]) > 3 THEN N'Moneda' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT q.*,
               tx.Tasa AS TipoCambio,
               COALESCE(q.[d_MontoCRC], CASE q.Moneda WHEN 'CRC' THEN q.[Monto] WHEN 'USD' THEN CAST(q.[Monto] * tx.Tasa AS decimal(19,4)) END) AS [MontoCRC],
               COALESCE(q.[d_MontoNoAplicadoCRC], CASE q.Moneda WHEN 'CRC' THEN q.[MontoNoAplicado] WHEN 'USD' THEN CAST(q.[MontoNoAplicado] * tx.Tasa AS decimal(19,4)) END) AS [MontoNoAplicadoCRC],
               CASE q.Moneda WHEN 'CRC' THEN q.[ImpuestoRetenido] WHEN 'USD' THEN CAST(q.[ImpuestoRetenido] * tx.Tasa AS decimal(19,4)) END AS [ImpuestoRetenidoCRC],
               q.[d_MontoReembolsadoCRC] AS [MontoReembolsadoCRC]
        FROM (
        SELECT 'ZohoBooks' AS FuenteSistema,
               N'ZBooks_Mirror' AS FuenteBase,
               N'customerpayments' AS FuenteTabla,
               ctl.fn_Texto(CONVERT(nvarchar(200), p.[payment_id])) AS FuenteLlave,
               ctl.fn_FechaCR(CONVERT(nvarchar(60), p.[created_time])) AS FechaDato,
               ctl.fn_Texto(CONVERT(nvarchar(max), p.[payment_id])) AS [PagoBooksId],
               ctl.fn_Texto(CONVERT(nvarchar(max), p.[payment_number])) AS [Numero],
               ctl.fn_FechaDia(CONVERT(nvarchar(60), p.[date])) AS [Fecha],
               ctl.fn_Texto(CONVERT(nvarchar(max), p.[payment_mode])) AS [MedioPago],
               ctl.fn_Monto(CONVERT(nvarchar(60), p.[amount])) AS [Monto],
               ctl.fn_Monto(CONVERT(nvarchar(60), p.[unused_amount])) AS [MontoNoAplicado],
               ctl.fn_Texto(CONVERT(nvarchar(max), p.[description])) AS [Descripcion],
               ctl.fn_Texto(CONVERT(nvarchar(max), p.[reference_number])) AS [Referencia],
               ctl.fn_Texto(CONVERT(nvarchar(max), p.[branch_name])) AS [Sucursal],
               ctl.fn_Texto(CONVERT(nvarchar(max), p.[customer_id])) AS [ContactoBooksId],
               ctl.fn_FechaCR(CONVERT(nvarchar(60), p.[created_time])) AS [FechaCreacionOrigen],
               ctl.fn_FechaCR(CONVERT(nvarchar(60), p.[last_modified_time])) AS [FechaModificacionOrigen],
               ctl.fn_Monto(CONVERT(nvarchar(60), p.[tax_amount_withheld])) AS [ImpuestoRetenido],
               fk_CuentaBancariaId_0.Id AS [CuentaBancariaId],
               ctl.fn_Texto(CONVERT(nvarchar(400), p.[account_id])) AS [o_CuentaBancariaId],
               co.ClienteId AS [ClienteId],
               COALESCE(co.ServicioId, CASE WHEN sc.n = 1 THEN sc.ServicioId END) AS [ServicioId],
               CASE WHEN co.ServicioId IS NULL AND sc.n > 1 THEN ctl.fn_Texto(p.customer_id) END AS [o_ServicioVarios],
               CASE WHEN co.ClienteId IS NULL THEN ctl.fn_Texto(p.customer_id) END AS [o_ClienteBooks],
               ctl.fn_Texto(CONVERT(nvarchar(400), p.[date])) AS [o_Fecha],
               ctl.fn_Texto(CONVERT(nvarchar(400), p.[amount])) AS [o_Monto],
               ctl.fn_Texto(CONVERT(nvarchar(400), p.[unused_amount])) AS [o_MontoNoAplicado],
               ctl.fn_Texto(CONVERT(nvarchar(400), p.[created_time])) AS [o_FechaCreacionOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(400), p.[last_modified_time])) AS [o_FechaModificacionOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(400), p.[tax_amount_withheld])) AS [o_ImpuestoRetenido],
               NULLIF((SELECT ctl.fn_Texto(CONVERT(nvarchar(max), p.[account_name])) AS [account_name], ctl.fn_Texto(CONVERT(nvarchar(max), p.[branch_id])) AS [branch_id], ctl.fn_Texto(CONVERT(nvarchar(max), p.[customer_name])) AS [customer_name], ctl.fn_Texto(CONVERT(nvarchar(max), p.[payment_gateway])) AS [payment_gateway], ctl.fn_Texto(CONVERT(nvarchar(max), p.[applied_invoices])) AS [applied_invoices], ctl.fn_Texto(CONVERT(nvarchar(max), p.[has_attachment])) AS [has_attachment], ctl.fn_Texto(CONVERT(nvarchar(max), p.[documents])) AS [documents], ctl.fn_Texto(CONVERT(nvarchar(max), p.[custom_fields_list])) AS [custom_fields_list], ctl.fn_Texto(CONVERT(nvarchar(max), p.[tax_account_name])) AS [tax_account_name], ctl.fn_Texto(CONVERT(nvarchar(max), p.[payment_type])) AS [payment_type], ctl.fn_Texto(CONVERT(nvarchar(max), p.[settlement_status])) AS [settlement_status] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER), N'{}') AS [AtributosExtendidos],
               CASE WHEN ctl.fn_Monto(p.amount) IS NULL OR ctl.fn_Monto(p.bcy_amount) IS NULL THEN NULL WHEN ctl.fn_Monto(p.amount) = ctl.fn_Monto(p.bcy_amount) THEN 'CRC' ELSE 'USD' END AS [Moneda],
               ctl.fn_Monto(CONVERT(nvarchar(60), p.[bcy_amount])) AS [d_MontoCRC],
               ctl.fn_Monto(CONVERT(nvarchar(60), p.[bcy_unused_amount])) AS [d_MontoNoAplicadoCRC],
               ctl.fn_Monto(CONVERT(nvarchar(60), p.[bcy_refunded_amount])) AS [d_MontoReembolsadoCRC]
        FROM ZBooks_Mirror.dbo.[customerpayments] p
        OUTER APPLY (SELECT CASE WHEN COUNT(DISTINCT o.ClienteId) = 1 THEN MIN(o.ClienteId) END AS ClienteId,
                            CASE WHEN COUNT(DISTINCT o.ServicioId) = 1 THEN MIN(o.ServicioId) END AS ServicioId
                     FROM core.ClienteOrigen o WHERE o.Sistema = 'ZohoBooks' AND o.LlaveOrigen = ctl.fn_Texto(p.customer_id)) co
        OUTER APPLY (SELECT COUNT(*) AS n, MIN(sv.ServicioId) AS ServicioId FROM core.Servicio sv WHERE sv.ClienteId = co.ClienteId) sc
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[CuentaBancariaId]) END AS Id FROM core.CuentaBancaria zref WHERE zref.[CuentaBooksId] = ctl.fn_Texto(CONVERT(nvarchar(max), p.[account_id]))) fk_CuentaBancariaId_0
        ) q
        OUTER APPLY (SELECT TOP 1 t.Venta FROM ref.TipoCambio t WHERE t.Fecha <= CAST(q.Fecha AS date) ORDER BY t.Fecha DESC) tc
        CROSS APPLY (SELECT CASE q.Moneda WHEN 'CRC' THEN CAST(1 AS decimal(19,6)) WHEN 'USD' THEN COALESCE(tc.Venta, NULL) END AS Tasa) tx
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'PagoBooksId obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[PagoBooksId] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'Fecha obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[Fecha] IS NULL
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
    DELETE FROM #src WHERE [PagoBooksId] IS NULL OR [Fecha] IS NULL OR [ContactoBooksId] IS NULL OR [FuenteLlave] IS NULL;

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
    SELECT t.[PagoId] AS RegistroId, t.FuenteLlave, (SELECT t.[PagoBooksId], t.[ClienteId], t.[ServicioId], t.[ContactoBooksId], t.[Numero], t.[Fecha], t.[MedioPago], t.[CuentaBancariaId], t.[Referencia], t.[Descripcion], t.[Moneda], t.[TipoCambio], t.[Monto], t.[MontoCRC], t.[MontoNoAplicado], t.[MontoNoAplicadoCRC], t.[MontoReembolsado], t.[MontoReembolsadoCRC], t.[ImpuestoRetenido], t.[ImpuestoRetenidoCRC], t.[Sucursal], t.[AtributosExtendidos], t.[FechaCreacionOrigen], t.[FechaModificacionOrigen], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.Pago t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido;

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.Pago WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido) THEN
        UPDATE SET t.[PagoBooksId] = s.[PagoBooksId], t.[Numero] = s.[Numero], t.[Fecha] = s.[Fecha], t.[MedioPago] = s.[MedioPago], t.[Monto] = s.[Monto], t.[MontoNoAplicado] = s.[MontoNoAplicado], t.[Descripcion] = s.[Descripcion], t.[Referencia] = s.[Referencia], t.[Sucursal] = s.[Sucursal], t.[ContactoBooksId] = s.[ContactoBooksId], t.[FechaCreacionOrigen] = s.[FechaCreacionOrigen], t.[FechaModificacionOrigen] = s.[FechaModificacionOrigen], t.[ImpuestoRetenido] = s.[ImpuestoRetenido], t.[CuentaBancariaId] = s.[CuentaBancariaId], t.[ClienteId] = s.[ClienteId], t.[ServicioId] = s.[ServicioId], t.[AtributosExtendidos] = s.[AtributosExtendidos], t.[Moneda] = s.[Moneda], t.[MontoCRC] = s.[MontoCRC], t.[MontoNoAplicadoCRC] = s.[MontoNoAplicadoCRC], t.[ImpuestoRetenidoCRC] = s.[ImpuestoRetenidoCRC], t.[MontoReembolsadoCRC] = s.[MontoReembolsadoCRC], t.[TipoCambio] = s.[TipoCambio], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([PagoBooksId], [Numero], [Fecha], [MedioPago], [Monto], [MontoNoAplicado], [Descripcion], [Referencia], [Sucursal], [ContactoBooksId], [FechaCreacionOrigen], [FechaModificacionOrigen], [ImpuestoRetenido], [CuentaBancariaId], [ClienteId], [ServicioId], [AtributosExtendidos], [Moneda], [MontoCRC], [MontoNoAplicadoCRC], [ImpuestoRetenidoCRC], [MontoReembolsadoCRC], [TipoCambio], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[PagoBooksId], s.[Numero], s.[Fecha], s.[MedioPago], s.[Monto], s.[MontoNoAplicado], s.[Descripcion], s.[Referencia], s.[Sucursal], s.[ContactoBooksId], s.[FechaCreacionOrigen], s.[FechaModificacionOrigen], s.[ImpuestoRetenido], s.[CuentaBancariaId], s.[ClienteId], s.[ServicioId], s.[AtributosExtendidos], s.[Moneda], s.[MontoCRC], s.[MontoNoAplicadoCRC], s.[ImpuestoRetenidoCRC], s.[MontoReembolsadoCRC], s.[TipoCambio], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[PagoId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.Pago', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.Pago', t.[PagoId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.Pago t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.Pago', t.[PagoId], N'ServicioId', LEFT(CONVERT(nvarchar(400), s.o_ServicioVarios), 400), N'Cliente con varios servicios: el documento de Books no indica a cuál corresponde (ID-03)'
    FROM #src s JOIN core.Pago t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_ServicioVarios IS NOT NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.Pago', t.[PagoId], N'ClienteId', LEFT(CONVERT(nvarchar(400), s.o_ClienteBooks), 400), N'Contacto de Books sin correspondencia en core.ClienteOrigen'
    FROM #src s JOIN core.Pago t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_ClienteBooks IS NOT NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.Pago', t.[PagoId], N'CuentaBancariaId', LEFT(CONVERT(nvarchar(400), s.o_CuentaBancariaId), 400), N'Referencia sin correspondencia única en core.CuentaBancaria'
    FROM #src s JOIN core.Pago t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_CuentaBancariaId IS NOT NULL AND s.[CuentaBancariaId] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.Pago', t.[PagoId], N'Fecha', LEFT(CONVERT(nvarchar(400), s.o_Fecha), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.Pago t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Fecha IS NOT NULL AND s.[Fecha] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-04', N'core.Pago', t.[PagoId], N'Monto', LEFT(CONVERT(nvarchar(400), s.o_Monto), 400), N'Monto ilegible; se conserva el texto original'
    FROM #src s JOIN core.Pago t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Monto IS NOT NULL AND s.[Monto] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-04', N'core.Pago', t.[PagoId], N'MontoNoAplicado', LEFT(CONVERT(nvarchar(400), s.o_MontoNoAplicado), 400), N'Monto ilegible; se conserva el texto original'
    FROM #src s JOIN core.Pago t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_MontoNoAplicado IS NOT NULL AND s.[MontoNoAplicado] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.Pago', t.[PagoId], N'FechaCreacionOrigen', LEFT(CONVERT(nvarchar(400), s.o_FechaCreacionOrigen), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.Pago t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaCreacionOrigen IS NOT NULL AND s.[FechaCreacionOrigen] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.Pago', t.[PagoId], N'FechaModificacionOrigen', LEFT(CONVERT(nvarchar(400), s.o_FechaModificacionOrigen), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.Pago t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaModificacionOrigen IS NOT NULL AND s.[FechaModificacionOrigen] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-04', N'core.Pago', t.[PagoId], N'ImpuestoRetenido', LEFT(CONVERT(nvarchar(400), s.o_ImpuestoRetenido), 400), N'Monto ilegible; se conserva el texto original'
    FROM #src s JOIN core.Pago t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_ImpuestoRetenido IS NOT NULL AND s.[ImpuestoRetenido] IS NULL;

    SELECT @Leidas AS FilasLeidas, @Validas - (SELECT COUNT_BIG(*) FROM #cambios) AS FilasSinCambio;
END;
GO
