USE ADN_Unificado;
GO
/* Paso 240 · core_ClienteOrigen → core.ClienteOrigen
   Tabla de correspondencia: cada cuenta del CRM, contacto de Books, contratación de ADNPayV2 y cliente VoIP de app.data.cr con el cliente y el servicio al que se vinculó y el método (ID-04, ID-05).
   Reglas: ID-01, ID-02, ID-04, ID-05, ID-06, ID-08, ES-08, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_ClienteOrigen @LoteId int, @Desde date = NULL, @Hasta date = NULL
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
    SELECT q.[ClienteId],
           q.[ServicioId],
           CAST(q.[Sistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [Sistema],
           CAST(q.[TablaOrigen] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [TablaOrigen],
           CAST(q.[LlaveOrigen] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [LlaveOrigen],
           CAST(q.[CedulaOriginal] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [CedulaOriginal],
           CAST(q.[CircuitoOriginal] AS nvarchar(100)) COLLATE DATABASE_DEFAULT AS [CircuitoOriginal],
           CAST(q.[MetodoEmparejamiento] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [MetodoEmparejamiento],
           q.[FechaEmparejamiento],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[ClienteId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ServicioId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Sistema]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TablaOrigen]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[LlaveOrigen]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[CedulaOriginal]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[CircuitoOriginal]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[MetodoEmparejamiento]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_Cuentas],
           CONCAT_WS(N',', CASE WHEN LEN(q.[Sistema]) > 20 THEN N'Sistema' END, CASE WHEN LEN(q.[TablaOrigen]) > 128 THEN N'TablaOrigen' END, CASE WHEN LEN(q.[LlaveOrigen]) > 200 THEN N'LlaveOrigen' END, CASE WHEN LEN(q.[CedulaOriginal]) > 50 THEN N'CedulaOriginal' END, CASE WHEN LEN(q.[CircuitoOriginal]) > 100 THEN N'CircuitoOriginal' END, CASE WHEN LEN(q.[MetodoEmparejamiento]) > 20 THEN N'MetodoEmparejamiento' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT f.Sis AS FuenteSistema, f.Base AS FuenteBase, f.Tab AS FuenteTabla, f.Llave AS FuenteLlave, f.Creada AS FechaDato,
               cl.ClienteId, sv.ServicioId, f.Sis AS Sistema, f.Tab AS TablaOrigen, f.Llave AS LlaveOrigen,
               ctl.fn_Texto(f.CedO) AS CedulaOriginal, ctl.fn_Texto(f.CircO) AS CircuitoOriginal,
               CASE WHEN f.CedHeredada = 1 THEN 'CEDULA_HEREDADA' ELSE f.Metodo END AS MetodoEmparejamiento,
               @Ahora AS FechaEmparejamiento, f.CuentasDelCircuito AS o_Cuentas
        FROM #f f
        LEFT JOIN core.Cliente cl ON cl.FuenteSistema = f.KSis AND cl.FuenteTabla = f.KTab AND cl.FuenteLlave = f.KLlave
        LEFT JOIN core.Servicio sv ON sv.CuentaCrmId = CASE WHEN f.Sis = 'ZohoCRM' THEN f.Llave ELSE f.CuentaCircuito END
        UNION ALL
        SELECT 'AppDataCR', N'ADNApp', N'ZohoEngine_zohocustomer', CAST(z.id AS nvarchar(200)), CAST(NULL AS datetimeoffset(0)),
               COALESCE(cla.ClienteId, clc.ClienteId), sv.ServicioId, 'AppDataCR', N'ZohoEngine_zohocustomer', CAST(z.id AS nvarchar(200)),
               ctl.fn_Texto(z.IDCard), ctl.fn_Texto(z.CircuitNumber),
               CASE WHEN svz.ServicioId IS NOT NULL THEN 'LLAVE_DIRECTA' WHEN svc.ServicioId IS NOT NULL THEN 'CIRCUITO'
                    WHEN clc.ClienteId IS NOT NULL THEN 'CEDULA' ELSE 'SIN_CORRESPONDENCIA' END,
               @Ahora, CASE WHEN svz.ServicioId IS NULL THEN c.Cuentas END
        FROM ADNApp.dbo.ZohoEngine_zohocustomer z
        LEFT JOIN core.Servicio svz ON svz.CuentaCrmId = ctl.fn_Texto(z.ZohoID)
        LEFT JOIN #circ c ON c.Circ = ctl.fn_Circuito(z.CircuitNumber)
        LEFT JOIN core.Servicio svc ON svz.ServicioId IS NULL AND svc.CuentaCrmId = c.Cuenta
        CROSS APPLY (SELECT COALESCE(svz.ServicioId, svc.ServicioId) AS ServicioId, COALESCE(svz.CuentaCrmId, svc.CuentaCrmId) AS Cuenta) sv
        LEFT JOIN #f fa ON fa.Sis = 'ZohoCRM' AND fa.Llave = sv.Cuenta
        LEFT JOIN core.Cliente cla ON cla.FuenteSistema = fa.KSis AND cla.FuenteTabla = fa.KTab AND cla.FuenteLlave = fa.KLlave
        LEFT JOIN core.Cliente clc ON sv.ServicioId IS NULL AND clc.FuenteTabla = N'Cedula' AND clc.FuenteLlave = ctl.fn_Cedula(z.IDCard)
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'Sistema obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[Sistema] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'TablaOrigen obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[TablaOrigen] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'LlaveOrigen obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[LlaveOrigen] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'MetodoEmparejamiento obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[MetodoEmparejamiento] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FechaEmparejamiento obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FechaEmparejamiento] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FuenteLlave obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FuenteLlave] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE FROM #src WHERE [Sistema] IS NULL OR [TablaOrigen] IS NULL OR [LlaveOrigen] IS NULL OR [MetodoEmparejamiento] IS NULL OR [FechaEmparejamiento] IS NULL OR [FuenteLlave] IS NULL;

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
    SELECT t.[ClienteOrigenId] AS RegistroId, t.FuenteLlave, (SELECT t.[ClienteId], t.[ServicioId], t.[Sistema], t.[TablaOrigen], t.[LlaveOrigen], t.[CedulaOriginal], t.[CircuitoOriginal], t.[MetodoEmparejamiento], t.[FechaEmparejamiento], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.ClienteOrigen t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido;

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.ClienteOrigen WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido) THEN
        UPDATE SET t.[ClienteId] = s.[ClienteId], t.[ServicioId] = s.[ServicioId], t.[Sistema] = s.[Sistema], t.[TablaOrigen] = s.[TablaOrigen], t.[LlaveOrigen] = s.[LlaveOrigen], t.[CedulaOriginal] = s.[CedulaOriginal], t.[CircuitoOriginal] = s.[CircuitoOriginal], t.[MetodoEmparejamiento] = s.[MetodoEmparejamiento], t.[FechaEmparejamiento] = s.[FechaEmparejamiento], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([ClienteId], [ServicioId], [Sistema], [TablaOrigen], [LlaveOrigen], [CedulaOriginal], [CircuitoOriginal], [MetodoEmparejamiento], [FechaEmparejamiento], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[ClienteId], s.[ServicioId], s.[Sistema], s.[TablaOrigen], s.[LlaveOrigen], s.[CedulaOriginal], s.[CircuitoOriginal], s.[MetodoEmparejamiento], s.[FechaEmparejamiento], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[ClienteOrigenId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.ClienteOrigen', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías de las filas afectadas */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.ClienteOrigen', c.RegistroId, LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #cambios c JOIN core.ClienteOrigen t ON t.[ClienteOrigenId] = c.RegistroId JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ID-01', N'core.ClienteOrigen', c.RegistroId, N'ServicioId', LEFT(CONVERT(nvarchar(400), s.CircuitoOriginal), 400), N'Circuito presente en varias cuentas: se vinculó a la cuenta activa más reciente'
    FROM #cambios c JOIN core.ClienteOrigen t ON t.[ClienteOrigenId] = c.RegistroId JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Cuentas > 1;

    SELECT @Leidas AS FilasLeidas, @Validas - (SELECT COUNT_BIG(*) FROM #cambios) AS FilasSinCambio;
END;
GO
