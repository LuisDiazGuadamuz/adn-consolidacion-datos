USE ADN_Unificado;
GO
/* Paso 151 · ref_CuentaContable_Padre → ref.CuentaContable
   Completa la cuenta padre de cada cuenta contable (requiere que todas las cuentas ya existan).
   Reglas: IN-01, IN-02, DD-02
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_ref_CuentaContable_Padre @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT q.[CuentaPadreId],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           q.[o_Modificada],
           CAST(N'' AS nvarchar(1)) AS _Recortadas
    INTO #src
    FROM (
        SELECT 'ZohoBooks' AS FuenteSistema, N'ZBooks_Mirror' AS FuenteBase, N'chartofaccounts' AS FuenteTabla,
               ctl.fn_Texto(x.account_id) AS FuenteLlave, CAST(NULL AS datetimeoffset(0)) AS FechaDato,
               p.CuentaContableId AS CuentaPadreId,
               ctl.fn_FechaCR(x.last_modified_time) AS o_Modificada
        FROM ZBooks_Mirror.dbo.chartofaccounts x
        LEFT JOIN ref.CuentaContable p ON p.CuentaBooksId = ctl.fn_Texto(x.parent_account_id)
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */
    -- sin columnas obligatorias adicionales

    /* 2b. Duplicados por la llave del paso (DD-02); el orden es determinista */
    ;WITH r AS (
        SELECT s.FuenteSistema, s.FuenteTabla, s.FuenteLlave,
               ROW_NUMBER() OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.o_Modificada DESC, s.CuentaPadreId) AS rn,
               FIRST_VALUE(s.FuenteLlave) OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.o_Modificada DESC, s.CuentaPadreId ROWS UNBOUNDED PRECEDING) AS Conservada
        FROM #src s)
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, LlaveConservada, Motivo, FechaDescarte)
    SELECT @LoteId, 'DD-02', r.FuenteSistema, r.FuenteTabla, r.FuenteLlave, r.Conservada, N'Versión anterior de la misma cuenta en el espejo de Books', @Ahora
    FROM r WHERE r.rn > 1
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'DD-02' AND x.FuenteTabla = r.FuenteTabla AND x.FuenteLlave = r.FuenteLlave);
    ;WITH r AS (
        SELECT ROW_NUMBER() OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.o_Modificada DESC, s.CuentaPadreId) AS rn FROM #src s)
    DELETE FROM r WHERE rn > 1;
    DECLARE @Validas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 3. Imagen previa de las filas que cambian (solo las columnas que actualiza este paso) */
    DROP TABLE IF EXISTS #antes;
    SELECT t.[CuentaContableId] AS RegistroId, t.FuenteLlave, (SELECT t.[CuentaPadreId] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM ref.CuentaContable t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave] WHERE EXISTS (SELECT s.[CuentaPadreId] EXCEPT SELECT t.[CuentaPadreId]);

    /* 4. Actualización */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    UPDATE t SET t.[CuentaPadreId] = s.[CuentaPadreId]
    OUTPUT N'UPDATE', inserted.[CuentaContableId], inserted.FuenteLlave INTO #cambios
    FROM ref.CuentaContable t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave] WHERE EXISTS (SELECT s.[CuentaPadreId] EXCEPT SELECT t.[CuentaPadreId]);

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'ref.CuentaContable', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'ref.CuentaContable', t.[CuentaContableId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN ref.CuentaContable t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    -- sin reglas de anomalía en este paso

    SELECT @Leidas AS FilasLeidas, @Validas - (SELECT COUNT_BIG(*) FROM #cambios) AS FilasSinCambio,
           CAST(NULL AS bigint) AS FilasExcluidas, CAST(NULL AS bigint) AS LlavesSinMotivo;
END;
GO
