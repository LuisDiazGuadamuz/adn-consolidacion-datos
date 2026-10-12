/* Diagnóstico de los pasos comerciales y de operación (Sprint 3) - SOLO LECTURA.
   Solo conteos y valores de catálogos internos (impuestos); no muestra datos de clientes. */
SET NOCOUNT ON; SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_WARNINGS ON;
USE ADN_Unificado;

/* Llaves normalizadas UNA vez, en tablas temporales con índice (comparar ctl.fn_Texto(columna) fila por fila
   impide usar índices y hace la consulta cuadrática) */
DROP TABLE IF EXISTS #so, #soe, #ld, #lin, #ot, #tk;
SELECT CAST(ctl.fn_Texto(id) AS nvarchar(200)) AS Id, MAX(CAST(ISNULL(deleted, 0) AS int)) AS Eliminada INTO #so
FROM Zoho_Mirror.dbo.Sales_Orders GROUP BY CAST(ctl.fn_Texto(id) AS nvarchar(200));
SELECT DISTINCT CAST(ctl.fn_Texto(id) AS nvarchar(200)) AS Id INTO #soe FROM Zoho_Mirror.dbo.Sales_Orders_Extended;
SELECT DISTINCT CAST(ctl.fn_Texto(id) AS nvarchar(200)) AS Id INTO #ld FROM Zoho_Mirror.dbo.Leads;
CREATE INDEX i ON #so (Id); CREATE INDEX i ON #soe (Id); CREATE INDEX i ON #ld (Id);
SELECT CAST(ctl.fn_Texto(sales_order) AS nvarchar(200)) AS Orden, CAST(ISNULL(deleted, 0) AS int) AS Eliminada INTO #lin FROM Zoho_Mirror.dbo.Sales_Orders_Products;
SELECT ctl.fn_Circuito(N_mero_de_circuito_contrato) AS Circ, CAST(ctl.fn_Texto(N_mero_de_circuito_contrato) AS nvarchar(250)) AS CircTexto,
       CAST(ctl.fn_Texto(Asignado_a) AS nvarchar(200)) AS Asignado INTO #ot
FROM Zoho_Mirror.dbo.Ordenes_de_Trabajo WHERE ISNULL(deleted, 0) = 0;
SELECT CAST(ctl.fn_Texto(What_Id) AS nvarchar(200)) AS Que, CAST(ctl.fn_Texto(Who_Id) AS nvarchar(200)) AS Quien INTO #tk FROM Zoho_Mirror.dbo.Tasks WHERE ISNULL(deleted, 0) = 0;

PRINT '== 3. Líneas de órdenes de venta: ¿a qué orden apuntan?';
SELECT CASE WHEN l.Orden IS NULL THEN 'sin orden'
            WHEN o.OrdenVentaCrmId IS NOT NULL THEN 'orden cargada en el modelo'
            WHEN so.Eliminada = 1 THEN 'orden eliminada en Zoho'
            WHEN so.Id IS NOT NULL OR soe.Id IS NOT NULL THEN 'orden en el espejo pero no cargada'
            ELSE 'orden que no existe en el espejo' END AS Situacion,
       SUM(l.Eliminada) AS LineasEliminadas, COUNT(*) AS Lineas
FROM #lin l
LEFT JOIN (SELECT DISTINCT OrdenVentaCrmId FROM core.OrdenVenta) o ON o.OrdenVentaCrmId = l.Orden
LEFT JOIN #so so ON so.Id = l.Orden
LEFT JOIN #soe soe ON soe.Id = l.Orden
GROUP BY CASE WHEN l.Orden IS NULL THEN 'sin orden'
              WHEN o.OrdenVentaCrmId IS NOT NULL THEN 'orden cargada en el modelo'
              WHEN so.Eliminada = 1 THEN 'orden eliminada en Zoho'
              WHEN so.Id IS NOT NULL OR soe.Id IS NOT NULL THEN 'orden en el espejo pero no cargada'
              ELSE 'orden que no existe en el espejo' END
ORDER BY Lineas DESC;

PRINT '== 4. Órdenes de trabajo: circuito (cuántos servicios coinciden) y forma del asignado';
SELECT CASE WHEN t.CircTexto IS NULL THEN 'circuito vacío' WHEN t.Circ IS NULL THEN 'circuito fuera del patrón'
            WHEN c.n IS NULL THEN 'circuito válido sin servicio' WHEN c.n = 1 THEN 'circuito con un servicio'
            ELSE 'circuito en varios servicios' END AS Circuito, COUNT(*) AS Ordenes
