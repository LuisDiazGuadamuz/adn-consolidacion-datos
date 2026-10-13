USE ADN_Unificado;
GO
/* Paso 324 · core_OrdenVentaLinea → core.OrdenVentaLinea
   Líneas de las órdenes de venta; heredan moneda y fecha de su orden (D5). Sin orden → descarte IN-01.
   Reglas: D5, DD-06, ES-04, IN-01, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_OrdenVentaLinea @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT q.[Impuesto],
           CAST(q.[Descripcion] AS nvarchar(1000)) COLLATE DATABASE_DEFAULT AS [Descripcion],
           q.[PrecioUnitario],
           q.[Total],
           q.[Descuento],
           q.[Cantidad],
           q.[ProductoId],
           q.[OrdenVentaId],
           CAST(q.[Moneda] AS char(3)) COLLATE DATABASE_DEFAULT AS [Moneda],
           q.[PrecioUnitarioCRC],
           q.[DescuentoCRC],
           q.[ImpuestoCRC],
           q.[TotalCRC],
           q.[TipoCambio],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[Impuesto]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Descripcion]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[PrecioUnitario]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Total]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Descuento]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Cantidad]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ProductoId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[OrdenVentaId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Moneda]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[PrecioUnitarioCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[DescuentoCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ImpuestoCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TotalCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TipoCambio]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_OrdenEliminada],
           q.[o_ProductoId],
           q.[o_OrdenVentaId],
           q.[o_Impuesto],
           q.[o_PrecioUnitario],
           q.[o_Total],
           q.[o_Descuento],
           q.[o_Eliminado],
           CONCAT_WS(N',', CASE WHEN LEN(q.[Descripcion]) > 1000 THEN N'Descripcion' END, CASE WHEN LEN(q.[Moneda]) > 3 THEN N'Moneda' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT q.*,
               CASE q.Moneda WHEN 'CRC' THEN CAST(1 AS decimal(19,6)) WHEN 'USD' THEN tc.Venta END AS TipoCambio,
               CASE q.Moneda WHEN 'CRC' THEN q.[PrecioUnitario] WHEN 'USD' THEN CAST(q.[PrecioUnitario] * tc.Venta AS decimal(19,4)) END AS [PrecioUnitarioCRC],
               CASE q.Moneda WHEN 'CRC' THEN q.[Descuento] WHEN 'USD' THEN CAST(q.[Descuento] * tc.Venta AS decimal(19,4)) END AS [DescuentoCRC],
               CASE q.Moneda WHEN 'CRC' THEN q.[Impuesto] WHEN 'USD' THEN CAST(q.[Impuesto] * tc.Venta AS decimal(19,4)) END AS [ImpuestoCRC],
               CASE q.Moneda WHEN 'CRC' THEN q.[Total] WHEN 'USD' THEN CAST(q.[Total] * tc.Venta AS decimal(19,4)) END AS [TotalCRC]
        FROM (
        SELECT 'ZohoCRM' AS FuenteSistema,
               N'Zoho_Mirror' AS FuenteBase,
               N'Sales_Orders_Products' AS FuenteTabla,
               ctl.fn_Texto(CONVERT(nvarchar(200), l.[id])) AS FuenteLlave,
               ov.FechaCreacionOrigen AS FechaDato,
               ctl.fn_Monto(CONVERT(nvarchar(60), l.[line_tax])) AS [Impuesto],
               ctl.fn_Texto(CONVERT(nvarchar(max), CONVERT(nvarchar(max), l.[product_description]))) AS [Descripcion],
               ctl.fn_Monto(CONVERT(nvarchar(60), l.[unit_price])) AS [PrecioUnitario],
               ctl.fn_Monto(CONVERT(nvarchar(60), l.[net_total])) AS [Total],
               ctl.fn_Monto(CONVERT(nvarchar(60), l.[Discount])) AS [Descuento],
               TRY_CONVERT(decimal(12,2), ctl.fn_PrimerNumero(CONVERT(nvarchar(255), l.[quantity]))) AS [Cantidad],
               fk_ProductoId_0.Id AS [ProductoId],
               ctl.fn_Texto(CONVERT(nvarchar(400), l.[product])) AS [o_ProductoId],
               fk_OrdenVentaId_0.Id AS [OrdenVentaId],
               ctl.fn_Texto(CONVERT(nvarchar(400), l.[sales_order])) AS [o_OrdenVentaId],
               ov.Moneda AS [Moneda],
               CASE WHEN EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.Sales_Orders so WHERE so.id = l.sales_order AND so.deleted = 1) THEN 1 ELSE 0 END AS [o_OrdenEliminada],
               ctl.fn_Texto(CONVERT(nvarchar(400), l.[line_tax])) AS [o_Impuesto],
               ctl.fn_Texto(CONVERT(nvarchar(400), l.[unit_price])) AS [o_PrecioUnitario],
               ctl.fn_Texto(CONVERT(nvarchar(400), l.[net_total])) AS [o_Total],
               ctl.fn_Texto(CONVERT(nvarchar(400), l.[Discount])) AS [o_Descuento],
               CAST(ISNULL(l.[deleted], 0) AS int) AS [o_Eliminado]
        FROM Zoho_Mirror.dbo.[Sales_Orders_Products] l
        LEFT JOIN core.OrdenVenta ov ON ov.OrdenVentaCrmId = ctl.fn_Texto(l.sales_order)
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[ProductoId]) END AS Id FROM core.Producto zref WHERE zref.[ProductoCrmId] = ctl.fn_Texto(CONVERT(nvarchar(max), l.[product])) OR zref.[ItemBooksId] = ctl.fn_Texto(CONVERT(nvarchar(max), l.[product]))) fk_ProductoId_0
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[OrdenVentaId]) END AS Id FROM core.OrdenVenta zref WHERE zref.[OrdenVentaCrmId] = ctl.fn_Texto(CONVERT(nvarchar(max), l.[sales_order]))) fk_OrdenVentaId_0
        ) q
        OUTER APPLY (SELECT TOP 1 t.Venta FROM ref.TipoCambio t WHERE t.Fecha <= CAST(q.FechaDato AS date) ORDER BY t.Fecha DESC) tc
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 2. Filtros de carga: filas excluidas con la regla que las excluye (DD-06) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'DD-06', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'Línea de una orden de venta eliminada en Zoho', @Ahora FROM #src s WHERE s.o_OrdenEliminada = 1
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'DD-06' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE s FROM #src s WHERE s.o_OrdenEliminada = 1;
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'DD-06', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'Registro marcado como eliminado en el origen (deleted = 1)', @Ahora FROM #src s WHERE s.o_Eliminado = 1
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'DD-06' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE s FROM #src s WHERE s.o_Eliminado = 1;
    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'IN-01', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'OrdenVentaId obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[OrdenVentaId] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'IN-01' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FuenteLlave obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FuenteLlave] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE FROM #src WHERE [OrdenVentaId] IS NULL OR [FuenteLlave] IS NULL;

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
    SELECT t.[OrdenVentaLineaId] AS RegistroId, t.FuenteLlave, (SELECT t.[OrdenVentaId], t.[ProductoId], t.[Descripcion], t.[Cantidad], t.[Moneda], t.[TipoCambio], t.[PrecioUnitario], t.[PrecioUnitarioCRC], t.[Descuento], t.[DescuentoCRC], t.[Impuesto], t.[ImpuestoCRC], t.[Total], t.[TotalCRC], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.OrdenVentaLinea t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido;

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.OrdenVentaLinea WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido) THEN
        UPDATE SET t.[Impuesto] = s.[Impuesto], t.[Descripcion] = s.[Descripcion], t.[PrecioUnitario] = s.[PrecioUnitario], t.[Total] = s.[Total], t.[Descuento] = s.[Descuento], t.[Cantidad] = s.[Cantidad], t.[ProductoId] = s.[ProductoId], t.[OrdenVentaId] = s.[OrdenVentaId], t.[Moneda] = s.[Moneda], t.[PrecioUnitarioCRC] = s.[PrecioUnitarioCRC], t.[DescuentoCRC] = s.[DescuentoCRC], t.[ImpuestoCRC] = s.[ImpuestoCRC], t.[TotalCRC] = s.[TotalCRC], t.[TipoCambio] = s.[TipoCambio], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([Impuesto], [Descripcion], [PrecioUnitario], [Total], [Descuento], [Cantidad], [ProductoId], [OrdenVentaId], [Moneda], [PrecioUnitarioCRC], [DescuentoCRC], [ImpuestoCRC], [TotalCRC], [TipoCambio], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[Impuesto], s.[Descripcion], s.[PrecioUnitario], s.[Total], s.[Descuento], s.[Cantidad], s.[ProductoId], s.[OrdenVentaId], s.[Moneda], s.[PrecioUnitarioCRC], s.[DescuentoCRC], s.[ImpuestoCRC], s.[TotalCRC], s.[TipoCambio], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[OrdenVentaLineaId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.OrdenVentaLinea', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.OrdenVentaLinea', t.[OrdenVentaLineaId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.OrdenVentaLinea t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.OrdenVentaLinea', t.[OrdenVentaLineaId], N'ProductoId', LEFT(CONVERT(nvarchar(400), s.o_ProductoId), 400), N'Referencia sin correspondencia única en core.Producto'
    FROM #src s JOIN core.OrdenVentaLinea t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_ProductoId IS NOT NULL AND s.[ProductoId] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.OrdenVentaLinea', t.[OrdenVentaLineaId], N'OrdenVentaId', LEFT(CONVERT(nvarchar(400), s.o_OrdenVentaId), 400), N'Referencia sin correspondencia única en core.OrdenVenta'
    FROM #src s JOIN core.OrdenVentaLinea t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_OrdenVentaId IS NOT NULL AND s.[OrdenVentaId] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-04', N'core.OrdenVentaLinea', t.[OrdenVentaLineaId], N'Impuesto', LEFT(CONVERT(nvarchar(400), s.o_Impuesto), 400), N'Monto ilegible; se conserva el texto original'
    FROM #src s JOIN core.OrdenVentaLinea t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Impuesto IS NOT NULL AND s.[Impuesto] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-04', N'core.OrdenVentaLinea', t.[OrdenVentaLineaId], N'PrecioUnitario', LEFT(CONVERT(nvarchar(400), s.o_PrecioUnitario), 400), N'Monto ilegible; se conserva el texto original'
    FROM #src s JOIN core.OrdenVentaLinea t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_PrecioUnitario IS NOT NULL AND s.[PrecioUnitario] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-04', N'core.OrdenVentaLinea', t.[OrdenVentaLineaId], N'Total', LEFT(CONVERT(nvarchar(400), s.o_Total), 400), N'Monto ilegible; se conserva el texto original'
    FROM #src s JOIN core.OrdenVentaLinea t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Total IS NOT NULL AND s.[Total] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-04', N'core.OrdenVentaLinea', t.[OrdenVentaLineaId], N'Descuento', LEFT(CONVERT(nvarchar(400), s.o_Descuento), 400), N'Monto ilegible; se conserva el texto original'
    FROM #src s JOIN core.OrdenVentaLinea t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Descuento IS NOT NULL AND s.[Descuento] IS NULL;

    SELECT @Leidas AS FilasLeidas, @Validas - (SELECT COUNT_BIG(*) FROM #cambios) AS FilasSinCambio;
END;
GO
