/* Duplicados: línea base del diagnóstico (origen) frente al modelo unificado · Sprint 4. SOLO LECTURA.
   Generado por etl/adn_etl/duplicados.py (no editar a mano). Cada bloque devuelve Origen, Modelo, Justificados.
   Ejecutar con ./etl.ps1 duplicados (reporte) o por bloques en SSMS. */
SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON;
USE ADN_Unificado;
GO

/* ===== Llaves repetidas · ref_Provincia · ref.Provincia ← ADNPayV2.AddressProvince ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM ref.Provincia t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'AddressProvince' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CAST(x.[id] AS nvarchar(200))) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM [ADNPayV2].dbo.[AddressProvince] x) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM ref.Provincia t
        WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'AddressProvince') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · ref_Canton · ref.Canton ← ADNPayV2.AddressCanton ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM ref.Canton t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'AddressCanton' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CAST(x.[id] AS nvarchar(200))) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM [ADNPayV2].dbo.[AddressCanton] x) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM ref.Canton t
        WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'AddressCanton') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · ref_Distrito · ref.Distrito ← ADNPayV2.AddressDistrict ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM ref.Distrito t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'AddressDistrict' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CAST(x.[id] AS nvarchar(200))) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM [ADNPayV2].dbo.[AddressDistrict] x) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM ref.Distrito t
        WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'AddressDistrict') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · ref_TipoCambio · ref.TipoCambio ← ADNApp.Telephony_usdexchange ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM ref.TipoCambio t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_usdexchange' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(CAST(x.id AS nvarchar(200)) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ADNApp.dbo.Telephony_usdexchange x) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM ref.TipoCambio t
        WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_usdexchange') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · ref_TipoCambio · ref.TipoCambio ← developer_adn_app_db.Telephony_usdexchange ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM ref.TipoCambio t WHERE t.FuenteBase = N'developer_adn_app_db' AND t.FuenteTabla = N'Telephony_usdexchange' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(CAST(x._id AS nvarchar(200)) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM stg.mongo_Telephony_usdexchange x) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM ref.TipoCambio t
        WHERE t.FuenteBase = N'developer_adn_app_db' AND t.FuenteTabla = N'Telephony_usdexchange') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · ref_Impuesto · ref.Impuesto ← ZBooks_Mirror.taxes ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM ref.Impuesto t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'taxes' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CAST(x.[tax_id] AS nvarchar(200))) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM [ZBooks_Mirror].dbo.[taxes] x) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM ref.Impuesto t
        WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'taxes') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · ref_CuentaContable · ref.CuentaContable ← ZBooks_Mirror.chartofaccounts ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM ref.CuentaContable t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'chartofaccounts' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CAST(x.[account_id] AS nvarchar(200))) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM [ZBooks_Mirror].dbo.[chartofaccounts] x) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM ref.CuentaContable t
        WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'chartofaccounts') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · ref_CodigoPromocion · ref.CodigoPromocion ← ADNPayV2.code_promo_condo ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM ref.CodigoPromocion t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'code_promo_condo' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CAST(x.[id] AS nvarchar(200))) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM [ADNPayV2].dbo.[code_promo_condo] x) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM ref.CodigoPromocion t
        WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'code_promo_condo') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · ref_Usuario · ref.Usuario ← Zoho_Mirror.Users ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM ref.Usuario t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Users' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CAST(x.[id] AS nvarchar(200))) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM [Zoho_Mirror].dbo.[Users] x) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM ref.Usuario t
        WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Users') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · ref_Usuario_ADNApp · ref.Usuario ← ADNApp.ZohoEngine_zohouser ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM ref.Usuario t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'ZohoEngine_zohouser' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(x.zoho_id) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ADNApp.dbo.ZohoEngine_zohouser x
WHERE NOT EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.Users u WHERE ctl.fn_Texto(u.id) = ctl.fn_Texto(x.zoho_id))) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM ref.Usuario t
        WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'ZohoEngine_zohouser') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_Condominio · core.Condominio ← Zoho_Mirror.Condominios ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Condominio t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Condominios' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CAST(x.[id] AS nvarchar(200))) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM [Zoho_Mirror].dbo.[Condominios] x) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.Condominio t
        WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Condominios') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_Nodo · core.Nodo ← Zoho_Mirror.Nodos ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Nodo t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Nodos' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CAST(x.[id] AS nvarchar(200))) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM [Zoho_Mirror].dbo.[Nodos] x) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.Nodo t
        WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Nodos') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_ClusterFTTH · core.ClusterFTTH ← Zoho_Mirror.FTTHs ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.ClusterFTTH t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'FTTHs' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CAST(x.[id] AS nvarchar(200))) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM [Zoho_Mirror].dbo.[FTTHs] x) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.ClusterFTTH t
        WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'FTTHs') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_Servicio · core.Servicio ← Zoho_Mirror.Accounts_Extended ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Servicio t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Accounts_Extended' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(x.id AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM Zoho_Mirror.dbo.Accounts_Extended x) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.Servicio t
        WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Accounts_Extended') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_Servicio · core.Servicio ← Zoho_Mirror.Accounts ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Servicio t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Accounts' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(x.id AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM Zoho_Mirror.dbo.Accounts x
WHERE NOT EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.Accounts_Extended e WHERE e.id = x.id)) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.Servicio t
        WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Accounts') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_ClienteOrigen · core.ClienteOrigen ← Zoho_Mirror.Accounts_Extended ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.ClienteOrigen t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Accounts_Extended' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(x.id AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM Zoho_Mirror.dbo.Accounts_Extended x) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.ClienteOrigen t
        WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Accounts_Extended') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_ClienteOrigen · core.ClienteOrigen ← Zoho_Mirror.Accounts ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.ClienteOrigen t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Accounts' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(x.id AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM Zoho_Mirror.dbo.Accounts x
WHERE ISNULL(x.deleted, 0) = 0
  AND NOT EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.Accounts_Extended e WHERE e.id = x.id)) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.ClienteOrigen t
        WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Accounts') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_ClienteOrigen · core.ClienteOrigen ← ZBooks_Mirror.contacts ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.ClienteOrigen t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'contacts' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(x.contact_id AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ZBooks_Mirror.dbo.contacts x
WHERE x.contact_type = 'customer' AND NULLIF(LTRIM(x.contact_id), '') IS NOT NULL) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.ClienteOrigen t
        WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'contacts') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_ClienteOrigen · core.ClienteOrigen ← ADNPayV2.Customer ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.ClienteOrigen t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'Customer' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(CAST(x.[index] AS nvarchar(200)) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ADNPayV2.dbo.Customer x
WHERE x.status = 'approved') x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.ClienteOrigen t
        WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'Customer') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_ClienteOrigen · core.ClienteOrigen ← ADNApp.ZohoEngine_zohocustomer ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.ClienteOrigen t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'ZohoEngine_zohocustomer' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(CAST(x.id AS nvarchar(200)) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ADNApp.dbo.ZohoEngine_zohocustomer x) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.ClienteOrigen t
        WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'ZohoEngine_zohocustomer') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_Contacto · core.Contacto ← Zoho_Mirror.Contacts ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Contacto t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Contacts' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CAST(x.[id] AS nvarchar(200))) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM [Zoho_Mirror].dbo.[Contacts] x) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.Contacto t
        WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Contacts') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_Producto_CRM · core.Producto ← Zoho_Mirror.Products ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Producto t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Products' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), p.[id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM Zoho_Mirror.dbo.[Products] p) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.Producto t
        WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Products') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_Producto_Books · core.Producto ← ZBooks_Mirror.items ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Producto t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'items' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), i.[item_id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ZBooks_Mirror.dbo.[items] i
WHERE NOT EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.Products p WHERE p.id = i.zcrm_product_id)) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.Producto t
        WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'items') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_Producto_ADNPayServicio · core.Producto ← ADNPayV2.Service ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Producto t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'Service' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), v.[index])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ADNPayV2.dbo.[Service] v) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.Producto t
        WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'Service') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_Producto_ADNPayProducto · core.Producto ← ADNPayV2.Product ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Producto t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'Product' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), v.[product_id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ADNPayV2.dbo.[Product] v) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.Producto t
        WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'Product') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_Producto_ADNPayIPTV · core.Producto ← ADNPayV2.IPTVService ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Producto t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'IPTVService' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), v.[tier_id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ADNPayV2.dbo.[IPTVService] v) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.Producto t
        WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'IPTVService') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_Producto_Onvo · core.Producto ← ADNPayV2.OnvoProduct ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Producto t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'OnvoProduct' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), v.[id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ADNPayV2.dbo.[OnvoProduct] v
OUTER APPLY (SELECT TOP 1 CAST(pr.unit_amount AS decimal(19,4)) AS Precio, pr.is_active AS Activo,
                    ctl.fn_FechaCR(CONVERT(nvarchar(30), pr.updated_at, 126)) AS Modificado
             FROM ADNPayV2.dbo.OnvoPrice pr WHERE pr.onvo_product_id = v.onvo_product_id
             ORDER BY pr.is_active DESC, pr.updated_at DESC, pr.id DESC) op) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.Producto t
        WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'OnvoProduct') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_Direccion · core.Direccion ← ADNPayV2.AddressMain ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Direccion t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'AddressMain' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), d.[id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ADNPayV2.dbo.[AddressMain] d) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.Direccion t
        WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'AddressMain') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_Prospecto_CRM · core.Prospecto ← Zoho_Mirror.Leads ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Prospecto t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Leads' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), l.[id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM Zoho_Mirror.dbo.[Leads] l
LEFT JOIN core.Cliente cl ON cl.FuenteTabla = N'Cedula' AND cl.FuenteLlave = ctl.fn_Cedula(l.Legal_ID) AND EXISTS (SELECT 1 FROM core.ClienteOrigen vo WHERE vo.ClienteId = cl.ClienteId AND vo.Sistema IN ('ZohoCRM', 'ZohoBooks', 'ADNPayV2'))) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.Prospecto t
        WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Leads') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_Prospecto_ADNPay · core.Prospecto ← ADNPayV2.CustomerProspect ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Prospecto t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'CustomerProspect' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), c.[id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ADNPayV2.dbo.[CustomerProspect] c
LEFT JOIN core.Cliente cl ON cl.FuenteTabla = N'Cedula' AND cl.FuenteLlave = ctl.fn_Cedula(c.id_card) AND EXISTS (SELECT 1 FROM core.ClienteOrigen vo WHERE vo.ClienteId = cl.ClienteId AND vo.Sistema IN ('ZohoCRM', 'ZohoBooks', 'ADNPayV2'))) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.Prospecto t
        WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'CustomerProspect') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_Oportunidad · core.Oportunidad ← Zoho_Mirror.Deals ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Oportunidad t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Deals' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), d.[id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM Zoho_Mirror.dbo.[Deals] d) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.Oportunidad t
        WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Deals') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_Cotizacion · core.Cotizacion ← Zoho_Mirror.Quotes ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Cotizacion t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Quotes' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), c.[id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM Zoho_Mirror.dbo.[Quotes] c) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.Cotizacion t
        WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Quotes') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_OrdenVenta · core.OrdenVenta ← Zoho_Mirror.Sales_Orders_Extended ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.OrdenVenta t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Sales_Orders_Extended' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), o.[id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM Zoho_Mirror.dbo.[Sales_Orders_Extended] o) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.OrdenVenta t
        WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Sales_Orders_Extended') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_OrdenVenta_Complemento · core.OrdenVenta ← Zoho_Mirror.Sales_Orders ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.OrdenVenta t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Sales_Orders' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), o.[id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM Zoho_Mirror.dbo.[Sales_Orders] o
WHERE NOT EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.Sales_Orders_Extended e WHERE e.id = o.id)) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.OrdenVenta t
        WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Sales_Orders') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_OrdenVentaLinea · core.OrdenVentaLinea ← Zoho_Mirror.Sales_Orders_Products ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.OrdenVentaLinea t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Sales_Orders_Products' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), l.[id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM Zoho_Mirror.dbo.[Sales_Orders_Products] l
LEFT JOIN core.OrdenVenta ov ON ov.OrdenVentaCrmId = ctl.fn_Texto(l.sales_order)) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.OrdenVentaLinea t
        WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Sales_Orders_Products') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_OrdenTrabajo · core.OrdenTrabajo ← Zoho_Mirror.Ordenes_de_Trabajo ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.OrdenTrabajo t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Ordenes_de_Trabajo' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), t.[id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM Zoho_Mirror.dbo.[Ordenes_de_Trabajo] t) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.OrdenTrabajo t
        WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Ordenes_de_Trabajo') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_OrdenServicioVoIP · core.OrdenServicioVoIP ← Zoho_Mirror.Orden_de_Servicio_Voz_IP ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.OrdenServicioVoIP t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Orden_de_Servicio_Voz_IP' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), v.[id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM Zoho_Mirror.dbo.[Orden_de_Servicio_Voz_IP] v) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.OrdenServicioVoIP t
        WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Orden_de_Servicio_Voz_IP') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_Caso · core.Caso ← Zoho_Mirror.Cases_Extended ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Caso t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Cases_Extended' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), c.[CaseId])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM Zoho_Mirror.dbo.[Cases_Extended] c) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.Caso t
        WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Cases_Extended') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_Caso_Complemento · core.Caso ← Zoho_Mirror.Cases ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Caso t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Cases' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), c.[id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM Zoho_Mirror.dbo.[Cases] c
WHERE NOT EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.Cases_Extended e WHERE e.CaseId = c.id)) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.Caso t
        WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Cases') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_Nota_Servicio · core.Nota ← Zoho_Mirror.Accounts_Notes ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Nota t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Accounts_Notes' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), n.[NoteId])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM Zoho_Mirror.dbo.[Accounts_Notes] n) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.Nota t
        WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Accounts_Notes') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_Nota_Caso · core.Nota ← Zoho_Mirror.Cases_Notes ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Nota t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Cases_Notes' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), n.[NoteId])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM Zoho_Mirror.dbo.[Cases_Notes] n) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.Nota t
        WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Cases_Notes') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_Nota_Cliente · core.Nota ← ZBooks_Mirror.comments_contacts ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Nota t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'comments_contacts' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), n.[id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ZBooks_Mirror.dbo.[comments_contacts] n
OUTER APPLY (SELECT CASE WHEN COUNT(DISTINCT o.ClienteId) = 1 THEN MIN(o.ClienteId) END AS ClienteId
             FROM core.ClienteOrigen o WHERE o.Sistema = 'ZohoBooks' AND o.LlaveOrigen = ctl.fn_Texto(n.contact_id)) co) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.Nota t
        WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'comments_contacts') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_Tarea · core.Tarea ← Zoho_Mirror.Tasks ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Tarea t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Tasks' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), t.[id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM Zoho_Mirror.dbo.[Tasks] t
CROSS APPLY (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(max), t.What_Id)) AS nvarchar(30)) AS Id) w
OUTER APPLY (SELECT MIN(x.ServicioId) AS Id, COUNT(*) AS n FROM core.Servicio x WHERE x.CuentaCrmId = w.Id) r1
OUTER APPLY (SELECT MIN(x.ServicioId) AS Id, COUNT(*) AS n FROM core.Oportunidad x WHERE x.OportunidadCrmId = w.Id) r2
OUTER APPLY (SELECT MIN(x.ServicioId) AS Id, COUNT(*) AS n FROM core.Caso x WHERE x.CasoCrmId = w.Id) r3
OUTER APPLY (SELECT MIN(x.ServicioId) AS Id, COUNT(*) AS n FROM core.OrdenVenta x WHERE x.OrdenVentaCrmId = w.Id) r4
OUTER APPLY (SELECT MIN(x.ServicioId) AS Id, COUNT(*) AS n FROM core.Cotizacion x WHERE x.CotizacionCrmId = w.Id) r5
OUTER APPLY (SELECT COUNT(*) AS n FROM core.Prospecto x WHERE x.FuenteSistema = 'ZohoCRM' AND x.FuenteTabla = N'Leads' AND x.FuenteLlave = w.Id) r6) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.Tarea t
        WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Tasks') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_Adjunto · core.Adjunto ← Zoho_Mirror.Zoho_Attachments ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Adjunto t WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Zoho_Attachments' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), a.[AttachmentId])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM Zoho_Mirror.dbo.[Zoho_Attachments] a) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.Adjunto t
        WHERE t.FuenteBase = N'Zoho_Mirror' AND t.FuenteTabla = N'Zoho_Attachments') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_Proveedor · core.Proveedor ← ZBooks_Mirror.contacts ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Proveedor t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'contacts' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), v.[contact_id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ZBooks_Mirror.dbo.[contacts] v
WHERE v.contact_type = 'vendor') x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.Proveedor t
        WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'contacts') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_CuentaBancaria · core.CuentaBancaria ← ZBooks_Mirror.bankaccounts ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.CuentaBancaria t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'bankaccounts' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), b.[account_id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ZBooks_Mirror.dbo.[bankaccounts] b) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.CuentaBancaria t
        WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'bankaccounts') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_MovimientoBancario · core.MovimientoBancario ← ZBooks_Mirror.banktransactions ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.MovimientoBancario t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'banktransactions' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), m.[transaction_id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ZBooks_Mirror.dbo.[banktransactions] m
OUTER APPLY (SELECT CASE WHEN COUNT(DISTINCT o.ClienteId) = 1 THEN MIN(o.ClienteId) END AS ClienteId
             FROM core.ClienteOrigen o WHERE o.Sistema = 'ZohoBooks' AND o.LlaveOrigen = ctl.fn_Texto(m.customer_id)) co) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.MovimientoBancario t
        WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'banktransactions') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_Factura · core.Factura ← ZBooks_Mirror.invoices ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Factura t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'invoices' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), f.[invoice_id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ZBooks_Mirror.dbo.[invoices] f
OUTER APPLY (SELECT CASE WHEN COUNT(DISTINCT o.ClienteId) = 1 THEN MIN(o.ClienteId) END AS ClienteId,
                    CASE WHEN COUNT(DISTINCT o.ServicioId) = 1 THEN MIN(o.ServicioId) END AS ServicioId
             FROM core.ClienteOrigen o WHERE o.Sistema = 'ZohoBooks' AND o.LlaveOrigen = ctl.fn_Texto(f.customer_id)) co
OUTER APPLY (SELECT COUNT(*) AS n, MIN(sv.ServicioId) AS ServicioId FROM core.Servicio sv WHERE sv.ClienteId = co.ClienteId) sc) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.Factura t
        WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'invoices') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_FacturaLinea · core.FacturaLinea ← ZBooks_Mirror.invoices_items ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.FacturaLinea t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'invoices_items' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), l.[line_item_id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ZBooks_Mirror.dbo.[invoices_items] l
LEFT JOIN core.Factura f ON f.FacturaBooksId = ctl.fn_Texto(l.invoice_id)) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.FacturaLinea t
        WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'invoices_items') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_FacturaRecurrente · core.FacturaRecurrente ← ZBooks_Mirror.recurringinvoices ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.FacturaRecurrente t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'recurringinvoices' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), r.[recurring_invoice_id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ZBooks_Mirror.dbo.[recurringinvoices] r
OUTER APPLY (SELECT CASE WHEN COUNT(DISTINCT o.ClienteId) = 1 THEN MIN(o.ClienteId) END AS ClienteId,
                    CASE WHEN COUNT(DISTINCT o.ServicioId) = 1 THEN MIN(o.ServicioId) END AS ServicioId
             FROM core.ClienteOrigen o WHERE o.Sistema = 'ZohoBooks' AND o.LlaveOrigen = ctl.fn_Texto(r.customer_id)) co
OUTER APPLY (SELECT COUNT(*) AS n, MIN(sv.ServicioId) AS ServicioId FROM core.Servicio sv WHERE sv.ClienteId = co.ClienteId) sc) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.FacturaRecurrente t
        WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'recurringinvoices') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_Pago · core.Pago ← ZBooks_Mirror.customerpayments ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Pago t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'customerpayments' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), p.[payment_id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ZBooks_Mirror.dbo.[customerpayments] p
OUTER APPLY (SELECT CASE WHEN COUNT(DISTINCT o.ClienteId) = 1 THEN MIN(o.ClienteId) END AS ClienteId,
                    CASE WHEN COUNT(DISTINCT o.ServicioId) = 1 THEN MIN(o.ServicioId) END AS ServicioId
             FROM core.ClienteOrigen o WHERE o.Sistema = 'ZohoBooks' AND o.LlaveOrigen = ctl.fn_Texto(p.customer_id)) co
OUTER APPLY (SELECT COUNT(*) AS n, MIN(sv.ServicioId) AS ServicioId FROM core.Servicio sv WHERE sv.ClienteId = co.ClienteId) sc) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.Pago t
        WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'customerpayments') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_PagoFactura · core.PagoFactura ← ZBooks_Mirror.customerpayments ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.PagoFactura t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'customerpayments' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(CONCAT(ctl.fn_Texto(p.payment_id), N'|', n.Numero) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ZBooks_Mirror.dbo.customerpayments p
CROSS APPLY (SELECT DISTINCT CAST(ctl.fn_Texto(v.value) AS nvarchar(50)) AS Numero
             FROM STRING_SPLIT(REPLACE(CONVERT(nvarchar(max), p.invoice_numbers), N';', N','), N',') v
             WHERE ctl.fn_Texto(v.value) IS NOT NULL) n) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.PagoFactura t
        WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'customerpayments') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_Gasto · core.Gasto ← ZBooks_Mirror.expenses ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Gasto t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'expenses' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), e.[expense_id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ZBooks_Mirror.dbo.[expenses] e) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.Gasto t
        WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'expenses') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_OrdenCompra · core.OrdenCompra ← ZBooks_Mirror.purchaseorders ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.OrdenCompra t WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'purchaseorders' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), o.[purchaseorder_id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ZBooks_Mirror.dbo.[purchaseorders] o) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.OrdenCompra t
        WHERE t.FuenteBase = N'ZBooks_Mirror' AND t.FuenteTabla = N'purchaseorders') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_HistorialEstadoCliente · core.HistorialEstadoCliente ← History_Tables.customer_status_zbooks ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.HistorialEstadoCliente t WHERE t.FuenteBase = N'History_Tables' AND t.FuenteTabla = N'customer_status_zbooks' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(CONCAT(ctl.fn_Texto(h.custome_id), N'|', CONVERT(nvarchar(30), h.modification_date, 126), N'|', ctl.fn_Texto(h.customer_status)) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM History_Tables.dbo.[customer_status_zbooks] h
OUTER APPLY (SELECT CASE WHEN COUNT(DISTINCT o.ClienteId) = 1 THEN MIN(o.ClienteId) END AS ClienteId
             FROM core.ClienteOrigen o WHERE o.Sistema = 'ZohoBooks' AND o.LlaveOrigen = ctl.fn_Texto(h.custome_id)) co) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.HistorialEstadoCliente t
        WHERE t.FuenteBase = N'History_Tables' AND t.FuenteTabla = N'customer_status_zbooks') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_FacturaElectronicaProveedor · core.FacturaElectronicaProveedor ← ADNApp.XMLEngine_invoicexmlfiles ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.FacturaElectronicaProveedor t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'XMLEngine_invoicexmlfiles' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), x.[invoice_number])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ADNApp.dbo.[XMLEngine_invoicexmlfiles] x) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.FacturaElectronicaProveedor t
        WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'XMLEngine_invoicexmlfiles') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · ref_ProveedorTelefonia · ref.ProveedorTelefonia ← ADNApp.Telephony_provider ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM ref.ProveedorTelefonia t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_provider' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), p.[id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ADNApp.dbo.[Telephony_provider] p) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM ref.ProveedorTelefonia t
        WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_provider') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · ref_TroncalProveedor · ref.TroncalProveedor ← ADNApp.Telephony_providertrunk ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM ref.TroncalProveedor t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_providertrunk' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), t.[id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ADNApp.dbo.[Telephony_providertrunk] t) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM ref.TroncalProveedor t
        WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_providertrunk') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · ref_TarifaDestino · ref.TarifaDestino ← ADNApp.Telephony_countrydialcoderate ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM ref.TarifaDestino t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_countrydialcoderate' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), r.[id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ADNApp.dbo.[Telephony_countrydialcoderate] r) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM ref.TarifaDestino t
        WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_countrydialcoderate') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · ref_TarifaNumeroEspecial · ref.TarifaDestino ← ADNApp.Telephony_specialnumberrate ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM ref.TarifaDestino t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_specialnumberrate' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), r.[id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ADNApp.dbo.[Telephony_specialnumberrate] r) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM ref.TarifaDestino t
        WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_specialnumberrate') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · ref_PaqueteMinutos · ref.PaqueteMinutos ← ADNApp.Telephony_minutepackage ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM ref.PaqueteMinutos t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_minutepackage' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), m.[id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ADNApp.dbo.[Telephony_minutepackage] m) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM ref.PaqueteMinutos t
        WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_minutepackage') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · ref_PaqueteMinutosCodigo · ref.PaqueteMinutosCodigo ← ADNApp.Telephony_minutepackagedialcode ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM ref.PaqueteMinutosCodigo t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_minutepackagedialcode' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), m.[id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ADNApp.dbo.[Telephony_minutepackagedialcode] m) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM ref.PaqueteMinutosCodigo t
        WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_minutepackagedialcode') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_Troncal · core.Troncal ← ADNApp.Telephony_trunk ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Troncal t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_trunk' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), t.[id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ADNApp.dbo.[Telephony_trunk] t) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.Troncal t
        WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_trunk') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_TroncalPermisoCodigo · core.TroncalPermisoCodigo ← ADNApp.Telephony_trunkpermissiondialcode ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.TroncalPermisoCodigo t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_trunkpermissiondialcode' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), d.[id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ADNApp.dbo.[Telephony_trunkpermissiondialcode] d) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.TroncalPermisoCodigo t
        WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_trunkpermissiondialcode') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_AlertaTroncal · core.AlertaTroncal ← ADNApp.Telephony_alertblockedtrunk ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.AlertaTroncal t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_alertblockedtrunk' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), a.[id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ADNApp.dbo.[Telephony_alertblockedtrunk] a) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.AlertaTroncal t
        WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_alertblockedtrunk') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_LineaGratuita · core.LineaGratuita ← ADNApp.Telephony_freelines ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.LineaGratuita t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_freelines' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), l.[id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ADNApp.dbo.[Telephony_freelines] l) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.LineaGratuita t
        WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_freelines') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_ServicioPaqueteMinutos · core.ServicioPaqueteMinutos ← ADNApp.Telephony_customerminutepackage ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.ServicioPaqueteMinutos t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_customerminutepackage' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), c.[id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ADNApp.dbo.[Telephony_customerminutepackage] c) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.ServicioPaqueteMinutos t
        WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_customerminutepackage') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_MinutosHistorico_Cliente · core.MinutosContratadosHistorico ← ADNApp.Minutos_Customer ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.MinutosContratadosHistorico t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Minutos_Customer' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(CONVERT(nvarchar(66), HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(4000), m.[Description]), N'~'), ISNULL(CONVERT(nvarchar(4000), m.[Minutes]), N'~'), ISNULL(CONVERT(nvarchar(4000), m.[Customer_id]), N'~'))), 2) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ADNApp.dbo.[Minutos_Customer] m
OUTER APPLY (SELECT CASE WHEN COUNT(DISTINCT o.ServicioId) = 1 THEN MIN(o.ServicioId) END AS ServicioId,
                    CASE WHEN COUNT(DISTINCT o.ClienteId) = 1 THEN MIN(o.ClienteId) END AS ClienteId
             FROM core.ClienteOrigen o WHERE o.Sistema = 'AppDataCR'
               AND o.LlaveOrigen = CAST(TRY_CONVERT(bigint, m.Customer_id) AS nvarchar(200))) co) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.MinutosContratadosHistorico t
        WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Minutos_Customer') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_MinutosHistorico_Cedula · core.MinutosContratadosHistorico ← ADNApp.MinutosLegalId ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.MinutosContratadosHistorico t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'MinutosLegalId' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(CONVERT(nvarchar(66), HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(4000), m.[IDCard]), N'~'), ISNULL(CONVERT(nvarchar(4000), m.[MinutosFijo]), N'~'), ISNULL(CONVERT(nvarchar(4000), m.[MinutosCelular]), N'~'))), 2) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ADNApp.dbo.[MinutosLegalId] m) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.MinutosContratadosHistorico t
        WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'MinutosLegalId') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_ArchivoCDR · core.ArchivoCDR ← ADNApp.Telephony_insertedcdrfiles ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.ArchivoCDR t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_insertedcdrfiles' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), f.[id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ADNApp.dbo.[Telephony_insertedcdrfiles] f) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.ArchivoCDR t
        WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_insertedcdrfiles') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_CorteVoIP · core.CorteVoIP ← ADNApp.ZohoEngine_zohocustomervoipbill ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.CorteVoIP t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'ZohoEngine_zohocustomervoipbill' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), b.[id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ADNApp.dbo.[ZohoEngine_zohocustomervoipbill] b) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.CorteVoIP t
        WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'ZohoEngine_zohocustomervoipbill') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_ConsumoVoIP_Corte · core.ConsumoVoIP ← ADNApp.ZohoEngine_zohocustomervoipbillservice ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.ConsumoVoIP t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'ZohoEngine_zohocustomervoipbillservice' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), s.[id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ADNApp.dbo.[ZohoEngine_zohocustomervoipbillservice] s
LEFT JOIN core.CorteVoIP cv ON cv.FuenteBase = N'ADNApp' AND cv.FuenteLlave = CAST(s.zoho_customer_voip_bill_id AS nvarchar(200))) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.ConsumoVoIP t
        WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'ZohoEngine_zohocustomervoipbillservice') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_ConsumoVoIP_Factura · core.ConsumoVoIP ← ADNApp.ZohoEngine_invoicevoip ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.ConsumoVoIP t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'ZohoEngine_invoicevoip' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), i.[id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ADNApp.dbo.[ZohoEngine_invoicevoip] i) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.ConsumoVoIP t
        WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'ZohoEngine_invoicevoip') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_Llamada_Historico · core.Llamada ← ADNApp.Telephony_cdr_historico ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Llamada t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_cdr_historico' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(CAST(c.id AS nvarchar(200)) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k, c.StartDateTime AS f
              FROM ADNApp.dbo.Telephony_cdr_historico c) x
WHERE x.f >= @Ini AND x.f < @Fin AND CONVERT(char(7), x.f, 126) IN (SELECT Mes FROM #m)) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.Llamada t
        WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_cdr_historico' AND CONVERT(char(7), t.FechaDato, 126) IN (SELECT Mes FROM #m)) AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_Llamada_SQL · core.Llamada ← ADNApp.Telephony_cdr ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Llamada t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_cdr' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(CAST(c.id AS nvarchar(200)) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k, c.StartDateTime AS f
              FROM ADNApp.dbo.Telephony_cdr c) x
WHERE x.f >= @Ini AND x.f < @Fin AND CONVERT(char(7), x.f, 126) IN (SELECT Mes FROM #m)) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.Llamada t
        WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_cdr' AND CONVERT(char(7), t.FechaDato, 126) IN (SELECT Mes FROM #m)) AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_Llamada · core.Llamada ← developer_adn_app_db.Telephony_cdr ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Llamada t WHERE t.FuenteBase = N'developer_adn_app_db' AND t.FuenteTabla = N'Telephony_cdr' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(CAST(c._id AS nvarchar(200)) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k, c.StartDateTime AS f
              FROM stg.mongo_Telephony_cdr c) x
WHERE x.f >= @Ini AND x.f < @Fin AND CONVERT(char(7), x.f, 126) IN (SELECT Mes FROM #m)) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.Llamada t
        WHERE t.FuenteBase = N'developer_adn_app_db' AND t.FuenteTabla = N'Telephony_cdr' AND CONVERT(char(7), t.FechaDato, 126) IN (SELECT Mes FROM #m)) AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_SolicitudEnLinea · core.SolicitudEnLinea ← ADNPayV2.Customer ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.SolicitudEnLinea t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'Customer' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), c.[index])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ADNPayV2.dbo.[Customer] c
OUTER APPLY (SELECT MIN(o.ClienteId) AS ClienteId FROM core.ClienteOrigen o
             WHERE o.Sistema = 'ADNPayV2' AND o.LlaveOrigen = CAST(c.[index] AS nvarchar(200))) co
LEFT JOIN core.Cliente cl ON cl.FuenteTabla = N'Cedula' AND cl.FuenteLlave = ctl.fn_Cedula(c.id)
    AND EXISTS (SELECT 1 FROM core.ClienteOrigen vo WHERE vo.ClienteId = cl.ClienteId AND vo.Sistema IN ('ZohoCRM', 'ZohoBooks', 'ADNPayV2'))) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.SolicitudEnLinea t
        WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'Customer') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_PagoEnLinea · core.PagoEnLinea ← ADNPayV2.OnvoCheckoutSession ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.PagoEnLinea t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'OnvoCheckoutSession' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), s.[session_index])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ADNPayV2.dbo.[OnvoCheckoutSession] s) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.PagoEnLinea t
        WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'OnvoCheckoutSession') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_Reserva_Visita · core.ReservaInstalacion ← ADNPayV2.Visitdate ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.ReservaInstalacion t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'Visitdate' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), v.[id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ADNPayV2.dbo.[Visitdate] v) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.ReservaInstalacion t
        WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'Visitdate') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_Reserva_Servicio · core.ReservaInstalacion ← ADNPayV2.ServiceReservations ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.ReservaInstalacion t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'ServiceReservations' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), r.[reservation_id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ADNPayV2.dbo.[ServiceReservations] r) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.ReservaInstalacion t
        WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'ServiceReservations') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_OrdenEnLinea_Venta · core.OrdenEnLinea ← ADNPayV2.SaleOrder ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.OrdenEnLinea t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'SaleOrder' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), o.[order_id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ADNPayV2.dbo.[SaleOrder] o) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.OrdenEnLinea t
        WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'SaleOrder') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_OrdenEnLinea_Carrito · core.OrdenEnLinea ← ADNPayV2.Cart ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.OrdenEnLinea t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'Cart' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), k.[cart_id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ADNPayV2.dbo.[Cart] k) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.OrdenEnLinea t
        WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'Cart') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_OrdenEnLineaLinea_Venta · core.OrdenEnLineaLinea ← ADNPayV2.SaleOrderLine ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.OrdenEnLineaLinea t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'SaleOrderLine' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), l.[line_id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ADNPayV2.dbo.[SaleOrderLine] l) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.OrdenEnLineaLinea t
        WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'SaleOrderLine') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_OrdenEnLineaLinea_Carrito · core.OrdenEnLineaLinea ← ADNPayV2.CartLine ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.OrdenEnLineaLinea t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'CartLine' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), l.[line_id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ADNPayV2.dbo.[CartLine] l) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.OrdenEnLineaLinea t
        WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'CartLine') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_AprovisionamientoOdoo · core.AprovisionamientoOdoo ← ADNPayV2.OdooProvisioning ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.AprovisionamientoOdoo t WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'OdooProvisioning' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), a.[id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ADNPayV2.dbo.[OdooProvisioning] a) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.AprovisionamientoOdoo t
        WHERE t.FuenteBase = N'ADNPayV2' AND t.FuenteTabla = N'OdooProvisioning') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · ref_UnidadFlota · ref.UnidadFlota ← Navsat.Dispositivo ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM ref.UnidadFlota t WHERE t.FuenteBase = N'Navsat' AND t.FuenteTabla = N'Dispositivo' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(CAST(ctl.fn_Texto(u.d) AS nvarchar(100)) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM (SELECT deviceName AS d FROM Navsat.dbo.Ultima_ubicacion UNION ALL SELECT DeviceName FROM Navsat.dbo.viajes_ayer_finalizado
      UNION ALL SELECT dispositivo FROM Navsat.dbo.eventos UNION ALL SELECT dispositivo FROM Navsat.dbo.Eco_Driving) u) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM ref.UnidadFlota t
        WHERE t.FuenteBase = N'Navsat' AND t.FuenteTabla = N'Dispositivo') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_UbicacionFlota · core.UbicacionFlota ← Navsat.Ultima_ubicacion ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.UbicacionFlota t WHERE t.FuenteBase = N'Navsat' AND t.FuenteTabla = N'Ultima_ubicacion' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(CONVERT(nvarchar(66), HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(4000), u.[deviceName]), N'~'), ISNULL(CONVERT(nvarchar(4000), u.[crDateTime]), N'~'), ISNULL(CONVERT(nvarchar(4000), u.[latitude]), N'~'), ISNULL(CONVERT(nvarchar(4000), u.[longitude]), N'~'))), 2) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k, ctl.fn_FechaCR(u.crDateTime) AS f
              FROM Navsat.dbo.[Ultima_ubicacion] u
WHERE (@Desde IS NULL OR ctl.fn_FechaCR(u.crDateTime) >= TODATETIMEOFFSET(CAST(@Desde AS datetime2), '-06:00')) AND (@Hasta IS NULL OR ctl.fn_FechaCR(u.crDateTime) < TODATETIMEOFFSET(CAST(@Hasta AS datetime2), '-06:00'))) x
WHERE x.f >= @Ini AND x.f < @Fin AND CONVERT(char(7), x.f, 126) IN (SELECT Mes FROM #m)) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.UbicacionFlota t
        WHERE t.FuenteBase = N'Navsat' AND t.FuenteTabla = N'Ultima_ubicacion' AND CONVERT(char(7), t.FechaDato, 126) IN (SELECT Mes FROM #m)) AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_ViajeFlota · core.ViajeFlota ← Navsat.viajes_ayer_finalizado ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.ViajeFlota t WHERE t.FuenteBase = N'Navsat' AND t.FuenteTabla = N'viajes_ayer_finalizado' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(CONVERT(nvarchar(66), HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(4000), v.[DeviceName]), N'~'), ISNULL(CONVERT(nvarchar(30), v.[FechaInicio], 126), N'~'), ISNULL(CONVERT(nvarchar(30), v.[FechaFin], 126), N'~'), ISNULL(CONVERT(nvarchar(4000), v.[KilometrosRecorridos]), N'~'))), 2) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM Navsat.dbo.[viajes_ayer_finalizado] v) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.ViajeFlota t
        WHERE t.FuenteBase = N'Navsat' AND t.FuenteTabla = N'viajes_ayer_finalizado') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_EventoFlota · core.EventoFlota ← Navsat.eventos ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.EventoFlota t WHERE t.FuenteBase = N'Navsat' AND t.FuenteTabla = N'eventos' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(CONVERT(nvarchar(66), HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(4000), e.[dispositivo]), N'~'), ISNULL(CONVERT(nvarchar(30), e.[fecha], 126), N'~'), ISNULL(CONVERT(nvarchar(4000), e.[evento]), N'~'), ISNULL(CONVERT(nvarchar(4000), e.[regla]), N'~'), ISNULL(CONVERT(nvarchar(4000), e.[latitude]), N'~'), ISNULL(CONVERT(nvarchar(4000), e.[longitude]), N'~'))), 2) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM Navsat.dbo.[eventos] e) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.EventoFlota t
        WHERE t.FuenteBase = N'Navsat' AND t.FuenteTabla = N'eventos') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_IncidenteConduccion · core.IncidenteConduccion ← Navsat.Eco_Driving ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.IncidenteConduccion t WHERE t.FuenteBase = N'Navsat' AND t.FuenteTabla = N'Eco_Driving' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(CONVERT(nvarchar(66), HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(4000), d.[dispositivo]), N'~'), ISNULL(CONVERT(nvarchar(30), d.[fecha_hora_incidente], 126), N'~'), ISNULL(CONVERT(nvarchar(4000), d.[id_evento]), N'~'), ISNULL(CONVERT(nvarchar(4000), d.[tipo_incidente]), N'~'))), 2) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM Navsat.dbo.[Eco_Driving] d) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.IncidenteConduccion t
        WHERE t.FuenteBase = N'Navsat' AND t.FuenteTabla = N'Eco_Driving') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_CheckInCampo · core.CheckInCampo ← History_Tables.check_in_navsat ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.CheckInCampo t WHERE t.FuenteBase = N'History_Tables' AND t.FuenteTabla = N'check_in_navsat' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), c.[Id])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM History_Tables.dbo.[check_in_navsat] c) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.CheckInCampo t
        WHERE t.FuenteBase = N'History_Tables' AND t.FuenteTabla = N'check_in_navsat') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_EventoConexion · core.EventoConexion ← History_Tables.Conexiones_desconexiones_realizadas ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.EventoConexion t WHERE t.FuenteBase = N'History_Tables' AND t.FuenteTabla = N'Conexiones_desconexiones_realizadas' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(CONVERT(nvarchar(66), HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(4000), x.[customer_name]), N'~'), ISNULL(CONVERT(nvarchar(4000), x.[type]), N'~'), ISNULL(CONVERT(nvarchar(30), x.[date], 126), N'~'), ISNULL(CONVERT(nvarchar(4000), x.[realized_by]), N'~'), ISNULL(CONVERT(nvarchar(4000), x.[type_desc_rec]), N'~'), ISNULL(CONVERT(nvarchar(30), x.[date_desc_rec], 126), N'~'))), 2) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM History_Tables.dbo.[Conexiones_desconexiones_realizadas] x
OUTER APPLY (SELECT CASE WHEN COUNT(DISTINCT o.ClienteId) = 1 THEN MIN(o.ClienteId) END AS ClienteId
             FROM core.ClienteOrigen o WHERE o.Sistema = 'ZohoBooks' AND o.LlaveOrigen = ctl.fn_Texto(x.customer_name)) co) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.EventoConexion t
        WHERE t.FuenteBase = N'History_Tables' AND t.FuenteTabla = N'Conexiones_desconexiones_realizadas') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llaves repetidas · core_TicketAtencion · core.TicketAtencion ← ZCRM2Trengo.trengo_data_tickets ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.TicketAtencion t WHERE t.FuenteBase = N'ZCRM2Trengo' AND t.FuenteTabla = N'trengo_data_tickets' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST(ctl.fn_Texto(CONVERT(nvarchar(200), t.[id_case])) AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k
              FROM ZCRM2Trengo.dbo.[trengo_data_tickets] t
CROSS APPLY (SELECT CONVERT(nvarchar(max), t.custom_data) COLLATE DATABASE_DEFAULT AS cd) d0
CROSS APPLY (SELECT CASE WHEN CHARINDEX(N'ID_ZCRM', d0.cd) > 0 THEN
                    NULLIF(LEFT(LTRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(d0.cd, CHARINDEX(N'ID_ZCRM', d0.cd) + 7, 60), N'''', N''), N'"', N''), N':', N'')), 19), N'')
                END COLLATE DATABASE_DEFAULT AS IdZcrm) z
OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(k.ContactoId) END AS ContactoId,
                    CASE WHEN COUNT(*) = 1 THEN MIN(k.ServicioId) END AS ServicioId
             FROM core.Contacto k WHERE k.ContactoCrmId = z.IdZcrm) ct) x) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM core.TicketAtencion t
        WHERE t.FuenteBase = N'ZCRM2Trengo' AND t.FuenteTabla = N'trengo_data_tickets') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Dos versiones · Zoho_Mirror.Accounts y Accounts_Extended → core.Servicio.CuentaCrmId ===== */
