/* Verificación después de recargar con ID-01 v1.1, cédulas en conflicto (2C) y nodos FTTH - SOLO LECTURA. Solo conteos. */
SET NOCOUNT ON; SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_WARNINGS ON;
USE ADN_Unificado;

PRINT '== 1. Circuitos de los servicios: con guiones, sin circuito, forma vieja';
SELECT COUNT(*) AS Servicios,
       SUM(CASE WHEN Circuito LIKE '[A-Z][A-Z][A-Z]-[0-9]%' THEN 1 ELSE 0 END) AS ConGuion,
       SUM(CASE WHEN Circuito IS NULL THEN 1 ELSE 0 END) AS SinCircuito,
       SUM(CASE WHEN Circuito IS NOT NULL AND Circuito NOT LIKE '[A-Z][A-Z][A-Z]-[0-9]%' THEN 1 ELSE 0 END) AS FormaVieja
FROM core.Servicio;

PRINT '== 2. Anomalías vigentes de identidad por paso y regla';
SELECT Paso, ReglaId, COUNT(*) AS Anomalias FROM ctl.vw_AnomaliaVigente
WHERE ReglaId IN ('ID-01', 'ID-02', 'ID-07') GROUP BY Paso, ReglaId ORDER BY Paso, ReglaId;

PRINT '== 3. Clientes por llave y clientes sin ningún registro de origen vigente (quedaron de la regla anterior)';
SELECT c.FuenteSistema, c.FuenteTabla, COUNT(*) AS Clientes,
       SUM(CASE WHEN o.ClienteId IS NULL THEN 1 ELSE 0 END) AS SinOrigen
FROM core.Cliente c
LEFT JOIN (SELECT DISTINCT ClienteId FROM core.ClienteOrigen WHERE ClienteId IS NOT NULL) o ON o.ClienteId = c.ClienteId
GROUP BY c.FuenteSistema, c.FuenteTabla ORDER BY 1, 2;

PRINT '== 4. Clústeres FTTH con y sin nodo, por nombre de nodo escrito en el clúster';
SELECT COALESCE(n.Nombre, '(sin nodo)') AS Nodo, COUNT(*) AS Clusteres
FROM core.ClusterFTTH f LEFT JOIN core.Nodo n ON n.NodoId = f.NodoId
GROUP BY COALESCE(n.Nombre, '(sin nodo)') ORDER BY 2 DESC;

PRINT '== 5. Llamadas cargadas por mes con y sin servicio';
SELECT CONVERT(char(7), FechaInicio, 120) AS Mes, COUNT_BIG(*) AS Llamadas,
       SUM(CASE WHEN ServicioId IS NOT NULL THEN 1 ELSE 0 END) AS ConServicio
FROM core.Llamada GROUP BY CONVERT(char(7), FechaInicio, 120) ORDER BY 1;
