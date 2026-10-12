/* Medición para afinar la identidad de clientes, las coordenadas y los nodos FTTH (Sprint 3) - SOLO LECTURA.
   Solo conteos: no muestra cédulas, nombres, circuitos ni coordenadas de clientes.
   Los nombres de nodos (sección 4) son infraestructura de la empresa, no datos de clientes. */
SET NOCOUNT ON; SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_WARNINGS ON;
USE ADN_Unificado;

PRINT '== 1. Cédula en las cuentas del CRM (Accounts_Extended)';
SELECT CASE WHEN NULLIF(LTRIM(RTRIM(a.Cedula_Jurida_Persona)), N'') IS NULL THEN 'vacía'
            WHEN ctl.fn_Cedula(a.Cedula_Jurida_Persona) IS NULL THEN 'con valor inválido'
            ELSE 'válida' END AS CedulaEnCuenta, COUNT(*) AS Cuentas
FROM Zoho_Mirror.dbo.Accounts_Extended a
GROUP BY CASE WHEN NULLIF(LTRIM(RTRIM(a.Cedula_Jurida_Persona)), N'') IS NULL THEN 'vacía'
              WHEN ctl.fn_Cedula(a.Cedula_Jurida_Persona) IS NULL THEN 'con valor inválido' ELSE 'válida' END;

PRINT '== 2. Clientes sin cédula (llave por cuenta): ¿otra fuente del mismo cliente trae cédula válida?';
;WITH cli AS (SELECT ClienteId FROM core.Cliente WHERE FuenteSistema = 'ZohoCRM'),
      ced AS (
    SELECT o.ClienteId, o.Sistema, ctl.fn_Cedula(o.CedulaOriginal) AS Ced
    FROM core.ClienteOrigen o JOIN cli ON cli.ClienteId = o.ClienteId
    WHERE ctl.fn_Cedula(o.CedulaOriginal) IS NOT NULL)
SELECT 'Clientes con llave por cuenta' AS Medida, COUNT(*) AS Clientes FROM cli
UNION ALL SELECT 'con cédula válida en Books (unido por circuito)', COUNT(DISTINCT ClienteId) FROM ced WHERE Sistema = 'ZohoBooks'
UNION ALL SELECT 'con cédula válida en app.data.cr', COUNT(DISTINCT ClienteId) FROM ced WHERE Sistema = 'AppDataCR'
UNION ALL SELECT 'con cédula válida en alguna fuente', COUNT(DISTINCT ClienteId) FROM ced
UNION ALL SELECT 'con más de una cédula distinta entre fuentes', COUNT(*) FROM (SELECT ClienteId FROM ced GROUP BY ClienteId HAVING COUNT(DISTINCT Ced) > 1) x;

PRINT '== 3. Cédula en los contactos del CRM de cuentas sin cédula';
;WITH cta AS (SELECT a.id FROM Zoho_Mirror.dbo.Accounts_Extended a WHERE ctl.fn_Cedula(a.Cedula_Jurida_Persona) IS NULL),
      con AS (
    SELECT ctl.fn_Texto(k.Account_Name) AS Cuenta, COALESCE(ctl.fn_Cedula(k.N_mero_Cedula_Pasaporte), ctl.fn_Cedula(k.Cedula_Juridica)) AS Ced
    FROM Zoho_Mirror.dbo.Contacts k WHERE ISNULL(k.deleted, 0) = 0),
      x AS (
    SELECT cta.id, COUNT(con.Cuenta) AS Contactos, COUNT(DISTINCT con.Ced) AS Cedulas
    FROM cta LEFT JOIN con ON con.Cuenta = cta.id COLLATE DATABASE_DEFAULT GROUP BY cta.id)
SELECT CASE WHEN Contactos = 0 THEN 'sin contactos' WHEN Cedulas = 0 THEN 'contactos sin cédula válida'
            WHEN Cedulas = 1 THEN 'una sola cédula válida' ELSE 'varias cédulas distintas' END AS Situacion, COUNT(*) AS Cuentas
FROM x GROUP BY CASE WHEN Contactos = 0 THEN 'sin contactos' WHEN Cedulas = 0 THEN 'contactos sin cédula válida'
                     WHEN Cedulas = 1 THEN 'una sola cédula válida' ELSE 'varias cédulas distintas' END;

