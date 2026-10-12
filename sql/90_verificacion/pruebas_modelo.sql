/* =====================================================================
   Pruebas del modelo ADN_Unificado - Sprint 2
   Comprueba que la base hace cumplir las reglas aprobadas (catálogo v1.0).
   Todo corre dentro de una transacción que se revierte al final:
   NO deja datos en la base. Ejecutar completo (F5) en el sandbox.
   Resultado esperado: todas las filas con Resultado = OK.
   ===================================================================== */
USE ADN_Unificado;
SET NOCOUNT ON;
SET XACT_ABORT OFF;

DECLARE @r TABLE (N int, Regla varchar(20), Prueba nvarchar(200), Esperado nvarchar(40), Obtenido nvarchar(400), Resultado varchar(5));
DECLARE @fuente int, @lote int, @cli int, @srv int, @msg nvarchar(400);

BEGIN TRANSACTION;

/* Datos mínimos de control */
INSERT ctl.Fuente (Sistema, Motor, Base, Tabla, Disposicion) VALUES ('Prueba', 'SQLServer', N'Prueba', N'Prueba', 'Cargada');
SET @fuente = SCOPE_IDENTITY();
INSERT ctl.Lote (FuenteId, FechaInicio, Estado, VersionReglas, Usuario) VALUES (@fuente, SYSDATETIMEOFFSET(), 'EnCurso', '1.0', N'pruebas');
SET @lote = SCOPE_IDENTITY();

/* 1. Cédula válida (9 dígitos) se acepta */
BEGIN TRY
  INSERT core.Cliente (Cedula, TipoIdentificacion, EstadoCorrespondencia, FuenteSistema, FuenteBase, FuenteTabla, FuenteLlave, FechaDato, LoteId)
  VALUES ('101110111', 'FISICA', 'CRM', 'Prueba', N'Prueba', N'Prueba', N'C1', '2026-10-05T10:00:00-06:00', @lote);
  SET @cli = SCOPE_IDENTITY();
  INSERT @r VALUES (1, 'ID-02', N'Cédula física de 9 dígitos', N'Se acepta', N'Aceptada', 'OK');
END TRY BEGIN CATCH INSERT @r VALUES (1, 'ID-02', N'Cédula física de 9 dígitos', N'Se acepta', ERROR_MESSAGE(), 'FALLA'); END CATCH

/* 2. Cédula con longitud inválida se rechaza */
BEGIN TRY
  INSERT core.Cliente (Cedula, TipoIdentificacion, EstadoCorrespondencia, FuenteSistema, FuenteBase, FuenteTabla, FuenteLlave, LoteId)
  VALUES ('12345', 'INVALIDA', 'CRM', 'Prueba', N'Prueba', N'Prueba', N'C2', @lote);
  INSERT @r VALUES (2, 'ID-02', N'Cédula de 5 dígitos', N'Se rechaza', N'Aceptada', 'FALLA');
END TRY BEGIN CATCH INSERT @r VALUES (2, 'ID-02', N'Cédula de 5 dígitos', N'Se rechaza', N'Rechazada (' + CAST(ERROR_NUMBER() AS varchar) + N')', 'OK'); END CATCH

/* 3. Cédula con guiones se rechaza (debe llegar normalizada) */
BEGIN TRY
  INSERT core.Cliente (Cedula, TipoIdentificacion, EstadoCorrespondencia, FuenteSistema, FuenteBase, FuenteTabla, FuenteLlave, LoteId)
  VALUES ('1-111-0111', 'FISICA', 'CRM', 'Prueba', N'Prueba', N'Prueba', N'C3', @lote);
  INSERT @r VALUES (3, 'ID-02', N'Cédula con guiones sin normalizar', N'Se rechaza', N'Aceptada', 'FALLA');
END TRY BEGIN CATCH INSERT @r VALUES (3, 'ID-02', N'Cédula con guiones sin normalizar', N'Se rechaza', N'Rechazada (' + CAST(ERROR_NUMBER() AS varchar) + N')', 'OK'); END CATCH

/* 4. Cédula repetida se rechaza */
BEGIN TRY
  INSERT core.Cliente (Cedula, TipoIdentificacion, EstadoCorrespondencia, FuenteSistema, FuenteBase, FuenteTabla, FuenteLlave, LoteId)
  VALUES ('101110111', 'FISICA', 'SOLO_BOOKS', 'Prueba', N'Prueba', N'Prueba', N'C4', @lote);
  INSERT @r VALUES (4, 'ID-02', N'Segundo cliente con la misma cédula', N'Se rechaza', N'Aceptada', 'FALLA');
END TRY BEGIN CATCH INSERT @r VALUES (4, 'ID-02', N'Segundo cliente con la misma cédula', N'Se rechaza', N'Rechazada (' + CAST(ERROR_NUMBER() AS varchar) + N')', 'OK'); END CATCH

