USE ADN_Unificado;
GO
/* Paso 130 · ref_TipoCambio → ref.TipoCambio
   Tipo de cambio del dólar por día. Une la copia MongoDB (vigente, requiere stage-mongo) y la copia SQL Server. Si un día aparece varias veces se conserva MongoDB y, dentro de la misma fuente, el último registro.
   Reglas: ES-02, ES-03, ES-04, DD-04, D1, D5, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_ref_TipoCambio @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT q.[Fecha],
           q.[Compra],
           q.[Venta],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[Fecha], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Compra]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Venta]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_Fecha],
           q.[o_Orden],
           CAST(N'' AS nvarchar(1)) AS _Recortadas
    INTO #src
    FROM (
        SELECT 'AppDataCR' AS FuenteSistema, N'developer_adn_app_db' AS FuenteBase, N'Telephony_usdexchange' AS FuenteTabla,
               CAST(m._id AS nvarchar(200)) AS FuenteLlave,
               TODATETIMEOFFSET(CAST(ctl.fn_FechaDia(CONVERT(nvarchar(30), m.ExchangeDate, 23)) AS datetime2(0)), '-06:00') AS FechaDato,
               ctl.fn_FechaDia(CONVERT(nvarchar(30), m.ExchangeDate, 23)) AS Fecha,
               CAST(m.Purchase AS decimal(19,6)) AS Compra, CAST(m.Sale AS decimal(19,6)) AS Venta,
               CONVERT(nvarchar(30), m.ExchangeDate, 23) AS o_Fecha, m.id AS o_Orden
        FROM stg.mongo_Telephony_usdexchange m
        UNION ALL
        SELECT 'AppDataCR', N'ADNApp', N'Telephony_usdexchange', CAST(u.id AS nvarchar(200)),
               TODATETIMEOFFSET(CAST(ctl.fn_FechaDia(CONVERT(nvarchar(30), u.ExchangeDate, 23)) AS datetime2(0)), '-06:00'),
               ctl.fn_FechaDia(CONVERT(nvarchar(30), u.ExchangeDate, 23)),
               CAST(u.Purchase AS decimal(19,6)), CAST(u.Sale AS decimal(19,6)),
               CONVERT(nvarchar(30), u.ExchangeDate, 23), u.id
        FROM ADNApp.dbo.Telephony_usdexchange u
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);
    /* Conciliación: llaves leídas, para comprobar al final que toda fila excluida tiene su motivo en ctl.Descarte */
    DROP TABLE IF EXISTS #leidas;
    SELECT DISTINCT FuenteTabla, FuenteLlave INTO #leidas FROM #src;

    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */
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
    DELETE FROM #src WHERE [Fecha] IS NULL OR [FuenteLlave] IS NULL;

    /* 2b. Duplicados por la llave del paso (DD-04); el orden es determinista */
    ;WITH r AS (
        SELECT s.FuenteSistema, s.FuenteTabla, s.FuenteLlave,
               ROW_NUMBER() OVER (PARTITION BY s.[Fecha] ORDER BY CASE s.FuenteBase WHEN N'developer_adn_app_db' THEN 0 ELSE 1 END, s.o_Orden DESC, s.FuenteLlave) AS rn,
               FIRST_VALUE(s.FuenteLlave) OVER (PARTITION BY s.[Fecha] ORDER BY CASE s.FuenteBase WHEN N'developer_adn_app_db' THEN 0 ELSE 1 END, s.o_Orden DESC, s.FuenteLlave ROWS UNBOUNDED PRECEDING) AS Conservada
        FROM #src s)
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, LlaveConservada, Motivo, FechaDescarte)
    SELECT @LoteId, 'DD-04', r.FuenteSistema, r.FuenteTabla, r.FuenteLlave, r.Conservada, N'Varios tipos de cambio para el mismo día; se conserva MongoDB y el último registrado', @Ahora
    FROM r WHERE r.rn > 1
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'DD-04' AND x.FuenteTabla = r.FuenteTabla AND x.FuenteLlave = r.FuenteLlave);
    ;WITH r AS (
        SELECT ROW_NUMBER() OVER (PARTITION BY s.[Fecha] ORDER BY CASE s.FuenteBase WHEN N'developer_adn_app_db' THEN 0 ELSE 1 END, s.o_Orden DESC, s.FuenteLlave) AS rn FROM #src s)
    DELETE FROM r WHERE rn > 1;
    DECLARE @Validas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 3. Imagen previa de las filas que van a cambiar (para el rollback) */
    DROP TABLE IF EXISTS #antes;
    SELECT t.[TipoCambioId] AS RegistroId, t.FuenteLlave, (SELECT t.[Fecha], t.[Compra], t.[Venta], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM ref.TipoCambio t JOIN #src s ON t.[Fecha] = s.[Fecha]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato);

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE ref.TipoCambio WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[Fecha] = s.[Fecha]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato)) THEN
        UPDATE SET t.[Fecha] = s.[Fecha], t.[Compra] = s.[Compra], t.[Venta] = s.[Venta], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([Fecha], [Compra], [Venta], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[Fecha], s.[Compra], s.[Venta], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[TipoCambioId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'ref.TipoCambio', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'ref.TipoCambio', t.[TipoCambioId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN ref.TipoCambio t ON t.[Fecha] = s.[Fecha]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-03', N'ref.TipoCambio', t.[TipoCambioId], N'Fecha', LEFT(CONVERT(nvarchar(400), s.o_Fecha), 400), N'Fecha posterior a la carga'
    FROM #src s JOIN ref.TipoCambio t ON t.[Fecha] = s.[Fecha]
    WHERE s.Fecha > CAST(SYSDATETIMEOFFSET() AS date);

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
