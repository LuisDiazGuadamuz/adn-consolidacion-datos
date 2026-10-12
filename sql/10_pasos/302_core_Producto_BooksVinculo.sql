USE ADN_Unificado;
GO
/* Paso 302 · core_Producto_BooksVinculo → core.Producto
   Completa el id de Books en los productos del CRM ligados por zcrm_product_id (ID-04).
   Reglas: ID-04, IN-02
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_Producto_BooksVinculo @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT CAST(q.[ItemBooksId] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [ItemBooksId],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           CONCAT_WS(N',', CASE WHEN LEN(q.[ItemBooksId]) > 30 THEN N'ItemBooksId' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT 'ZohoCRM' AS FuenteSistema, N'Zoho_Mirror' AS FuenteBase, N'Products' AS FuenteTabla, ctl.fn_Texto(i.zcrm_product_id) AS FuenteLlave,
               CAST(NULL AS datetimeoffset(0)) AS FechaDato, ctl.fn_Texto(i.item_id) AS ItemBooksId
        FROM ZBooks_Mirror.dbo.items i
        WHERE EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.Products p WHERE p.id = i.zcrm_product_id)
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */
    -- sin columnas obligatorias adicionales

    /* 2b. Duplicados por la llave del paso (DD-04); el orden es determinista */
    ;WITH r AS (
        SELECT s.FuenteSistema, s.FuenteTabla, s.FuenteLlave,
               ROW_NUMBER() OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.ItemBooksId) AS rn,
               FIRST_VALUE(s.FuenteLlave) OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.ItemBooksId ROWS UNBOUNDED PRECEDING) AS Conservada
        FROM #src s)
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, LlaveConservada, Motivo, FechaDescarte)
    SELECT @LoteId, 'DD-04', r.FuenteSistema, r.FuenteTabla, r.FuenteLlave, r.Conservada, N'Registro repetido por la llave del paso; se conserva uno según el orden definido', @Ahora
    FROM r WHERE r.rn > 1
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'DD-04' AND x.FuenteTabla = r.FuenteTabla AND x.FuenteLlave = r.FuenteLlave);
    ;WITH r AS (
        SELECT ROW_NUMBER() OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.ItemBooksId) AS rn FROM #src s)
    DELETE FROM r WHERE rn > 1;
    DECLARE @Validas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 3. Imagen previa de las filas que cambian (solo las columnas que actualiza este paso) */
    DROP TABLE IF EXISTS #antes;
    SELECT t.[ProductoId] AS RegistroId, t.FuenteLlave, (SELECT t.[ItemBooksId] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.Producto t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave] WHERE EXISTS (SELECT s.[ItemBooksId] EXCEPT SELECT t.[ItemBooksId]);

    /* 4. Actualización */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    UPDATE t SET t.[ItemBooksId] = s.[ItemBooksId]
    OUTPUT N'UPDATE', inserted.[ProductoId], inserted.FuenteLlave INTO #cambios
    FROM core.Producto t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave] WHERE EXISTS (SELECT s.[ItemBooksId] EXCEPT SELECT t.[ItemBooksId]);

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
