USE ADN_Unificado;
GO
/* Paso 300 · core_Producto_CRM → core.Producto
   Productos del CRM (catálogo principal). El impuesto se vincula por nombre o id de Books.
   Reglas: D5, DD-06, ES-01, ES-02, ES-04, ES-07, IN-01, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_Producto_CRM @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT q.[Precio],
           CAST(q.[CodigoCabys] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [CodigoCabys],
           CAST(q.[Nombre] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [Nombre],
           CAST(q.[Tipo] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Tipo],
           q.[FechaCreacionOrigen],
           q.[FechaModificacionOrigen],
           CAST(q.[Unidad] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [Unidad],
           q.[Activo],
           CAST(q.[Descripcion] AS nvarchar(1000)) COLLATE DATABASE_DEFAULT AS [Descripcion],
           CAST(q.[Categoria] AS nvarchar(100)) COLLATE DATABASE_DEFAULT AS [Categoria],
           q.[ImpuestoId],
           CAST(q.[Sistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [Sistema],
           CAST(q.[ProductoCrmId] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [ProductoCrmId],
           q.[AtributosExtendidos] COLLATE DATABASE_DEFAULT AS [AtributosExtendidos],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[Precio]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[CodigoCabys]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Nombre]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Tipo]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaCreacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaModificacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Unidad]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Activo]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Descripcion]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Categoria]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ImpuestoId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Sistema]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ProductoCrmId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[AtributosExtendidos]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_ImpuestoId],
           q.[o_Precio],
           q.[o_FechaCreacionOrigen],
           q.[o_FechaModificacionOrigen],
           q.[o_Eliminado],
           CONCAT_WS(N',', CASE WHEN LEN(q.[CodigoCabys]) > 30 THEN N'CodigoCabys' END, CASE WHEN LEN(q.[Nombre]) > 200 THEN N'Nombre' END, CASE WHEN LEN(q.[Tipo]) > 50 THEN N'Tipo' END, CASE WHEN LEN(q.[Unidad]) > 30 THEN N'Unidad' END, CASE WHEN LEN(q.[Descripcion]) > 1000 THEN N'Descripcion' END, CASE WHEN LEN(q.[Categoria]) > 100 THEN N'Categoria' END, CASE WHEN LEN(q.[Sistema]) > 20 THEN N'Sistema' END, CASE WHEN LEN(q.[ProductoCrmId]) > 30 THEN N'ProductoCrmId' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT 'ZohoCRM' AS FuenteSistema,
               N'Zoho_Mirror' AS FuenteBase,
               N'Products' AS FuenteTabla,
               ctl.fn_Texto(CONVERT(nvarchar(200), p.[id])) AS FuenteLlave,
               ctl.fn_FechaCR(CONVERT(nvarchar(60), p.[Created_Time])) AS FechaDato,
               ctl.fn_Monto(CONVERT(nvarchar(60), p.[Unit_Price])) AS [Precio],
               ctl.fn_Texto(CONVERT(nvarchar(max), p.[C_digo_Cabyss])) AS [CodigoCabys],
               ctl.fn_Texto(CONVERT(nvarchar(max), p.[Product_Name])) AS [Nombre],
               ctl.fn_Texto(CONVERT(nvarchar(max), p.[Tipo_Producto])) AS [Tipo],
               ctl.fn_FechaCR(CONVERT(nvarchar(60), p.[Created_Time])) AS [FechaCreacionOrigen],
               ctl.fn_FechaCR(CONVERT(nvarchar(60), p.[Modified_Time])) AS [FechaModificacionOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(max), p.[Unidad_de_Medida])) AS [Unidad],
               ctl.fn_Bit(CONVERT(nvarchar(20), p.[Product_Active])) AS [Activo],
               ctl.fn_Texto(CONVERT(nvarchar(max), CONVERT(nvarchar(max), p.[Description]))) AS [Descripcion],
               ctl.fn_Texto(CONVERT(nvarchar(max), p.[Product_Category])) AS [Categoria],
               fk_ImpuestoId_0.Id AS [ImpuestoId],
               ctl.fn_Texto(CONVERT(nvarchar(400), p.[Tax])) AS [o_ImpuestoId],
               'ZohoCRM' AS [Sistema],
               ctl.fn_Texto(p.id) AS [ProductoCrmId],
               ctl.fn_Texto(CONVERT(nvarchar(400), p.[Unit_Price])) AS [o_Precio],
               ctl.fn_Texto(CONVERT(nvarchar(400), p.[Created_Time])) AS [o_FechaCreacionOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(400), p.[Modified_Time])) AS [o_FechaModificacionOrigen],
               NULLIF((SELECT ctl.fn_Texto(CONVERT(nvarchar(max), p.[Taxable])) AS [Taxable], ctl.fn_Texto(CONVERT(nvarchar(max), p.[Tag])) AS [Tag], ctl.fn_Texto(CONVERT(nvarchar(max), p.[Created_By])) AS [Created_By], ctl.fn_Texto(CONVERT(nvarchar(max), p.[Layout])) AS [Layout], ctl.fn_Texto(CONVERT(nvarchar(max), p.[Commission_Rate])) AS [Commission_Rate], ctl.fn_Texto(CONVERT(nvarchar(max), p.[Modified_By])) AS [Modified_By], ctl.fn_Texto(CONVERT(nvarchar(max), p.[Record_Image])) AS [Record_Image], ctl.fn_Texto(CONVERT(nvarchar(max), p.[Owner])) AS [Owner] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER), N'{}') AS [AtributosExtendidos],
               CAST(ISNULL(p.[deleted], 0) AS int) AS [o_Eliminado]
        FROM Zoho_Mirror.dbo.[Products] p
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(r.[ImpuestoId]) END AS Id FROM ref.Impuesto r WHERE r.[ImpuestoBooksId] = ctl.fn_Texto(CONVERT(nvarchar(max), p.[Tax])) OR r.[Nombre] = ctl.fn_Texto(CONVERT(nvarchar(max), p.[Tax]))) fk_ImpuestoId_0
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 2. Filtros de carga: filas excluidas con la regla que las excluye (DD-06) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'DD-06', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'Registro marcado como eliminado en el origen (deleted = 1)', @Ahora FROM #src s WHERE s.o_Eliminado = 1
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'DD-06' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE s FROM #src s WHERE s.o_Eliminado = 1;
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
        UPDATE SET t.[Precio] = s.[Precio], t.[CodigoCabys] = s.[CodigoCabys], t.[Nombre] = s.[Nombre], t.[Tipo] = s.[Tipo], t.[FechaCreacionOrigen] = s.[FechaCreacionOrigen], t.[FechaModificacionOrigen] = s.[FechaModificacionOrigen], t.[Unidad] = s.[Unidad], t.[Activo] = s.[Activo], t.[Descripcion] = s.[Descripcion], t.[Categoria] = s.[Categoria], t.[ImpuestoId] = s.[ImpuestoId], t.[Sistema] = s.[Sistema], t.[ProductoCrmId] = s.[ProductoCrmId], t.[AtributosExtendidos] = s.[AtributosExtendidos], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([Precio], [CodigoCabys], [Nombre], [Tipo], [FechaCreacionOrigen], [FechaModificacionOrigen], [Unidad], [Activo], [Descripcion], [Categoria], [ImpuestoId], [Sistema], [ProductoCrmId], [AtributosExtendidos], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[Precio], s.[CodigoCabys], s.[Nombre], s.[Tipo], s.[FechaCreacionOrigen], s.[FechaModificacionOrigen], s.[Unidad], s.[Activo], s.[Descripcion], s.[Categoria], s.[ImpuestoId], s.[Sistema], s.[ProductoCrmId], s.[AtributosExtendidos], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
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
