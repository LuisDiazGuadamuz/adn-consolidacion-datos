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

/* Normalización propuesta para la opción B: mayúsculas, sin espacios, CONSERVANDO los guiones.
   Patrón propuesto: 3 letras - bloque de 2 a 6 dígitos [- bloque de 1 a 3 dígitos], 2 a 9 dígitos en total (1A). */
ALTER TABLE #v ADD NormB nvarchar(100) COLLATE DATABASE_DEFAULT NULL, CumpleB bit NULL, CumpleA bit NULL;
UPDATE #v SET NormB = REPLACE(Valor, N' ', N'');
UPDATE #v SET CumpleB = CASE WHEN TRANSLATE(NormB COLLATE Latin1_General_BIN, N'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ', N'9999999999AAAAAAAAAAAAAAAAAAAAAAAAAA')
                                  IN (N'AAA-99', N'AAA-999', N'AAA-9999', N'AAA-99999', N'AAA-999999',
                                      N'AAA-99-9', N'AAA-99-99', N'AAA-99-999', N'AAA-999-9', N'AAA-999-99', N'AAA-999-999',
                                      N'AAA-9999-9', N'AAA-9999-99', N'AAA-9999-999', N'AAA-99999-9', N'AAA-99999-99', N'AAA-99999-999',
                                      N'AAA-999999-9', N'AAA-999999-99', N'AAA-999999-999') THEN 1 ELSE 0 END,
              CumpleA = CASE WHEN SinSep COLLATE Latin1_General_BIN LIKE N'[A-Z][A-Z][A-Z][0-9][0-9]%' AND SUBSTRING(SinSep, 4, 100) NOT LIKE N'%[^0-9]%'
                                  AND LEN(SinSep) BETWEEN 5 AND 12 THEN 1 ELSE 0 END;

PRINT '== 3. Valores que cumplen: opción B (con guiones) vs quitando separadores (A)';
SELECT Fuente, COUNT_BIG(*) AS Valores, SUM(CAST(CumpleB AS int)) AS CumpleOpcionB, SUM(CAST(CumpleA AS int)) AS CumpleQuitandoSeparadores,
       MAX(CASE WHEN CumpleB = 1 THEN LEN(NormB) END) AS LargoMaximoValido
FROM #v GROUP BY Fuente ORDER BY Fuente;

PRINT '== 4. Formas que cumplirían quitando separadores pero NO la opción B (top 15)';
SELECT TOP 15 Forma, COUNT_BIG(*) AS Valores FROM #v WHERE CumpleA = 1 AND CumpleB = 0 GROUP BY Forma ORDER BY COUNT_BIG(*) DESC;

PRINT '== 5. Emparejamiento con las cuentas del CRM: opción B (exacto con guiones) vs quitando separadores';
DROP TABLE IF EXISTS #crmB; DROP TABLE IF EXISTS #crmA;
SELECT DISTINCT NormB AS k INTO #crmB FROM #v WHERE Fuente LIKE 'CRM%' AND CumpleB = 1;
SELECT DISTINCT SinSep AS k INTO #crmA FROM #v WHERE Fuente LIKE 'CRM%' AND CumpleA = 1;
CREATE UNIQUE CLUSTERED INDEX i ON #crmB (k); CREATE UNIQUE CLUSTERED INDEX i ON #crmA (k);
SELECT v.Fuente, COUNT_BIG(*) AS Filas,
       SUM(CASE WHEN b.k IS NOT NULL AND v.CumpleB = 1 THEN 1 ELSE 0 END) AS EmparejaOpcionB,
       SUM(CASE WHEN a.k IS NOT NULL AND v.CumpleA = 1 THEN 1 ELSE 0 END) AS EmparejaQuitandoSeparadores
FROM #v v LEFT JOIN #crmB b ON b.k = v.NormB LEFT JOIN #crmA a ON a.k = v.SinSep
WHERE v.Fuente NOT LIKE 'CRM%'
GROUP BY v.Fuente ORDER BY v.Fuente;

PRINT '== 6. Circuitos distintos del CRM que quedarían iguales al quitar los separadores (choques que la opción B evita)';
SELECT COUNT(*) AS CircuitosSinSeparadorConVariasFormas, SUM(Formas) AS FormasInvolucradas
FROM (SELECT SinSep, COUNT(DISTINCT NormB) AS Formas FROM #v WHERE Fuente LIKE 'CRM%' AND CumpleA = 1 GROUP BY SinSep HAVING COUNT(DISTINCT NormB) > 1) x;
DROP TABLE #v;
