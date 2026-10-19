/* Formas de escribir el circuito en cada fuente (Sprint 3, regla ID-01 opción B: conservar separadores) - SOLO LECTURA.
   Cada valor se reduce a su forma: letras → A, dígitos → 9 (sin mostrar ningún circuito). Sirve para definir qué
   separadores se conservan, el largo máximo de la columna y cuántos valores emparejan entre fuentes con y sin separadores. */
SET NOCOUNT ON; SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_WARNINGS ON;
USE ADN_Unificado;

DROP TABLE IF EXISTS #v;
CREATE TABLE #v (Fuente varchar(30), Valor nvarchar(100) COLLATE DATABASE_DEFAULT);
INSERT #v SELECT 'CRM Accounts_Extended', UPPER(LTRIM(RTRIM(N_mero_Circuito))) FROM Zoho_Mirror.dbo.Accounts_Extended WHERE NULLIF(LTRIM(RTRIM(N_mero_Circuito)), N'') IS NOT NULL;
INSERT #v SELECT 'CRM Accounts', UPPER(LTRIM(RTRIM(N_mero_Circuito))) FROM Zoho_Mirror.dbo.Accounts WHERE NULLIF(LTRIM(RTRIM(N_mero_Circuito)), N'') IS NOT NULL AND ISNULL(deleted, 0) = 0;
INSERT #v SELECT 'Books contactos', UPPER(LTRIM(RTRIM(cf_circuit_number_unformatted))) FROM ZBooks_Mirror.dbo.contacts WHERE contact_type = 'customer' AND NULLIF(LTRIM(RTRIM(cf_circuit_number_unformatted)), N'') IS NOT NULL;
INSERT #v SELECT 'Books facturas', UPPER(LTRIM(RTRIM(customer_cf_circuit_number_unformatted))) FROM ZBooks_Mirror.dbo.invoices WHERE NULLIF(LTRIM(RTRIM(customer_cf_circuit_number_unformatted)), N'') IS NOT NULL;
INSERT #v SELECT 'app.data.cr clientes VoIP', UPPER(LTRIM(RTRIM(CircuitNumber))) FROM ADNApp.dbo.ZohoEngine_zohocustomer WHERE NULLIF(LTRIM(RTRIM(CircuitNumber)), N'') IS NOT NULL;
INSERT #v SELECT 'Llamadas abr-2026', UPPER(LTRIM(RTRIM(CustomerCircuitNumber))) FROM ADNApp.dbo.Telephony_cdr
  WHERE StartDateTime >= '2026-04-01' AND StartDateTime < '2026-05-01' AND NULLIF(LTRIM(RTRIM(CustomerCircuitNumber)), N'') IS NOT NULL;

/* Forma: dígitos → 9 y letras → A (colación binaria para no confundir acentos) */
ALTER TABLE #v ADD Forma nvarchar(100) COLLATE Latin1_General_BIN NULL, SinSep nvarchar(100) COLLATE DATABASE_DEFAULT NULL;
UPDATE #v SET Forma = TRANSLATE(Valor COLLATE Latin1_General_BIN, N'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ', N'9999999999AAAAAAAAAAAAAAAAAAAAAAAAAA'),
              SinSep = REPLACE(REPLACE(REPLACE(REPLACE(Valor, N' ', N''), N'-', N''), N'.', N''), N'_', N'');

PRINT '== 1. Formas más frecuentes por fuente (A = letra, 9 = dígito)';
SELECT TOP 60 Fuente, Forma, COUNT_BIG(*) AS Valores FROM #v GROUP BY Fuente, Forma ORDER BY Fuente, COUNT_BIG(*) DESC;

PRINT '== 2. Separadores presentes por fuente';
SELECT Fuente, COUNT_BIG(*) AS Valores,
       SUM(CASE WHEN Valor LIKE N'%-%' THEN 1 ELSE 0 END) AS ConGuion,
       SUM(CASE WHEN Valor LIKE N'% %' THEN 1 ELSE 0 END) AS ConEspacio,
       SUM(CASE WHEN Valor LIKE N'%.%' THEN 1 ELSE 0 END) AS ConPunto,
       SUM(CASE WHEN Valor LIKE N'%[_]%' THEN 1 ELSE 0 END) AS ConGuionBajo,
       MAX(LEN(Valor)) AS LargoMaximo
FROM #v GROUP BY Fuente ORDER BY Fuente;

PRINT '== 3. Patrón aprobado (3 letras + 2 a 9 dígitos), con y sin quitar separadores';
SELECT Fuente, COUNT_BIG(*) AS Valores,
       SUM(CASE WHEN Forma LIKE N'AAA9%' AND SUBSTRING(Forma, 4, 100) NOT LIKE N'%[^9]%' AND LEN(Valor) BETWEEN 5 AND 12 THEN 1 ELSE 0 END) AS CumpleSinSeparador,
       SUM(CASE WHEN Forma LIKE N'AAA-9%' AND SUBSTRING(Forma, 5, 100) NOT LIKE N'%[^9]%' AND LEN(Valor) BETWEEN 6 AND 13 THEN 1 ELSE 0 END) AS CumpleConGuion,
       SUM(CASE WHEN SinSep COLLATE Latin1_General_BIN LIKE N'[A-Z][A-Z][A-Z][0-9][0-9]%' AND SUBSTRING(SinSep, 4, 100) NOT LIKE N'%[^0-9]%'
                 AND LEN(SinSep) BETWEEN 5 AND 12 THEN 1 ELSE 0 END) AS CumpleQuitandoSeparadores
FROM #v GROUP BY Fuente ORDER BY Fuente;

PRINT '== 4. Emparejamiento con las cuentas del CRM (valores distintos): exacto vs quitando separadores';
;WITH crm AS (SELECT DISTINCT Valor, SinSep FROM #v WHERE Fuente LIKE 'CRM%'),
      otr AS (SELECT Fuente, Valor, SinSep, COUNT_BIG(*) AS n FROM #v WHERE Fuente NOT LIKE 'CRM%' GROUP BY Fuente, Valor, SinSep)
SELECT o.Fuente, SUM(o.n) AS Filas,
       SUM(CASE WHEN EXISTS (SELECT 1 FROM crm c WHERE c.Valor = o.Valor) THEN o.n ELSE 0 END) AS EmparejaExacto,
       SUM(CASE WHEN EXISTS (SELECT 1 FROM crm c WHERE c.SinSep = o.SinSep) THEN o.n ELSE 0 END) AS EmparejaSinSeparadores
FROM otr o GROUP BY o.Fuente ORDER BY o.Fuente;

PRINT '== 5. Circuitos del CRM que solo difieren por separadores (choques al quitarlos)';
SELECT COUNT(*) AS CircuitosSinSeparadorConVariasFormas, SUM(Formas) AS FormasInvolucradas
FROM (SELECT SinSep, COUNT(DISTINCT Valor) AS Formas FROM #v WHERE Fuente LIKE 'CRM%' GROUP BY SinSep HAVING COUNT(DISTINCT Valor) > 1) x;
DROP TABLE #v;
