USE ADN_Unificado;
GO
/* Paso 304 · core_Producto_ADNPayProducto → core.Producto
   Productos adicionales de la venta en línea (ADNPayV2.Product), en colones.
   Reglas: D5, ES-01, ES-04, ES-07, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_Producto_ADNPayProducto @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT CAST(q.[CodigoOrigen] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [CodigoOrigen],
           CAST(q.[Nombre] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [Nombre],
           CAST(q.[Descripcion] AS nvarchar(1000)) COLLATE DATABASE_DEFAULT AS [Descripcion],
           q.[Precio],
           q.[Activo],
           q.[FechaCreacionOrigen],
           q.[PrecioSinImpuesto],
           CAST(q.[Sistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [Sistema],
           q.[AtributosExtendidos] COLLATE DATABASE_DEFAULT AS [AtributosExtendidos],
           CAST(q.[Moneda] AS char(3)) COLLATE DATABASE_DEFAULT AS [Moneda],
           q.[PrecioCRC],
           q.[PrecioSinImpuestoCRC],
           q.[TipoCambio],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[CodigoOrigen]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Nombre]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Descripcion]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Precio]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Activo]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaCreacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[PrecioSinImpuesto]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Sistema]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[AtributosExtendidos]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Moneda]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[PrecioCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[PrecioSinImpuestoCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TipoCambio]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           CONCAT_WS(N',', CASE WHEN LEN(q.[CodigoOrigen]) > 50 THEN N'CodigoOrigen' END, CASE WHEN LEN(q.[Nombre]) > 200 THEN N'Nombre' END, CASE WHEN LEN(q.[Descripcion]) > 1000 THEN N'Descripcion' END, CASE WHEN LEN(q.[Sistema]) > 20 THEN N'Sistema' END, CASE WHEN LEN(q.[Moneda]) > 3 THEN N'Moneda' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT q.*,
               tx.Tasa AS TipoCambio,
               CASE q.Moneda WHEN 'CRC' THEN q.[Precio] WHEN 'USD' THEN CAST(q.[Precio] * tx.Tasa AS decimal(19,4)) END AS [PrecioCRC],
               CASE q.Moneda WHEN 'CRC' THEN q.[PrecioSinImpuesto] WHEN 'USD' THEN CAST(q.[PrecioSinImpuesto] * tx.Tasa AS decimal(19,4)) END AS [PrecioSinImpuestoCRC]
        FROM (
        SELECT 'ADNPayV2' AS FuenteSistema,
               N'ADNPayV2' AS FuenteBase,
               N'Product' AS FuenteTabla,
               ctl.fn_Texto(CONVERT(nvarchar(200), v.[product_id])) AS FuenteLlave,
               ctl.fn_FechaCR(CONVERT(nvarchar(30), v.[created_at], 126)) AS FechaDato,
               ctl.fn_Texto(CONVERT(nvarchar(max), v.[product_id])) AS [CodigoOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(max), v.[name])) AS [Nombre],
               ctl.fn_Texto(CONVERT(nvarchar(max), v.[description])) AS [Descripcion],
               TRY_CONVERT(decimal(19,4), v.[price_crc]) AS [Precio],
               v.[is_active] AS [Activo],
               ctl.fn_FechaCR(CONVERT(nvarchar(30), v.[created_at], 126)) AS [FechaCreacionOrigen],
               TRY_CONVERT(decimal(19,4), v.[price_without_tax]) AS [PrecioSinImpuesto],
               'ADNPayV2' AS [Sistema],
               CAST(NULL AS nvarchar(max)) AS [AtributosExtendidos],
               'CRC' AS [Moneda]
        FROM ADNPayV2.dbo.[Product] v
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
        UPDATE SET t.[CodigoOrigen] = s.[CodigoOrigen], t.[Nombre] = s.[Nombre], t.[Descripcion] = s.[Descripcion], t.[Precio] = s.[Precio], t.[Activo] = s.[Activo], t.[FechaCreacionOrigen] = s.[FechaCreacionOrigen], t.[PrecioSinImpuesto] = s.[PrecioSinImpuesto], t.[Sistema] = s.[Sistema], t.[AtributosExtendidos] = s.[AtributosExtendidos], t.[Moneda] = s.[Moneda], t.[PrecioCRC] = s.[PrecioCRC], t.[PrecioSinImpuestoCRC] = s.[PrecioSinImpuestoCRC], t.[TipoCambio] = s.[TipoCambio], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([CodigoOrigen], [Nombre], [Descripcion], [Precio], [Activo], [FechaCreacionOrigen], [PrecioSinImpuesto], [Sistema], [AtributosExtendidos], [Moneda], [PrecioCRC], [PrecioSinImpuestoCRC], [TipoCambio], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[CodigoOrigen], s.[Nombre], s.[Descripcion], s.[Precio], s.[Activo], s.[FechaCreacionOrigen], s.[PrecioSinImpuesto], s.[Sistema], s.[AtributosExtendidos], s.[Moneda], s.[PrecioCRC], s.[PrecioSinImpuestoCRC], s.[TipoCambio], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
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
    -- sin reglas de anomalía en este paso

    SELECT @Leidas AS FilasLeidas, @Validas - (SELECT COUNT_BIG(*) FROM #cambios) AS FilasSinCambio;
END;
GO
