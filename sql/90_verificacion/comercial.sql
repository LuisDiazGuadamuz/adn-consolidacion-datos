/* Diagnóstico de los pasos comerciales y de operación (Sprint 3) - SOLO LECTURA.
   Solo conteos y valores de catálogos internos (impuestos); no muestra datos de clientes. */
SET NOCOUNT ON; SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_WARNINGS ON;
USE ADN_Unificado;

PRINT '== 1. Anomalías vigentes de los pasos 300-339 por columna';
SELECT a.Paso, a.ReglaId, a.Columna, COUNT(*) AS Anomalias
FROM ctl.vw_AnomaliaVigente a
WHERE a.Paso LIKE 'core[_]Producto%' OR a.Paso IN ('core_Direccion', 'core_Prospecto_CRM', 'core_Prospecto_ADNPay', 'core_Oportunidad',
      'core_Cotizacion', 'core_OrdenVenta', 'core_OrdenVenta_Complemento', 'core_OrdenVentaLinea', 'core_OrdenTrabajo',
      'core_OrdenServicioVoIP', 'core_Caso', 'core_Caso_Complemento', 'core_Nota_Servicio', 'core_Nota_Caso', 'core_Nota_Cliente',
      'core_Tarea', 'core_Adjunto', 'core_Proveedor')
GROUP BY a.Paso, a.ReglaId, a.Columna ORDER BY a.Paso, Anomalias DESC;

PRINT '== 2. Filas en las fuentes que dieron 0';
SELECT 'ADNPayV2.OnvoProduct' AS Fuente, COUNT(*) AS Filas FROM ADNPayV2.dbo.OnvoProduct
UNION ALL SELECT 'ADNPayV2.OnvoPrice', COUNT(*) FROM ADNPayV2.dbo.OnvoPrice
UNION ALL SELECT 'Zoho_Mirror.Zoho_Attachments', COUNT(*) FROM Zoho_Mirror.dbo.Zoho_Attachments;

PRINT '== 3. Líneas de órdenes de venta descartadas: ¿a qué orden apuntan?';
;WITH l AS (SELECT ctl.fn_Texto(sales_order) AS Orden, CAST(ISNULL(deleted, 0) AS int) AS Eliminada FROM Zoho_Mirror.dbo.Sales_Orders_Products),
      c AS (
    SELECT l.Eliminada,
           CASE WHEN l.Orden IS NULL THEN 'sin orden'
                WHEN EXISTS (SELECT 1 FROM core.OrdenVenta o WHERE o.OrdenVentaCrmId = l.Orden) THEN 'orden cargada en el modelo'
                WHEN EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.Sales_Orders s WHERE ctl.fn_Texto(s.id) = l.Orden AND s.deleted = 1) THEN 'orden eliminada en Zoho'
                WHEN EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.Sales_Orders s WHERE ctl.fn_Texto(s.id) = l.Orden)
                  OR EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.Sales_Orders_Extended e WHERE ctl.fn_Texto(e.id) = l.Orden) THEN 'orden en el espejo pero no cargada'
                ELSE 'orden que no existe en el espejo' END AS Situacion
    FROM l)
SELECT Situacion, SUM(Eliminada) AS LineasEliminadas, COUNT(*) AS Lineas FROM c GROUP BY Situacion ORDER BY Lineas DESC;

PRINT '== 4. Órdenes de trabajo: forma del circuito y del asignado';
SELECT CASE WHEN ctl.fn_Texto(t.N_mero_de_circuito_contrato) IS NULL THEN 'circuito vacío'
            WHEN ctl.fn_Circuito(t.N_mero_de_circuito_contrato) IS NULL THEN 'circuito fuera del patrón'
            ELSE 'circuito válido' END AS Circuito,
       COUNT(*) AS Ordenes
FROM Zoho_Mirror.dbo.Ordenes_de_Trabajo t WHERE ISNULL(t.deleted, 0) = 0
GROUP BY CASE WHEN ctl.fn_Texto(t.N_mero_de_circuito_contrato) IS NULL THEN 'circuito vacío'
              WHEN ctl.fn_Circuito(t.N_mero_de_circuito_contrato) IS NULL THEN 'circuito fuera del patrón' ELSE 'circuito válido' END;
