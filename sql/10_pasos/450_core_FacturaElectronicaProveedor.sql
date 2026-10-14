USE ADN_Unificado;
GO
/* Paso 450 · core_FacturaElectronicaProveedor → core.FacturaElectronicaProveedor
   Facturas electrónicas de proveedores leídas por app.data.cr (XMLEngine).
   Reglas: ES-01, ES-07, ID-02, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_FacturaElectronicaProveedor @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT CAST(q.[Numero] AS nvarchar(60)) COLLATE DATABASE_DEFAULT AS [Numero],
           CAST(q.[Ruta] AS nvarchar(1000)) COLLATE DATABASE_DEFAULT AS [Ruta],
           q.[FechaEmision],
           CAST(q.[NombreArchivo] AS nvarchar(300)) COLLATE DATABASE_DEFAULT AS [NombreArchivo],
           CAST(q.[EmisorNombre] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [EmisorNombre],
           CAST(q.[EmisorCedula] AS varchar(12)) COLLATE DATABASE_DEFAULT AS [EmisorCedula],
           q.[TextoPlano] COLLATE DATABASE_DEFAULT AS [TextoPlano],
           q.[Procesada],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[Numero]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Ruta]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaEmision], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[NombreArchivo]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[EmisorNombre]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[EmisorCedula]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TextoPlano]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Procesada]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           CONCAT_WS(N',', CASE WHEN LEN(q.[Numero]) > 60 THEN N'Numero' END, CASE WHEN LEN(q.[Ruta]) > 1000 THEN N'Ruta' END, CASE WHEN LEN(q.[NombreArchivo]) > 300 THEN N'NombreArchivo' END, CASE WHEN LEN(q.[EmisorNombre]) > 200 THEN N'EmisorNombre' END, CASE WHEN LEN(q.[EmisorCedula]) > 12 THEN N'EmisorCedula' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT 'AppDataCR' AS FuenteSistema,
               N'ADNApp' AS FuenteBase,
               N'XMLEngine_invoicexmlfiles' AS FuenteTabla,
               ctl.fn_Texto(CONVERT(nvarchar(200), x.[invoice_number])) AS FuenteLlave,
               ctl.fn_FechaCR(CONVERT(nvarchar(30), x.[invoice_issue_date], 126)) AS FechaDato,
               ctl.fn_Texto(CONVERT(nvarchar(max), x.[invoice_number])) AS [Numero],
               ctl.fn_Texto(CONVERT(nvarchar(max), x.[path])) AS [Ruta],
               ctl.fn_FechaCR(CONVERT(nvarchar(30), x.[invoice_issue_date], 126)) AS [FechaEmision],
               ctl.fn_Texto(CONVERT(nvarchar(max), x.[filename])) AS [NombreArchivo],
               ctl.fn_Texto(CONVERT(nvarchar(max), x.[invoice_emisor_name])) AS [EmisorNombre],
               ctl.fn_Cedula(CONVERT(nvarchar(100), x.[invoice_emisor_id])) AS [EmisorCedula],
               ctl.fn_Texto(CONVERT(nvarchar(max), x.[invoice_plain_text])) AS [TextoPlano],
               ctl.fn_Bit(CONVERT(nvarchar(20), x.[is_processed])) AS [Procesada]
        FROM ADNApp.dbo.[XMLEngine_invoicexmlfiles] x
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);
    /* Conciliación: llaves leídas, para comprobar al final que toda fila excluida tiene su motivo en ctl.Descarte */
    DROP TABLE IF EXISTS #leidas;
    SELECT DISTINCT FuenteTabla, FuenteLlave INTO #leidas FROM #src;

    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'Numero obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[Numero] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FuenteLlave obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FuenteLlave] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE FROM #src WHERE [Numero] IS NULL OR [FuenteLlave] IS NULL;

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
    SELECT t.[FacturaElectronicaProveedorId] AS RegistroId, t.FuenteLlave, (SELECT t.[Numero], t.[EmisorNombre], t.[EmisorCedula], t.[FechaEmision], t.[NombreArchivo], t.[Ruta], t.[TextoPlano], t.[Procesada], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.FacturaElectronicaProveedor t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato);

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.FacturaElectronicaProveedor WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato)) THEN
        UPDATE SET t.[Numero] = s.[Numero], t.[Ruta] = s.[Ruta], t.[FechaEmision] = s.[FechaEmision], t.[NombreArchivo] = s.[NombreArchivo], t.[EmisorNombre] = s.[EmisorNombre], t.[EmisorCedula] = s.[EmisorCedula], t.[TextoPlano] = s.[TextoPlano], t.[Procesada] = s.[Procesada], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([Numero], [Ruta], [FechaEmision], [NombreArchivo], [EmisorNombre], [EmisorCedula], [TextoPlano], [Procesada], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[Numero], s.[Ruta], s.[FechaEmision], s.[NombreArchivo], s.[EmisorNombre], s.[EmisorCedula], s.[TextoPlano], s.[Procesada], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[FacturaElectronicaProveedorId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.FacturaElectronicaProveedor', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.FacturaElectronicaProveedor', t.[FacturaElectronicaProveedorId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.FacturaElectronicaProveedor t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    -- sin reglas de anomalía en este paso

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
