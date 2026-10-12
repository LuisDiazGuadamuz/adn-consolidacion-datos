/* Corrección del modelo ADN_Unificado (versión 1.1)
   Quita la restricción UNIQUE duplicada sobre core.Cliente.Cedula.
   La unicidad de la cédula la sigue garantizando el índice filtrado UX_Cliente_Cedula,
   que admite varios clientes sin cédula (decisión D8). Ejecutar una vez en el sandbox. */
SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON;
USE ADN_Unificado;
IF OBJECT_ID(N'core.UQ_Cliente_Cedula', N'UQ') IS NOT NULL
    ALTER TABLE core.Cliente DROP CONSTRAINT UQ_Cliente_Cedula;
SELECT name AS Indice, is_unique AS Unico, has_filter AS Filtrado, filter_definition AS Filtro
FROM sys.indexes WHERE object_id = OBJECT_ID(N'core.Cliente') AND name LIKE N'U%Cedula';