SET NOCOUNT ON;
SELECT (SELECT COUNT_BIG(*) FROM (SELECT DISTINCT b.id FROM Zoho_Mirror.dbo.[Accounts] b
                                  WHERE EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.[Accounts_Extended] e WHERE e.id = b.id)) z) AS Origen,
       (SELECT COUNT_BIG(t.[CuentaCrmId]) - COUNT_BIG(DISTINCT t.[CuentaCrmId]) FROM core.Servicio t) AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Dos versiones · Zoho_Mirror.Cases y Cases_Extended → core.Caso.CasoCrmId ===== */
SET NOCOUNT ON;
SELECT (SELECT COUNT_BIG(*) FROM (SELECT DISTINCT b.id FROM Zoho_Mirror.dbo.[Cases] b
                                  WHERE EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.[Cases_Extended] e WHERE e.id = b.id)) z) AS Origen,
       (SELECT COUNT_BIG(t.[CasoCrmId]) - COUNT_BIG(DISTINCT t.[CasoCrmId]) FROM core.Caso t) AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Dos versiones · Zoho_Mirror.Sales_Orders y Sales_Orders_Extended → core.OrdenVenta.OrdenVentaCrmId ===== */
SET NOCOUNT ON;
SELECT (SELECT COUNT_BIG(*) FROM (SELECT DISTINCT b.id FROM Zoho_Mirror.dbo.[Sales_Orders] b
                                  WHERE EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.[Sales_Orders_Extended] e WHERE e.id = b.id)) z) AS Origen,
       (SELECT COUNT_BIG(t.[OrdenVentaCrmId]) - COUNT_BIG(DISTINCT t.[OrdenVentaCrmId]) FROM core.OrdenVenta t) AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llamadas idénticas · core_Llamada_Historico (ADNApp.Telephony_cdr_historico, meses cargados) ===== */