SELECT x.Coincidencias, COUNT(*) AS Ordenes FROM (
    SELECT (SELECT COUNT(*) FROM core.Servicio s WHERE s.Circuito = ctl.fn_Circuito(t.N_mero_de_circuito_contrato)) AS Coincidencias
    FROM Zoho_Mirror.dbo.Ordenes_de_Trabajo t
    WHERE ISNULL(t.deleted, 0) = 0 AND ctl.fn_Circuito(t.N_mero_de_circuito_contrato) IS NOT NULL) x
GROUP BY x.Coincidencias ORDER BY x.Coincidencias;
SELECT CASE WHEN ctl.fn_Texto(t.Asignado_a) IS NULL THEN 'vacío'
            WHEN ctl.fn_Texto(t.Asignado_a) NOT LIKE '%[^0-9]%' THEN 'id numérico'
            ELSE 'texto' END AS FormaAsignado,
       SUM(CASE WHEN u.UsuarioId IS NOT NULL THEN 1 ELSE 0 END) AS ConUsuario, COUNT(*) AS Ordenes
FROM Zoho_Mirror.dbo.Ordenes_de_Trabajo t
OUTER APPLY (SELECT TOP 1 r.UsuarioId FROM ref.Usuario r WHERE r.ZohoUsuarioId = ctl.fn_Texto(t.Asignado_a) OR r.NombreCompleto = ctl.fn_Texto(t.Asignado_a)) u
WHERE ISNULL(t.deleted, 0) = 0
GROUP BY CASE WHEN ctl.fn_Texto(t.Asignado_a) IS NULL THEN 'vacío'
              WHEN ctl.fn_Texto(t.Asignado_a) NOT LIKE '%[^0-9]%' THEN 'id numérico' ELSE 'texto' END;

PRINT '== 5. Tareas: a qué módulo del CRM apunta el registro relacionado (What_Id) y la persona (Who_Id)';
;WITH t AS (SELECT ctl.fn_Texto(What_Id) AS Que, ctl.fn_Texto(Who_Id) AS Quien FROM Zoho_Mirror.dbo.Tasks WHERE ISNULL(deleted, 0) = 0),
      c AS (
    SELECT CASE WHEN t.Que IS NULL THEN 'vacío'
                WHEN EXISTS (SELECT 1 FROM core.Servicio s WHERE s.CuentaCrmId = t.Que) THEN 'cuenta (servicio)'
                WHEN EXISTS (SELECT 1 FROM core.Oportunidad o WHERE o.OportunidadCrmId = t.Que) THEN 'oportunidad'
                WHEN EXISTS (SELECT 1 FROM core.Caso k WHERE k.CasoCrmId = t.Que) THEN 'caso'
                WHEN EXISTS (SELECT 1 FROM core.OrdenVenta v WHERE v.OrdenVentaCrmId = t.Que) THEN 'orden de venta'
                WHEN EXISTS (SELECT 1 FROM core.Cotizacion q WHERE q.CotizacionCrmId = t.Que) THEN 'cotización'
                ELSE 'otro módulo o no cargado' END AS Relacionado,
           CASE WHEN t.Quien IS NULL THEN 'vacío'
                WHEN EXISTS (SELECT 1 FROM core.Contacto k WHERE k.ContactoCrmId = t.Quien) THEN 'contacto'
                WHEN EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.Leads l WHERE ctl.fn_Texto(l.id) = t.Quien) THEN 'prospecto (lead)'
                ELSE 'otro' END AS Persona
    FROM t)
SELECT Relacionado, Persona, COUNT(*) AS Tareas FROM c GROUP BY Relacionado, Persona ORDER BY Tareas DESC;

PRINT '== 6. Impuesto de los productos del CRM frente al catálogo de impuestos (catálogo interno)';
SELECT TOP 10 ctl.fn_Texto(p.Tax) AS ImpuestoEnProducto, COUNT(*) AS Productos FROM Zoho_Mirror.dbo.Products p GROUP BY ctl.fn_Texto(p.Tax) ORDER BY Productos DESC;
SELECT ImpuestoBooksId, Nombre, Porcentaje FROM ref.Impuesto ORDER BY Nombre;