/* 5. Varios clientes sin cédula se aceptan (quedan marcados, D8) */
BEGIN TRY
  INSERT core.Cliente (Cedula, TipoIdentificacion, EstadoCorrespondencia, FuenteSistema, FuenteBase, FuenteTabla, FuenteLlave, LoteId)
  VALUES (NULL, 'SIN_DATO', 'SIN_CORRESPONDENCIA', 'Prueba', N'Prueba', N'Prueba', N'C5', @lote),
         (NULL, 'SIN_DATO', 'SIN_CORRESPONDENCIA', 'Prueba', N'Prueba', N'Prueba', N'C6', @lote);
  INSERT @r VALUES (5, 'D8', N'Dos clientes sin cédula', N'Se aceptan', N'Aceptados', 'OK');
END TRY BEGIN CATCH INSERT @r VALUES (5, 'D8', N'Dos clientes sin cédula', N'Se aceptan', ERROR_MESSAGE(), 'FALLA'); END CATCH

/* 6. Servicio con circuito válido y cliente existente se acepta */
BEGIN TRY
  INSERT core.Servicio (ClienteId, Circuito, CuentaCrmId, Moneda, Mensualidad, EstadoCorrespondencia, AtributosExtendidos,
                        FuenteSistema, FuenteBase, FuenteTabla, FuenteLlave, FechaDato, LoteId)
  VALUES (@cli, 'ADN12345', N'900000000000000001', 'USD', 45.5, 'CRM', N'{"Tag":"prueba"}',
          'Prueba', N'Prueba', N'Prueba', N'S1', '2026-10-05T10:00:00-06:00', @lote);
  SET @srv = SCOPE_IDENTITY();
  INSERT @r VALUES (6, 'ID-01', N'Servicio con circuito ADN12345', N'Se acepta', N'Aceptado', 'OK');
END TRY BEGIN CATCH INSERT @r VALUES (6, 'ID-01', N'Servicio con circuito ADN12345', N'Se acepta', ERROR_MESSAGE(), 'FALLA'); END CATCH

/* 7. Circuito con formato inválido se rechaza */
BEGIN TRY
  INSERT core.Servicio (Circuito, EstadoCorrespondencia, FuenteSistema, FuenteBase, FuenteTabla, FuenteLlave, LoteId)
  VALUES ('AB12345', 'CRM', 'Prueba', N'Prueba', N'Prueba', N'S2', @lote);
  INSERT @r VALUES (7, 'ID-01', N'Circuito con 2 letras (AB12345)', N'Se rechaza', N'Aceptado', 'FALLA');
END TRY BEGIN CATCH INSERT @r VALUES (7, 'ID-01', N'Circuito con 2 letras (AB12345)', N'Se rechaza', N'Rechazado (' + CAST(ERROR_NUMBER() AS varchar) + N')', 'OK'); END CATCH

/* 8. Circuito repetido se rechaza */
BEGIN TRY
  INSERT core.Servicio (Circuito, EstadoCorrespondencia, FuenteSistema, FuenteBase, FuenteTabla, FuenteLlave, LoteId)
  VALUES ('ADN12345', 'CRM', 'Prueba', N'Prueba', N'Prueba', N'S3', @lote);
  INSERT @r VALUES (8, 'ID-01', N'Segundo servicio con el mismo circuito', N'Se rechaza', N'Aceptado', 'FALLA');
END TRY BEGIN CATCH INSERT @r VALUES (8, 'ID-01', N'Segundo servicio con el mismo circuito', N'Se rechaza', N'Rechazado (' + CAST(ERROR_NUMBER() AS varchar) + N')', 'OK'); END CATCH

/* 9. Servicio apuntando a un cliente inexistente se rechaza */
BEGIN TRY
  INSERT core.Servicio (ClienteId, EstadoCorrespondencia, FuenteSistema, FuenteBase, FuenteTabla, FuenteLlave, LoteId)
  VALUES (-1, 'CRM', 'Prueba', N'Prueba', N'Prueba', N'S4', @lote);
  INSERT @r VALUES (9, 'IN-02', N'Servicio con ClienteId inexistente', N'Se rechaza', N'Aceptado', 'FALLA');
END TRY BEGIN CATCH INSERT @r VALUES (9, 'IN-02', N'Servicio con ClienteId inexistente', N'Se rechaza', N'Rechazado (' + CAST(ERROR_NUMBER() AS varchar) + N')', 'OK'); END CATCH

