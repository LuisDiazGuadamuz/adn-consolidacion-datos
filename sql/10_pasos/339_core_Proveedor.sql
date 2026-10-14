USE ADN_Unificado;
GO
/* Paso 339 · core_Proveedor → core.Proveedor
   Proveedores de Books (contacts con contact_type = vendor).
   Reglas: ES-02, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_Proveedor @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT q.[FechaCreacionOrigen],
           q.[FechaModificacionOrigen],
           CAST(q.[ContactoBooksId] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [ContactoBooksId],
           CAST(q.[Nombre] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [Nombre],
           CAST(q.[Empresa] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [Empresa],
           CAST(q.[Cedula] AS varchar(12)) COLLATE DATABASE_DEFAULT AS [Cedula],
           CAST(q.[Correo] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [Correo],
           CAST(q.[Telefono] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [Telefono],
           CAST(q.[Estado] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [Estado],
           q.[AtributosExtendidos] COLLATE DATABASE_DEFAULT AS [AtributosExtendidos],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[FechaCreacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaModificacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ContactoBooksId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Nombre]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Empresa]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Cedula]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Correo]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Telefono]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Estado]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[AtributosExtendidos]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_FechaCreacionOrigen],
           q.[o_FechaModificacionOrigen],
           CONCAT_WS(N',', CASE WHEN LEN(q.[ContactoBooksId]) > 30 THEN N'ContactoBooksId' END, CASE WHEN LEN(q.[Nombre]) > 200 THEN N'Nombre' END, CASE WHEN LEN(q.[Empresa]) > 200 THEN N'Empresa' END, CASE WHEN LEN(q.[Cedula]) > 12 THEN N'Cedula' END, CASE WHEN LEN(q.[Correo]) > 200 THEN N'Correo' END, CASE WHEN LEN(q.[Telefono]) > 30 THEN N'Telefono' END, CASE WHEN LEN(q.[Estado]) > 30 THEN N'Estado' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT 'ZohoBooks' AS FuenteSistema,
               N'ZBooks_Mirror' AS FuenteBase,
               N'contacts' AS FuenteTabla,
               ctl.fn_Texto(CONVERT(nvarchar(200), v.[contact_id])) AS FuenteLlave,
               ctl.fn_FechaCR(CONVERT(nvarchar(60), v.[created_time])) AS FechaDato,
               ctl.fn_FechaCR(CONVERT(nvarchar(60), v.[created_time])) AS [FechaCreacionOrigen],
               ctl.fn_FechaCR(CONVERT(nvarchar(60), v.[last_modified_time])) AS [FechaModificacionOrigen],
               ctl.fn_Texto(v.contact_id) AS [ContactoBooksId],
               ctl.fn_Texto(v.contact_name) AS [Nombre],
               ctl.fn_Texto(v.company_name) AS [Empresa],
               ctl.fn_Cedula(v.cf_identificaci_n_unformatted) AS [Cedula],
               ctl.fn_Texto(v.email) AS [Correo],
               ctl.fn_Texto(v.phone) AS [Telefono],
               ctl.fn_Texto(v.status) AS [Estado],
               ctl.fn_Texto(CONVERT(nvarchar(400), v.[created_time])) AS [o_FechaCreacionOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(400), v.[last_modified_time])) AS [o_FechaModificacionOrigen],
               CAST(NULL AS nvarchar(max)) AS [AtributosExtendidos]
        FROM ZBooks_Mirror.dbo.[contacts] v
        WHERE v.contact_type = 'vendor'
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);
    /* Conciliación: llaves leídas, para comprobar al final que toda fila excluida tiene su motivo en ctl.Descarte */
    DROP TABLE IF EXISTS #leidas;
    SELECT DISTINCT FuenteTabla, FuenteLlave INTO #leidas FROM #src;

    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'ContactoBooksId obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[ContactoBooksId] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FuenteLlave obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FuenteLlave] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE FROM #src WHERE [ContactoBooksId] IS NULL OR [FuenteLlave] IS NULL;

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
    SELECT t.[ProveedorId] AS RegistroId, t.FuenteLlave, (SELECT t.[ContactoBooksId], t.[Nombre], t.[Empresa], t.[Cedula], t.[Correo], t.[Telefono], t.[Estado], t.[AtributosExtendidos], t.[FechaCreacionOrigen], t.[FechaModificacionOrigen], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.Proveedor t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato);

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.Proveedor WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato)) THEN
        UPDATE SET t.[FechaCreacionOrigen] = s.[FechaCreacionOrigen], t.[FechaModificacionOrigen] = s.[FechaModificacionOrigen], t.[ContactoBooksId] = s.[ContactoBooksId], t.[Nombre] = s.[Nombre], t.[Empresa] = s.[Empresa], t.[Cedula] = s.[Cedula], t.[Correo] = s.[Correo], t.[Telefono] = s.[Telefono], t.[Estado] = s.[Estado], t.[AtributosExtendidos] = s.[AtributosExtendidos], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([FechaCreacionOrigen], [FechaModificacionOrigen], [ContactoBooksId], [Nombre], [Empresa], [Cedula], [Correo], [Telefono], [Estado], [AtributosExtendidos], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[FechaCreacionOrigen], s.[FechaModificacionOrigen], s.[ContactoBooksId], s.[Nombre], s.[Empresa], s.[Cedula], s.[Correo], s.[Telefono], s.[Estado], s.[AtributosExtendidos], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[ProveedorId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.Proveedor', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.Proveedor', t.[ProveedorId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.Proveedor t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.Proveedor', t.[ProveedorId], N'FechaCreacionOrigen', LEFT(CONVERT(nvarchar(400), s.o_FechaCreacionOrigen), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.Proveedor t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaCreacionOrigen IS NOT NULL AND s.[FechaCreacionOrigen] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.Proveedor', t.[ProveedorId], N'FechaModificacionOrigen', LEFT(CONVERT(nvarchar(400), s.o_FechaModificacionOrigen), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.Proveedor t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaModificacionOrigen IS NOT NULL AND s.[FechaModificacionOrigen] IS NULL;

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
