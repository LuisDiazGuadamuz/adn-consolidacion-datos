USE ADN_Unificado;
GO
/* Paso 400 · core_CuentaBancaria → core.CuentaBancaria
   Cuentas bancarias de Books. El saldo en colones es el saldo en moneda base de Books (bcy_balance).
   Reglas: D5, ES-04, ES-07, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_CuentaBancaria @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT CAST(q.[CuentaBooksId] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [CuentaBooksId],
           CAST(q.[Nombre] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [Nombre],
           CAST(q.[Codigo] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Codigo],
           CAST(q.[Moneda] AS char(3)) COLLATE DATABASE_DEFAULT AS [Moneda],
           CAST(q.[Tipo] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Tipo],
           q.[Activa],
           q.[Saldo],
           q.[SaldoBanco],
           CAST(q.[Banco] AS nvarchar(100)) COLLATE DATABASE_DEFAULT AS [Banco],
           q.[AtributosExtendidos] COLLATE DATABASE_DEFAULT AS [AtributosExtendidos],
           q.[SaldoCRC],
           q.[SaldoBancoCRC],
           q.[TipoCambio],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[CuentaBooksId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Nombre]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Codigo]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Moneda]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Tipo]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Activa]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Saldo]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[SaldoBanco]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Banco]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[AtributosExtendidos]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[SaldoCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[SaldoBancoCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TipoCambio]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_Saldo],
           q.[o_SaldoBanco],
           CONCAT_WS(N',', CASE WHEN LEN(q.[CuentaBooksId]) > 30 THEN N'CuentaBooksId' END, CASE WHEN LEN(q.[Nombre]) > 200 THEN N'Nombre' END, CASE WHEN LEN(q.[Codigo]) > 50 THEN N'Codigo' END, CASE WHEN LEN(q.[Moneda]) > 3 THEN N'Moneda' END, CASE WHEN LEN(q.[Tipo]) > 50 THEN N'Tipo' END, CASE WHEN LEN(q.[Banco]) > 100 THEN N'Banco' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT q.*,
               tx.Tasa AS TipoCambio,
               COALESCE(q.[d_SaldoCRC], CASE q.Moneda WHEN 'CRC' THEN q.[Saldo] WHEN 'USD' THEN CAST(q.[Saldo] * tx.Tasa AS decimal(19,4)) END) AS [SaldoCRC],
               CASE q.Moneda WHEN 'CRC' THEN q.[SaldoBanco] WHEN 'USD' THEN CAST(q.[SaldoBanco] * tx.Tasa AS decimal(19,4)) END AS [SaldoBancoCRC]
        FROM (
        SELECT 'ZohoBooks' AS FuenteSistema,
               N'ZBooks_Mirror' AS FuenteBase,
               N'bankaccounts' AS FuenteTabla,
               ctl.fn_Texto(CONVERT(nvarchar(200), b.[account_id])) AS FuenteLlave,
               CAST(NULL AS datetimeoffset(0)) AS FechaDato,
               ctl.fn_Texto(CONVERT(nvarchar(max), b.[account_id])) AS [CuentaBooksId],
               ctl.fn_Texto(CONVERT(nvarchar(max), b.[account_name])) AS [Nombre],
               ctl.fn_Texto(CONVERT(nvarchar(max), b.[account_code])) AS [Codigo],
               ctl.fn_Moneda(CONVERT(nvarchar(20), b.[currency_code])) AS [Moneda],
               ctl.fn_Texto(CONVERT(nvarchar(max), b.[account_type])) AS [Tipo],
               ctl.fn_Bit(CONVERT(nvarchar(20), b.[is_active])) AS [Activa],
               ctl.fn_Monto(CONVERT(nvarchar(60), b.[balance])) AS [Saldo],
               ctl.fn_Monto(CONVERT(nvarchar(60), b.[bank_balance])) AS [SaldoBanco],
               ctl.fn_Texto(CONVERT(nvarchar(max), b.[bank_name])) AS [Banco],
               ctl.fn_Texto(CONVERT(nvarchar(400), b.[balance])) AS [o_Saldo],
               ctl.fn_Texto(CONVERT(nvarchar(400), b.[bank_balance])) AS [o_SaldoBanco],
               NULLIF((SELECT ctl.fn_Texto(CONVERT(nvarchar(max), b.[currency_id])) AS [currency_id], ctl.fn_Texto(CONVERT(nvarchar(max), b.[uncategorized_transactions])) AS [uncategorized_transactions], ctl.fn_Texto(CONVERT(nvarchar(max), b.[total_unprinted_checks])) AS [total_unprinted_checks], ctl.fn_Texto(CONVERT(nvarchar(max), b.[is_paypal_account])) AS [is_paypal_account], ctl.fn_Texto(CONVERT(nvarchar(max), b.[is_direct_paypal])) AS [is_direct_paypal], ctl.fn_Texto(CONVERT(nvarchar(max), b.[is_beta_feed])) AS [is_beta_feed], ctl.fn_Texto(CONVERT(nvarchar(max), b.[feed_status])) AS [feed_status] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER), N'{}') AS [AtributosExtendidos],
               ctl.fn_Monto(CONVERT(nvarchar(60), b.[bcy_balance])) AS [d_SaldoCRC]
        FROM ZBooks_Mirror.dbo.[bankaccounts] b
        ) q
        OUTER APPLY (SELECT TOP 1 t.Venta FROM ref.TipoCambio t WHERE t.Fecha <= CAST(q.FechaDato AS date) ORDER BY t.Fecha DESC) tc
        CROSS APPLY (SELECT CASE q.Moneda WHEN 'CRC' THEN CAST(1 AS decimal(19,6)) WHEN 'USD' THEN COALESCE(tc.Venta, NULL) END AS Tasa) tx
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);
    /* Conciliación: llaves leídas, para comprobar al final que toda fila excluida tiene su motivo en ctl.Descarte */
    DROP TABLE IF EXISTS #leidas;
    SELECT DISTINCT FuenteTabla, FuenteLlave INTO #leidas FROM #src;

    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'CuentaBooksId obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[CuentaBooksId] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FuenteLlave obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FuenteLlave] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE FROM #src WHERE [CuentaBooksId] IS NULL OR [FuenteLlave] IS NULL;

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
    SELECT t.[CuentaBancariaId] AS RegistroId, t.FuenteLlave, (SELECT t.[CuentaBooksId], t.[Nombre], t.[Codigo], t.[Banco], t.[Tipo], t.[Activa], t.[Moneda], t.[TipoCambio], t.[Saldo], t.[SaldoCRC], t.[SaldoBanco], t.[SaldoBancoCRC], t.[AtributosExtendidos], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.CuentaBancaria t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato);

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.CuentaBancaria WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato)) THEN
        UPDATE SET t.[CuentaBooksId] = s.[CuentaBooksId], t.[Nombre] = s.[Nombre], t.[Codigo] = s.[Codigo], t.[Moneda] = s.[Moneda], t.[Tipo] = s.[Tipo], t.[Activa] = s.[Activa], t.[Saldo] = s.[Saldo], t.[SaldoBanco] = s.[SaldoBanco], t.[Banco] = s.[Banco], t.[AtributosExtendidos] = s.[AtributosExtendidos], t.[SaldoCRC] = s.[SaldoCRC], t.[SaldoBancoCRC] = s.[SaldoBancoCRC], t.[TipoCambio] = s.[TipoCambio], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([CuentaBooksId], [Nombre], [Codigo], [Moneda], [Tipo], [Activa], [Saldo], [SaldoBanco], [Banco], [AtributosExtendidos], [SaldoCRC], [SaldoBancoCRC], [TipoCambio], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[CuentaBooksId], s.[Nombre], s.[Codigo], s.[Moneda], s.[Tipo], s.[Activa], s.[Saldo], s.[SaldoBanco], s.[Banco], s.[AtributosExtendidos], s.[SaldoCRC], s.[SaldoBancoCRC], s.[TipoCambio], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[CuentaBancariaId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.CuentaBancaria', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.CuentaBancaria', t.[CuentaBancariaId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.CuentaBancaria t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-04', N'core.CuentaBancaria', t.[CuentaBancariaId], N'Saldo', LEFT(CONVERT(nvarchar(400), s.o_Saldo), 400), N'Monto ilegible; se conserva el texto original'
    FROM #src s JOIN core.CuentaBancaria t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Saldo IS NOT NULL AND s.[Saldo] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-04', N'core.CuentaBancaria', t.[CuentaBancariaId], N'SaldoBanco', LEFT(CONVERT(nvarchar(400), s.o_SaldoBanco), 400), N'Monto ilegible; se conserva el texto original'
    FROM #src s JOIN core.CuentaBancaria t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_SaldoBanco IS NOT NULL AND s.[SaldoBanco] IS NULL;

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