PRINT '== 4. Misma cédula en más de un cliente (posibles duplicados)';
;WITH c AS (SELECT DISTINCT ctl.fn_Cedula(o.CedulaOriginal) AS Ced, o.ClienteId FROM core.ClienteOrigen o WHERE ctl.fn_Cedula(o.CedulaOriginal) IS NOT NULL)
SELECT COUNT(*) AS CedulasEnVariosClientes, SUM(n) AS ClientesInvolucrados FROM (SELECT Ced, COUNT(*) AS n FROM c GROUP BY Ced HAVING COUNT(*) > 1) x;

PRINT '== 5. Forma de las coordenadas rechazadas en servicios (último lote confirmado de core_Servicio)';
DECLARE @L int = (SELECT MAX(LoteId) FROM ctl.Lote WHERE Paso = 'core_Servicio' AND Modo = 'CONFIRM' AND Estado = 'Exitoso');
;WITH v AS (
    SELECT a.ValorOriginal AS t, CHARINDEX(N',', a.ValorOriginal) AS p FROM ctl.Anomalia a
    WHERE a.LoteId = @L AND a.ReglaId = 'ES-05' AND a.Columna = N'Latitud'),
      n AS (
    SELECT t, CASE WHEN p > 1 THEN TRY_CONVERT(float, LTRIM(RTRIM(LEFT(t, p - 1)))) END AS a1,
           CASE WHEN p > 0 THEN TRY_CONVERT(float, LTRIM(RTRIM(SUBSTRING(t, p + 1, 100)))) END AS a2, p FROM v)
SELECT CASE WHEN p = 0 THEN 'sin coma'
            WHEN a1 IS NULL OR a2 IS NULL THEN 'texto no numérico (' + CASE WHEN t LIKE N'%http%' THEN 'enlace' WHEN t LIKE N'%°%' THEN 'grados' ELSE 'otro' END + ')'
            WHEN a1 = 0 AND a2 = 0 THEN 'cero, cero'
            WHEN a1 BETWEEN -86.0 AND -82.5 AND a2 BETWEEN 8.0 AND 11.3 THEN 'invertidas (lon, lat) dentro de Costa Rica'
            WHEN a1 BETWEEN 8.0 AND 11.3 AND a2 BETWEEN 82.5 AND 86.0 THEN 'longitud sin signo negativo'
            ELSE 'fuera de Costa Rica' END AS Forma, COUNT(*) AS Servicios
FROM n GROUP BY CASE WHEN p = 0 THEN 'sin coma'
            WHEN a1 IS NULL OR a2 IS NULL THEN 'texto no numérico (' + CASE WHEN t LIKE N'%http%' THEN 'enlace' WHEN t LIKE N'%°%' THEN 'grados' ELSE 'otro' END + ')'
            WHEN a1 = 0 AND a2 = 0 THEN 'cero, cero'
            WHEN a1 BETWEEN -86.0 AND -82.5 AND a2 BETWEEN 8.0 AND 11.3 THEN 'invertidas (lon, lat) dentro de Costa Rica'
            WHEN a1 BETWEEN 8.0 AND 11.3 AND a2 BETWEEN 82.5 AND 86.0 THEN 'longitud sin signo negativo'
            ELSE 'fuera de Costa Rica' END ORDER BY Servicios DESC;

PRINT '== 6. Nodos FTTH sin correspondencia: nodos cuyo nombre contiene el valor del clúster';
;WITH u AS (
    SELECT DISTINCT ctl.fn_Texto(f.Nodo) AS Nodo FROM Zoho_Mirror.dbo.FTTHs f
    WHERE ISNULL(f.deleted, 0) = 0 AND ctl.fn_Texto(f.Nodo) IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM core.Nodo n WHERE n.Nombre = ctl.fn_Texto(f.Nodo)))
SELECT u.Nodo AS NodoEnCluster, n.Nombre AS NodoCandidato, n.Nomenclatura, n.Estado
FROM u LEFT JOIN core.Nodo n ON n.Nombre LIKE N'%' + u.Nodo + N'%' OR u.Nodo LIKE N'%' + n.Nombre + N'%'
ORDER BY u.Nodo, n.Nombre;