/* 10. Moneda no permitida se rechaza */
BEGIN TRY
  INSERT core.Servicio (Moneda, EstadoCorrespondencia, FuenteSistema, FuenteBase, FuenteTabla, FuenteLlave, LoteId)
  VALUES ('XXX', 'CRM', 'Prueba', N'Prueba', N'Prueba', N'S5', @lote);
  INSERT @r VALUES (10, 'ES-04', N'Moneda XXX', N'Se rechaza', N'Aceptada', 'FALLA');
END TRY BEGIN CATCH INSERT @r VALUES (10, 'ES-04', N'Moneda XXX', N'Se rechaza', N'Rechazada (' + CAST(ERROR_NUMBER() AS varchar) + N')', 'OK'); END CATCH

/* 11. Atributos extendidos con JSON inválido se rechazan */
BEGIN TRY
  INSERT core.Servicio (AtributosExtendidos, EstadoCorrespondencia, FuenteSistema, FuenteBase, FuenteTabla, FuenteLlave, LoteId)
  VALUES (N'{Tag: sin comillas', 'CRM', 'Prueba', N'Prueba', N'Prueba', N'S6', @lote);
  INSERT @r VALUES (11, 'ES-05', N'AtributosExtendidos con JSON inválido', N'Se rechaza', N'Aceptado', 'FALLA');
END TRY BEGIN CATCH INSERT @r VALUES (11, 'ES-05', N'AtributosExtendidos con JSON inválido', N'Se rechaza', N'Rechazado (' + CAST(ERROR_NUMBER() AS varchar) + N')', 'OK'); END CATCH

/* 12. Registro sin datos de trazabilidad se rechaza */
BEGIN TRY
  INSERT core.Servicio (EstadoCorrespondencia, LoteId) VALUES ('CRM', @lote);
  INSERT @r VALUES (12, 'IN-05', N'Servicio sin sistema, tabla ni llave de origen', N'Se rechaza', N'Aceptado', 'FALLA');
END TRY BEGIN CATCH INSERT @r VALUES (12, 'IN-05', N'Servicio sin sistema, tabla ni llave de origen', N'Se rechaza', N'Rechazado (' + CAST(ERROR_NUMBER() AS varchar) + N')', 'OK'); END CATCH

/* 13. Registro con lote inexistente se rechaza */
BEGIN TRY
  INSERT core.Servicio (EstadoCorrespondencia, FuenteSistema, FuenteBase, FuenteTabla, FuenteLlave, LoteId)
  VALUES ('CRM', 'Prueba', N'Prueba', N'Prueba', N'S7', -1);
  INSERT @r VALUES (13, 'IN-05', N'Servicio con LoteId inexistente', N'Se rechaza', N'Aceptado', 'FALLA');
END TRY BEGIN CATCH INSERT @r VALUES (13, 'IN-05', N'Servicio con LoteId inexistente', N'Se rechaza', N'Rechazado (' + CAST(ERROR_NUMBER() AS varchar) + N')', 'OK'); END CATCH

/* 14. Período del dato y fecha de carga con zona -06:00 */
SELECT @msg = N'PeriodoDato=' + ISNULL(PeriodoDato, 'NULL') + N'; zona FechaCarga=' + CAST(DATEPART(TZOFFSET, FechaCarga) AS varchar) + N' min'
FROM core.Servicio WHERE ServicioId = @srv;
INSERT @r VALUES (14, 'IN-05/ES-01', N'PeriodoDato calculado y FechaCarga en -06:00', N'2026-10 y -360 min', @msg,
  CASE WHEN @msg = N'PeriodoDato=2026-10; zona FechaCarga=-360 min' THEN 'OK' ELSE 'FALLA' END);

/* 15. Llamada repetida (misma huella de contenido) se rechaza */
BEGIN TRY
  INSERT core.Llamada (ServicioId, Circuito, FechaInicio, Moneda, Costo, HashContenido, FuenteSistema, FuenteBase, FuenteTabla, FuenteLlave, FechaDato, LoteId)
  VALUES (@srv, 'ADN12345', '2026-10-05T10:00:00-06:00', 'USD', 0.05, HASHBYTES('SHA2_256', N'llamada-prueba'), 'Prueba', N'Prueba', N'Prueba', N'L1', '2026-10-05T10:00:00-06:00', @lote);
  INSERT core.Llamada (ServicioId, Circuito, FechaInicio, Moneda, Costo, HashContenido, FuenteSistema, FuenteBase, FuenteTabla, FuenteLlave, FechaDato, LoteId)
  VALUES (@srv, 'ADN12345', '2026-10-05T10:00:00-06:00', 'USD', 0.05, HASHBYTES('SHA2_256', N'llamada-prueba'), 'Prueba', N'Prueba', N'Prueba', N'L2', '2026-10-05T10:00:00-06:00', @lote);
  INSERT @r VALUES (15, 'DD-01', N'Segunda llamada con la misma huella', N'Se rechaza', N'Aceptada', 'FALLA');
