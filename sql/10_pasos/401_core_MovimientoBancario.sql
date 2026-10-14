USE ADN_Unificado;
GO
/* Paso 401 · core_MovimientoBancario → core.MovimientoBancario
   Movimientos bancarios de Books. El cliente se liga por la tabla de correspondencia (ID-06). Los movimientos de proveedores no son anomalía (el contacto es un proveedor de core.Proveedor).
   Reglas: D5, DD-02, ES-02, ES-03, ES-04, IN-01, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_MovimientoBancario @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT CAST(q.[MovimientoBooksId] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [MovimientoBooksId],
           q.[Fecha],
           q.[Monto],
           CAST(q.[Tipo] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Tipo],
           CAST(q.[Estado] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [Estado],
           CAST(q.[Origen] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Origen],
           CAST(q.[Beneficiario] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [Beneficiario],
           CAST(q.[Descripcion] AS nvarchar(1000)) COLLATE DATABASE_DEFAULT AS [Descripcion],
           CAST(q.[Moneda] AS char(3)) COLLATE DATABASE_DEFAULT AS [Moneda],
           CAST(q.[DebitoCredito] AS varchar(10)) COLLATE DATABASE_DEFAULT AS [DebitoCredito],
           CAST(q.[Referencia] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [Referencia],
           CAST(q.[EstadoConciliacion] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [EstadoConciliacion],
           CAST(q.[Sucursal] AS nvarchar(100)) COLLATE DATABASE_DEFAULT AS [Sucursal],
           q.[CuentaBancariaId],
           q.[ClienteId],
           q.[AtributosExtendidos] COLLATE DATABASE_DEFAULT AS [AtributosExtendidos],
           q.[MontoCRC],
           q.[TipoCambio],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[MovimientoBooksId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Fecha], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Monto]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Tipo]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Estado]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Origen]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Beneficiario]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Descripcion]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Moneda]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[DebitoCredito]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Referencia]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[EstadoConciliacion]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Sucursal]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[CuentaBancariaId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ClienteId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[AtributosExtendidos]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[MontoCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TipoCambio]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_ClienteBooks],
           q.[o_CuentaBancariaId],
           q.[o_Fecha],
           q.[o_Monto],
           CONCAT_WS(N',', CASE WHEN LEN(q.[MovimientoBooksId]) > 30 THEN N'MovimientoBooksId' END, CASE WHEN LEN(q.[Tipo]) > 50 THEN N'Tipo' END, CASE WHEN LEN(q.[Estado]) > 30 THEN N'Estado' END, CASE WHEN LEN(q.[Origen]) > 50 THEN N'Origen' END, CASE WHEN LEN(q.[Beneficiario]) > 200 THEN N'Beneficiario' END, CASE WHEN LEN(q.[Descripcion]) > 1000 THEN N'Descripcion' END, CASE WHEN LEN(q.[Moneda]) > 3 THEN N'Moneda' END, CASE WHEN LEN(q.[DebitoCredito]) > 10 THEN N'DebitoCredito' END, CASE WHEN LEN(q.[Referencia]) > 200 THEN N'Referencia' END, CASE WHEN LEN(q.[EstadoConciliacion]) > 30 THEN N'EstadoConciliacion' END, CASE WHEN LEN(q.[Sucursal]) > 100 THEN N'Sucursal' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT q.*,
               tx.Tasa AS TipoCambio,
               CASE q.Moneda WHEN 'CRC' THEN q.[Monto] WHEN 'USD' THEN CAST(q.[Monto] * tx.Tasa AS decimal(19,4)) END AS [MontoCRC]
        FROM (
        SELECT 'ZohoBooks' AS FuenteSistema,
               N'ZBooks_Mirror' AS FuenteBase,
               N'banktransactions' AS FuenteTabla,
               ctl.fn_Texto(CONVERT(nvarchar(200), m.[transaction_id])) AS FuenteLlave,
               TODATETIMEOFFSET(CAST(ctl.fn_FechaDia(m.[date]) AS datetime2), '-06:00') AS FechaDato,
               ctl.fn_Texto(CONVERT(nvarchar(max), m.[transaction_id])) AS [MovimientoBooksId],
               ctl.fn_FechaDia(CONVERT(nvarchar(60), m.[date])) AS [Fecha],
               ctl.fn_Monto(CONVERT(nvarchar(60), m.[amount])) AS [Monto],
               ctl.fn_Texto(CONVERT(nvarchar(max), m.[transaction_type])) AS [Tipo],
               ctl.fn_Texto(CONVERT(nvarchar(max), m.[status])) AS [Estado],
               ctl.fn_Texto(CONVERT(nvarchar(max), m.[source])) AS [Origen],
               ctl.fn_Texto(CONVERT(nvarchar(max), m.[payee])) AS [Beneficiario],
               ctl.fn_Texto(CONVERT(nvarchar(max), m.[description])) AS [Descripcion],
               ctl.fn_Moneda(CONVERT(nvarchar(20), m.[currency_code])) AS [Moneda],
               ctl.fn_Texto(CONVERT(nvarchar(max), m.[debit_or_credit])) AS [DebitoCredito],
               ctl.fn_Texto(CONVERT(nvarchar(max), m.[reference_number])) AS [Referencia],
               ctl.fn_Texto(CONVERT(nvarchar(max), m.[reconcile_status])) AS [EstadoConciliacion],
               ctl.fn_Texto(CONVERT(nvarchar(max), m.[branch_name])) AS [Sucursal],
               fk_CuentaBancariaId_0.Id AS [CuentaBancariaId],
               ctl.fn_Texto(CONVERT(nvarchar(400), m.[account_id])) AS [o_CuentaBancariaId],
               co.ClienteId AS [ClienteId],
               CASE WHEN co.ClienteId IS NULL AND NOT EXISTS (SELECT 1 FROM core.Proveedor pv WHERE pv.ContactoBooksId = ctl.fn_Texto(m.customer_id)) THEN ctl.fn_Texto(m.customer_id) END AS [o_ClienteBooks],
               ctl.fn_Texto(CONVERT(nvarchar(400), m.[date])) AS [o_Fecha],
               ctl.fn_Texto(CONVERT(nvarchar(400), m.[amount])) AS [o_Monto],
               NULLIF((SELECT ctl.fn_Texto(CONVERT(nvarchar(max), m.[account_name])) AS [account_name], ctl.fn_Texto(CONVERT(nvarchar(max), m.[account_type])) AS [account_type], ctl.fn_Texto(CONVERT(nvarchar(max), m.[price_precision])) AS [price_precision], ctl.fn_Texto(CONVERT(nvarchar(max), m.[is_paid_via_print_check])) AS [is_paid_via_print_check], ctl.fn_Texto(CONVERT(nvarchar(max), m.[currency_id])) AS [currency_id], ctl.fn_Texto(CONVERT(nvarchar(max), m.[currency_symbol])) AS [currency_symbol], ctl.fn_Texto(CONVERT(nvarchar(max), m.[offset_account_name])) AS [offset_account_name], ctl.fn_Texto(CONVERT(nvarchar(max), m.[is_offsetaccount_matched])) AS [is_offsetaccount_matched], ctl.fn_Texto(CONVERT(nvarchar(max), m.[imported_transaction_id])) AS [imported_transaction_id], ctl.fn_Texto(CONVERT(nvarchar(max), m.[is_rule_exist])) AS [is_rule_exist], ctl.fn_Texto(CONVERT(nvarchar(max), m.[rule_details])) AS [rule_details], ctl.fn_Texto(CONVERT(nvarchar(max), m.[exclude_description])) AS [exclude_description], ctl.fn_Texto(CONVERT(nvarchar(max), m.[is_excluded_by_system])) AS [is_excluded_by_system], ctl.fn_Texto(CONVERT(nvarchar(max), m.[branch_id])) AS [branch_id] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER), N'{}') AS [AtributosExtendidos]
        FROM ZBooks_Mirror.dbo.[banktransactions] m
        OUTER APPLY (SELECT CASE WHEN COUNT(DISTINCT o.ClienteId) = 1 THEN MIN(o.ClienteId) END AS ClienteId
                     FROM core.ClienteOrigen o WHERE o.Sistema = 'ZohoBooks' AND o.LlaveOrigen = ctl.fn_Texto(m.customer_id)) co
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[CuentaBancariaId]) END AS Id FROM core.CuentaBancaria zref WHERE zref.[CuentaBooksId] = ctl.fn_Texto(CONVERT(nvarchar(max), m.[account_id]))) fk_CuentaBancariaId_0
        ) q
        OUTER APPLY (SELECT TOP 1 t.Venta FROM ref.TipoCambio t WHERE t.Fecha <= CAST(q.Fecha AS date) ORDER BY t.Fecha DESC) tc
        CROSS APPLY (SELECT CASE q.Moneda WHEN 'CRC' THEN CAST(1 AS decimal(19,6)) WHEN 'USD' THEN COALESCE(tc.Venta, NULL) END AS Tasa) tx
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);
    /* Conciliación: llaves leídas, para comprobar al final que toda fila excluida tiene su motivo en ctl.Descarte */
    DROP TABLE IF EXISTS #leidas;
    SELECT DISTINCT FuenteTabla, FuenteLlave INTO #leidas FROM #src;

    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'MovimientoBooksId obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[MovimientoBooksId] IS NULL
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
    DELETE FROM #src WHERE [MovimientoBooksId] IS NULL OR [Fecha] IS NULL OR [FuenteLlave] IS NULL;

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
    SELECT t.[MovimientoBancarioId] AS RegistroId, t.FuenteLlave, (SELECT t.[MovimientoBooksId], t.[CuentaBancariaId], t.[ClienteId], t.[Fecha], t.[Tipo], t.[DebitoCredito], t.[Estado], t.[Origen], t.[Beneficiario], t.[Descripcion], t.[Referencia], t.[EstadoConciliacion], t.[Moneda], t.[TipoCambio], t.[Monto], t.[MontoCRC], t.[Sucursal], t.[AtributosExtendidos], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.MovimientoBancario t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato);

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.MovimientoBancario WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato)) THEN
        UPDATE SET t.[MovimientoBooksId] = s.[MovimientoBooksId], t.[Fecha] = s.[Fecha], t.[Monto] = s.[Monto], t.[Tipo] = s.[Tipo], t.[Estado] = s.[Estado], t.[Origen] = s.[Origen], t.[Beneficiario] = s.[Beneficiario], t.[Descripcion] = s.[Descripcion], t.[Moneda] = s.[Moneda], t.[DebitoCredito] = s.[DebitoCredito], t.[Referencia] = s.[Referencia], t.[EstadoConciliacion] = s.[EstadoConciliacion], t.[Sucursal] = s.[Sucursal], t.[CuentaBancariaId] = s.[CuentaBancariaId], t.[ClienteId] = s.[ClienteId], t.[AtributosExtendidos] = s.[AtributosExtendidos], t.[MontoCRC] = s.[MontoCRC], t.[TipoCambio] = s.[TipoCambio], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([MovimientoBooksId], [Fecha], [Monto], [Tipo], [Estado], [Origen], [Beneficiario], [Descripcion], [Moneda], [DebitoCredito], [Referencia], [EstadoConciliacion], [Sucursal], [CuentaBancariaId], [ClienteId], [AtributosExtendidos], [MontoCRC], [TipoCambio], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[MovimientoBooksId], s.[Fecha], s.[Monto], s.[Tipo], s.[Estado], s.[Origen], s.[Beneficiario], s.[Descripcion], s.[Moneda], s.[DebitoCredito], s.[Referencia], s.[EstadoConciliacion], s.[Sucursal], s.[CuentaBancariaId], s.[ClienteId], s.[AtributosExtendidos], s.[MontoCRC], s.[TipoCambio], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[MovimientoBancarioId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.MovimientoBancario', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.MovimientoBancario', t.[MovimientoBancarioId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.MovimientoBancario t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.MovimientoBancario', t.[MovimientoBancarioId], N'ClienteId', LEFT(CONVERT(nvarchar(400), s.o_ClienteBooks), 400), N'Contacto de Books que no es cliente con correspondencia ni proveedor'
    FROM #src s JOIN core.MovimientoBancario t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_ClienteBooks IS NOT NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.MovimientoBancario', t.[MovimientoBancarioId], N'CuentaBancariaId', LEFT(CONVERT(nvarchar(400), s.o_CuentaBancariaId), 400), N'Referencia sin correspondencia única en core.CuentaBancaria'
    FROM #src s JOIN core.MovimientoBancario t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_CuentaBancariaId IS NOT NULL AND s.[CuentaBancariaId] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.MovimientoBancario', t.[MovimientoBancarioId], N'Fecha', LEFT(CONVERT(nvarchar(400), s.o_Fecha), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.MovimientoBancario t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Fecha IS NOT NULL AND s.[Fecha] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-04', N'core.MovimientoBancario', t.[MovimientoBancarioId], N'Monto', LEFT(CONVERT(nvarchar(400), s.o_Monto), 400), N'Monto ilegible; se conserva el texto original'
    FROM #src s JOIN core.MovimientoBancario t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Monto IS NOT NULL AND s.[Monto] IS NULL;

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
