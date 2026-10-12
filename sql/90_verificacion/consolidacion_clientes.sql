/* Verificación de la consolidación de clientes y servicios (Sprint 3) - SOLO LECTURA.
   Solo conteos: no muestra cédulas, nombres ni circuitos de clientes.
   Ejecutar sobre ADN_Unificado del sandbox. */
SET NOCOUNT ON; SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_WARNINGS ON;
USE ADN_Unificado;

PRINT '== 1. Clientes por origen de la llave y estado de correspondencia';
SELECT FuenteSistema, FuenteTabla, EstadoCorrespondencia, COUNT(*) AS Clientes
FROM core.Cliente GROUP BY FuenteSistema, FuenteTabla, EstadoCorrespondencia ORDER BY FuenteSistema, FuenteTabla, EstadoCorrespondencia;

PRINT '== 2. Clientes por tipo de identificación';
SELECT ISNULL(TipoIdentificacion, '(sin)') AS TipoIdentificacion, COUNT(*) AS Clientes,
       SUM(CASE WHEN Cedula IS NULL THEN 1 ELSE 0 END) AS SinCedula
FROM core.Cliente GROUP BY TipoIdentificacion ORDER BY Clientes DESC;

PRINT '== 3. Registros de origen por sistema y método de emparejamiento (ID-04, ID-05)';
SELECT Sistema, TablaOrigen, MetodoEmparejamiento, COUNT(*) AS Registros,
       SUM(CASE WHEN ClienteId IS NULL THEN 1 ELSE 0 END) AS SinCliente,
       SUM(CASE WHEN ServicioId IS NULL THEN 1 ELSE 0 END) AS SinServicio
FROM core.ClienteOrigen GROUP BY Sistema, TablaOrigen, MetodoEmparejamiento ORDER BY Sistema, TablaOrigen, MetodoEmparejamiento;

PRINT '== 4. Clientes según cuántos sistemas los aportan';
SELECT Sistemas, COUNT(*) AS Clientes FROM (
    SELECT ClienteId, COUNT(DISTINCT Sistema) AS Sistemas FROM core.ClienteOrigen WHERE ClienteId IS NOT NULL GROUP BY ClienteId) x
GROUP BY Sistemas ORDER BY Sistemas;

PRINT '== 5. Combinaciones de sistemas por cliente';
SELECT Combinacion, COUNT(*) AS Clientes FROM (
    SELECT o.ClienteId, STRING_AGG(o.Sistema, ' + ') WITHIN GROUP (ORDER BY o.Sistema) AS Combinacion
    FROM (SELECT DISTINCT ClienteId, Sistema FROM core.ClienteOrigen WHERE ClienteId IS NOT NULL) o GROUP BY o.ClienteId) x
GROUP BY Combinacion ORDER BY Clientes DESC;

PRINT '== 6. Servicios por cliente (ID-03)';
SELECT CASE WHEN n >= 5 THEN '5 o más' ELSE CAST(n AS varchar(5)) END AS ServiciosPorCliente, COUNT(*) AS Clientes
FROM (SELECT ClienteId, COUNT(*) AS n FROM core.Servicio WHERE ClienteId IS NOT NULL GROUP BY ClienteId) x
GROUP BY CASE WHEN n >= 5 THEN '5 o más' ELSE CAST(n AS varchar(5)) END ORDER BY 1;
SELECT COUNT(*) AS Servicios, SUM(CASE WHEN ClienteId IS NULL THEN 1 ELSE 0 END) AS ServiciosSinCliente FROM core.Servicio;
SELECT COUNT(*) AS ClientesSinServicio FROM core.Cliente c WHERE NOT EXISTS (SELECT 1 FROM core.Servicio s WHERE s.ClienteId = c.ClienteId);

PRINT '== 7. Contactos con y sin servicio/cliente';
SELECT COUNT(*) AS Contactos, SUM(CASE WHEN ServicioId IS NULL THEN 1 ELSE 0 END) AS SinServicio,
       SUM(CASE WHEN ClienteId IS NULL THEN 1 ELSE 0 END) AS SinCliente FROM core.Contacto;

PRINT '== 8. Linaje por campo del cliente (D9): sistema que aportó cada valor';
SELECT l.Columna, l.FuenteSistema, COUNT(*) AS Valores
FROM ctl.LinajeCampo l JOIN ctl.Lote lo ON lo.LoteId = l.LoteId AND lo.Estado = 'Exitoso'
WHERE l.TablaModelo = N'core.Cliente' GROUP BY l.Columna, l.FuenteSistema ORDER BY l.Columna, Valores DESC;

PRINT '== 9. Anomalías vigentes por tabla, regla y detalle (último lote confirmado de cada paso)';
SELECT a.TablaModelo, a.ReglaId, a.Columna, LEFT(a.Detalle, 90) AS Detalle, COUNT(*) AS Anomalias
FROM ctl.vw_AnomaliaVigente a
GROUP BY a.TablaModelo, a.ReglaId, a.Columna, LEFT(a.Detalle, 90) ORDER BY a.TablaModelo, Anomalias DESC;

PRINT '== 10. Nodo de los clústeres FTTH: forma del valor y con qué coincide (datos de infraestructura, no de clientes)';
SELECT Forma, SUM(PorId) AS PorId, SUM(PorNombre) AS PorNombre, SUM(PorNomenclatura) AS PorNomenclatura, COUNT(*) AS Clusteres
FROM (
    SELECT CASE WHEN v.Nodo IS NULL THEN 'vacío'
                WHEN v.Nodo NOT LIKE '%[^0-9]%' THEN 'solo dígitos (' + CAST(LEN(v.Nodo) AS varchar(3)) + ')'
                ELSE 'texto' END AS Forma,
           CASE WHEN EXISTS (SELECT 1 FROM core.Nodo n WHERE n.NodoCrmId = v.Nodo) THEN 1 ELSE 0 END AS PorId,
           CASE WHEN EXISTS (SELECT 1 FROM core.Nodo n WHERE n.Nombre = v.Nodo) THEN 1 ELSE 0 END AS PorNombre,
           CASE WHEN EXISTS (SELECT 1 FROM core.Nodo n WHERE n.Nomenclatura = v.Nodo) THEN 1 ELSE 0 END AS PorNomenclatura
    FROM Zoho_Mirror.dbo.FTTHs f CROSS APPLY (SELECT ctl.fn_Texto(f.Nodo) AS Nodo) v
    WHERE ISNULL(f.deleted, 0) = 0) x
GROUP BY Forma;
SELECT TOP 10 ctl.fn_Texto(f.Nodo) AS NodoEnCluster, COUNT(*) AS Clusteres
FROM Zoho_Mirror.dbo.FTTHs f
WHERE ISNULL(f.deleted, 0) = 0 AND ctl.fn_Texto(f.Nodo) IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM core.Nodo n WHERE n.NodoCrmId = ctl.fn_Texto(f.Nodo) OR n.Nombre = ctl.fn_Texto(f.Nodo))
GROUP BY ctl.fn_Texto(f.Nodo) ORDER BY Clusteres DESC;
SELECT TOP 10 Nombre, Nomenclatura FROM core.Nodo ORDER BY Nombre;