END TRY BEGIN CATCH INSERT @r VALUES (15, 'DD-01', N'Segunda llamada con la misma huella', N'Se rechaza', N'Rechazada (' + CAST(ERROR_NUMBER() AS varchar) + N')', 'OK'); END CATCH

/* 16. Archivo CDR procesado dos veces se rechaza */
BEGIN TRY
  INSERT core.ArchivoCDR (NombreArchivo, Dispositivo, FuenteSistema, FuenteBase, FuenteTabla, FuenteLlave, LoteId)
  VALUES (N'cdr_prueba.csv', N'SBC1', 'Prueba', N'Prueba', N'Prueba', N'A1', @lote);
  INSERT core.ArchivoCDR (NombreArchivo, Dispositivo, FuenteSistema, FuenteBase, FuenteTabla, FuenteLlave, LoteId)
  VALUES (N'cdr_prueba.csv', N'SBC1', 'Prueba', N'Prueba', N'Prueba', N'A2', @lote);
  INSERT @r VALUES (16, 'DD-05', N'Mismo archivo CDR del mismo dispositivo', N'Se rechaza', N'Aceptado', 'FALLA');
END TRY BEGIN CATCH INSERT @r VALUES (16, 'DD-05', N'Mismo archivo CDR del mismo dispositivo', N'Se rechaza', N'Rechazado (' + CAST(ERROR_NUMBER() AS varchar) + N')', 'OK'); END CATCH

/* 17. Descarte con una regla que no existe en el catálogo se rechaza */
BEGIN TRY
  INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
  VALUES (@lote, 'ZZ-99', 'Prueba', N'Prueba', N'X1', N'prueba', SYSDATETIMEOFFSET());
  INSERT @r VALUES (17, 'DD-06', N'Descarte con regla inexistente', N'Se rechaza', N'Aceptado', 'FALLA');
END TRY BEGIN CATCH INSERT @r VALUES (17, 'DD-06', N'Descarte con regla inexistente', N'Se rechaza', N'Rechazado (' + CAST(ERROR_NUMBER() AS varchar) + N')', 'OK'); END CATCH

/* 18. Descarte con regla del catálogo se acepta */
BEGIN TRY
  INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, LlaveConservada, Motivo, FechaDescarte)
  VALUES (@lote, 'DD-01', 'Prueba', N'Prueba', N'L2', N'L1', N'Llamada duplicada', SYSDATETIMEOFFSET());
  INSERT @r VALUES (18, 'DD-06', N'Descarte de llamada duplicada con regla DD-01', N'Se acepta', N'Aceptado', 'OK');
END TRY BEGIN CATCH INSERT @r VALUES (18, 'DD-06', N'Descarte de llamada duplicada con regla DD-01', N'Se acepta', ERROR_MESSAGE(), 'FALLA'); END CATCH

/* 19. Linaje por campo: un solo origen por registro y columna */
BEGIN TRY
  INSERT ctl.LinajeCampo (TablaModelo, RegistroId, Columna, FuenteSistema, FuenteTabla, FuenteLlave, LoteId)
  VALUES (N'core.Cliente', @cli, N'Correo', 'ZohoCRM', N'Contacts', N'1', @lote);
  INSERT ctl.LinajeCampo (TablaModelo, RegistroId, Columna, FuenteSistema, FuenteTabla, FuenteLlave, LoteId)
  VALUES (N'core.Cliente', @cli, N'Correo', 'ZohoBooks', N'contacts', N'2', @lote);
  INSERT @r VALUES (19, 'D9', N'Dos orígenes para el mismo campo del mismo cliente', N'Se rechaza', N'Aceptado', 'FALLA');
END TRY BEGIN CATCH INSERT @r VALUES (19, 'D9', N'Dos orígenes para el mismo campo del mismo cliente', N'Se rechaza', N'Rechazado (' + CAST(ERROR_NUMBER() AS varchar) + N')', 'OK'); END CATCH

ROLLBACK TRANSACTION;

/* Resultado */
SELECT N, Regla, Prueba, Esperado, Obtenido, Resultado FROM @r ORDER BY N;
SELECT COUNT(*) AS Pruebas, SUM(CASE WHEN Resultado = 'OK' THEN 1 ELSE 0 END) AS Correctas,
       SUM(CASE WHEN Resultado = 'FALLA' THEN 1 ELSE 0 END) AS Fallidas FROM @r;
/* Confirmación de que no quedaron datos de prueba */
SELECT (SELECT COUNT(*) FROM core.Cliente) AS Clientes, (SELECT COUNT(*) FROM core.Servicio) AS Servicios,
       (SELECT COUNT(*) FROM ctl.Lote) AS Lotes;
