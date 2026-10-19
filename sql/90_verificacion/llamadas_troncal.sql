/* ¿Se puede ligar una llamada a su servicio por la troncal del cliente cuando no trae circuito? - SOLO LECTURA. Conteos.
   MongoDB no tiene el campo CustomerCircuitNumber; las troncales del cliente (core.Troncal.ServicioId) sí vienen.
   1) Valida la regla en las llamadas de SQL Server, que traen circuito: ¿coincide el servicio por troncal con el del circuito?
   2) Mide cuántas llamadas de MongoDB (octubre) quedarían con servicio. */
SET NOCOUNT ON; SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_WARNINGS ON;
USE ADN_Unificado;

;WITH x AS (
    SELECT l.FuenteTabla, CONVERT(char(7), l.FechaInicio, 120) AS Mes, l.ServicioId AS PorCircuito,
           te.ServicioId AS PorEntrada, ts.ServicioId AS PorSalida
    FROM core.Llamada l
    LEFT JOIN core.Troncal te ON te.TroncalId = l.TroncalEntradaId
    LEFT JOIN core.Troncal ts ON ts.TroncalId = l.TroncalSalidaId),
y AS (
    SELECT FuenteTabla, Mes, PorCircuito,
           CASE WHEN PorEntrada IS NOT NULL AND PorSalida IS NOT NULL AND PorEntrada <> PorSalida THEN -1
                ELSE COALESCE(PorEntrada, PorSalida) END AS PorTroncal
    FROM x)
SELECT FuenteTabla, Mes, COUNT_BIG(*) AS Llamadas,
       SUM(CASE WHEN PorCircuito IS NOT NULL THEN 1 ELSE 0 END) AS ConServicioPorCircuito,
       SUM(CASE WHEN PorTroncal > 0 THEN 1 ELSE 0 END) AS ConServicioPorTroncal,
       SUM(CASE WHEN PorTroncal = -1 THEN 1 ELSE 0 END) AS TroncalesAmbiguas,
       SUM(CASE WHEN PorCircuito IS NOT NULL AND PorTroncal > 0 THEN 1 ELSE 0 END) AS AmbasFormas,
       SUM(CASE WHEN PorCircuito IS NOT NULL AND PorTroncal > 0 AND PorCircuito = PorTroncal THEN 1 ELSE 0 END) AS Coinciden,
       SUM(CASE WHEN PorCircuito IS NULL AND PorTroncal > 0 THEN 1 ELSE 0 END) AS SoloPorTroncal
FROM y GROUP BY FuenteTabla, Mes ORDER BY Mes;

PRINT '== Troncales de clientes con servicio';
SELECT COUNT(*) AS Troncales, SUM(CASE WHEN ServicioId IS NOT NULL THEN 1 ELSE 0 END) AS ConServicio FROM core.Troncal;
