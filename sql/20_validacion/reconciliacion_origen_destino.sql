/* Reconciliación origen-destino · ADN_Unificado (Sprint 4). SOLO LECTURA sobre el origen y el modelo.
   Generado por etl/adn_etl/reconciliar.py (no editar a mano): una consulta por tabla de origen.
   Ejecutar con ./etl.ps1 reconciliar (guarda resultados y reporte) o por bloques en SSMS. */
SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON;
USE ADN_Unificado;
GO
/* core_Cliente: cliente consolidado (por cédula o por cuenta): se reconcilia por sus orígenes en core.ClienteOrigen */

/* ===== ref_Provincia · ref.Provincia ← ADNPayV2.AddressProvince ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM ref.Provincia t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'AddressProvince' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CAST(x.[id] AS nvarchar(200))) AS k
      FROM [ADNPayV2].dbo.[AddressProvince] x) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM [ADNPayV2].dbo.[AddressProvince] x);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM ref.Provincia t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'AddressProvince' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'ref_Provincia') AND d.FuenteTabla = N'AddressProvince' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'AddressProvince' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'ref_Provincia') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== ref_Canton · ref.Canton ← ADNPayV2.AddressCanton ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM ref.Canton t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'AddressCanton' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CAST(x.[id] AS nvarchar(200))) AS k
      FROM [ADNPayV2].dbo.[AddressCanton] x) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM [ADNPayV2].dbo.[AddressCanton] x);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM ref.Canton t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'AddressCanton' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'ref_Canton') AND d.FuenteTabla = N'AddressCanton' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'AddressCanton' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'ref_Canton') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== ref_Distrito · ref.Distrito ← ADNPayV2.AddressDistrict ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM ref.Distrito t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'AddressDistrict' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CAST(x.[id] AS nvarchar(200))) AS k
      FROM [ADNPayV2].dbo.[AddressDistrict] x) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM [ADNPayV2].dbo.[AddressDistrict] x);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM ref.Distrito t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'AddressDistrict' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'ref_Distrito') AND d.FuenteTabla = N'AddressDistrict' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'AddressDistrict' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'ref_Distrito') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== ref_TipoCambio · ref.TipoCambio ← ADNApp.Telephony_usdexchange ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM ref.TipoCambio t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_usdexchange' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT CAST(x.id AS nvarchar(200)) AS k
      FROM ADNApp.dbo.Telephony_usdexchange x) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNApp.dbo.Telephony_usdexchange x);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM ref.TipoCambio t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_usdexchange' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'ref_TipoCambio') AND d.FuenteTabla = N'Telephony_usdexchange' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Telephony_usdexchange' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'ref_TipoCambio') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== ref_TipoCambio · ref.TipoCambio ← developer_adn_app_db.Telephony_usdexchange ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM ref.TipoCambio t WHERE t.FuenteBase = N'developer_adn_app_db' AND t.FuenteTabla = N'Telephony_usdexchange' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT CAST(x._id AS nvarchar(200)) AS k
      FROM stg.mongo_Telephony_usdexchange x) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM stg.mongo_Telephony_usdexchange x);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM ref.TipoCambio t WHERE t.FuenteBase = N'developer_adn_app_db' AND t.FuenteTabla = N'Telephony_usdexchange' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'ref_TipoCambio') AND d.FuenteTabla = N'Telephony_usdexchange' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Telephony_usdexchange' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'ref_TipoCambio') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== ref_Impuesto · ref.Impuesto ← ZBooks_Mirror.taxes ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM ref.Impuesto t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'taxes' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CAST(x.[tax_id] AS nvarchar(200))) AS k
      FROM [ZBooks_Mirror].dbo.[taxes] x) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM [ZBooks_Mirror].dbo.[taxes] x);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM ref.Impuesto t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'taxes' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'ref_Impuesto') AND d.FuenteTabla = N'taxes' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'taxes' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'ref_Impuesto') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== ref_CuentaContable · ref.CuentaContable ← ZBooks_Mirror.chartofaccounts ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM ref.CuentaContable t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'chartofaccounts' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CAST(x.[account_id] AS nvarchar(200))) AS k
      FROM [ZBooks_Mirror].dbo.[chartofaccounts] x) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM [ZBooks_Mirror].dbo.[chartofaccounts] x);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM ref.CuentaContable t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'chartofaccounts' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'ref_CuentaContable') AND d.FuenteTabla = N'chartofaccounts' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'chartofaccounts' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'ref_CuentaContable') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== ref_CodigoPromocion · ref.CodigoPromocion ← ADNPayV2.code_promo_condo ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM ref.CodigoPromocion t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'code_promo_condo' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CAST(x.[id] AS nvarchar(200))) AS k
      FROM [ADNPayV2].dbo.[code_promo_condo] x) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM [ADNPayV2].dbo.[code_promo_condo] x);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM ref.CodigoPromocion t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'code_promo_condo' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'ref_CodigoPromocion') AND d.FuenteTabla = N'code_promo_condo' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'code_promo_condo' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'ref_CodigoPromocion') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== ref_Usuario · ref.Usuario ← Zoho_Mirror.Users ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM ref.Usuario t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Users' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CAST(x.[id] AS nvarchar(200))) AS k
      FROM [Zoho_Mirror].dbo.[Users] x) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM [Zoho_Mirror].dbo.[Users] x);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM ref.Usuario t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Users' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'ref_Usuario', N'ref_Usuario_ADNApp') AND d.FuenteTabla = N'Users' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Users' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'ref_Usuario', N'ref_Usuario_ADNApp') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== ref_Usuario_ADNApp · ref.Usuario ← ADNApp.ZohoEngine_zohouser ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM ref.Usuario t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'ZohoEngine_zohouser' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(x.zoho_id) AS k
      FROM ADNApp.dbo.ZohoEngine_zohouser x
WHERE NOT EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.Users u WHERE ctl.fn_Texto(u.id) = ctl.fn_Texto(x.zoho_id))) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNApp.dbo.ZohoEngine_zohouser x);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM ref.Usuario t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'ZohoEngine_zohouser' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'ref_Usuario', N'ref_Usuario_ADNApp') AND d.FuenteTabla = N'ZohoEngine_zohouser' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'ZohoEngine_zohouser' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'ref_Usuario', N'ref_Usuario_ADNApp') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_Condominio · core.Condominio ← Zoho_Mirror.Condominios ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Condominio t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Condominios' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CAST(x.[id] AS nvarchar(200))) AS k
      FROM [Zoho_Mirror].dbo.[Condominios] x) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM [Zoho_Mirror].dbo.[Condominios] x);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.Condominio t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Condominios' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_Condominio') AND d.FuenteTabla = N'Condominios' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Condominios' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_Condominio') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_Nodo · core.Nodo ← Zoho_Mirror.Nodos ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Nodo t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Nodos' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CAST(x.[id] AS nvarchar(200))) AS k
      FROM [Zoho_Mirror].dbo.[Nodos] x) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM [Zoho_Mirror].dbo.[Nodos] x);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.Nodo t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Nodos' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_Nodo') AND d.FuenteTabla = N'Nodos' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Nodos' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_Nodo') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_ClusterFTTH · core.ClusterFTTH ← Zoho_Mirror.FTTHs ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.ClusterFTTH t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'FTTHs' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CAST(x.[id] AS nvarchar(200))) AS k
      FROM [Zoho_Mirror].dbo.[FTTHs] x) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM [Zoho_Mirror].dbo.[FTTHs] x);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.ClusterFTTH t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'FTTHs' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_ClusterFTTH') AND d.FuenteTabla = N'FTTHs' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'FTTHs' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_ClusterFTTH') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_Servicio · core.Servicio ← Zoho_Mirror.Accounts_Extended ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Servicio t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Accounts_Extended' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT x.id AS k
      FROM Zoho_Mirror.dbo.Accounts_Extended x) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM Zoho_Mirror.dbo.Accounts_Extended x);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.Servicio t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Accounts_Extended' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_Servicio') AND d.FuenteTabla = N'Accounts_Extended' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Accounts_Extended' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_Servicio') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_Servicio · core.Servicio ← Zoho_Mirror.Accounts ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Servicio t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Accounts' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT x.id AS k
      FROM Zoho_Mirror.dbo.Accounts x
WHERE NOT EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.Accounts_Extended e WHERE e.id = x.id)) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM Zoho_Mirror.dbo.Accounts x);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.Servicio t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Accounts' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_Servicio') AND d.FuenteTabla = N'Accounts' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Accounts' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_Servicio') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_ClienteOrigen · core.ClienteOrigen ← Zoho_Mirror.Accounts_Extended ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.ClienteOrigen t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Accounts_Extended' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT x.id AS k
      FROM Zoho_Mirror.dbo.Accounts_Extended x) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM Zoho_Mirror.dbo.Accounts_Extended x);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.ClienteOrigen t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Accounts_Extended' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_ClienteOrigen') AND d.FuenteTabla = N'Accounts_Extended' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Accounts_Extended' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_ClienteOrigen') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_ClienteOrigen · core.ClienteOrigen ← Zoho_Mirror.Accounts ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.ClienteOrigen t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Accounts' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT x.id AS k
      FROM Zoho_Mirror.dbo.Accounts x
WHERE ISNULL(x.deleted, 0) = 0
  AND NOT EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.Accounts_Extended e WHERE e.id = x.id)) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM Zoho_Mirror.dbo.Accounts x);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.ClienteOrigen t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Accounts' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_ClienteOrigen') AND d.FuenteTabla = N'Accounts' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Accounts' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_ClienteOrigen') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_ClienteOrigen · core.ClienteOrigen ← ZBooks_Mirror.contacts ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.ClienteOrigen t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'contacts' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT x.contact_id AS k
      FROM ZBooks_Mirror.dbo.contacts x
WHERE x.contact_type = 'customer' AND NULLIF(LTRIM(x.contact_id), '') IS NOT NULL) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ZBooks_Mirror.dbo.contacts x);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.ClienteOrigen t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'contacts' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_ClienteOrigen') AND d.FuenteTabla = N'contacts' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'contacts' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_ClienteOrigen') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_ClienteOrigen · core.ClienteOrigen ← ADNPayV2.Customer ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.ClienteOrigen t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'Customer' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT CAST(x.[index] AS nvarchar(200)) AS k
      FROM ADNPayV2.dbo.Customer x
WHERE x.status = 'approved') x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNPayV2.dbo.Customer x);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.ClienteOrigen t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'Customer' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_ClienteOrigen') AND d.FuenteTabla = N'Customer' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Customer' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_ClienteOrigen') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_ClienteOrigen · core.ClienteOrigen ← ADNApp.ZohoEngine_zohocustomer ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.ClienteOrigen t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'ZohoEngine_zohocustomer' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT CAST(x.id AS nvarchar(200)) AS k
      FROM ADNApp.dbo.ZohoEngine_zohocustomer x) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNApp.dbo.ZohoEngine_zohocustomer x);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.ClienteOrigen t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'ZohoEngine_zohocustomer' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_ClienteOrigen') AND d.FuenteTabla = N'ZohoEngine_zohocustomer' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'ZohoEngine_zohocustomer' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_ClienteOrigen') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_Contacto · core.Contacto ← Zoho_Mirror.Contacts ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Contacto t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Contacts' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CAST(x.[id] AS nvarchar(200))) AS k
      FROM [Zoho_Mirror].dbo.[Contacts] x) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM [Zoho_Mirror].dbo.[Contacts] x);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.Contacto t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Contacts' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_Contacto') AND d.FuenteTabla = N'Contacts' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Contacts' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_Contacto') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_Producto_CRM · core.Producto ← Zoho_Mirror.Products ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Producto t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Products' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), p.[id])) AS k
      FROM Zoho_Mirror.dbo.[Products] p) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM Zoho_Mirror.dbo.[Products] p);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.Producto t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Products' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_Producto_CRM', N'core_Producto_Books', N'core_Producto_ADNPayServicio', N'core_Producto_ADNPayProducto', N'core_Producto_ADNPayIPTV', N'core_Producto_Onvo') AND d.FuenteTabla = N'Products' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Products' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_Producto_CRM', N'core_Producto_Books', N'core_Producto_ADNPayServicio', N'core_Producto_ADNPayProducto', N'core_Producto_ADNPayIPTV', N'core_Producto_Onvo') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_Producto_Books · core.Producto ← ZBooks_Mirror.items ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Producto t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'items' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), i.[item_id])) AS k
      FROM ZBooks_Mirror.dbo.[items] i
WHERE NOT EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.Products p WHERE p.id = i.zcrm_product_id)) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ZBooks_Mirror.dbo.[items] i);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.Producto t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'items' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_Producto_CRM', N'core_Producto_Books', N'core_Producto_ADNPayServicio', N'core_Producto_ADNPayProducto', N'core_Producto_ADNPayIPTV', N'core_Producto_Onvo') AND d.FuenteTabla = N'items' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'items' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_Producto_CRM', N'core_Producto_Books', N'core_Producto_ADNPayServicio', N'core_Producto_ADNPayProducto', N'core_Producto_ADNPayIPTV', N'core_Producto_Onvo') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_Producto_ADNPayServicio · core.Producto ← ADNPayV2.Service ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Producto t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'Service' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), v.[index])) AS k
      FROM ADNPayV2.dbo.[Service] v) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNPayV2.dbo.[Service] v);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.Producto t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'Service' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_Producto_CRM', N'core_Producto_Books', N'core_Producto_ADNPayServicio', N'core_Producto_ADNPayProducto', N'core_Producto_ADNPayIPTV', N'core_Producto_Onvo') AND d.FuenteTabla = N'Service' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Service' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_Producto_CRM', N'core_Producto_Books', N'core_Producto_ADNPayServicio', N'core_Producto_ADNPayProducto', N'core_Producto_ADNPayIPTV', N'core_Producto_Onvo') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_Producto_ADNPayProducto · core.Producto ← ADNPayV2.Product ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Producto t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'Product' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), v.[product_id])) AS k
      FROM ADNPayV2.dbo.[Product] v) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNPayV2.dbo.[Product] v);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.Producto t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'Product' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_Producto_CRM', N'core_Producto_Books', N'core_Producto_ADNPayServicio', N'core_Producto_ADNPayProducto', N'core_Producto_ADNPayIPTV', N'core_Producto_Onvo') AND d.FuenteTabla = N'Product' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Product' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_Producto_CRM', N'core_Producto_Books', N'core_Producto_ADNPayServicio', N'core_Producto_ADNPayProducto', N'core_Producto_ADNPayIPTV', N'core_Producto_Onvo') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_Producto_ADNPayIPTV · core.Producto ← ADNPayV2.IPTVService ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Producto t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'IPTVService' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), v.[tier_id])) AS k
      FROM ADNPayV2.dbo.[IPTVService] v) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNPayV2.dbo.[IPTVService] v);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.Producto t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'IPTVService' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_Producto_CRM', N'core_Producto_Books', N'core_Producto_ADNPayServicio', N'core_Producto_ADNPayProducto', N'core_Producto_ADNPayIPTV', N'core_Producto_Onvo') AND d.FuenteTabla = N'IPTVService' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'IPTVService' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_Producto_CRM', N'core_Producto_Books', N'core_Producto_ADNPayServicio', N'core_Producto_ADNPayProducto', N'core_Producto_ADNPayIPTV', N'core_Producto_Onvo') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_Producto_Onvo · core.Producto ← ADNPayV2.OnvoProduct ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Producto t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'OnvoProduct' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), v.[id])) AS k
      FROM ADNPayV2.dbo.[OnvoProduct] v
OUTER APPLY (SELECT TOP 1 CAST(pr.unit_amount AS decimal(19,4)) AS Precio, pr.is_active AS Activo,
                    ctl.fn_FechaCR(CONVERT(nvarchar(30), pr.updated_at, 126)) AS Modificado
             FROM ADNPayV2.dbo.OnvoPrice pr WHERE pr.onvo_product_id = v.onvo_product_id
             ORDER BY pr.is_active DESC, pr.updated_at DESC, pr.id DESC) op) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNPayV2.dbo.[OnvoProduct] v);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.Producto t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'OnvoProduct' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_Producto_CRM', N'core_Producto_Books', N'core_Producto_ADNPayServicio', N'core_Producto_ADNPayProducto', N'core_Producto_ADNPayIPTV', N'core_Producto_Onvo') AND d.FuenteTabla = N'OnvoProduct' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'OnvoProduct' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_Producto_CRM', N'core_Producto_Books', N'core_Producto_ADNPayServicio', N'core_Producto_ADNPayProducto', N'core_Producto_ADNPayIPTV', N'core_Producto_Onvo') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_Direccion · core.Direccion ← ADNPayV2.AddressMain ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Direccion t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'AddressMain' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), d.[id])) AS k
      FROM ADNPayV2.dbo.[AddressMain] d) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNPayV2.dbo.[AddressMain] d);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.Direccion t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'AddressMain' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_Direccion') AND d.FuenteTabla = N'AddressMain' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'AddressMain' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_Direccion') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_Prospecto_CRM · core.Prospecto ← Zoho_Mirror.Leads ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Prospecto t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Leads' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), l.[id])) AS k
      FROM Zoho_Mirror.dbo.[Leads] l
LEFT JOIN core.Cliente cl ON cl.FuenteTabla = N'Cedula' AND cl.FuenteLlave = ctl.fn_Cedula(l.Legal_ID) AND EXISTS (SELECT 1 FROM core.ClienteOrigen vo WHERE vo.ClienteId = cl.ClienteId AND vo.Sistema IN ('ZohoCRM', 'ZohoBooks', 'ADNPayV2'))) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM Zoho_Mirror.dbo.[Leads] l);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.Prospecto t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Leads' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_Prospecto_CRM', N'core_Prospecto_ADNPay') AND d.FuenteTabla = N'Leads' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Leads' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_Prospecto_CRM', N'core_Prospecto_ADNPay') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_Prospecto_ADNPay · core.Prospecto ← ADNPayV2.CustomerProspect ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Prospecto t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'CustomerProspect' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), c.[id])) AS k
      FROM ADNPayV2.dbo.[CustomerProspect] c
LEFT JOIN core.Cliente cl ON cl.FuenteTabla = N'Cedula' AND cl.FuenteLlave = ctl.fn_Cedula(c.id_card) AND EXISTS (SELECT 1 FROM core.ClienteOrigen vo WHERE vo.ClienteId = cl.ClienteId AND vo.Sistema IN ('ZohoCRM', 'ZohoBooks', 'ADNPayV2'))) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNPayV2.dbo.[CustomerProspect] c);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.Prospecto t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'CustomerProspect' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_Prospecto_CRM', N'core_Prospecto_ADNPay') AND d.FuenteTabla = N'CustomerProspect' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'CustomerProspect' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_Prospecto_CRM', N'core_Prospecto_ADNPay') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_Oportunidad · core.Oportunidad ← Zoho_Mirror.Deals ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Oportunidad t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Deals' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), d.[id])) AS k
      FROM Zoho_Mirror.dbo.[Deals] d) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM Zoho_Mirror.dbo.[Deals] d);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.Oportunidad t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Deals' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_Oportunidad') AND d.FuenteTabla = N'Deals' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Deals' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_Oportunidad') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_Cotizacion · core.Cotizacion ← Zoho_Mirror.Quotes ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Cotizacion t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Quotes' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), c.[id])) AS k
      FROM Zoho_Mirror.dbo.[Quotes] c) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM Zoho_Mirror.dbo.[Quotes] c);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.Cotizacion t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Quotes' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_Cotizacion') AND d.FuenteTabla = N'Quotes' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Quotes' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_Cotizacion') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_OrdenVenta · core.OrdenVenta ← Zoho_Mirror.Sales_Orders_Extended ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.OrdenVenta t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Sales_Orders_Extended' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), o.[id])) AS k
      FROM Zoho_Mirror.dbo.[Sales_Orders_Extended] o) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM Zoho_Mirror.dbo.[Sales_Orders_Extended] o);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.OrdenVenta t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Sales_Orders_Extended' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_OrdenVenta', N'core_OrdenVenta_Complemento') AND d.FuenteTabla = N'Sales_Orders_Extended' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Sales_Orders_Extended' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_OrdenVenta', N'core_OrdenVenta_Complemento') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_OrdenVenta_Complemento · core.OrdenVenta ← Zoho_Mirror.Sales_Orders ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.OrdenVenta t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Sales_Orders' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), o.[id])) AS k
      FROM Zoho_Mirror.dbo.[Sales_Orders] o
WHERE NOT EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.Sales_Orders_Extended e WHERE e.id = o.id)) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM Zoho_Mirror.dbo.[Sales_Orders] o);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.OrdenVenta t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Sales_Orders' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_OrdenVenta', N'core_OrdenVenta_Complemento') AND d.FuenteTabla = N'Sales_Orders' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Sales_Orders' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_OrdenVenta', N'core_OrdenVenta_Complemento') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_OrdenVentaLinea · core.OrdenVentaLinea ← Zoho_Mirror.Sales_Orders_Products ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.OrdenVentaLinea t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Sales_Orders_Products' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), l.[id])) AS k
      FROM Zoho_Mirror.dbo.[Sales_Orders_Products] l
LEFT JOIN core.OrdenVenta ov ON ov.OrdenVentaCrmId = ctl.fn_Texto(l.sales_order)) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM Zoho_Mirror.dbo.[Sales_Orders_Products] l);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.OrdenVentaLinea t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Sales_Orders_Products' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_OrdenVentaLinea') AND d.FuenteTabla = N'Sales_Orders_Products' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Sales_Orders_Products' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_OrdenVentaLinea') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_OrdenTrabajo · core.OrdenTrabajo ← Zoho_Mirror.Ordenes_de_Trabajo ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.OrdenTrabajo t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Ordenes_de_Trabajo' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), t.[id])) AS k
      FROM Zoho_Mirror.dbo.[Ordenes_de_Trabajo] t) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM Zoho_Mirror.dbo.[Ordenes_de_Trabajo] t);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.OrdenTrabajo t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Ordenes_de_Trabajo' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_OrdenTrabajo') AND d.FuenteTabla = N'Ordenes_de_Trabajo' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Ordenes_de_Trabajo' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_OrdenTrabajo') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_OrdenServicioVoIP · core.OrdenServicioVoIP ← Zoho_Mirror.Orden_de_Servicio_Voz_IP ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.OrdenServicioVoIP t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Orden_de_Servicio_Voz_IP' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), v.[id])) AS k
      FROM Zoho_Mirror.dbo.[Orden_de_Servicio_Voz_IP] v) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM Zoho_Mirror.dbo.[Orden_de_Servicio_Voz_IP] v);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.OrdenServicioVoIP t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Orden_de_Servicio_Voz_IP' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_OrdenServicioVoIP') AND d.FuenteTabla = N'Orden_de_Servicio_Voz_IP' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Orden_de_Servicio_Voz_IP' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_OrdenServicioVoIP') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_Caso · core.Caso ← Zoho_Mirror.Cases_Extended ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Caso t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Cases_Extended' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), c.[CaseId])) AS k
      FROM Zoho_Mirror.dbo.[Cases_Extended] c) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM Zoho_Mirror.dbo.[Cases_Extended] c);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.Caso t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Cases_Extended' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_Caso', N'core_Caso_Complemento') AND d.FuenteTabla = N'Cases_Extended' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Cases_Extended' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_Caso', N'core_Caso_Complemento') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_Caso_Complemento · core.Caso ← Zoho_Mirror.Cases ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Caso t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Cases' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), c.[id])) AS k
      FROM Zoho_Mirror.dbo.[Cases] c
WHERE NOT EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.Cases_Extended e WHERE e.CaseId = c.id)) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM Zoho_Mirror.dbo.[Cases] c);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.Caso t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Cases' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_Caso', N'core_Caso_Complemento') AND d.FuenteTabla = N'Cases' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Cases' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_Caso', N'core_Caso_Complemento') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_Nota_Servicio · core.Nota ← Zoho_Mirror.Accounts_Notes ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Nota t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Accounts_Notes' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), n.[NoteId])) AS k
      FROM Zoho_Mirror.dbo.[Accounts_Notes] n) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM Zoho_Mirror.dbo.[Accounts_Notes] n);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.Nota t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Accounts_Notes' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_Nota_Servicio', N'core_Nota_Caso', N'core_Nota_Cliente') AND d.FuenteTabla = N'Accounts_Notes' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Accounts_Notes' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_Nota_Servicio', N'core_Nota_Caso', N'core_Nota_Cliente') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_Nota_Caso · core.Nota ← Zoho_Mirror.Cases_Notes ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Nota t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Cases_Notes' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), n.[NoteId])) AS k
      FROM Zoho_Mirror.dbo.[Cases_Notes] n) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM Zoho_Mirror.dbo.[Cases_Notes] n);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.Nota t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Cases_Notes' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_Nota_Servicio', N'core_Nota_Caso', N'core_Nota_Cliente') AND d.FuenteTabla = N'Cases_Notes' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Cases_Notes' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_Nota_Servicio', N'core_Nota_Caso', N'core_Nota_Cliente') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_Nota_Cliente · core.Nota ← ZBooks_Mirror.comments_contacts ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Nota t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'comments_contacts' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), n.[id])) AS k
      FROM ZBooks_Mirror.dbo.[comments_contacts] n
OUTER APPLY (SELECT CASE WHEN COUNT(DISTINCT o.ClienteId) = 1 THEN MIN(o.ClienteId) END AS ClienteId
             FROM core.ClienteOrigen o WHERE o.Sistema = 'ZohoBooks' AND o.LlaveOrigen = ctl.fn_Texto(n.contact_id)) co) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ZBooks_Mirror.dbo.[comments_contacts] n);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.Nota t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'comments_contacts' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_Nota_Servicio', N'core_Nota_Caso', N'core_Nota_Cliente') AND d.FuenteTabla = N'comments_contacts' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'comments_contacts' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_Nota_Servicio', N'core_Nota_Caso', N'core_Nota_Cliente') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_Tarea · core.Tarea ← Zoho_Mirror.Tasks ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Tarea t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Tasks' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), t.[id])) AS k
      FROM Zoho_Mirror.dbo.[Tasks] t
CROSS APPLY (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(max), t.What_Id)) AS nvarchar(30)) AS Id) w
OUTER APPLY (SELECT MIN(x.ServicioId) AS Id, COUNT(*) AS n FROM core.Servicio x WHERE x.CuentaCrmId = w.Id) r1
OUTER APPLY (SELECT MIN(x.ServicioId) AS Id, COUNT(*) AS n FROM core.Oportunidad x WHERE x.OportunidadCrmId = w.Id) r2
OUTER APPLY (SELECT MIN(x.ServicioId) AS Id, COUNT(*) AS n FROM core.Caso x WHERE x.CasoCrmId = w.Id) r3
OUTER APPLY (SELECT MIN(x.ServicioId) AS Id, COUNT(*) AS n FROM core.OrdenVenta x WHERE x.OrdenVentaCrmId = w.Id) r4
OUTER APPLY (SELECT MIN(x.ServicioId) AS Id, COUNT(*) AS n FROM core.Cotizacion x WHERE x.CotizacionCrmId = w.Id) r5
OUTER APPLY (SELECT COUNT(*) AS n FROM core.Prospecto x WHERE x.FuenteSistema = 'ZohoCRM' AND x.FuenteTabla = N'Leads' AND x.FuenteLlave = w.Id) r6) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM Zoho_Mirror.dbo.[Tasks] t);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.Tarea t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Tasks' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_Tarea') AND d.FuenteTabla = N'Tasks' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Tasks' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_Tarea') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_Adjunto · core.Adjunto ← Zoho_Mirror.Zoho_Attachments ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Adjunto t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Zoho_Attachments' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), a.[AttachmentId])) AS k
      FROM Zoho_Mirror.dbo.[Zoho_Attachments] a) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM Zoho_Mirror.dbo.[Zoho_Attachments] a);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.Adjunto t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Zoho_Attachments' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_Adjunto') AND d.FuenteTabla = N'Zoho_Attachments' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Zoho_Attachments' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_Adjunto') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_Proveedor · core.Proveedor ← ZBooks_Mirror.contacts ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Proveedor t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'contacts' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), v.[contact_id])) AS k
      FROM ZBooks_Mirror.dbo.[contacts] v
WHERE v.contact_type = 'vendor') x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ZBooks_Mirror.dbo.[contacts] v);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.Proveedor t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'contacts' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_Proveedor') AND d.FuenteTabla = N'contacts' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'contacts' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_Proveedor') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_CuentaBancaria · core.CuentaBancaria ← ZBooks_Mirror.bankaccounts ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.CuentaBancaria t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'bankaccounts' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), b.[account_id])) AS k
      FROM ZBooks_Mirror.dbo.[bankaccounts] b) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ZBooks_Mirror.dbo.[bankaccounts] b);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.CuentaBancaria t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'bankaccounts' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_CuentaBancaria') AND d.FuenteTabla = N'bankaccounts' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'bankaccounts' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_CuentaBancaria') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_MovimientoBancario · core.MovimientoBancario ← ZBooks_Mirror.banktransactions ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.MovimientoBancario t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'banktransactions' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), m.[transaction_id])) AS k
      FROM ZBooks_Mirror.dbo.[banktransactions] m
OUTER APPLY (SELECT CASE WHEN COUNT(DISTINCT o.ClienteId) = 1 THEN MIN(o.ClienteId) END AS ClienteId
             FROM core.ClienteOrigen o WHERE o.Sistema = 'ZohoBooks' AND o.LlaveOrigen = ctl.fn_Texto(m.customer_id)) co) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ZBooks_Mirror.dbo.[banktransactions] m);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.MovimientoBancario t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'banktransactions' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_MovimientoBancario') AND d.FuenteTabla = N'banktransactions' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'banktransactions' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_MovimientoBancario') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_Factura · core.Factura ← ZBooks_Mirror.invoices ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Factura t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'invoices' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), f.[invoice_id])) AS k
      FROM ZBooks_Mirror.dbo.[invoices] f
OUTER APPLY (SELECT CASE WHEN COUNT(DISTINCT o.ClienteId) = 1 THEN MIN(o.ClienteId) END AS ClienteId,
                    CASE WHEN COUNT(DISTINCT o.ServicioId) = 1 THEN MIN(o.ServicioId) END AS ServicioId
             FROM core.ClienteOrigen o WHERE o.Sistema = 'ZohoBooks' AND o.LlaveOrigen = ctl.fn_Texto(f.customer_id)) co
OUTER APPLY (SELECT COUNT(*) AS n, MIN(sv.ServicioId) AS ServicioId FROM core.Servicio sv WHERE sv.ClienteId = co.ClienteId) sc) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ZBooks_Mirror.dbo.[invoices] f);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.Factura t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'invoices' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_Factura') AND d.FuenteTabla = N'invoices' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'invoices' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_Factura') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_FacturaLinea · core.FacturaLinea ← ZBooks_Mirror.invoices_items ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.FacturaLinea t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'invoices_items' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), l.[line_item_id])) AS k
      FROM ZBooks_Mirror.dbo.[invoices_items] l
LEFT JOIN core.Factura f ON f.FacturaBooksId = ctl.fn_Texto(l.invoice_id)) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ZBooks_Mirror.dbo.[invoices_items] l);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.FacturaLinea t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'invoices_items' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_FacturaLinea') AND d.FuenteTabla = N'invoices_items' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'invoices_items' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_FacturaLinea') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_FacturaRecurrente · core.FacturaRecurrente ← ZBooks_Mirror.recurringinvoices ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.FacturaRecurrente t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'recurringinvoices' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), r.[recurring_invoice_id])) AS k
      FROM ZBooks_Mirror.dbo.[recurringinvoices] r
OUTER APPLY (SELECT CASE WHEN COUNT(DISTINCT o.ClienteId) = 1 THEN MIN(o.ClienteId) END AS ClienteId,
                    CASE WHEN COUNT(DISTINCT o.ServicioId) = 1 THEN MIN(o.ServicioId) END AS ServicioId
             FROM core.ClienteOrigen o WHERE o.Sistema = 'ZohoBooks' AND o.LlaveOrigen = ctl.fn_Texto(r.customer_id)) co
OUTER APPLY (SELECT COUNT(*) AS n, MIN(sv.ServicioId) AS ServicioId FROM core.Servicio sv WHERE sv.ClienteId = co.ClienteId) sc) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ZBooks_Mirror.dbo.[recurringinvoices] r);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.FacturaRecurrente t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'recurringinvoices' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_FacturaRecurrente') AND d.FuenteTabla = N'recurringinvoices' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'recurringinvoices' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_FacturaRecurrente') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_Pago · core.Pago ← ZBooks_Mirror.customerpayments ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Pago t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'customerpayments' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), p.[payment_id])) AS k
      FROM ZBooks_Mirror.dbo.[customerpayments] p
OUTER APPLY (SELECT CASE WHEN COUNT(DISTINCT o.ClienteId) = 1 THEN MIN(o.ClienteId) END AS ClienteId,
                    CASE WHEN COUNT(DISTINCT o.ServicioId) = 1 THEN MIN(o.ServicioId) END AS ServicioId
             FROM core.ClienteOrigen o WHERE o.Sistema = 'ZohoBooks' AND o.LlaveOrigen = ctl.fn_Texto(p.customer_id)) co
OUTER APPLY (SELECT COUNT(*) AS n, MIN(sv.ServicioId) AS ServicioId FROM core.Servicio sv WHERE sv.ClienteId = co.ClienteId) sc) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ZBooks_Mirror.dbo.[customerpayments] p);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.Pago t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'customerpayments' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_Pago') AND d.FuenteTabla = N'customerpayments' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'customerpayments' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_Pago') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_PagoFactura · core.PagoFactura ← ZBooks_Mirror.customerpayments ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.PagoFactura t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'customerpayments' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT CONCAT(ctl.fn_Texto(p.payment_id), N'|', n.Numero) AS k
      FROM ZBooks_Mirror.dbo.customerpayments p
CROSS APPLY (SELECT DISTINCT CAST(ctl.fn_Texto(v.value) AS nvarchar(50)) AS Numero
             FROM STRING_SPLIT(REPLACE(CONVERT(nvarchar(max), p.invoice_numbers), N';', N','), N',') v
             WHERE ctl.fn_Texto(v.value) IS NOT NULL) n) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ZBooks_Mirror.dbo.customerpayments p);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.PagoFactura t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'customerpayments' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_PagoFactura') AND d.FuenteTabla = N'customerpayments' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'customerpayments' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_PagoFactura') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_Gasto · core.Gasto ← ZBooks_Mirror.expenses ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Gasto t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'expenses' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), e.[expense_id])) AS k
      FROM ZBooks_Mirror.dbo.[expenses] e) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ZBooks_Mirror.dbo.[expenses] e);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.Gasto t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'expenses' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_Gasto') AND d.FuenteTabla = N'expenses' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'expenses' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_Gasto') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_OrdenCompra · core.OrdenCompra ← ZBooks_Mirror.purchaseorders ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.OrdenCompra t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'purchaseorders' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), o.[purchaseorder_id])) AS k
      FROM ZBooks_Mirror.dbo.[purchaseorders] o) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ZBooks_Mirror.dbo.[purchaseorders] o);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.OrdenCompra t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'purchaseorders' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_OrdenCompra') AND d.FuenteTabla = N'purchaseorders' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'purchaseorders' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_OrdenCompra') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_HistorialEstadoCliente · core.HistorialEstadoCliente ← History_Tables.customer_status_zbooks ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.HistorialEstadoCliente t WHERE t.FuenteBase = N'History_Tables' AND t.FuenteTabla = N'customer_status_zbooks' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT CONCAT(ctl.fn_Texto(h.custome_id), N'|', CONVERT(nvarchar(30), h.modification_date, 126), N'|', ctl.fn_Texto(h.customer_status)) AS k
      FROM History_Tables.dbo.[customer_status_zbooks] h
OUTER APPLY (SELECT CASE WHEN COUNT(DISTINCT o.ClienteId) = 1 THEN MIN(o.ClienteId) END AS ClienteId
             FROM core.ClienteOrigen o WHERE o.Sistema = 'ZohoBooks' AND o.LlaveOrigen = ctl.fn_Texto(h.custome_id)) co) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM History_Tables.dbo.[customer_status_zbooks] h);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.HistorialEstadoCliente t WHERE t.FuenteBase = N'History_Tables' AND t.FuenteTabla = N'customer_status_zbooks' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_HistorialEstadoCliente') AND d.FuenteTabla = N'customer_status_zbooks' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'customer_status_zbooks' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_HistorialEstadoCliente') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_FacturaElectronicaProveedor · core.FacturaElectronicaProveedor ← ADNApp.XMLEngine_invoicexmlfiles ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.FacturaElectronicaProveedor t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'XMLEngine_invoicexmlfiles' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), x.[invoice_number])) AS k
      FROM ADNApp.dbo.[XMLEngine_invoicexmlfiles] x) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNApp.dbo.[XMLEngine_invoicexmlfiles] x);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.FacturaElectronicaProveedor t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'XMLEngine_invoicexmlfiles' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_FacturaElectronicaProveedor') AND d.FuenteTabla = N'XMLEngine_invoicexmlfiles' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'XMLEngine_invoicexmlfiles' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_FacturaElectronicaProveedor') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== ref_ProveedorTelefonia · ref.ProveedorTelefonia ← ADNApp.Telephony_provider ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM ref.ProveedorTelefonia t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_provider' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), p.[id])) AS k
      FROM ADNApp.dbo.[Telephony_provider] p) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNApp.dbo.[Telephony_provider] p);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM ref.ProveedorTelefonia t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_provider' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'ref_ProveedorTelefonia') AND d.FuenteTabla = N'Telephony_provider' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Telephony_provider' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'ref_ProveedorTelefonia') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== ref_TroncalProveedor · ref.TroncalProveedor ← ADNApp.Telephony_providertrunk ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM ref.TroncalProveedor t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_providertrunk' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), t.[id])) AS k
      FROM ADNApp.dbo.[Telephony_providertrunk] t) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNApp.dbo.[Telephony_providertrunk] t);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM ref.TroncalProveedor t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_providertrunk' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'ref_TroncalProveedor') AND d.FuenteTabla = N'Telephony_providertrunk' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Telephony_providertrunk' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'ref_TroncalProveedor') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== ref_TarifaDestino · ref.TarifaDestino ← ADNApp.Telephony_countrydialcoderate ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM ref.TarifaDestino t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_countrydialcoderate' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), r.[id])) AS k
      FROM ADNApp.dbo.[Telephony_countrydialcoderate] r) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNApp.dbo.[Telephony_countrydialcoderate] r);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM ref.TarifaDestino t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_countrydialcoderate' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'ref_TarifaDestino', N'ref_TarifaNumeroEspecial') AND d.FuenteTabla = N'Telephony_countrydialcoderate' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Telephony_countrydialcoderate' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'ref_TarifaDestino', N'ref_TarifaNumeroEspecial') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== ref_TarifaNumeroEspecial · ref.TarifaDestino ← ADNApp.Telephony_specialnumberrate ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM ref.TarifaDestino t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_specialnumberrate' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), r.[id])) AS k
      FROM ADNApp.dbo.[Telephony_specialnumberrate] r) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNApp.dbo.[Telephony_specialnumberrate] r);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM ref.TarifaDestino t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_specialnumberrate' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'ref_TarifaDestino', N'ref_TarifaNumeroEspecial') AND d.FuenteTabla = N'Telephony_specialnumberrate' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Telephony_specialnumberrate' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'ref_TarifaDestino', N'ref_TarifaNumeroEspecial') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== ref_PaqueteMinutos · ref.PaqueteMinutos ← ADNApp.Telephony_minutepackage ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM ref.PaqueteMinutos t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_minutepackage' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), m.[id])) AS k
      FROM ADNApp.dbo.[Telephony_minutepackage] m) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNApp.dbo.[Telephony_minutepackage] m);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM ref.PaqueteMinutos t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_minutepackage' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'ref_PaqueteMinutos') AND d.FuenteTabla = N'Telephony_minutepackage' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Telephony_minutepackage' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'ref_PaqueteMinutos') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== ref_PaqueteMinutosCodigo · ref.PaqueteMinutosCodigo ← ADNApp.Telephony_minutepackagedialcode ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM ref.PaqueteMinutosCodigo t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_minutepackagedialcode' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), m.[id])) AS k
      FROM ADNApp.dbo.[Telephony_minutepackagedialcode] m) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNApp.dbo.[Telephony_minutepackagedialcode] m);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM ref.PaqueteMinutosCodigo t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_minutepackagedialcode' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'ref_PaqueteMinutosCodigo') AND d.FuenteTabla = N'Telephony_minutepackagedialcode' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Telephony_minutepackagedialcode' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'ref_PaqueteMinutosCodigo') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_Troncal · core.Troncal ← ADNApp.Telephony_trunk ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Troncal t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_trunk' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), t.[id])) AS k
      FROM ADNApp.dbo.[Telephony_trunk] t) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNApp.dbo.[Telephony_trunk] t);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.Troncal t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_trunk' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_Troncal') AND d.FuenteTabla = N'Telephony_trunk' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Telephony_trunk' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_Troncal') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_TroncalPermisoCodigo · core.TroncalPermisoCodigo ← ADNApp.Telephony_trunkpermissiondialcode ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.TroncalPermisoCodigo t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_trunkpermissiondialcode' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), d.[id])) AS k
      FROM ADNApp.dbo.[Telephony_trunkpermissiondialcode] d) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNApp.dbo.[Telephony_trunkpermissiondialcode] d);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.TroncalPermisoCodigo t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_trunkpermissiondialcode' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_TroncalPermisoCodigo') AND d.FuenteTabla = N'Telephony_trunkpermissiondialcode' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Telephony_trunkpermissiondialcode' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_TroncalPermisoCodigo') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_AlertaTroncal · core.AlertaTroncal ← ADNApp.Telephony_alertblockedtrunk ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.AlertaTroncal t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_alertblockedtrunk' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), a.[id])) AS k
      FROM ADNApp.dbo.[Telephony_alertblockedtrunk] a) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNApp.dbo.[Telephony_alertblockedtrunk] a);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.AlertaTroncal t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_alertblockedtrunk' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_AlertaTroncal') AND d.FuenteTabla = N'Telephony_alertblockedtrunk' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Telephony_alertblockedtrunk' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_AlertaTroncal') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_LineaGratuita · core.LineaGratuita ← ADNApp.Telephony_freelines ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.LineaGratuita t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_freelines' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), l.[id])) AS k
      FROM ADNApp.dbo.[Telephony_freelines] l) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNApp.dbo.[Telephony_freelines] l);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.LineaGratuita t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_freelines' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_LineaGratuita') AND d.FuenteTabla = N'Telephony_freelines' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Telephony_freelines' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_LineaGratuita') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_ServicioPaqueteMinutos · core.ServicioPaqueteMinutos ← ADNApp.Telephony_customerminutepackage ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.ServicioPaqueteMinutos t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_customerminutepackage' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), c.[id])) AS k
      FROM ADNApp.dbo.[Telephony_customerminutepackage] c) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNApp.dbo.[Telephony_customerminutepackage] c);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.ServicioPaqueteMinutos t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_customerminutepackage' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_ServicioPaqueteMinutos') AND d.FuenteTabla = N'Telephony_customerminutepackage' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Telephony_customerminutepackage' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_ServicioPaqueteMinutos') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_MinutosHistorico_Cliente · core.MinutosContratadosHistorico ← ADNApp.Minutos_Customer ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.MinutosContratadosHistorico t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Minutos_Customer' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT CONVERT(nvarchar(66), HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(4000), m.[Description]), N'~'), ISNULL(CONVERT(nvarchar(4000), m.[Minutes]), N'~'), ISNULL(CONVERT(nvarchar(4000), m.[Customer_id]), N'~'))), 2) AS k
      FROM ADNApp.dbo.[Minutos_Customer] m
OUTER APPLY (SELECT CASE WHEN COUNT(DISTINCT o.ServicioId) = 1 THEN MIN(o.ServicioId) END AS ServicioId,
                    CASE WHEN COUNT(DISTINCT o.ClienteId) = 1 THEN MIN(o.ClienteId) END AS ClienteId
             FROM core.ClienteOrigen o WHERE o.Sistema = 'AppDataCR'
               AND o.LlaveOrigen = CAST(TRY_CONVERT(bigint, m.Customer_id) AS nvarchar(200))) co) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNApp.dbo.[Minutos_Customer] m);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.MinutosContratadosHistorico t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Minutos_Customer' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_MinutosHistorico_Cliente', N'core_MinutosHistorico_Cedula') AND d.FuenteTabla = N'Minutos_Customer' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Minutos_Customer' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_MinutosHistorico_Cliente', N'core_MinutosHistorico_Cedula') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_MinutosHistorico_Cedula · core.MinutosContratadosHistorico ← ADNApp.MinutosLegalId ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.MinutosContratadosHistorico t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'MinutosLegalId' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT CONVERT(nvarchar(66), HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(4000), m.[IDCard]), N'~'), ISNULL(CONVERT(nvarchar(4000), m.[MinutosFijo]), N'~'), ISNULL(CONVERT(nvarchar(4000), m.[MinutosCelular]), N'~'))), 2) AS k
      FROM ADNApp.dbo.[MinutosLegalId] m) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNApp.dbo.[MinutosLegalId] m);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.MinutosContratadosHistorico t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'MinutosLegalId' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_MinutosHistorico_Cliente', N'core_MinutosHistorico_Cedula') AND d.FuenteTabla = N'MinutosLegalId' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'MinutosLegalId' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_MinutosHistorico_Cliente', N'core_MinutosHistorico_Cedula') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_ArchivoCDR · core.ArchivoCDR ← ADNApp.Telephony_insertedcdrfiles ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.ArchivoCDR t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_insertedcdrfiles' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), f.[id])) AS k
      FROM ADNApp.dbo.[Telephony_insertedcdrfiles] f) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNApp.dbo.[Telephony_insertedcdrfiles] f);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.ArchivoCDR t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_insertedcdrfiles' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_ArchivoCDR') AND d.FuenteTabla = N'Telephony_insertedcdrfiles' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Telephony_insertedcdrfiles' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_ArchivoCDR') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_CorteVoIP · core.CorteVoIP ← ADNApp.ZohoEngine_zohocustomervoipbill ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.CorteVoIP t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'ZohoEngine_zohocustomervoipbill' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), b.[id])) AS k
      FROM ADNApp.dbo.[ZohoEngine_zohocustomervoipbill] b) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNApp.dbo.[ZohoEngine_zohocustomervoipbill] b);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.CorteVoIP t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'ZohoEngine_zohocustomervoipbill' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_CorteVoIP') AND d.FuenteTabla = N'ZohoEngine_zohocustomervoipbill' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'ZohoEngine_zohocustomervoipbill' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_CorteVoIP') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_ConsumoVoIP_Corte · core.ConsumoVoIP ← ADNApp.ZohoEngine_zohocustomervoipbillservice ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.ConsumoVoIP t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'ZohoEngine_zohocustomervoipbillservice' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), s.[id])) AS k
      FROM ADNApp.dbo.[ZohoEngine_zohocustomervoipbillservice] s
LEFT JOIN core.CorteVoIP cv ON cv.FuenteBase = N'ADNApp' AND cv.FuenteLlave = CAST(s.zoho_customer_voip_bill_id AS nvarchar(200))) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNApp.dbo.[ZohoEngine_zohocustomervoipbillservice] s);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.ConsumoVoIP t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'ZohoEngine_zohocustomervoipbillservice' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_ConsumoVoIP_Corte', N'core_ConsumoVoIP_Factura') AND d.FuenteTabla = N'ZohoEngine_zohocustomervoipbillservice' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'ZohoEngine_zohocustomervoipbillservice' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_ConsumoVoIP_Corte', N'core_ConsumoVoIP_Factura') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_ConsumoVoIP_Factura · core.ConsumoVoIP ← ADNApp.ZohoEngine_invoicevoip ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.ConsumoVoIP t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'ZohoEngine_invoicevoip' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), i.[id])) AS k
      FROM ADNApp.dbo.[ZohoEngine_invoicevoip] i) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNApp.dbo.[ZohoEngine_invoicevoip] i);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.ConsumoVoIP t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'ZohoEngine_invoicevoip' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_ConsumoVoIP_Corte', N'core_ConsumoVoIP_Factura') AND d.FuenteTabla = N'ZohoEngine_invoicevoip' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'ZohoEngine_invoicevoip' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_ConsumoVoIP_Corte', N'core_ConsumoVoIP_Factura') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_Llamada_Historico · core.Llamada ← ADNApp.Telephony_cdr_historico ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Llamada t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_cdr_historico' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT CAST(c.id AS nvarchar(200)) AS k, c.StartDateTime AS f
      FROM ADNApp.dbo.Telephony_cdr_historico c) x
WHERE x.f >= @Ini AND x.f < @Fin AND CONVERT(char(7), x.f, 126) IN (SELECT Mes FROM #m);
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNApp.dbo.Telephony_cdr_historico c WHERE c.StartDateTime >= @Ini AND c.StartDateTime < @Fin AND CONVERT(char(7), c.StartDateTime, 126) IN (SELECT Mes FROM #m));
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.Llamada t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_cdr_historico' AND t.FuenteLlave IS NOT NULL AND CONVERT(char(7), t.FechaDato, 126) IN (SELECT Mes FROM #m);
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_Llamada_Historico', N'core_Llamada_SQL', N'core_Llamada') AND d.FuenteTabla = N'Telephony_cdr_historico' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Telephony_cdr_historico' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_Llamada_Historico', N'core_Llamada_SQL', N'core_Llamada') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_Llamada_SQL · core.Llamada ← ADNApp.Telephony_cdr ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Llamada t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_cdr' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT CAST(c.id AS nvarchar(200)) AS k, c.StartDateTime AS f
      FROM ADNApp.dbo.Telephony_cdr c) x
WHERE x.f >= @Ini AND x.f < @Fin AND CONVERT(char(7), x.f, 126) IN (SELECT Mes FROM #m);
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNApp.dbo.Telephony_cdr c WHERE c.StartDateTime >= @Ini AND c.StartDateTime < @Fin AND CONVERT(char(7), c.StartDateTime, 126) IN (SELECT Mes FROM #m));
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.Llamada t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_cdr' AND t.FuenteLlave IS NOT NULL AND CONVERT(char(7), t.FechaDato, 126) IN (SELECT Mes FROM #m);
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_Llamada_Historico', N'core_Llamada_SQL', N'core_Llamada') AND d.FuenteTabla = N'Telephony_cdr' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Telephony_cdr' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_Llamada_Historico', N'core_Llamada_SQL', N'core_Llamada') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_Llamada · core.Llamada ← developer_adn_app_db.Telephony_cdr ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Llamada t WHERE t.FuenteBase = N'developer_adn_app_db' AND t.FuenteTabla = N'Telephony_cdr' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT CAST(c._id AS nvarchar(200)) AS k, c.StartDateTime AS f
      FROM stg.mongo_Telephony_cdr c) x
WHERE x.f >= @Ini AND x.f < @Fin AND CONVERT(char(7), x.f, 126) IN (SELECT Mes FROM #m);
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM stg.mongo_Telephony_cdr c WHERE c.StartDateTime >= @Ini AND c.StartDateTime < @Fin AND CONVERT(char(7), c.StartDateTime, 126) IN (SELECT Mes FROM #m));
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.Llamada t WHERE t.FuenteBase = N'developer_adn_app_db' AND t.FuenteTabla = N'Telephony_cdr' AND t.FuenteLlave IS NOT NULL AND CONVERT(char(7), t.FechaDato, 126) IN (SELECT Mes FROM #m);
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_Llamada_Historico', N'core_Llamada_SQL', N'core_Llamada') AND d.FuenteTabla = N'Telephony_cdr' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Telephony_cdr' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_Llamada_Historico', N'core_Llamada_SQL', N'core_Llamada') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_SolicitudEnLinea · core.SolicitudEnLinea ← ADNPayV2.Customer ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.SolicitudEnLinea t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'Customer' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), c.[index])) AS k
      FROM ADNPayV2.dbo.[Customer] c
OUTER APPLY (SELECT MIN(o.ClienteId) AS ClienteId FROM core.ClienteOrigen o
             WHERE o.Sistema = 'ADNPayV2' AND o.LlaveOrigen = CAST(c.[index] AS nvarchar(200))) co
LEFT JOIN core.Cliente cl ON cl.FuenteTabla = N'Cedula' AND cl.FuenteLlave = ctl.fn_Cedula(c.id)
    AND EXISTS (SELECT 1 FROM core.ClienteOrigen vo WHERE vo.ClienteId = cl.ClienteId AND vo.Sistema IN ('ZohoCRM', 'ZohoBooks', 'ADNPayV2'))) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNPayV2.dbo.[Customer] c);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.SolicitudEnLinea t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'Customer' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_SolicitudEnLinea') AND d.FuenteTabla = N'Customer' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Customer' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_SolicitudEnLinea') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_PagoEnLinea · core.PagoEnLinea ← ADNPayV2.OnvoCheckoutSession ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.PagoEnLinea t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'OnvoCheckoutSession' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), s.[session_index])) AS k
      FROM ADNPayV2.dbo.[OnvoCheckoutSession] s) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNPayV2.dbo.[OnvoCheckoutSession] s);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.PagoEnLinea t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'OnvoCheckoutSession' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_PagoEnLinea') AND d.FuenteTabla = N'OnvoCheckoutSession' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'OnvoCheckoutSession' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_PagoEnLinea') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_Reserva_Visita · core.ReservaInstalacion ← ADNPayV2.Visitdate ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.ReservaInstalacion t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'Visitdate' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), v.[id])) AS k
      FROM ADNPayV2.dbo.[Visitdate] v) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNPayV2.dbo.[Visitdate] v);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.ReservaInstalacion t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'Visitdate' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_Reserva_Visita', N'core_Reserva_Servicio') AND d.FuenteTabla = N'Visitdate' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Visitdate' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_Reserva_Visita', N'core_Reserva_Servicio') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_Reserva_Servicio · core.ReservaInstalacion ← ADNPayV2.ServiceReservations ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.ReservaInstalacion t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'ServiceReservations' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), r.[reservation_id])) AS k
      FROM ADNPayV2.dbo.[ServiceReservations] r) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNPayV2.dbo.[ServiceReservations] r);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.ReservaInstalacion t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'ServiceReservations' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_Reserva_Visita', N'core_Reserva_Servicio') AND d.FuenteTabla = N'ServiceReservations' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'ServiceReservations' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_Reserva_Visita', N'core_Reserva_Servicio') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_OrdenEnLinea_Venta · core.OrdenEnLinea ← ADNPayV2.SaleOrder ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.OrdenEnLinea t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'SaleOrder' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), o.[order_id])) AS k
      FROM ADNPayV2.dbo.[SaleOrder] o) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNPayV2.dbo.[SaleOrder] o);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.OrdenEnLinea t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'SaleOrder' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_OrdenEnLinea_Venta', N'core_OrdenEnLinea_Carrito') AND d.FuenteTabla = N'SaleOrder' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'SaleOrder' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_OrdenEnLinea_Venta', N'core_OrdenEnLinea_Carrito') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_OrdenEnLinea_Carrito · core.OrdenEnLinea ← ADNPayV2.Cart ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.OrdenEnLinea t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'Cart' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), k.[cart_id])) AS k
      FROM ADNPayV2.dbo.[Cart] k) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNPayV2.dbo.[Cart] k);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.OrdenEnLinea t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'Cart' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_OrdenEnLinea_Venta', N'core_OrdenEnLinea_Carrito') AND d.FuenteTabla = N'Cart' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Cart' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_OrdenEnLinea_Venta', N'core_OrdenEnLinea_Carrito') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_OrdenEnLineaLinea_Venta · core.OrdenEnLineaLinea ← ADNPayV2.SaleOrderLine ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.OrdenEnLineaLinea t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'SaleOrderLine' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), l.[line_id])) AS k
      FROM ADNPayV2.dbo.[SaleOrderLine] l) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNPayV2.dbo.[SaleOrderLine] l);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.OrdenEnLineaLinea t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'SaleOrderLine' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_OrdenEnLineaLinea_Venta', N'core_OrdenEnLineaLinea_Carrito') AND d.FuenteTabla = N'SaleOrderLine' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'SaleOrderLine' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_OrdenEnLineaLinea_Venta', N'core_OrdenEnLineaLinea_Carrito') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_OrdenEnLineaLinea_Carrito · core.OrdenEnLineaLinea ← ADNPayV2.CartLine ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.OrdenEnLineaLinea t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'CartLine' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), l.[line_id])) AS k
      FROM ADNPayV2.dbo.[CartLine] l) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNPayV2.dbo.[CartLine] l);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.OrdenEnLineaLinea t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'CartLine' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_OrdenEnLineaLinea_Venta', N'core_OrdenEnLineaLinea_Carrito') AND d.FuenteTabla = N'CartLine' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'CartLine' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_OrdenEnLineaLinea_Venta', N'core_OrdenEnLineaLinea_Carrito') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_AprovisionamientoOdoo · core.AprovisionamientoOdoo ← ADNPayV2.OdooProvisioning ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.AprovisionamientoOdoo t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'OdooProvisioning' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), a.[id])) AS k
      FROM ADNPayV2.dbo.[OdooProvisioning] a) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ADNPayV2.dbo.[OdooProvisioning] a);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.AprovisionamientoOdoo t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'OdooProvisioning' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_AprovisionamientoOdoo') AND d.FuenteTabla = N'OdooProvisioning' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'OdooProvisioning' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_AprovisionamientoOdoo') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== ref_UnidadFlota · ref.UnidadFlota ← Navsat.Dispositivo ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM ref.UnidadFlota t WHERE t.FuenteBase = N'Navsat' AND t.FuenteTabla = N'Dispositivo' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT CAST(ctl.fn_Texto(u.d) AS nvarchar(100)) AS k
      FROM (SELECT deviceName AS d FROM Navsat.dbo.Ultima_ubicacion UNION ALL SELECT DeviceName FROM Navsat.dbo.viajes_ayer_finalizado
      UNION ALL SELECT dispositivo FROM Navsat.dbo.eventos UNION ALL SELECT dispositivo FROM Navsat.dbo.Eco_Driving) u) x;
DECLARE @FilasOrigen bigint = CAST(NULL AS bigint);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM ref.UnidadFlota t WHERE t.FuenteBase = N'Navsat' AND t.FuenteTabla = N'Dispositivo' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'ref_UnidadFlota') AND d.FuenteTabla = N'Dispositivo' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Dispositivo' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'ref_UnidadFlota') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_UbicacionFlota · core.UbicacionFlota ← Navsat.Ultima_ubicacion ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.UbicacionFlota t WHERE t.FuenteBase = N'Navsat' AND t.FuenteTabla = N'Ultima_ubicacion' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT CONVERT(nvarchar(66), HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(4000), u.[deviceName]), N'~'), ISNULL(CONVERT(nvarchar(4000), u.[crDateTime]), N'~'), ISNULL(CONVERT(nvarchar(4000), u.[latitude]), N'~'), ISNULL(CONVERT(nvarchar(4000), u.[longitude]), N'~'))), 2) AS k, ctl.fn_FechaCR(u.crDateTime) AS f
      FROM Navsat.dbo.[Ultima_ubicacion] u
WHERE (@Desde IS NULL OR ctl.fn_FechaCR(u.crDateTime) >= TODATETIMEOFFSET(CAST(@Desde AS datetime2), '-06:00')) AND (@Hasta IS NULL OR ctl.fn_FechaCR(u.crDateTime) < TODATETIMEOFFSET(CAST(@Hasta AS datetime2), '-06:00'))) x
WHERE x.f >= @Ini AND x.f < @Fin AND CONVERT(char(7), x.f, 126) IN (SELECT Mes FROM #m);
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM Navsat.dbo.[Ultima_ubicacion] u WHERE ctl.fn_FechaCR(u.crDateTime) >= @Ini AND ctl.fn_FechaCR(u.crDateTime) < @Fin AND CONVERT(char(7), ctl.fn_FechaCR(u.crDateTime), 126) IN (SELECT Mes FROM #m));
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.UbicacionFlota t WHERE t.FuenteBase = N'Navsat' AND t.FuenteTabla = N'Ultima_ubicacion' AND t.FuenteLlave IS NOT NULL AND CONVERT(char(7), t.FechaDato, 126) IN (SELECT Mes FROM #m);
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_UbicacionFlota') AND d.FuenteTabla = N'Ultima_ubicacion' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Ultima_ubicacion' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_UbicacionFlota') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_ViajeFlota · core.ViajeFlota ← Navsat.viajes_ayer_finalizado ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.ViajeFlota t WHERE t.FuenteBase = N'Navsat' AND t.FuenteTabla = N'viajes_ayer_finalizado' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT CONVERT(nvarchar(66), HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(4000), v.[DeviceName]), N'~'), ISNULL(CONVERT(nvarchar(30), v.[FechaInicio], 126), N'~'), ISNULL(CONVERT(nvarchar(30), v.[FechaFin], 126), N'~'), ISNULL(CONVERT(nvarchar(4000), v.[KilometrosRecorridos]), N'~'))), 2) AS k
      FROM Navsat.dbo.[viajes_ayer_finalizado] v) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM Navsat.dbo.[viajes_ayer_finalizado] v);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.ViajeFlota t WHERE t.FuenteBase = N'Navsat' AND t.FuenteTabla = N'viajes_ayer_finalizado' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_ViajeFlota') AND d.FuenteTabla = N'viajes_ayer_finalizado' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'viajes_ayer_finalizado' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_ViajeFlota') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_EventoFlota · core.EventoFlota ← Navsat.eventos ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.EventoFlota t WHERE t.FuenteBase = N'Navsat' AND t.FuenteTabla = N'eventos' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT CONVERT(nvarchar(66), HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(4000), e.[dispositivo]), N'~'), ISNULL(CONVERT(nvarchar(30), e.[fecha], 126), N'~'), ISNULL(CONVERT(nvarchar(4000), e.[evento]), N'~'), ISNULL(CONVERT(nvarchar(4000), e.[regla]), N'~'), ISNULL(CONVERT(nvarchar(4000), e.[latitude]), N'~'), ISNULL(CONVERT(nvarchar(4000), e.[longitude]), N'~'))), 2) AS k
      FROM Navsat.dbo.[eventos] e) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM Navsat.dbo.[eventos] e);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.EventoFlota t WHERE t.FuenteBase = N'Navsat' AND t.FuenteTabla = N'eventos' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_EventoFlota') AND d.FuenteTabla = N'eventos' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'eventos' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_EventoFlota') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_IncidenteConduccion · core.IncidenteConduccion ← Navsat.Eco_Driving ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.IncidenteConduccion t WHERE t.FuenteBase = N'Navsat' AND t.FuenteTabla = N'Eco_Driving' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT CONVERT(nvarchar(66), HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(4000), d.[dispositivo]), N'~'), ISNULL(CONVERT(nvarchar(30), d.[fecha_hora_incidente], 126), N'~'), ISNULL(CONVERT(nvarchar(4000), d.[id_evento]), N'~'), ISNULL(CONVERT(nvarchar(4000), d.[tipo_incidente]), N'~'))), 2) AS k
      FROM Navsat.dbo.[Eco_Driving] d) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM Navsat.dbo.[Eco_Driving] d);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.IncidenteConduccion t WHERE t.FuenteBase = N'Navsat' AND t.FuenteTabla = N'Eco_Driving' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_IncidenteConduccion') AND d.FuenteTabla = N'Eco_Driving' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Eco_Driving' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_IncidenteConduccion') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_CheckInCampo · core.CheckInCampo ← History_Tables.check_in_navsat ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.CheckInCampo t WHERE t.FuenteBase = N'History_Tables' AND t.FuenteTabla = N'check_in_navsat' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), c.[Id])) AS k
      FROM History_Tables.dbo.[check_in_navsat] c) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM History_Tables.dbo.[check_in_navsat] c);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.CheckInCampo t WHERE t.FuenteBase = N'History_Tables' AND t.FuenteTabla = N'check_in_navsat' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_CheckInCampo') AND d.FuenteTabla = N'check_in_navsat' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'check_in_navsat' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_CheckInCampo') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_EventoConexion · core.EventoConexion ← History_Tables.Conexiones_desconexiones_realizadas ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.EventoConexion t WHERE t.FuenteBase = N'History_Tables' AND t.FuenteTabla = N'Conexiones_desconexiones_realizadas' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT CONVERT(nvarchar(66), HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(4000), x.[customer_name]), N'~'), ISNULL(CONVERT(nvarchar(4000), x.[type]), N'~'), ISNULL(CONVERT(nvarchar(30), x.[date], 126), N'~'), ISNULL(CONVERT(nvarchar(4000), x.[realized_by]), N'~'), ISNULL(CONVERT(nvarchar(4000), x.[type_desc_rec]), N'~'), ISNULL(CONVERT(nvarchar(30), x.[date_desc_rec], 126), N'~'))), 2) AS k
      FROM History_Tables.dbo.[Conexiones_desconexiones_realizadas] x
OUTER APPLY (SELECT CASE WHEN COUNT(DISTINCT o.ClienteId) = 1 THEN MIN(o.ClienteId) END AS ClienteId
             FROM core.ClienteOrigen o WHERE o.Sistema = 'ZohoBooks' AND o.LlaveOrigen = ctl.fn_Texto(x.customer_name)) co) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM History_Tables.dbo.[Conexiones_desconexiones_realizadas] x);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.EventoConexion t WHERE t.FuenteBase = N'History_Tables' AND t.FuenteTabla = N'Conexiones_desconexiones_realizadas' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_EventoConexion') AND d.FuenteTabla = N'Conexiones_desconexiones_realizadas' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'Conexiones_desconexiones_realizadas' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_EventoConexion') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO

/* ===== core_TicketAtencion · core.TicketAtencion ← ZCRM2Trengo.trengo_data_tickets ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.TicketAtencion t WHERE t.FuenteBase = N'ZCRM2Trengo' AND t.FuenteTabla = N'trengo_data_tickets' AND t.FechaDato IS NOT NULL;
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT ctl.fn_Texto(CONVERT(nvarchar(200), t.[id_case])) AS k
      FROM ZCRM2Trengo.dbo.[trengo_data_tickets] t
CROSS APPLY (SELECT CONVERT(nvarchar(max), t.custom_data) COLLATE DATABASE_DEFAULT AS cd) d0
CROSS APPLY (SELECT CASE WHEN CHARINDEX(N'ID_ZCRM', d0.cd) > 0 THEN
                    NULLIF(LEFT(LTRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(d0.cd, CHARINDEX(N'ID_ZCRM', d0.cd) + 7, 60), N'''', N''), N'"', N''), N':', N'')), 19), N'')
                END COLLATE DATABASE_DEFAULT AS IdZcrm) z
OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(k.ContactoId) END AS ContactoId,
                    CASE WHEN COUNT(*) = 1 THEN MIN(k.ServicioId) END AS ServicioId
             FROM core.Contacto k WHERE k.ContactoCrmId = z.IdZcrm) ct) x;
DECLARE @FilasOrigen bigint = (SELECT COUNT_BIG(*) FROM ZCRM2Trengo.dbo.[trengo_data_tickets] t);
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM core.TicketAtencion t WHERE t.FuenteBase = N'ZCRM2Trengo' AND t.FuenteTabla = N'trengo_data_tickets' AND t.FuenteLlave IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN (N'core_TicketAtencion') AND d.FuenteTabla = N'trengo_data_tickets' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'trengo_data_tickets' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN (N'core_TicketAtencion') AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
GO