FROM #ot t LEFT JOIN (SELECT Circuito, COUNT(*) AS n FROM core.Servicio WHERE Circuito IS NOT NULL GROUP BY Circuito) c ON c.Circuito = t.Circ
GROUP BY CASE WHEN t.CircTexto IS NULL THEN 'circuito vacío' WHEN t.Circ IS NULL THEN 'circuito fuera del patrón'
              WHEN c.n IS NULL THEN 'circuito válido sin servicio' WHEN c.n = 1 THEN 'circuito con un servicio'
              ELSE 'circuito en varios servicios' END
ORDER BY Ordenes DESC;
SELECT CASE WHEN t.Asignado IS NULL THEN 'vacío' WHEN t.Asignado NOT LIKE '%[^0-9]%' THEN 'id numérico' ELSE 'texto' END AS FormaAsignado,
       SUM(CASE WHEN ui.UsuarioId IS NOT NULL OR un.UsuarioId IS NOT NULL THEN 1 ELSE 0 END) AS ConUsuario, COUNT(*) AS Ordenes
FROM #ot t
LEFT JOIN (SELECT ZohoUsuarioId, MIN(UsuarioId) AS UsuarioId FROM ref.Usuario GROUP BY ZohoUsuarioId) ui ON ui.ZohoUsuarioId = t.Asignado
LEFT JOIN (SELECT NombreCompleto, MIN(UsuarioId) AS UsuarioId FROM ref.Usuario GROUP BY NombreCompleto) un ON un.NombreCompleto = t.Asignado
GROUP BY CASE WHEN t.Asignado IS NULL THEN 'vacío' WHEN t.Asignado NOT LIKE '%[^0-9]%' THEN 'id numérico' ELSE 'texto' END;

PRINT '== 5. Tareas: a qué apunta el registro relacionado (What_Id) y la persona (Who_Id)';
SELECT CASE WHEN t.Que IS NULL THEN 'vacío' WHEN s.CuentaCrmId IS NOT NULL THEN 'cuenta (servicio)'
            WHEN o.OportunidadCrmId IS NOT NULL THEN 'oportunidad' WHEN k.CasoCrmId IS NOT NULL THEN 'caso'
            WHEN v.OrdenVentaCrmId IS NOT NULL THEN 'orden de venta' WHEN q.CotizacionCrmId IS NOT NULL THEN 'cotización'
            ELSE 'otro módulo o no cargado' END AS Relacionado,
       CASE WHEN t.Quien IS NULL THEN 'vacío' WHEN c.ContactoCrmId IS NOT NULL THEN 'contacto'
            WHEN ld.Id IS NOT NULL THEN 'prospecto (lead)' ELSE 'otro' END AS Persona,
       COUNT(*) AS Tareas
FROM #tk t
LEFT JOIN (SELECT DISTINCT CuentaCrmId FROM core.Servicio) s ON s.CuentaCrmId = t.Que
LEFT JOIN (SELECT DISTINCT OportunidadCrmId FROM core.Oportunidad) o ON o.OportunidadCrmId = t.Que
LEFT JOIN (SELECT DISTINCT CasoCrmId FROM core.Caso) k ON k.CasoCrmId = t.Que
LEFT JOIN (SELECT DISTINCT OrdenVentaCrmId FROM core.OrdenVenta) v ON v.OrdenVentaCrmId = t.Que
LEFT JOIN (SELECT DISTINCT CotizacionCrmId FROM core.Cotizacion) q ON q.CotizacionCrmId = t.Que
LEFT JOIN (SELECT DISTINCT ContactoCrmId FROM core.Contacto) c ON c.ContactoCrmId = t.Quien
LEFT JOIN #ld ld ON ld.Id = t.Quien
GROUP BY CASE WHEN t.Que IS NULL THEN 'vacío' WHEN s.CuentaCrmId IS NOT NULL THEN 'cuenta (servicio)'
              WHEN o.OportunidadCrmId IS NOT NULL THEN 'oportunidad' WHEN k.CasoCrmId IS NOT NULL THEN 'caso'
              WHEN v.OrdenVentaCrmId IS NOT NULL THEN 'orden de venta' WHEN q.CotizacionCrmId IS NOT NULL THEN 'cotización'
              ELSE 'otro módulo o no cargado' END,
         CASE WHEN t.Quien IS NULL THEN 'vacío' WHEN c.ContactoCrmId IS NOT NULL THEN 'contacto'
              WHEN ld.Id IS NOT NULL THEN 'prospecto (lead)' ELSE 'otro' END
ORDER BY Tareas DESC;

PRINT '== 6. Impuesto de los productos del CRM frente al catálogo de impuestos (catálogo interno)';
SELECT TOP 10 ctl.fn_Texto(p.Tax) AS ImpuestoEnProducto, COUNT(*) AS Productos FROM Zoho_Mirror.dbo.Products p GROUP BY ctl.fn_Texto(p.Tax) ORDER BY Productos DESC;
SELECT ImpuestoBooksId, Nombre, Porcentaje FROM ref.Impuesto ORDER BY Nombre;
