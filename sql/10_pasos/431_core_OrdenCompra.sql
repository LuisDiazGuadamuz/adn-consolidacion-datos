USE ADN_Unificado;
GO
/* Paso 431 · core_OrdenCompra → core.OrdenCompra
   Órdenes de compra a proveedores en Books.
   Reglas: D5, ES-01, ES-02, ES-04, IN-01, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_OrdenCompra @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT CAST(q.[OrdenCompraBooksId] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [OrdenCompraBooksId],
           CAST(q.[Estado] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [Estado],
           CAST(q.[EstadoFacturacion] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [EstadoFacturacion],
           CAST(q.[EstadoRecepcion] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [EstadoRecepcion],
           CAST(q.[Numero] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Numero],
           CAST(q.[Referencia] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [Referencia],
           q.[Fecha],
           q.[FechaEntrega],
           CAST(q.[Moneda] AS char(3)) COLLATE DATABASE_DEFAULT AS [Moneda],
           q.[Total],
           q.[FechaCreacionOrigen],
           q.[FechaModificacionOrigen],
           CAST(q.[Sucursal] AS nvarchar(100)) COLLATE DATABASE_DEFAULT AS [Sucursal],
           q.[ProveedorId],
           q.[AtributosExtendidos] COLLATE DATABASE_DEFAULT AS [AtributosExtendidos],
           q.[TotalCRC],
           q.[TipoCambio],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[OrdenCompraBooksId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Estado]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[EstadoFacturacion]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[EstadoRecepcion]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Numero]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Referencia]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Fecha], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaEntrega], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Moneda]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Total]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaCreacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaModificacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Sucursal]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ProveedorId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[AtributosExtendidos]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TotalCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TipoCambio]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_ProveedorId],
           q.[o_Fecha],
           q.[o_FechaEntrega],
           q.[o_Total],
           q.[o_FechaCreacionOrigen],
           q.[o_FechaModificacionOrigen],
           CONCAT_WS(N',', CASE WHEN LEN(q.[OrdenCompraBooksId]) > 30 THEN N'OrdenCompraBooksId' END, CASE WHEN LEN(q.[Estado]) > 30 THEN N'Estado' END, CASE WHEN LEN(q.[EstadoFacturacion]) > 30 THEN N'EstadoFacturacion' END, CASE WHEN LEN(q.[EstadoRecepcion]) > 30 THEN N'EstadoRecepcion' END, CASE WHEN LEN(q.[Numero]) > 50 THEN N'Numero' END, CASE WHEN LEN(q.[Referencia]) > 200 THEN N'Referencia' END, CASE WHEN LEN(q.[Moneda]) > 3 THEN N'Moneda' END, CASE WHEN LEN(q.[Sucursal]) > 100 THEN N'Sucursal' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT q.*,
               tx.Tasa AS TipoCambio,
               CASE q.Moneda WHEN 'CRC' THEN q.[Total] WHEN 'USD' THEN CAST(q.[Total] * tx.Tasa AS decimal(19,4)) END AS [TotalCRC]
        FROM (
        SELECT 'ZohoBooks' AS FuenteSistema,
               N'ZBooks_Mirror' AS FuenteBase,
               N'purchaseorders' AS FuenteTabla,
               ctl.fn_Texto(CONVERT(nvarchar(200), o.[purchaseorder_id])) AS FuenteLlave,
               ctl.fn_FechaCR(CONVERT(nvarchar(60), o.[created_time])) AS FechaDato,
               ctl.fn_Texto(CONVERT(nvarchar(max), o.[purchaseorder_id])) AS [OrdenCompraBooksId],
               ctl.fn_Texto(CONVERT(nvarchar(max), o.[order_status])) AS [Estado],
               ctl.fn_Texto(CONVERT(nvarchar(max), o.[billed_status])) AS [EstadoFacturacion],
               ctl.fn_Texto(CONVERT(nvarchar(max), o.[received_status])) AS [EstadoRecepcion],
               ctl.fn_Texto(CONVERT(nvarchar(max), o.[purchaseorder_number])) AS [Numero],
               ctl.fn_Texto(CONVERT(nvarchar(max), o.[reference_number])) AS [Referencia],
               ctl.fn_FechaDia(CONVERT(nvarchar(60), o.[date])) AS [Fecha],
               ctl.fn_FechaDia(CONVERT(nvarchar(60), o.[delivery_date])) AS [FechaEntrega],
               ctl.fn_Moneda(CONVERT(nvarchar(20), o.[currency_code])) AS [Moneda],
               ctl.fn_Monto(CONVERT(nvarchar(60), o.[total])) AS [Total],
               ctl.fn_FechaCR(CONVERT(nvarchar(60), o.[created_time])) AS [FechaCreacionOrigen],
               ctl.fn_FechaCR(CONVERT(nvarchar(60), o.[last_modified_time])) AS [FechaModificacionOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(max), o.[branch_name])) AS [Sucursal],
               fk_ProveedorId_0.Id AS [ProveedorId],
               ctl.fn_Texto(CONVERT(nvarchar(400), o.[vendor_id])) AS [o_ProveedorId],
               ctl.fn_Texto(CONVERT(nvarchar(400), o.[date])) AS [o_Fecha],
               ctl.fn_Texto(CONVERT(nvarchar(400), o.[delivery_date])) AS [o_FechaEntrega],
               ctl.fn_Texto(CONVERT(nvarchar(400), o.[total])) AS [o_Total],
               ctl.fn_Texto(CONVERT(nvarchar(400), o.[created_time])) AS [o_FechaCreacionOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(400), o.[last_modified_time])) AS [o_FechaModificacionOrigen],
               NULLIF((SELECT ctl.fn_Texto(CONVERT(nvarchar(max), o.[vendor_name])) AS [vendor_name], ctl.fn_Texto(CONVERT(nvarchar(max), o.[company_name])) AS [company_name], ctl.fn_Texto(CONVERT(nvarchar(max), o.[status])) AS [status], ctl.fn_Texto(CONVERT(nvarchar(max), o.[color_code])) AS [color_code], ctl.fn_Texto(CONVERT(nvarchar(max), o.[current_sub_status])) AS [current_sub_status], ctl.fn_Texto(CONVERT(nvarchar(max), o.[delivery_days])) AS [delivery_days], ctl.fn_Texto(CONVERT(nvarchar(max), o.[due_by_days])) AS [due_by_days], ctl.fn_Texto(CONVERT(nvarchar(max), o.[due_in_days])) AS [due_in_days], ctl.fn_Texto(CONVERT(nvarchar(max), o.[currency_id])) AS [currency_id], ctl.fn_Texto(CONVERT(nvarchar(max), o.[has_attachment])) AS [has_attachment], ctl.fn_Texto(CONVERT(nvarchar(max), o.[is_drop_shipment])) AS [is_drop_shipment], ctl.fn_Texto(CONVERT(nvarchar(max), o.[total_ordered_quantity])) AS [total_ordered_quantity], ctl.fn_Texto(CONVERT(nvarchar(max), o.[quantity_yet_to_receive])) AS [quantity_yet_to_receive], ctl.fn_Texto(CONVERT(nvarchar(max), o.[quantity_marked_as_received])) AS [quantity_marked_as_received], ctl.fn_Texto(CONVERT(nvarchar(max), o.[is_po_marked_as_received])) AS [is_po_marked_as_received], ctl.fn_Texto(CONVERT(nvarchar(max), o.[is_backorder])) AS [is_backorder], ctl.fn_Texto(CONVERT(nvarchar(max), o.[receives])) AS [receives], ctl.fn_Texto(CONVERT(nvarchar(max), o.[is_viewed_by_client])) AS [is_viewed_by_client], ctl.fn_Texto(CONVERT(nvarchar(max), o.[branch_id])) AS [branch_id], ctl.fn_Texto(CONVERT(nvarchar(max), o.[odoo])) AS [odoo] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER), N'{}') AS [AtributosExtendidos]
        FROM ZBooks_Mirror.dbo.[purchaseorders] o
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[ProveedorId]) END AS Id FROM core.Proveedor zref WHERE zref.[ContactoBooksId] = ctl.fn_Texto(CONVERT(nvarchar(max), o.[vendor_id]))) fk_ProveedorId_0
        ) q
        OUTER APPLY (SELECT TOP 1 t.Venta FROM ref.TipoCambio t WHERE t.Fecha <= CAST(COALESCE(q.Fecha, CAST(q.FechaCreacionOrigen AS date)) AS date) ORDER BY t.Fecha DESC) tc
        CROSS APPLY (SELECT CASE q.Moneda WHEN 'CRC' THEN CAST(1 AS decimal(19,6)) WHEN 'USD' THEN COALESCE(tc.Venta, NULL) END AS Tasa) tx
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'OrdenCompraBooksId obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[OrdenCompraBooksId] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FuenteLlave obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FuenteLlave] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE FROM #src WHERE [OrdenCompraBooksId] IS NULL OR [FuenteLlave] IS NULL;

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
    SELECT t.[OrdenCompraId] AS RegistroId, t.FuenteLlave, (SELECT t.[OrdenCompraBooksId], t.[ProveedorId], t.[Numero], t.[Referencia], t.[Estado], t.[EstadoFacturacion], t.[EstadoRecepcion], t.[Fecha], t.[FechaEntrega], t.[Moneda], t.[TipoCambio], t.[Total], t.[TotalCRC], t.[Sucursal], t.[AtributosExtendidos], t.[FechaCreacionOrigen], t.[FechaModificacionOrigen], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.OrdenCompra t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato);

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.OrdenCompra WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato)) THEN
        UPDATE SET t.[OrdenCompraBooksId] = s.[OrdenCompraBooksId], t.[Estado] = s.[Estado], t.[EstadoFacturacion] = s.[EstadoFacturacion], t.[EstadoRecepcion] = s.[EstadoRecepcion], t.[Numero] = s.[Numero], t.[Referencia] = s.[Referencia], t.[Fecha] = s.[Fecha], t.[FechaEntrega] = s.[FechaEntrega], t.[Moneda] = s.[Moneda], t.[Total] = s.[Total], t.[FechaCreacionOrigen] = s.[FechaCreacionOrigen], t.[FechaModificacionOrigen] = s.[FechaModificacionOrigen], t.[Sucursal] = s.[Sucursal], t.[ProveedorId] = s.[ProveedorId], t.[AtributosExtendidos] = s.[AtributosExtendidos], t.[TotalCRC] = s.[TotalCRC], t.[TipoCambio] = s.[TipoCambio], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([OrdenCompraBooksId], [Estado], [EstadoFacturacion], [EstadoRecepcion], [Numero], [Referencia], [Fecha], [FechaEntrega], [Moneda], [Total], [FechaCreacionOrigen], [FechaModificacionOrigen], [Sucursal], [ProveedorId], [AtributosExtendidos], [TotalCRC], [TipoCambio], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[OrdenCompraBooksId], s.[Estado], s.[EstadoFacturacion], s.[EstadoRecepcion], s.[Numero], s.[Referencia], s.[Fecha], s.[FechaEntrega], s.[Moneda], s.[Total], s.[FechaCreacionOrigen], s.[FechaModificacionOrigen], s.[Sucursal], s.[ProveedorId], s.[AtributosExtendidos], s.[TotalCRC], s.[TipoCambio], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[OrdenCompraId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.OrdenCompra', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.OrdenCompra', t.[OrdenCompraId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.OrdenCompra t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.OrdenCompra', t.[OrdenCompraId], N'ProveedorId', LEFT(CONVERT(nvarchar(400), s.o_ProveedorId), 400), N'Referencia sin correspondencia única en core.Proveedor'
    FROM #src s JOIN core.OrdenCompra t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_ProveedorId IS NOT NULL AND s.[ProveedorId] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.OrdenCompra', t.[OrdenCompraId], N'Fecha', LEFT(CONVERT(nvarchar(400), s.o_Fecha), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.OrdenCompra t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Fecha IS NOT NULL AND s.[Fecha] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.OrdenCompra', t.[OrdenCompraId], N'FechaEntrega', LEFT(CONVERT(nvarchar(400), s.o_FechaEntrega), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.OrdenCompra t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaEntrega IS NOT NULL AND s.[FechaEntrega] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-04', N'core.OrdenCompra', t.[OrdenCompraId], N'Total', LEFT(CONVERT(nvarchar(400), s.o_Total), 400), N'Monto ilegible; se conserva el texto original'
    FROM #src s JOIN core.OrdenCompra t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Total IS NOT NULL AND s.[Total] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.OrdenCompra', t.[OrdenCompraId], N'FechaCreacionOrigen', LEFT(CONVERT(nvarchar(400), s.o_FechaCreacionOrigen), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.OrdenCompra t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaCreacionOrigen IS NOT NULL AND s.[FechaCreacionOrigen] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.OrdenCompra', t.[OrdenCompraId], N'FechaModificacionOrigen', LEFT(CONVERT(nvarchar(400), s.o_FechaModificacionOrigen), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.OrdenCompra t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaModificacionOrigen IS NOT NULL AND s.[FechaModificacionOrigen] IS NULL;

    SELECT @Leidas AS FilasLeidas, @Validas - (SELECT COUNT_BIG(*) FROM #cambios) AS FilasSinCambio;
END;
GO