SET NOCOUNT ON;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Llamada t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_cdr_historico' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m);
DECLARE @Fin datetime2 = DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m));
SELECT (SELECT COUNT_BIG(*) - COUNT_BIG(DISTINCT CONVERT(nvarchar(66), HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(4000), c.[CDRTypeCode]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[CDRTypeReason]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[StartDateTime]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[AnswerTimeOfDate]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[DisconnectDateTime]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[IngressTrunk]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[EgressTrunk]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[DialedNumber]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[usd_exchange]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[Destination]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[DestinationCode]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[DestinationRate]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[DestinationRateNoProfit]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[DestinationRound]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[DurationInSeconds]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[DurationInRoundedSeconds]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[DurationInMinutes]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[CallCost]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[CallCostNoProfit]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[CallingNumber]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[BillingNumber]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[VoipDevice]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[CustomerIncrement]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[CustomerPorcentage]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[CustomerCircuitNumber]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[RoutingDigits]), N'~'))), 2)) FROM ADNApp.dbo.Telephony_cdr_historico c
        WHERE c.StartDateTime >= @Ini AND c.StartDateTime < @Fin
          AND CONVERT(char(7), c.StartDateTime, 126) IN (SELECT Mes FROM #m)) AS Origen,
       (SELECT COUNT_BIG(*) - COUNT_BIG(DISTINCT t.HashContenido) FROM core.Llamada t
        WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_cdr_historico') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llamadas idénticas · core_Llamada_SQL (ADNApp.Telephony_cdr, meses cargados) ===== */
SET NOCOUNT ON;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Llamada t WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_cdr' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m);
DECLARE @Fin datetime2 = DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m));
SELECT (SELECT COUNT_BIG(*) - COUNT_BIG(DISTINCT CONVERT(nvarchar(66), HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(4000), c.[CDRTypeCode]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[CDRTypeReason]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[StartDateTime]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[AnswerTimeOfDate]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[DisconnectDateTime]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[IngressTrunk]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[EgressTrunk]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[DialedNumber]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[usd_exchange]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[Destination]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[DestinationCode]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[DestinationRate]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[DestinationRateNoProfit]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[DestinationRound]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[DurationInSeconds]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[DurationInRoundedSeconds]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[DurationInMinutes]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[CallCost]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[CallCostNoProfit]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[CallingNumber]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[BillingNumber]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[VoipDevice]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[CustomerIncrement]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[CustomerPorcentage]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[CustomerCircuitNumber]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[RoutingDigits]), N'~'))), 2)) FROM ADNApp.dbo.Telephony_cdr c
        WHERE c.StartDateTime >= @Ini AND c.StartDateTime < @Fin
          AND CONVERT(char(7), c.StartDateTime, 126) IN (SELECT Mes FROM #m)) AS Origen,
       (SELECT COUNT_BIG(*) - COUNT_BIG(DISTINCT t.HashContenido) FROM core.Llamada t
        WHERE t.FuenteBase = N'ADNApp' AND t.FuenteTabla = N'Telephony_cdr') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Llamadas idénticas · core_Llamada (developer_adn_app_db.Telephony_cdr, meses cargados) ===== */
SET NOCOUNT ON;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Llamada t WHERE t.FuenteBase = N'developer_adn_app_db' AND t.FuenteTabla = N'Telephony_cdr' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m);
DECLARE @Fin datetime2 = DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m));
SELECT (SELECT COUNT_BIG(*) - COUNT_BIG(DISTINCT CONVERT(nvarchar(66), HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(4000), c.[CDRTypeCode]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[CDRTypeReason]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[StartDateTime]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[AnswerTimeOfDate]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[DisconnectDateTime]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[IngressTrunk]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[EgressTrunk]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[DialedNumber]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[usd_exchange]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[Destination]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[DestinationCode]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[DestinationRate]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[DestinationRateNoProfit]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[DestinationRound]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[DurationInSeconds]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[DurationInRoundedSeconds]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[DurationInMinutes]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[CallCost]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[CallCostNoProfit]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[CallingNumber]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[BillingNumber]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[VoipDevice]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[CustomerIncrement]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[CustomerPorcentage]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[CustomerCircuitNumber]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[RoutingDigits]), N'~'))), 2)) FROM stg.mongo_Telephony_cdr c
        WHERE c.StartDateTime >= @Ini AND c.StartDateTime < @Fin
          AND CONVERT(char(7), c.StartDateTime, 126) IN (SELECT Mes FROM #m)) AS Origen,
       (SELECT COUNT_BIG(*) - COUNT_BIG(DISTINCT t.HashContenido) FROM core.Llamada t
        WHERE t.FuenteBase = N'developer_adn_app_db' AND t.FuenteTabla = N'Telephony_cdr') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO

/* ===== Clientes repetidos entre sistemas (misma cédula válida) ===== */
SET NOCOUNT ON;
DROP TABLE IF EXISTS #ced;
SELECT ctl.fn_Cedula(a.Cedula_Jurida_Persona) AS Ced INTO #ced
FROM (SELECT x.*, ROW_NUMBER() OVER (PARTITION BY x.id ORDER BY x.Modified_Time DESC) AS rn FROM Zoho_Mirror.dbo.Accounts_Extended x) a
WHERE a.rn = 1
UNION ALL
SELECT ctl.fn_Cedula(b.Cedula_Jurida_Persona)
FROM (SELECT x.*, ROW_NUMBER() OVER (PARTITION BY x.id ORDER BY ctl.fn_FechaCR(x.Modified_Time) DESC) AS rn FROM Zoho_Mirror.dbo.Accounts x
      WHERE ISNULL(x.deleted, 0) = 0 AND NOT EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.Accounts_Extended e WHERE e.id = x.id)) b
WHERE b.rn = 1
UNION ALL
SELECT ctl.fn_Cedula(c.cf_identificaci_n_unformatted)
FROM (SELECT x.*, ROW_NUMBER() OVER (PARTITION BY x.contact_id ORDER BY ctl.fn_FechaCR(x.last_modified_time) DESC, x.contact_name) AS rn
      FROM ZBooks_Mirror.dbo.contacts x WHERE x.contact_type = 'customer' AND NULLIF(LTRIM(x.contact_id), '') IS NOT NULL) c
WHERE c.rn = 1
UNION ALL
SELECT ctl.fn_Cedula(p.id) FROM ADNPayV2.dbo.Customer p WHERE p.status = 'approved';
SELECT (SELECT COUNT_BIG(Ced) - COUNT_BIG(DISTINCT Ced) FROM #ced) AS Origen,
       (SELECT COUNT_BIG(Cedula) - COUNT_BIG(DISTINCT Cedula) FROM core.Cliente) AS Modelo,
       CAST(0 AS bigint) AS Justificados;
GO
