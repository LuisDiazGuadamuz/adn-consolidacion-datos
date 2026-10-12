USE ADN_Unificado;
GO
/* Paso 230 · core_Cliente → core.Cliente
   Clientes consolidados de CRM, Books y ADNPayV2. Con cédula válida: un cliente por cédula (FuenteTabla = Cedula). Sin cédula: un cliente por registro de origen sin correspondencia (D8). Cada campo toma el valor según D9 y su origen queda en ctl.LinajeCampo.
   Reglas: ID-02, ID-03, ID-05, ID-06, D8, D9, ES-05, ES-07, ES-08, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_Cliente @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 0. Preparación */
    /* Cuentas del CRM: _Extended (principal) + base completa solo para cuentas ausentes (D2); sin eliminadas */
    DROP TABLE IF EXISTS #crm;
    SELECT x.* INTO #crm FROM (
        SELECT N'Accounts_Extended' AS Tab, a.id COLLATE DATABASE_DEFAULT AS Llave, a.Cedula_Jurida_Persona AS CedO, ctl.fn_Cedula(a.Cedula_Jurida_Persona) AS Ced,
               a.N_mero_Circuito AS CircO, ctl.fn_Circuito(a.N_mero_Circuito) AS Circ, ctl.fn_Texto(a.Estado) AS Estado,
               ctl.fn_Texto(a.Account_Name) AS Nombre, ctl.fn_Texto(a.Raz_n_Social) AS Razon, ctl.fn_Texto(a.Tipo_Fiscal) AS TipoFis,
               CAST(NULL AS bit) AS Exon, ctl.fn_Texto(a.Segmento_Cuenta) AS Segmento, ctl.fn_Texto(a.Industry) AS Industria,
               ctl.fn_FechaCR(CONVERT(nvarchar(30), a.Created_Time, 126)) AS Creada,
               ctl.fn_FechaCR(CONVERT(nvarchar(30), a.Modified_Time, 126)) AS Modificada,
               ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.Modified_Time DESC) AS rn
        FROM Zoho_Mirror.dbo.Accounts_Extended a
        UNION ALL
        SELECT N'Accounts', b.id COLLATE DATABASE_DEFAULT, b.Cedula_Jurida_Persona, ctl.fn_Cedula(b.Cedula_Jurida_Persona),
               b.N_mero_Circuito, ctl.fn_Circuito(b.N_mero_Circuito), ctl.fn_Texto(b.Estado),
               ctl.fn_Texto(b.Account_Name), ctl.fn_Texto(b.Raz_n_Social), ctl.fn_Texto(b.Tipo_Fiscal),
               ctl.fn_Bit(b.Exonerado), ctl.fn_Texto(b.Segmento_Cuenta), ctl.fn_Texto(b.Industry),
               ctl.fn_FechaCR(b.Created_Time), ctl.fn_FechaCR(b.Modified_Time),
               ROW_NUMBER() OVER (PARTITION BY b.id ORDER BY ctl.fn_FechaCR(b.Modified_Time) DESC)
        FROM Zoho_Mirror.dbo.Accounts b
        WHERE ISNULL(b.deleted, 0) = 0
          AND NOT EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.Accounts_Extended e WHERE e.id = b.id)
    ) x WHERE x.rn = 1;
    CREATE CLUSTERED INDEX ix_crm ON #crm (Llave);
    
    /* Circuito → cuenta: si el circuito está en varias cuentas se elige la activa más reciente (marcado como ambiguo) */
    DROP TABLE IF EXISTS #circ;
    SELECT Circ, Llave AS Cuenta, Tab, Cuentas INTO #circ FROM (
        SELECT Circ, Llave, Tab, COUNT(*) OVER (PARTITION BY Circ) AS Cuentas,
               ROW_NUMBER() OVER (PARTITION BY Circ ORDER BY CASE WHEN Estado = N'Activo' THEN 0 ELSE 1 END, Modificada DESC, Llave) AS rn
        FROM #crm WHERE Circ IS NOT NULL) z
    WHERE rn = 1;
    CREATE UNIQUE CLUSTERED INDEX ix_circ ON #circ (Circ);
    
    /* Todas las fuentes de cliente con su llave de identidad (ID-05: circuito > cédula > sin correspondencia) */
    DROP TABLE IF EXISTS #f;
    CREATE TABLE #f (Sis varchar(20) COLLATE DATABASE_DEFAULT NOT NULL, Base nvarchar(128) COLLATE DATABASE_DEFAULT NOT NULL, Tab nvarchar(128) COLLATE DATABASE_DEFAULT NOT NULL, Llave nvarchar(200) COLLATE DATABASE_DEFAULT NOT NULL,
                     CedO nvarchar(255) COLLATE DATABASE_DEFAULT NULL, Ced varchar(12) COLLATE DATABASE_DEFAULT NULL, CircO nvarchar(255) COLLATE DATABASE_DEFAULT NULL, Circ varchar(12) COLLATE DATABASE_DEFAULT NULL,
                     CuentaCircuito nvarchar(200) COLLATE DATABASE_DEFAULT NULL, CuentasDelCircuito int NULL,
                     Nombre nvarchar(255) COLLATE DATABASE_DEFAULT NULL, Razon nvarchar(255) COLLATE DATABASE_DEFAULT NULL, TipoFis nvarchar(120) COLLATE DATABASE_DEFAULT NULL, Exon bit NULL,
                     Correo nvarchar(255) COLLATE DATABASE_DEFAULT NULL, Tel nvarchar(60) COLLATE DATABASE_DEFAULT NULL, Segmento nvarchar(120) COLLATE DATABASE_DEFAULT NULL, Industria nvarchar(120) COLLATE DATABASE_DEFAULT NULL,
                     Creada datetimeoffset(0) NULL, Modificada datetimeoffset(0) NULL,
                     RankCom tinyint NOT NULL, RankFis tinyint NOT NULL, Clave nvarchar(220) COLLATE DATABASE_DEFAULT NULL, Metodo varchar(20) COLLATE DATABASE_DEFAULT NULL,
                     CedHeredada bit NOT NULL DEFAULT 0,
                     KSis varchar(20) COLLATE DATABASE_DEFAULT NULL, KBase nvarchar(128) COLLATE DATABASE_DEFAULT NULL, KTab nvarchar(128) COLLATE DATABASE_DEFAULT NULL, KLlave nvarchar(200) COLLATE DATABASE_DEFAULT NULL);
    INSERT #f (Sis, Base, Tab, Llave, CedO, Ced, CircO, Circ, Nombre, Razon, TipoFis, Exon, Segmento, Industria, Creada, Modificada, RankCom, RankFis, Clave, Metodo)
    SELECT 'ZohoCRM', N'Zoho_Mirror', Tab, Llave, CedO, Ced, CircO, Circ, Nombre, Razon, TipoFis, Exon, Segmento, Industria, Creada, Modificada, 1, 2,
           CASE WHEN Ced IS NOT NULL THEN N'C:' + Ced ELSE N'A:' + Tab + N':' + Llave END, 'LLAVE_DIRECTA'
    FROM #crm;
    
    /* Books: un registro por contacto cliente (versión más reciente, DD-02) */
    INSERT #f (Sis, Base, Tab, Llave, CedO, Ced, CircO, Circ, Nombre, Razon, TipoFis, Exon, Correo, Tel, Segmento, Creada, Modificada, RankCom, RankFis)
    SELECT 'ZohoBooks', N'ZBooks_Mirror', N'contacts', c.contact_id, c.cf_identificaci_n_unformatted, ctl.fn_Cedula(c.cf_identificaci_n_unformatted),
           c.cf_circuit_number_unformatted, ctl.fn_Circuito(c.cf_circuit_number_unformatted),
           COALESCE(ctl.fn_Texto(c.customer_name), ctl.fn_Texto(c.contact_name)), ctl.fn_Texto(c.company_name),
           ctl.fn_Texto(c.cf_tipo_fiscal_unformatted), ctl.fn_Bit(c.cf_exonerado_unformatted),
           ctl.fn_Texto(c.email), COALESCE(ctl.fn_Texto(c.phone), ctl.fn_Texto(c.mobile)), ctl.fn_Texto(c.cf_segmento_unformatted),
           ctl.fn_FechaCR(c.created_time), ctl.fn_FechaCR(c.last_modified_time), 2, 1
    FROM (SELECT x.*, ROW_NUMBER() OVER (PARTITION BY x.contact_id ORDER BY ctl.fn_FechaCR(x.last_modified_time) DESC, x.contact_name) AS rn
          FROM ZBooks_Mirror.dbo.contacts x WHERE x.contact_type = 'customer' AND NULLIF(LTRIM(x.contact_id), '') IS NOT NULL) c
    WHERE c.rn = 1;
    
    /* ADNPayV2: contrataciones aprobadas (solo completan vacíos, D9) */
    INSERT #f (Sis, Base, Tab, Llave, CedO, Ced, Nombre, Correo, Tel, Creada, Modificada, RankCom, RankFis)
    SELECT 'ADNPayV2', N'ADNPayV2', N'Customer', CAST(p.[index] AS nvarchar(200)), p.id, ctl.fn_Cedula(p.id), ctl.fn_Texto(p.name),
           ctl.fn_Texto(p.email), COALESCE(ctl.fn_Texto(p.mobile), ctl.fn_Texto(p.phone)),
           ctl.fn_FechaCR(CONVERT(nvarchar(30), p.create_time, 126)), ctl.fn_FechaCR(CONVERT(nvarchar(30), p.create_time, 126)), 3, 3
    FROM ADNPayV2.dbo.Customer p WHERE p.status = 'approved';
    
    /* Emparejamiento de Books y ADNPayV2 */
    UPDATE f SET f.CuentaCircuito = c.Cuenta, f.CuentasDelCircuito = c.Cuentas
    FROM #f f JOIN #circ c ON c.Circ = f.Circ WHERE f.Sis <> 'ZohoCRM';
    /* Cédula heredada (ID-02 + D9, Books manda en lo fiscal): cuenta del CRM sin cédula válida toma la cédula de los
       registros ligados a ella (Books por circuito, app.data.cr por id de Zoho) solo si todos traen la MISMA cédula.
       El valor original de la cuenta no cambia (core.ClienteOrigen.CedulaOriginal); se marca con anomalía ID-02. */
    DROP TABLE IF EXISTS #her;
    SELECT Cuenta, MIN(Ced) AS Ced, COUNT(DISTINCT Ced) AS Cedulas INTO #her FROM (
        SELECT f.CuentaCircuito AS Cuenta, f.Ced FROM #f f WHERE f.Sis = 'ZohoBooks' AND f.CuentaCircuito IS NOT NULL AND f.Ced IS NOT NULL
        UNION ALL
        SELECT ctl.fn_Texto(z.ZohoID), ctl.fn_Cedula(z.IDCard) FROM ADNApp.dbo.ZohoEngine_zohocustomer z
        WHERE ctl.fn_Texto(z.ZohoID) IS NOT NULL AND ctl.fn_Cedula(z.IDCard) IS NOT NULL) x
    GROUP BY Cuenta;
    UPDATE f SET f.Ced = h.Ced, f.CedHeredada = 1, f.Clave = N'C:' + h.Ced
    FROM #f f JOIN #her h ON h.Cuenta = f.Llave
    WHERE f.Sis = 'ZohoCRM' AND f.Ced IS NULL AND h.Cedulas = 1;
    UPDATE f SET f.Clave = k.Clave, f.Metodo = 'CIRCUITO'
    FROM #f f JOIN #f k ON k.Sis = 'ZohoCRM' AND k.Llave = f.CuentaCircuito
    WHERE f.Sis <> 'ZohoCRM' AND f.CuentaCircuito IS NOT NULL;
    UPDATE #f SET Clave = N'C:' + Ced, Metodo = 'CEDULA' WHERE Clave IS NULL AND Ced IS NOT NULL;
    UPDATE #f SET Clave = CASE Sis WHEN 'ZohoBooks' THEN N'B:' ELSE N'P:' END + Llave, Metodo = 'SIN_CORRESPONDENCIA' WHERE Clave IS NULL;
    /* Una cédula sin cuenta del CRM: si existe, el método CEDULA solo cuenta como correspondencia con otro sistema */
    UPDATE f SET f.Metodo = 'SIN_CORRESPONDENCIA'
    FROM #f f WHERE f.Metodo = 'CEDULA' AND NOT EXISTS (SELECT 1 FROM #f g WHERE g.Clave = f.Clave AND g.Sis <> f.Sis);
    /* Linaje del cliente al que pertenece cada registro (llave del MERGE de core.Cliente) */
    UPDATE #f SET KSis = CASE LEFT(Clave, 2) WHEN N'C:' THEN 'Consolidado' WHEN N'A:' THEN 'ZohoCRM' WHEN N'B:' THEN 'ZohoBooks' ELSE 'ADNPayV2' END,
                  KBase = CASE LEFT(Clave, 2) WHEN N'C:' THEN N'ADN_Unificado' WHEN N'A:' THEN N'Zoho_Mirror' WHEN N'B:' THEN N'ZBooks_Mirror' ELSE N'ADNPayV2' END,
                  KTab = CASE LEFT(Clave, 2) WHEN N'C:' THEN N'Cedula' WHEN N'A:' THEN SUBSTRING(Clave, 3, CHARINDEX(N':', Clave, 3) - 3)
                              WHEN N'B:' THEN N'contacts' ELSE N'Customer' END,
                  KLlave = CASE LEFT(Clave, 2) WHEN N'C:' THEN SUBSTRING(Clave, 3, 20) WHEN N'A:' THEN SUBSTRING(Clave, CHARINDEX(N':', Clave, 3) + 1, 200)
                                ELSE SUBSTRING(Clave, 3, 200) END;
    CREATE CLUSTERED INDEX ix_f ON #f (Clave, RankCom, RankFis);
    CREATE INDEX ix_f_llave ON #f (Sis, Llave) INCLUDE (KSis, KTab, KLlave);

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT CAST(q.[Cedula] AS varchar(12)) COLLATE DATABASE_DEFAULT AS [Cedula],
           CAST(q.[TipoIdentificacion] AS varchar(10)) COLLATE DATABASE_DEFAULT AS [TipoIdentificacion],
           CAST(q.[Nombre] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [Nombre],
           CAST(q.[RazonSocial] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [RazonSocial],
           CAST(q.[TipoFiscal] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [TipoFiscal],
           q.[Exonerado],
           CAST(q.[Correo] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [Correo],
           CAST(q.[Telefono] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [Telefono],
           CAST(q.[Segmento] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Segmento],
           CAST(q.[Industria] AS nvarchar(100)) COLLATE DATABASE_DEFAULT AS [Industria],
           CAST(q.[EstadoCorrespondencia] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [EstadoCorrespondencia],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[Cedula]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TipoIdentificacion]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Nombre]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[RazonSocial]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TipoFiscal]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Exonerado]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Correo]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Telefono]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Segmento]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Industria]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[EstadoCorrespondencia]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_Cedula],
           q.[o_Heredada],
           q.[lf_Nombre_sis],
           q.[lf_Nombre_tab],
           q.[lf_Nombre_llave],
           q.[lf_Nombre_fecha],
           q.[lf_RazonSocial_sis],
           q.[lf_RazonSocial_tab],
           q.[lf_RazonSocial_llave],
           q.[lf_RazonSocial_fecha],
           q.[lf_TipoFiscal_sis],
           q.[lf_TipoFiscal_tab],
           q.[lf_TipoFiscal_llave],
           q.[lf_TipoFiscal_fecha],
           q.[lf_Exonerado_sis],
           q.[lf_Exonerado_tab],
           q.[lf_Exonerado_llave],
           q.[lf_Exonerado_fecha],
           q.[lf_Correo_sis],
           q.[lf_Correo_tab],
           q.[lf_Correo_llave],
           q.[lf_Correo_fecha],
           q.[lf_Telefono_sis],
           q.[lf_Telefono_tab],
           q.[lf_Telefono_llave],
           q.[lf_Telefono_fecha],
           q.[lf_Segmento_sis],
           q.[lf_Segmento_tab],
           q.[lf_Segmento_llave],
           q.[lf_Segmento_fecha],
           q.[lf_Industria_sis],
           q.[lf_Industria_tab],
           q.[lf_Industria_llave],
           q.[lf_Industria_fecha],
           CONCAT_WS(N',', CASE WHEN LEN(q.[Cedula]) > 12 THEN N'Cedula' END, CASE WHEN LEN(q.[TipoIdentificacion]) > 10 THEN N'TipoIdentificacion' END, CASE WHEN LEN(q.[Nombre]) > 200 THEN N'Nombre' END, CASE WHEN LEN(q.[RazonSocial]) > 200 THEN N'RazonSocial' END, CASE WHEN LEN(q.[TipoFiscal]) > 50 THEN N'TipoFiscal' END, CASE WHEN LEN(q.[Correo]) > 200 THEN N'Correo' END, CASE WHEN LEN(q.[Telefono]) > 30 THEN N'Telefono' END, CASE WHEN LEN(q.[Segmento]) > 50 THEN N'Segmento' END, CASE WHEN LEN(q.[Industria]) > 100 THEN N'Industria' END, CASE WHEN LEN(q.[EstadoCorrespondencia]) > 20 THEN N'EstadoCorrespondencia' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT p.KSis AS FuenteSistema, p.KBase AS FuenteBase, p.KTab AS FuenteTabla, p.KLlave AS FuenteLlave,
               k.Desde AS FechaDato,
               CASE WHEN LEFT(k.Clave, 2) = N'C:' THEN SUBSTRING(k.Clave, 3, 20) END AS Cedula,
               CASE WHEN LEFT(k.Clave, 2) = N'C:' THEN ctl.fn_TipoIdentificacion(SUBSTRING(k.Clave, 3, 20)) ELSE ctl.fn_TipoIdentificacion(p.CedO) END AS TipoIdentificacion,
               x_Nombre.v AS Nombre,
               x_Razon.v AS RazonSocial,
               x_TipoFis.v AS TipoFiscal,
               x_Exon.v AS Exonerado,
               x_Correo.v AS Correo,
               x_Tel.v AS Telefono,
               x_Segmento.v AS Segmento,
               x_Industria.v AS Industria,
               CASE WHEN k.ConCrm = 1 THEN 'CRM' WHEN k.ConBooks = 1 THEN 'SOLO_BOOKS' ELSE 'SOLO_ADNPAY' END AS EstadoCorrespondencia,
               x_Nombre.Sis AS lf_Nombre_sis, x_Nombre.Tab AS lf_Nombre_tab, x_Nombre.Llave AS lf_Nombre_llave, x_Nombre.Modificada AS lf_Nombre_fecha,
               x_Razon.Sis AS lf_RazonSocial_sis, x_Razon.Tab AS lf_RazonSocial_tab, x_Razon.Llave AS lf_RazonSocial_llave, x_Razon.Modificada AS lf_RazonSocial_fecha,
               x_TipoFis.Sis AS lf_TipoFiscal_sis, x_TipoFis.Tab AS lf_TipoFiscal_tab, x_TipoFis.Llave AS lf_TipoFiscal_llave, x_TipoFis.Modificada AS lf_TipoFiscal_fecha,
               x_Exon.Sis AS lf_Exonerado_sis, x_Exon.Tab AS lf_Exonerado_tab, x_Exon.Llave AS lf_Exonerado_llave, x_Exon.Modificada AS lf_Exonerado_fecha,
               x_Correo.Sis AS lf_Correo_sis, x_Correo.Tab AS lf_Correo_tab, x_Correo.Llave AS lf_Correo_llave, x_Correo.Modificada AS lf_Correo_fecha,
               x_Tel.Sis AS lf_Telefono_sis, x_Tel.Tab AS lf_Telefono_tab, x_Tel.Llave AS lf_Telefono_llave, x_Tel.Modificada AS lf_Telefono_fecha,
               x_Segmento.Sis AS lf_Segmento_sis, x_Segmento.Tab AS lf_Segmento_tab, x_Segmento.Llave AS lf_Segmento_llave, x_Segmento.Modificada AS lf_Segmento_fecha,
               x_Industria.Sis AS lf_Industria_sis, x_Industria.Tab AS lf_Industria_tab, x_Industria.Llave AS lf_Industria_llave, x_Industria.Modificada AS lf_Industria_fecha,
               p.CedO AS o_Cedula, k.Heredada AS o_Heredada
        FROM (SELECT Clave, MIN(Creada) AS Desde, MAX(CASE WHEN Sis = 'ZohoCRM' THEN 1 ELSE 0 END) AS ConCrm,
                     MAX(CASE WHEN Sis = 'ZohoBooks' THEN 1 ELSE 0 END) AS ConBooks, COUNT(DISTINCT Ced) AS Cedulas,
                     MAX(CAST(CedHeredada AS int)) AS Heredada
              FROM #f GROUP BY Clave) k
        CROSS APPLY (SELECT TOP 1 f.KSis, f.KBase, f.KTab, f.KLlave, f.CedO FROM #f f WHERE f.Clave = k.Clave ORDER BY f.RankCom, f.Modificada DESC, f.Llave) p
        OUTER APPLY (SELECT TOP 1 f.Nombre AS v, f.Sis, f.Tab, f.Llave, f.Modificada FROM #f f WHERE f.Clave = k.Clave AND f.Nombre IS NOT NULL ORDER BY f.RankCom, f.Modificada DESC, f.Llave) AS x_Nombre
        OUTER APPLY (SELECT TOP 1 f.Razon AS v, f.Sis, f.Tab, f.Llave, f.Modificada FROM #f f WHERE f.Clave = k.Clave AND f.Razon IS NOT NULL ORDER BY f.RankFis, f.Modificada DESC, f.Llave) AS x_Razon
        OUTER APPLY (SELECT TOP 1 f.TipoFis AS v, f.Sis, f.Tab, f.Llave, f.Modificada FROM #f f WHERE f.Clave = k.Clave AND f.TipoFis IS NOT NULL ORDER BY f.RankFis, f.Modificada DESC, f.Llave) AS x_TipoFis
        OUTER APPLY (SELECT TOP 1 f.Exon AS v, f.Sis, f.Tab, f.Llave, f.Modificada FROM #f f WHERE f.Clave = k.Clave AND f.Exon IS NOT NULL ORDER BY f.RankFis, f.Modificada DESC, f.Llave) AS x_Exon
        OUTER APPLY (SELECT TOP 1 f.Correo AS v, f.Sis, f.Tab, f.Llave, f.Modificada FROM #f f WHERE f.Clave = k.Clave AND f.Correo IS NOT NULL ORDER BY f.RankCom, f.Modificada DESC, f.Llave) AS x_Correo
        OUTER APPLY (SELECT TOP 1 f.Tel AS v, f.Sis, f.Tab, f.Llave, f.Modificada FROM #f f WHERE f.Clave = k.Clave AND f.Tel IS NOT NULL ORDER BY f.RankCom, f.Modificada DESC, f.Llave) AS x_Tel
        OUTER APPLY (SELECT TOP 1 f.Segmento AS v, f.Sis, f.Tab, f.Llave, f.Modificada FROM #f f WHERE f.Clave = k.Clave AND f.Segmento IS NOT NULL ORDER BY f.RankCom, f.Modificada DESC, f.Llave) AS x_Segmento
        OUTER APPLY (SELECT TOP 1 f.Industria AS v, f.Sis, f.Tab, f.Llave, f.Modificada FROM #f f WHERE f.Clave = k.Clave AND f.Industria IS NOT NULL ORDER BY f.RankCom, f.Modificada DESC, f.Llave) AS x_Industria
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'TipoIdentificacion obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[TipoIdentificacion] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'EstadoCorrespondencia obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[EstadoCorrespondencia] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FuenteLlave obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FuenteLlave] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE FROM #src WHERE [TipoIdentificacion] IS NULL OR [EstadoCorrespondencia] IS NULL OR [FuenteLlave] IS NULL;

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
    SELECT t.[ClienteId] AS RegistroId, t.FuenteLlave, (SELECT t.[Cedula], t.[TipoIdentificacion], t.[Nombre], t.[RazonSocial], t.[TipoFiscal], t.[Exonerado], t.[Correo], t.[Telefono], t.[Segmento], t.[Industria], t.[EstadoCorrespondencia], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.Cliente t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido;

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.Cliente WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido) THEN
        UPDATE SET t.[Cedula] = s.[Cedula], t.[TipoIdentificacion] = s.[TipoIdentificacion], t.[Nombre] = s.[Nombre], t.[RazonSocial] = s.[RazonSocial], t.[TipoFiscal] = s.[TipoFiscal], t.[Exonerado] = s.[Exonerado], t.[Correo] = s.[Correo], t.[Telefono] = s.[Telefono], t.[Segmento] = s.[Segmento], t.[Industria] = s.[Industria], t.[EstadoCorrespondencia] = s.[EstadoCorrespondencia], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([Cedula], [TipoIdentificacion], [Nombre], [RazonSocial], [TipoFiscal], [Exonerado], [Correo], [Telefono], [Segmento], [Industria], [EstadoCorrespondencia], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[Cedula], s.[TipoIdentificacion], s.[Nombre], s.[RazonSocial], s.[TipoFiscal], s.[Exonerado], s.[Correo], s.[Telefono], s.[Segmento], s.[Industria], s.[EstadoCorrespondencia], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[ClienteId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.Cliente', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 5b. Linaje por campo (D9): qué sistema aportó cada valor de las filas afectadas */
    INSERT ctl.LinajeCampo (TablaModelo, RegistroId, Columna, FuenteSistema, FuenteTabla, FuenteLlave, FechaDato, LoteId)
    SELECT N'core.Cliente', c.RegistroId, N'Nombre', s.lf_Nombre_sis, s.lf_Nombre_tab, s.lf_Nombre_llave, s.lf_Nombre_fecha, @LoteId
    FROM #cambios c JOIN core.Cliente t ON t.[ClienteId] = c.RegistroId JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.lf_Nombre_sis IS NOT NULL AND s.lf_Nombre_tab IS NOT NULL AND s.lf_Nombre_llave IS NOT NULL;
    INSERT ctl.LinajeCampo (TablaModelo, RegistroId, Columna, FuenteSistema, FuenteTabla, FuenteLlave, FechaDato, LoteId)
    SELECT N'core.Cliente', c.RegistroId, N'RazonSocial', s.lf_RazonSocial_sis, s.lf_RazonSocial_tab, s.lf_RazonSocial_llave, s.lf_RazonSocial_fecha, @LoteId
    FROM #cambios c JOIN core.Cliente t ON t.[ClienteId] = c.RegistroId JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.lf_RazonSocial_sis IS NOT NULL AND s.lf_RazonSocial_tab IS NOT NULL AND s.lf_RazonSocial_llave IS NOT NULL;
    INSERT ctl.LinajeCampo (TablaModelo, RegistroId, Columna, FuenteSistema, FuenteTabla, FuenteLlave, FechaDato, LoteId)
    SELECT N'core.Cliente', c.RegistroId, N'TipoFiscal', s.lf_TipoFiscal_sis, s.lf_TipoFiscal_tab, s.lf_TipoFiscal_llave, s.lf_TipoFiscal_fecha, @LoteId
    FROM #cambios c JOIN core.Cliente t ON t.[ClienteId] = c.RegistroId JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.lf_TipoFiscal_sis IS NOT NULL AND s.lf_TipoFiscal_tab IS NOT NULL AND s.lf_TipoFiscal_llave IS NOT NULL;
    INSERT ctl.LinajeCampo (TablaModelo, RegistroId, Columna, FuenteSistema, FuenteTabla, FuenteLlave, FechaDato, LoteId)
    SELECT N'core.Cliente', c.RegistroId, N'Exonerado', s.lf_Exonerado_sis, s.lf_Exonerado_tab, s.lf_Exonerado_llave, s.lf_Exonerado_fecha, @LoteId
    FROM #cambios c JOIN core.Cliente t ON t.[ClienteId] = c.RegistroId JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.lf_Exonerado_sis IS NOT NULL AND s.lf_Exonerado_tab IS NOT NULL AND s.lf_Exonerado_llave IS NOT NULL;
    INSERT ctl.LinajeCampo (TablaModelo, RegistroId, Columna, FuenteSistema, FuenteTabla, FuenteLlave, FechaDato, LoteId)
    SELECT N'core.Cliente', c.RegistroId, N'Correo', s.lf_Correo_sis, s.lf_Correo_tab, s.lf_Correo_llave, s.lf_Correo_fecha, @LoteId
    FROM #cambios c JOIN core.Cliente t ON t.[ClienteId] = c.RegistroId JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.lf_Correo_sis IS NOT NULL AND s.lf_Correo_tab IS NOT NULL AND s.lf_Correo_llave IS NOT NULL;
    INSERT ctl.LinajeCampo (TablaModelo, RegistroId, Columna, FuenteSistema, FuenteTabla, FuenteLlave, FechaDato, LoteId)
    SELECT N'core.Cliente', c.RegistroId, N'Telefono', s.lf_Telefono_sis, s.lf_Telefono_tab, s.lf_Telefono_llave, s.lf_Telefono_fecha, @LoteId
    FROM #cambios c JOIN core.Cliente t ON t.[ClienteId] = c.RegistroId JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.lf_Telefono_sis IS NOT NULL AND s.lf_Telefono_tab IS NOT NULL AND s.lf_Telefono_llave IS NOT NULL;
    INSERT ctl.LinajeCampo (TablaModelo, RegistroId, Columna, FuenteSistema, FuenteTabla, FuenteLlave, FechaDato, LoteId)
    SELECT N'core.Cliente', c.RegistroId, N'Segmento', s.lf_Segmento_sis, s.lf_Segmento_tab, s.lf_Segmento_llave, s.lf_Segmento_fecha, @LoteId
    FROM #cambios c JOIN core.Cliente t ON t.[ClienteId] = c.RegistroId JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.lf_Segmento_sis IS NOT NULL AND s.lf_Segmento_tab IS NOT NULL AND s.lf_Segmento_llave IS NOT NULL;
    INSERT ctl.LinajeCampo (TablaModelo, RegistroId, Columna, FuenteSistema, FuenteTabla, FuenteLlave, FechaDato, LoteId)
    SELECT N'core.Cliente', c.RegistroId, N'Industria', s.lf_Industria_sis, s.lf_Industria_tab, s.lf_Industria_llave, s.lf_Industria_fecha, @LoteId
    FROM #cambios c JOIN core.Cliente t ON t.[ClienteId] = c.RegistroId JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.lf_Industria_sis IS NOT NULL AND s.lf_Industria_tab IS NOT NULL AND s.lf_Industria_llave IS NOT NULL;

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.Cliente', t.[ClienteId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.Cliente t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ID-02', N'core.Cliente', t.[ClienteId], N'Cedula', LEFT(CONVERT(nvarchar(400), s.o_Cedula), 400), N'Identificación con formato inválido; se conserva el valor original en core.ClienteOrigen'
    FROM #src s JOIN core.Cliente t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.Cedula IS NULL AND s.TipoIdentificacion = 'INVALIDA';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ID-02', N'core.Cliente', t.[ClienteId], N'Cedula', LEFT(CONVERT(nvarchar(400), s.o_Cedula), 400), N'Cuenta del CRM sin cédula: se tomó la cédula única de Books o app.data.cr ligados a la cuenta'
    FROM #src s JOIN core.Cliente t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Heredada = 1;

    SELECT @Leidas AS FilasLeidas, @Validas - (SELECT COUNT_BIG(*) FROM #cambios) AS FilasSinCambio;
END;
GO
