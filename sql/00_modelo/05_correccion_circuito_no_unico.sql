/* Corrección del modelo ADN_Unificado (versión 1.3) - core.Servicio.Circuito deja de ser único.
   Evidencia (12/10/2026, sql/90_verificacion/circuitos.sql): 140 circuitos normalizados aparecen en más de una
   cuenta del CRM (282 cuentas), p. ej. por cambio de razón social. Cada cuenta sigue siendo un servicio
   (llave CuentaCrmId); el circuito queda indexado para el emparejamiento (ID-01) pero sin restricción de unicidad.
   Idempotente. Ejecutar en el sandbox. */
USE ADN_Unificado;
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_Servicio_Circuito' AND object_id = OBJECT_ID(N'core.Servicio'))
    DROP INDEX UX_Servicio_Circuito ON core.Servicio;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Servicio_Circuito' AND object_id = OBJECT_ID(N'core.Servicio'))
    CREATE INDEX IX_Servicio_Circuito ON core.Servicio (Circuito);
SELECT name AS Indice, is_unique AS Unico FROM sys.indexes WHERE object_id = OBJECT_ID(N'core.Servicio') AND name LIKE N'%Circuito%';
