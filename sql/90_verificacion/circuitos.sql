/* Análisis de la regla de circuitos ID-01 (Sprint 3) - SOLO LECTURA.
   Mide: (1) cuántos circuitos tienen menos de 4 dígitos, (2) choques al quitar separadores,
   (3) cuánto cruzan llamadas y facturas con la regla actual (4-9 dígitos) y con una regla ampliada (2-9 dígitos).
   No muestra circuitos ni datos de clientes: solo conteos. */
SET NOCOUNT ON;

/* Circuitos de las cuentas del CRM, normalizados */
SELECT a.id, UPPER(LTRIM(RTRIM(a.N_mero_Circuito))) AS Original,
       UPPER(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(a.N_mero_Circuito)), N' ', N''), N'-', N''), N'.', N''), N'_', N'')) AS Norm
INTO #crm FROM Zoho_Mirror.dbo.Accounts_Extended a WHERE NULLIF(LTRIM(RTRIM(a.N_mero_Circuito)), N'') IS NOT NULL;
ALTER TABLE #crm ADD Digitos int NULL, Valido varchar(12) NULL;
UPDATE #crm SET Digitos = CASE WHEN LEFT(Norm, 3) COLLATE Latin1_General_BIN LIKE '[A-Z][A-Z][A-Z]' AND SUBSTRING(Norm, 4, 50) NOT LIKE '%[^0-9]%'
                               THEN LEN(Norm) - 3 END;
UPDATE #crm SET Valido = CASE WHEN Digitos BETWEEN 4 AND 9 THEN 'ACTUAL' WHEN Digitos BETWEEN 2 AND 3 THEN 'SOLO_AMPLIA' ELSE 'NINGUNA' END;

SELECT N'1. Cuentas CRM por cantidad de dígitos del circuito' AS Parte, ISNULL(CAST(Digitos AS varchar(5)), 'no cumple forma') AS Digitos,
       Valido AS ReglaQueLoAcepta, COUNT(*) AS Cuentas
FROM #crm GROUP BY Digitos, Valido ORDER BY Digitos;

/* Choques: distintos circuitos originales que quedan iguales al normalizar */
SELECT N'2. Choques al quitar separadores' AS Parte,
       COUNT(*) AS CircuitosNormalizadosConVariasFormas,
       SUM(Formas) AS FormasOriginalesInvolucradas,
       SUM(Cuentas) AS CuentasInvolucradas
FROM (SELECT Norm, COUNT(DISTINCT Original) AS Formas, COUNT(*) AS Cuentas FROM #crm WHERE Digitos IS NOT NULL GROUP BY Norm HAVING COUNT(DISTINCT Original) > 1) x;

SELECT N'2b. Choques por regla' AS Parte, c.Valido, COUNT(DISTINCT c.Norm) AS CircuitosConChoque
FROM #crm c JOIN (SELECT Norm FROM #crm WHERE Digitos IS NOT NULL GROUP BY Norm HAVING COUNT(DISTINCT Original) > 1) x ON x.Norm = c.Norm
GROUP BY c.Valido;

SELECT N'2c. Mismo circuito en varias cuentas (tras normalizar)' AS Parte, COUNT(*) AS Circuitos, SUM(n) AS Cuentas
FROM (SELECT Norm, COUNT(*) AS n FROM #crm WHERE Digitos IS NOT NULL GROUP BY Norm HAVING COUNT(*) > 1) x;

/* 3. Cruce de llamadas (muestra 1 %) y facturas con las cuentas del CRM */
SELECT DISTINCT Norm, Valido INTO #circ FROM #crm WHERE Digitos IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #circ (Norm);

;WITH x AS (
  SELECT N'Llamadas SQL (1 %)' AS Origen,
         UPPER(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(CustomerCircuitNumber)), N' ', N''), N'-', N''), N'.', N''), N'_', N'')) AS Norm
  FROM ADNApp.dbo.Telephony_cdr WHERE id % 100 = 0
  UNION ALL
  SELECT N'Facturas Books',
         UPPER(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(customer_cf_circuit_number_unformatted)), N' ', N''), N'-', N''), N'.', N''), N'_', N''))
  FROM ZBooks_Mirror.dbo.invoices
  UNION ALL
  SELECT N'Contactos Books',
         UPPER(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(cf_circuit_number_unformatted)), N' ', N''), N'-', N''), N'.', N''), N'_', N''))
  FROM ZBooks_Mirror.dbo.contacts WHERE contact_type = 'customer'
)
SELECT N'3. Cruce con cuentas CRM' AS Parte, x.Origen, COUNT_BIG(*) AS Filas,
       SUM(CASE WHEN c.Valido = 'ACTUAL' THEN 1 ELSE 0 END) AS CruzanConReglaActual,
       SUM(CASE WHEN c.Valido IN ('ACTUAL', 'SOLO_AMPLIA') THEN 1 ELSE 0 END) AS CruzanConReglaAmpliada,
       SUM(CASE WHEN c.Valido = 'SOLO_AMPLIA' THEN 1 ELSE 0 END) AS GananciaReglaAmpliada
FROM x LEFT JOIN #circ c ON c.Norm = x.Norm COLLATE DATABASE_DEFAULT
GROUP BY x.Origen;
