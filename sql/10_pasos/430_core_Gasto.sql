USE ADN_Unificado;
GO
/* Paso 430 · core_Gasto → core.Gasto
   Gastos de Books con sus etiquetas (expense_tags) en JSON. Totales en colones de moneda base (bcy_*).
   Reglas: D5, DD-02, ES-01, ES-02, ES-03, ES-04, IN-01, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_Gasto @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT CAST(q.[GastoBooksId] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [GastoBooksId],
           q.[Fecha],
           CAST(q.[PagadoDesde] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [PagadoDesde],
           CAST(q.[Cuenta] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [Cuenta],
           CAST(q.[Descripcion] AS nvarchar(1000)) COLLATE DATABASE_DEFAULT AS [Descripcion],
           CAST(q.[Moneda] AS char(3)) COLLATE DATABASE_DEFAULT AS [Moneda],
           q.[Total],
           q.[TotalSinImpuesto],
           CAST(q.[Referencia] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [Referencia],
           CAST(q.[Estado] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [Estado],
           q.[FechaCreacionOrigen],
           q.[FechaModificacionOrigen],
           CAST(q.[Sucursal] AS nvarchar(100)) COLLATE DATABASE_DEFAULT AS [Sucursal],
           q.[ClienteId],
           q.[ProveedorId],
           q.[Etiquetas] COLLATE DATABASE_DEFAULT AS [Etiquetas],
           q.[AtributosExtendidos] COLLATE DATABASE_DEFAULT AS [AtributosExtendidos],
           q.[TotalCRC],
           q.[TotalSinImpuestoCRC],
           q.[TipoCambio],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[GastoBooksId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Fecha], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[PagadoDesde]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Cuenta]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Descripcion]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Moneda]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Total]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TotalSinImpuesto]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Referencia]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Estado]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaCreacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaModificacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Sucursal]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ClienteId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ProveedorId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Etiquetas]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[AtributosExtendidos]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TotalCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TotalSinImpuestoCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TipoCambio]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_ClienteId],
           q.[o_ProveedorId],
           q.[o_Fecha],
           q.[o_Total],
           q.[o_TotalSinImpuesto],
           q.[o_FechaCreacionOrigen],
           q.[o_FechaModificacionOrigen],
           CONCAT_WS(N',', CASE WHEN LEN(q.[GastoBooksId]) > 30 THEN N'GastoBooksId' END, CASE WHEN LEN(q.[PagadoDesde]) > 200 THEN N'PagadoDesde' END, CASE WHEN LEN(q.[Cuenta]) > 200 THEN N'Cuenta' END, CASE WHEN LEN(q.[Descripcion]) > 1000 THEN N'Descripcion' END, CASE WHEN LEN(q.[Moneda]) > 3 THEN N'Moneda' END, CASE WHEN LEN(q.[Referencia]) > 200 THEN N'Referencia' END, CASE WHEN LEN(q.[Estado]) > 30 THEN N'Estado' END, CASE WHEN LEN(q.[Sucursal]) > 100 THEN N'Sucursal' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT q.*,
               CASE q.Moneda WHEN 'CRC' THEN CAST(1 AS decimal(19,6)) WHEN 'USD' THEN tc.Venta END AS TipoCambio,
               COALESCE(q.[d_TotalCRC], CASE q.Moneda WHEN 'CRC' THEN q.[Total] WHEN 'USD' THEN CAST(q.[Total] * tc.Venta AS decimal(19,4)) END) AS [TotalCRC],
               COALESCE(q.[d_TotalSinImpuestoCRC], CASE q.Moneda WHEN 'CRC' THEN q.[TotalSinImpuesto] WHEN 'USD' THEN CAST(q.[TotalSinImpuesto] * tc.Venta AS decimal(19,4)) END) AS [TotalSinImpuestoCRC]
        FROM (
        SELECT 'ZohoBooks' AS FuenteSistema,
               N'ZBooks_Mirror' AS FuenteBase,
               N'expenses' AS FuenteTabla,
               ctl.fn_Texto(CONVERT(nvarchar(200), e.[expense_id])) AS FuenteLlave,
               ctl.fn_FechaCR(CONVERT(nvarchar(60), e.[created_time])) AS FechaDato,
               ctl.fn_Texto(CONVERT(nvarchar(max), e.[expense_id])) AS [GastoBooksId],
               ctl.fn_FechaDia(CONVERT(nvarchar(60), e.[date])) AS [Fecha],
               ctl.fn_Texto(CONVERT(nvarchar(max), e.[paid_through_account_name])) AS [PagadoDesde],
               ctl.fn_Texto(CONVERT(nvarchar(max), e.[account_name])) AS [Cuenta],
               ctl.fn_Texto(CONVERT(nvarchar(max), e.[description])) AS [Descripcion],
               ctl.fn_Moneda(CONVERT(nvarchar(20), e.[currency_code])) AS [Moneda],
               ctl.fn_Monto(CONVERT(nvarchar(60), e.[total])) AS [Total],
               ctl.fn_Monto(CONVERT(nvarchar(60), e.[total_without_tax])) AS [TotalSinImpuesto],
               ctl.fn_Texto(CONVERT(nvarchar(max), e.[reference_number])) AS [Referencia],
               ctl.fn_Texto(CONVERT(nvarchar(max), e.[status])) AS [Estado],
               ctl.fn_FechaCR(CONVERT(nvarchar(60), e.[created_time])) AS [FechaCreacionOrigen],
               ctl.fn_FechaCR(CONVERT(nvarchar(60), e.[last_modified_time])) AS [FechaModificacionOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(max), e.[branch_name])) AS [Sucursal],
               fk_ClienteId_0.Id AS [ClienteId],
               ctl.fn_Texto(CONVERT(nvarchar(400), e.[customer_id])) AS [o_ClienteId],
               fk_ProveedorId_0.Id AS [ProveedorId],
               ctl.fn_Texto(CONVERT(nvarchar(400), e.[vendor_id])) AS [o_ProveedorId],
               (SELECT ctl.fn_Texto(t.tag_name) AS Etiqueta, ctl.fn_Texto(t.tag_option) AS Opcion
                         FROM ZBooks_Mirror.dbo.expense_tags t WHERE t.expense_id = TRY_CONVERT(bigint, e.expense_id)
                         FOR JSON PATH) AS [Etiquetas],
               ctl.fn_Texto(CONVERT(nvarchar(400), e.[date])) AS [o_Fecha],
               ctl.fn_Texto(CONVERT(nvarchar(400), e.[total])) AS [o_Total],
               ctl.fn_Texto(CONVERT(nvarchar(400), e.[total_without_tax])) AS [o_TotalSinImpuesto],
               ctl.fn_Texto(CONVERT(nvarchar(400), e.[created_time])) AS [o_FechaCreacionOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(400), e.[last_modified_time])) AS [o_FechaModificacionOrigen],
               NULLIF((SELECT ctl.fn_Texto(CONVERT(nvarchar(max), e.[currency_id])) AS [currency_id], ctl.fn_Texto(CONVERT(nvarchar(max), e.[is_billable])) AS [is_billable], ctl.fn_Texto(CONVERT(nvarchar(max), e.[is_personal])) AS [is_personal], ctl.fn_Texto(CONVERT(nvarchar(max), e.[customer_name])) AS [customer_name], ctl.fn_Texto(CONVERT(nvarchar(max), e.[vendor_name])) AS [vendor_name], ctl.fn_Texto(CONVERT(nvarchar(max), e.[expense_receipt_name])) AS [expense_receipt_name], ctl.fn_Texto(CONVERT(nvarchar(max), e.[distance])) AS [distance], ctl.fn_Texto(CONVERT(nvarchar(max), e.[mileage_rate])) AS [mileage_rate], ctl.fn_Texto(CONVERT(nvarchar(max), e.[mileage_unit])) AS [mileage_unit], ctl.fn_Texto(CONVERT(nvarchar(max), e.[mileage_type])) AS [mileage_type], ctl.fn_Texto(CONVERT(nvarchar(max), e.[expense_type])) AS [expense_type], ctl.fn_Texto(CONVERT(nvarchar(max), e.[report_id])) AS [report_id], ctl.fn_Texto(CONVERT(nvarchar(max), e.[branch_id])) AS [branch_id], ctl.fn_Texto(CONVERT(nvarchar(max), e.[start_reading])) AS [start_reading], ctl.fn_Texto(CONVERT(nvarchar(max), e.[end_reading])) AS [end_reading], ctl.fn_Texto(CONVERT(nvarchar(max), e.[report_name])) AS [report_name], ctl.fn_Texto(CONVERT(nvarchar(max), e.[report_number])) AS [report_number], ctl.fn_Texto(CONVERT(nvarchar(max), e.[has_attachment])) AS [has_attachment], ctl.fn_Texto(CONVERT(nvarchar(max), e.[custom_fields_list])) AS [custom_fields_list] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER), N'{}') AS [AtributosExtendidos],
               ctl.fn_Monto(CONVERT(nvarchar(60), e.[bcy_total])) AS [d_TotalCRC],
               ctl.fn_Monto(CONVERT(nvarchar(60), e.[bcy_total_without_tax])) AS [d_TotalSinImpuestoCRC]
        FROM ZBooks_Mirror.dbo.[expenses] e
        OUTER APPLY (SELECT CASE WHEN COUNT(DISTINCT zref.[ClienteId]) = 1 THEN MIN(zref.[ClienteId]) END AS Id FROM core.ClienteOrigen zref WHERE zref.Sistema = 'ZohoBooks' AND zref.LlaveOrigen = ctl.fn_Texto(CONVERT(nvarchar(max), e.[customer_id]))) fk_ClienteId_0
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[ProveedorId]) END AS Id FROM core.Proveedor zref WHERE zref.[ContactoBooksId] = ctl.fn_Texto(CONVERT(nvarchar(max), e.[vendor_id]))) fk_ProveedorId_0
        ) q
        OUTER APPLY (SELECT TOP 1 t.Venta FROM ref.TipoCambio t WHERE t.Fecha <= CAST(q.Fecha AS date) ORDER BY t.Fecha DESC) tc
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'GastoBooksId obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[GastoBooksId] IS NULL
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
    DELETE FROM #src WHERE [GastoBooksId] IS NULL OR [Fecha] IS NULL OR [FuenteLlave] IS NULL;

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
    SELECT t.[GastoId] AS RegistroId, t.FuenteLlave, (SELECT t.[GastoBooksId], t.[ProveedorId], t.[ClienteId], t.[Fecha], t.[Cuenta], t.[PagadoDesde], t.[Descripcion], t.[Estado], t.[Referencia], t.[Moneda], t.[TipoCambio], t.[Total], t.[TotalCRC], t.[TotalSinImpuesto], t.[TotalSinImpuestoCRC], t.[Etiquetas], t.[Sucursal], t.[AtributosExtendidos], t.[FechaCreacionOrigen], t.[FechaModificacionOrigen], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.Gasto t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido;

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.Gasto WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido) THEN
        UPDATE SET t.[GastoBooksId] = s.[GastoBooksId], t.[Fecha] = s.[Fecha], t.[PagadoDesde] = s.[PagadoDesde], t.[Cuenta] = s.[Cuenta], t.[Descripcion] = s.[Descripcion], t.[Moneda] = s.[Moneda], t.[Total] = s.[Total], t.[TotalSinImpuesto] = s.[TotalSinImpuesto], t.[Referencia] = s.[Referencia], t.[Estado] = s.[Estado], t.[FechaCreacionOrigen] = s.[FechaCreacionOrigen], t.[FechaModificacionOrigen] = s.[FechaModificacionOrigen], t.[Sucursal] = s.[Sucursal], t.[ClienteId] = s.[ClienteId], t.[ProveedorId] = s.[ProveedorId], t.[Etiquetas] = s.[Etiquetas], t.[AtributosExtendidos] = s.[AtributosExtendidos], t.[TotalCRC] = s.[TotalCRC], t.[TotalSinImpuestoCRC] = s.[TotalSinImpuestoCRC], t.[TipoCambio] = s.[TipoCambio], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([GastoBooksId], [Fecha], [PagadoDesde], [Cuenta], [Descripcion], [Moneda], [Total], [TotalSinImpuesto], [Referencia], [Estado], [FechaCreacionOrigen], [FechaModificacionOrigen], [Sucursal], [ClienteId], [ProveedorId], [Etiquetas], [AtributosExtendidos], [TotalCRC], [TotalSinImpuestoCRC], [TipoCambio], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[GastoBooksId], s.[Fecha], s.[PagadoDesde], s.[Cuenta], s.[Descripcion], s.[Moneda], s.[Total], s.[TotalSinImpuesto], s.[Referencia], s.[Estado], s.[FechaCreacionOrigen], s.[FechaModificacionOrigen], s.[Sucursal], s.[ClienteId], s.[ProveedorId], s.[Etiquetas], s.[AtributosExtendidos], s.[TotalCRC], s.[TotalSinImpuestoCRC], s.[TipoCambio], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[GastoId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.Gasto', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.Gasto', t.[GastoId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.Gasto t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.Gasto', t.[GastoId], N'ClienteId', LEFT(CONVERT(nvarchar(400), s.o_ClienteId), 400), N'Referencia sin correspondencia única en core.Cliente'
    FROM #src s JOIN core.Gasto t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_ClienteId IS NOT NULL AND s.[ClienteId] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.Gasto', t.[GastoId], N'ProveedorId', LEFT(CONVERT(nvarchar(400), s.o_ProveedorId), 400), N'Referencia sin correspondencia única en core.Proveedor'
    FROM #src s JOIN core.Gasto t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_ProveedorId IS NOT NULL AND s.[ProveedorId] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.Gasto', t.[GastoId], N'Fecha', LEFT(CONVERT(nvarchar(400), s.o_Fecha), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.Gasto t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Fecha IS NOT NULL AND s.[Fecha] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-04', N'core.Gasto', t.[GastoId], N'Total', LEFT(CONVERT(nvarchar(400), s.o_Total), 400), N'Monto ilegible; se conserva el texto original'
    FROM #src s JOIN core.Gasto t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Total IS NOT NULL AND s.[Total] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-04', N'core.Gasto', t.[GastoId], N'TotalSinImpuesto', LEFT(CONVERT(nvarchar(400), s.o_TotalSinImpuesto), 400), N'Monto ilegible; se conserva el texto original'
    FROM #src s JOIN core.Gasto t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_TotalSinImpuesto IS NOT NULL AND s.[TotalSinImpuesto] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.Gasto', t.[GastoId], N'FechaCreacionOrigen', LEFT(CONVERT(nvarchar(400), s.o_FechaCreacionOrigen), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.Gasto t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaCreacionOrigen IS NOT NULL AND s.[FechaCreacionOrigen] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.Gasto', t.[GastoId], N'FechaModificacionOrigen', LEFT(CONVERT(nvarchar(400), s.o_FechaModificacionOrigen), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.Gasto t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaModificacionOrigen IS NOT NULL AND s.[FechaModificacionOrigen] IS NULL;

    SELECT @Leidas AS FilasLeidas, @Validas - (SELECT COUNT_BIG(*) FROM #cambios) AS FilasSinCambio;
END;
GO
