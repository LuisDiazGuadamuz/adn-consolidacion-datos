USE ADN_Unificado;
GO
/* Paso 301 · core_Producto_Books → core.Producto
   Artículos de Books que no están en el CRM. Los ligados a un producto del CRM solo completan su id de Books (paso siguiente). Precios en la moneda base de Books (CRC).
   Reglas: D5, ES-01, ES-02, ES-04, ES-07, IN-01, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_Producto_Books @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT CAST(q.[Nombre] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [Nombre],
           CAST(q.[Unidad] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [Unidad],
           q.[Activo],
           CAST(q.[Descripcion] AS nvarchar(1000)) COLLATE DATABASE_DEFAULT AS [Descripcion],
           q.[Precio],
           CAST(q.[Tipo] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Tipo],
           CAST(q.[Categoria] AS nvarchar(100)) COLLATE DATABASE_DEFAULT AS [Categoria],
           q.[FechaCreacionOrigen],
           q.[FechaModificacionOrigen],
           q.[ImpuestoId],
           CAST(q.[Sistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [Sistema],
           CAST(q.[ItemBooksId] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [ItemBooksId],
           CAST(q.[ProductoCrmId] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [ProductoCrmId],
           CAST(q.[Moneda] AS char(3)) COLLATE DATABASE_DEFAULT AS [Moneda],
           q.[AtributosExtendidos] COLLATE DATABASE_DEFAULT AS [AtributosExtendidos],
           q.[PrecioCRC],
           q.[TipoCambio],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[Nombre]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Unidad]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Activo]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Descripcion]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Precio]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Tipo]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Categoria]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaCreacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaModificacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ImpuestoId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Sistema]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ItemBooksId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ProductoCrmId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Moneda]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[AtributosExtendidos]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[PrecioCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TipoCambio]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_ImpuestoId],
           q.[o_Precio],
           q.[o_FechaCreacionOrigen],
           q.[o_FechaModificacionOrigen],
           CONCAT_WS(N',', CASE WHEN LEN(q.[Nombre]) > 200 THEN N'Nombre' END, CASE WHEN LEN(q.[Unidad]) > 30 THEN N'Unidad' END, CASE WHEN LEN(q.[Descripcion]) > 1000 THEN N'Descripcion' END, CASE WHEN LEN(q.[Tipo]) > 50 THEN N'Tipo' END, CASE WHEN LEN(q.[Categoria]) > 100 THEN N'Categoria' END, CASE WHEN LEN(q.[Sistema]) > 20 THEN N'Sistema' END, CASE WHEN LEN(q.[ItemBooksId]) > 30 THEN N'ItemBooksId' END, CASE WHEN LEN(q.[ProductoCrmId]) > 30 THEN N'ProductoCrmId' END, CASE WHEN LEN(q.[Moneda]) > 3 THEN N'Moneda' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT q.*,
               tx.Tasa AS TipoCambio,
               CASE q.Moneda WHEN 'CRC' THEN q.[Precio] WHEN 'USD' THEN CAST(q.[Precio] * tx.Tasa AS decimal(19,4)) END AS [PrecioCRC]
        FROM (
        SELECT 'ZohoBooks' AS FuenteSistema,
               N'ZBooks_Mirror' AS FuenteBase,
               N'items' AS FuenteTabla,
               ctl.fn_Texto(CONVERT(nvarchar(200), i.[item_id])) AS FuenteLlave,
               ctl.fn_FechaCR(CONVERT(nvarchar(60), i.[created_time])) AS FechaDato,
               ctl.fn_Texto(CONVERT(nvarchar(max), i.[name])) AS [Nombre],
               ctl.fn_Texto(CONVERT(nvarchar(max), i.[unit])) AS [Unidad],
               ctl.fn_Bit(CONVERT(nvarchar(20), i.[status])) AS [Activo],
               ctl.fn_Texto(CONVERT(nvarchar(max), i.[description])) AS [Descripcion],
               ctl.fn_Monto(CONVERT(nvarchar(60), i.[rate])) AS [Precio],
               ctl.fn_Texto(CONVERT(nvarchar(max), i.[item_type])) AS [Tipo],
               ctl.fn_Texto(CONVERT(nvarchar(max), i.[product_type])) AS [Categoria],
               ctl.fn_FechaCR(CONVERT(nvarchar(60), i.[created_time])) AS [FechaCreacionOrigen],
               ctl.fn_FechaCR(CONVERT(nvarchar(60), i.[last_modified_time])) AS [FechaModificacionOrigen],
               fk_ImpuestoId_0.Id AS [ImpuestoId],
               ctl.fn_Texto(CONVERT(nvarchar(400), i.[tax_id])) AS [o_ImpuestoId],
               'ZohoBooks' AS [Sistema],
               ctl.fn_Texto(i.item_id) AS [ItemBooksId],
               CAST(NULL AS nvarchar(30)) AS [ProductoCrmId],
               'CRC' AS [Moneda],
               ctl.fn_Texto(CONVERT(nvarchar(400), i.[rate])) AS [o_Precio],
               ctl.fn_Texto(CONVERT(nvarchar(400), i.[created_time])) AS [o_FechaCreacionOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(400), i.[last_modified_time])) AS [o_FechaModificacionOrigen],
               NULLIF((SELECT ctl.fn_Texto(CONVERT(nvarchar(max), i.[group_id])) AS [group_id], ctl.fn_Texto(CONVERT(nvarchar(max), i.[group_name])) AS [group_name], ctl.fn_Texto(CONVERT(nvarchar(max), i.[item_name])) AS [item_name], ctl.fn_Texto(CONVERT(nvarchar(max), i.[source])) AS [source], ctl.fn_Texto(CONVERT(nvarchar(max), i.[is_combo_product])) AS [is_combo_product], ctl.fn_Texto(CONVERT(nvarchar(max), i.[is_linked_with_zohocrm])) AS [is_linked_with_zohocrm], ctl.fn_Texto(CONVERT(nvarchar(max), i.[brand])) AS [brand], ctl.fn_Texto(CONVERT(nvarchar(max), i.[manufacturer])) AS [manufacturer], ctl.fn_Texto(CONVERT(nvarchar(max), i.[tax_name])) AS [tax_name], ctl.fn_Texto(CONVERT(nvarchar(max), i.[tax_percentage])) AS [tax_percentage], ctl.fn_Texto(CONVERT(nvarchar(max), i.[purchase_account_id])) AS [purchase_account_id], ctl.fn_Texto(CONVERT(nvarchar(max), i.[purchase_account_name])) AS [purchase_account_name], ctl.fn_Texto(CONVERT(nvarchar(max), i.[account_id])) AS [account_id], ctl.fn_Texto(CONVERT(nvarchar(max), i.[account_name])) AS [account_name], ctl.fn_Texto(CONVERT(nvarchar(max), i.[purchase_description])) AS [purchase_description], ctl.fn_Texto(CONVERT(nvarchar(max), i.[purchase_rate])) AS [purchase_rate], ctl.fn_Texto(CONVERT(nvarchar(max), i.[has_attachment])) AS [has_attachment], ctl.fn_Texto(CONVERT(nvarchar(max), i.[is_returnable])) AS [is_returnable], ctl.fn_Texto(CONVERT(nvarchar(max), i.[attribute_id1])) AS [attribute_id1], ctl.fn_Texto(CONVERT(nvarchar(max), i.[attribute_id2])) AS [attribute_id2], ctl.fn_Texto(CONVERT(nvarchar(max), i.[attribute_id3])) AS [attribute_id3], ctl.fn_Texto(CONVERT(nvarchar(max), i.[attribute_name1])) AS [attribute_name1], ctl.fn_Texto(CONVERT(nvarchar(max), i.[attribute_name2])) AS [attribute_name2], ctl.fn_Texto(CONVERT(nvarchar(max), i.[attribute_name3])) AS [attribute_name3], ctl.fn_Texto(CONVERT(nvarchar(max), i.[attribute_type1])) AS [attribute_type1], ctl.fn_Texto(CONVERT(nvarchar(max), i.[attribute_type2])) AS [attribute_type2], ctl.fn_Texto(CONVERT(nvarchar(max), i.[attribute_type3])) AS [attribute_type3], ctl.fn_Texto(CONVERT(nvarchar(max), i.[attribute_option_id1])) AS [attribute_option_id1], ctl.fn_Texto(CONVERT(nvarchar(max), i.[attribute_option_id2])) AS [attribute_option_id2], ctl.fn_Texto(CONVERT(nvarchar(max), i.[attribute_option_id3])) AS [attribute_option_id3], ctl.fn_Texto(CONVERT(nvarchar(max), i.[attribute_option_name1])) AS [attribute_option_name1], ctl.fn_Texto(CONVERT(nvarchar(max), i.[attribute_option_name2])) AS [attribute_option_name2], ctl.fn_Texto(CONVERT(nvarchar(max), i.[attribute_option_name3])) AS [attribute_option_name3], ctl.fn_Texto(CONVERT(nvarchar(max), i.[attribute_option_data1])) AS [attribute_option_data1], ctl.fn_Texto(CONVERT(nvarchar(max), i.[attribute_option_data2])) AS [attribute_option_data2], ctl.fn_Texto(CONVERT(nvarchar(max), i.[attribute_option_data3])) AS [attribute_option_data3], ctl.fn_Texto(CONVERT(nvarchar(max), i.[sku])) AS [sku], ctl.fn_Texto(CONVERT(nvarchar(max), i.[upc])) AS [upc], ctl.fn_Texto(CONVERT(nvarchar(max), i.[ean])) AS [ean], ctl.fn_Texto(CONVERT(nvarchar(max), i.[isbn])) AS [isbn], ctl.fn_Texto(CONVERT(nvarchar(max), i.[part_number])) AS [part_number], ctl.fn_Texto(CONVERT(nvarchar(max), i.[track_serial_number])) AS [track_serial_number], ctl.fn_Texto(CONVERT(nvarchar(max), i.[image_name])) AS [image_name], ctl.fn_Texto(CONVERT(nvarchar(max), i.[image_type])) AS [image_type], ctl.fn_Texto(CONVERT(nvarchar(max), i.[show_in_storefront])) AS [show_in_storefront], ctl.fn_Texto(CONVERT(nvarchar(max), i.[length])) AS [length], ctl.fn_Texto(CONVERT(nvarchar(max), i.[width])) AS [width], ctl.fn_Texto(CONVERT(nvarchar(max), i.[height])) AS [height], ctl.fn_Texto(CONVERT(nvarchar(max), i.[weight])) AS [weight], ctl.fn_Texto(CONVERT(nvarchar(max), i.[weight_unit])) AS [weight_unit], ctl.fn_Texto(CONVERT(nvarchar(max), i.[dimension_unit])) AS [dimension_unit], ctl.fn_Texto(CONVERT(nvarchar(max), i.[odoo])) AS [odoo] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER), N'{}') AS [AtributosExtendidos]
        FROM ZBooks_Mirror.dbo.[items] i
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[ImpuestoId]) END AS Id FROM ref.Impuesto zref WHERE zref.[ImpuestoBooksId] = ctl.fn_Texto(CONVERT(nvarchar(max), i.[tax_id])) OR zref.[Nombre] = ctl.fn_Texto(CONVERT(nvarchar(max), i.[tax_id]))) fk_ImpuestoId_0
        WHERE NOT EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.Products p WHERE p.id = i.zcrm_product_id)
        ) q
        OUTER APPLY (SELECT TOP 1 t.Venta FROM ref.TipoCambio t WHERE t.Fecha <= CAST(q.FechaCreacionOrigen AS date) ORDER BY t.Fecha DESC) tc
        CROSS APPLY (SELECT CASE q.Moneda WHEN 'CRC' THEN CAST(1 AS decimal(19,6)) WHEN 'USD' THEN COALESCE(tc.Venta, NULL) END AS Tasa) tx
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'Sistema obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[Sistema] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FuenteLlave obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FuenteLlave] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE FROM #src WHERE [Sistema] IS NULL OR [FuenteLlave] IS NULL;

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
    SELECT t.[ProductoId] AS RegistroId, t.FuenteLlave, (SELECT t.[Sistema], t.[ProductoCrmId], t.[ItemBooksId], t.[CodigoOrigen], t.[Nombre], t.[Descripcion], t.[Tipo], t.[Categoria], t.[Unidad], t.[CodigoCabys], t.[ImpuestoId], t.[Moneda], t.[TipoCambio], t.[Precio], t.[PrecioCRC], t.[PrecioSinImpuesto], t.[PrecioSinImpuestoCRC], t.[VelocidadDescargaMbps], t.[VelocidadCargaMbps], t.[IncluyeIPTV], t.[IncluyeTelefonia], t.[IncluyeIPPublica], t.[Activo], t.[AtributosExtendidos], t.[FechaCreacionOrigen], t.[FechaModificacionOrigen], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.Producto t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido;

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.Producto WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido) THEN
        UPDATE SET t.[Nombre] = s.[Nombre], t.[Unidad] = s.[Unidad], t.[Activo] = s.[Activo], t.[Descripcion] = s.[Descripcion], t.[Precio] = s.[Precio], t.[Tipo] = s.[Tipo], t.[Categoria] = s.[Categoria], t.[FechaCreacionOrigen] = s.[FechaCreacionOrigen], t.[FechaModificacionOrigen] = s.[FechaModificacionOrigen], t.[ImpuestoId] = s.[ImpuestoId], t.[Sistema] = s.[Sistema], t.[ItemBooksId] = s.[ItemBooksId], t.[ProductoCrmId] = s.[ProductoCrmId], t.[Moneda] = s.[Moneda], t.[AtributosExtendidos] = s.[AtributosExtendidos], t.[PrecioCRC] = s.[PrecioCRC], t.[TipoCambio] = s.[TipoCambio], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([Nombre], [Unidad], [Activo], [Descripcion], [Precio], [Tipo], [Categoria], [FechaCreacionOrigen], [FechaModificacionOrigen], [ImpuestoId], [Sistema], [ItemBooksId], [ProductoCrmId], [Moneda], [AtributosExtendidos], [PrecioCRC], [TipoCambio], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[Nombre], s.[Unidad], s.[Activo], s.[Descripcion], s.[Precio], s.[Tipo], s.[Categoria], s.[FechaCreacionOrigen], s.[FechaModificacionOrigen], s.[ImpuestoId], s.[Sistema], s.[ItemBooksId], s.[ProductoCrmId], s.[Moneda], s.[AtributosExtendidos], s.[PrecioCRC], s.[TipoCambio], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[ProductoId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.Producto', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.Producto', t.[ProductoId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.Producto t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.Producto', t.[ProductoId], N'ImpuestoId', LEFT(CONVERT(nvarchar(400), s.o_ImpuestoId), 400), N'Referencia sin correspondencia única en ref.Impuesto'
    FROM #src s JOIN core.Producto t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_ImpuestoId IS NOT NULL AND s.[ImpuestoId] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-04', N'core.Producto', t.[ProductoId], N'Precio', LEFT(CONVERT(nvarchar(400), s.o_Precio), 400), N'Monto ilegible; se conserva el texto original'
    FROM #src s JOIN core.Producto t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Precio IS NOT NULL AND s.[Precio] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.Producto', t.[ProductoId], N'FechaCreacionOrigen', LEFT(CONVERT(nvarchar(400), s.o_FechaCreacionOrigen), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.Producto t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaCreacionOrigen IS NOT NULL AND s.[FechaCreacionOrigen] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.Producto', t.[ProductoId], N'FechaModificacionOrigen', LEFT(CONVERT(nvarchar(400), s.o_FechaModificacionOrigen), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.Producto t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaModificacionOrigen IS NOT NULL AND s.[FechaModificacionOrigen] IS NULL;

    SELECT @Leidas AS FilasLeidas, @Validas - (SELECT COUNT_BIG(*) FROM #cambios) AS FilasSinCambio;
END;
GO
