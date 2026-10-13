USE ADN_Unificado;
GO
/* Paso 411 · core_FacturaLinea → core.FacturaLinea
   Líneas de factura de Books; heredan moneda y fecha de su factura (D5). Sin factura → descarte IN-01.
   Reglas: D5, ES-04, IN-01, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_FacturaLinea @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT CAST(q.[LineaBooksId] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [LineaBooksId],
           CAST(q.[Nombre] AS nvarchar(300)) COLLATE DATABASE_DEFAULT AS [Nombre],
           q.[Descripcion] COLLATE DATABASE_DEFAULT AS [Descripcion],
           q.[Cantidad],
           q.[PrecioUnitario],
           q.[Total],
           q.[FacturaId],
           q.[ProductoId],
           CAST(q.[Moneda] AS char(3)) COLLATE DATABASE_DEFAULT AS [Moneda],
           q.[PrecioUnitarioCRC],
           q.[TotalCRC],
           q.[TipoCambio],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[LineaBooksId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Nombre]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Descripcion]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Cantidad]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[PrecioUnitario]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Total]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FacturaId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ProductoId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Moneda]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[PrecioUnitarioCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TotalCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TipoCambio]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_FacturaId],
           q.[o_ProductoId],
           q.[o_PrecioUnitario],
           q.[o_Total],
           CONCAT_WS(N',', CASE WHEN LEN(q.[LineaBooksId]) > 30 THEN N'LineaBooksId' END, CASE WHEN LEN(q.[Nombre]) > 300 THEN N'Nombre' END, CASE WHEN LEN(q.[Moneda]) > 3 THEN N'Moneda' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT q.*,
               CASE q.Moneda WHEN 'CRC' THEN CAST(1 AS decimal(19,6)) WHEN 'USD' THEN tc.Venta END AS TipoCambio,
               CASE q.Moneda WHEN 'CRC' THEN q.[PrecioUnitario] WHEN 'USD' THEN CAST(q.[PrecioUnitario] * tc.Venta AS decimal(19,4)) END AS [PrecioUnitarioCRC],
               CASE q.Moneda WHEN 'CRC' THEN q.[Total] WHEN 'USD' THEN CAST(q.[Total] * tc.Venta AS decimal(19,4)) END AS [TotalCRC]
        FROM (
        SELECT 'ZohoBooks' AS FuenteSistema,
               N'ZBooks_Mirror' AS FuenteBase,
               N'invoices_items' AS FuenteTabla,
               ctl.fn_Texto(CONVERT(nvarchar(200), l.[line_item_id])) AS FuenteLlave,
               TODATETIMEOFFSET(CAST(f.Fecha AS datetime2), '-06:00') AS FechaDato,
               ctl.fn_Texto(CONVERT(nvarchar(max), l.[line_item_id])) AS [LineaBooksId],
               ctl.fn_Texto(CONVERT(nvarchar(max), l.[name])) AS [Nombre],
               ctl.fn_Texto(CONVERT(nvarchar(max), CONVERT(nvarchar(max), l.[description]))) AS [Descripcion],
               TRY_CONVERT(decimal(12,2), ctl.fn_PrimerNumero(CONVERT(nvarchar(255), l.[quantity]))) AS [Cantidad],
               ctl.fn_Monto(CONVERT(nvarchar(60), l.[rate])) AS [PrecioUnitario],
               ctl.fn_Monto(CONVERT(nvarchar(60), l.[total])) AS [Total],
               fk_FacturaId_0.Id AS [FacturaId],
               ctl.fn_Texto(CONVERT(nvarchar(400), l.[invoice_id])) AS [o_FacturaId],
               fk_ProductoId_0.Id AS [ProductoId],
               ctl.fn_Texto(CONVERT(nvarchar(400), l.[item_id])) AS [o_ProductoId],
               f.Moneda AS [Moneda],
               ctl.fn_Texto(CONVERT(nvarchar(400), l.[rate])) AS [o_PrecioUnitario],
               ctl.fn_Texto(CONVERT(nvarchar(400), l.[total])) AS [o_Total]
        FROM ZBooks_Mirror.dbo.[invoices_items] l
        LEFT JOIN core.Factura f ON f.FacturaBooksId = ctl.fn_Texto(l.invoice_id)
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[FacturaId]) END AS Id FROM core.Factura zref WHERE zref.[FacturaBooksId] = ctl.fn_Texto(CONVERT(nvarchar(max), l.[invoice_id]))) fk_FacturaId_0
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[ProductoId]) END AS Id FROM core.Producto zref WHERE zref.[ProductoCrmId] = ctl.fn_Texto(CONVERT(nvarchar(max), l.[item_id])) OR zref.[ItemBooksId] = ctl.fn_Texto(CONVERT(nvarchar(max), l.[item_id]))) fk_ProductoId_0
        ) q
        OUTER APPLY (SELECT TOP 1 t.Venta FROM ref.TipoCambio t WHERE t.Fecha <= CAST(q.FechaDato AS date) ORDER BY t.Fecha DESC) tc
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'LineaBooksId obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[LineaBooksId] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'IN-01', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FacturaId obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FacturaId] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'IN-01' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FuenteLlave obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FuenteLlave] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE FROM #src WHERE [LineaBooksId] IS NULL OR [FacturaId] IS NULL OR [FuenteLlave] IS NULL;

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
    SELECT t.[FacturaLineaId] AS RegistroId, t.FuenteLlave, (SELECT t.[LineaBooksId], t.[FacturaId], t.[ProductoId], t.[Nombre], t.[Descripcion], t.[Cantidad], t.[Moneda], t.[TipoCambio], t.[PrecioUnitario], t.[PrecioUnitarioCRC], t.[Total], t.[TotalCRC], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.FacturaLinea t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido;

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.FacturaLinea WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido) THEN
        UPDATE SET t.[LineaBooksId] = s.[LineaBooksId], t.[Nombre] = s.[Nombre], t.[Descripcion] = s.[Descripcion], t.[Cantidad] = s.[Cantidad], t.[PrecioUnitario] = s.[PrecioUnitario], t.[Total] = s.[Total], t.[FacturaId] = s.[FacturaId], t.[ProductoId] = s.[ProductoId], t.[Moneda] = s.[Moneda], t.[PrecioUnitarioCRC] = s.[PrecioUnitarioCRC], t.[TotalCRC] = s.[TotalCRC], t.[TipoCambio] = s.[TipoCambio], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([LineaBooksId], [Nombre], [Descripcion], [Cantidad], [PrecioUnitario], [Total], [FacturaId], [ProductoId], [Moneda], [PrecioUnitarioCRC], [TotalCRC], [TipoCambio], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[LineaBooksId], s.[Nombre], s.[Descripcion], s.[Cantidad], s.[PrecioUnitario], s.[Total], s.[FacturaId], s.[ProductoId], s.[Moneda], s.[PrecioUnitarioCRC], s.[TotalCRC], s.[TipoCambio], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[FacturaLineaId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.FacturaLinea', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.FacturaLinea', t.[FacturaLineaId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.FacturaLinea t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.FacturaLinea', t.[FacturaLineaId], N'FacturaId', LEFT(CONVERT(nvarchar(400), s.o_FacturaId), 400), N'Referencia sin correspondencia única en core.Factura'
    FROM #src s JOIN core.FacturaLinea t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FacturaId IS NOT NULL AND s.[FacturaId] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.FacturaLinea', t.[FacturaLineaId], N'ProductoId', LEFT(CONVERT(nvarchar(400), s.o_ProductoId), 400), N'Referencia sin correspondencia única en core.Producto'
    FROM #src s JOIN core.FacturaLinea t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_ProductoId IS NOT NULL AND s.[ProductoId] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-04', N'core.FacturaLinea', t.[FacturaLineaId], N'PrecioUnitario', LEFT(CONVERT(nvarchar(400), s.o_PrecioUnitario), 400), N'Monto ilegible; se conserva el texto original'
    FROM #src s JOIN core.FacturaLinea t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_PrecioUnitario IS NOT NULL AND s.[PrecioUnitario] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-04', N'core.FacturaLinea', t.[FacturaLineaId], N'Total', LEFT(CONVERT(nvarchar(400), s.o_Total), 400), N'Monto ilegible; se conserva el texto original'
    FROM #src s JOIN core.FacturaLinea t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Total IS NOT NULL AND s.[Total] IS NULL;

    SELECT @Leidas AS FilasLeidas, @Validas - (SELECT COUNT_BIG(*) FROM #cambios) AS FilasSinCambio;
END;
GO
