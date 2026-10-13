USE ADN_Unificado;
GO
/* Paso 333 · core_Caso_Complemento → core.Caso
   Casos presentes solo en la tabla completa Cases (complemento, D2).
   Reglas: D2, DD-06, ES-01, ES-02, ES-07, ID-01, IN-01, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_Caso_Complemento @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT q.[FechaFinalizacion],
           q.[FechaFinMantenimiento],
           CAST(q.[Segmento] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Segmento],
           CAST(q.[Asunto] AS nvarchar(500)) COLLATE DATABASE_DEFAULT AS [Asunto],
           CAST(q.[NumeroTicket] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [NumeroTicket],
           CAST(q.[Origen] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Origen],
           CAST(q.[ProveedorExterno] AS nvarchar(100)) COLLATE DATABASE_DEFAULT AS [ProveedorExterno],
           q.[FechaModificacionOrigen],
           CAST(q.[TipoMantenimiento] AS nvarchar(100)) COLLATE DATABASE_DEFAULT AS [TipoMantenimiento],
           q.[Descripcion] COLLATE DATABASE_DEFAULT AS [Descripcion],
           CAST(q.[DepartamentoOrigen] AS nvarchar(100)) COLLATE DATABASE_DEFAULT AS [DepartamentoOrigen],
           q.[FechaCreacionOrigen],
           CAST(q.[Estado] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Estado],
           q.[FechaSolicitud],
           CAST(q.[CasoCrmId] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [CasoCrmId],
           CAST(q.[Circuito] AS varchar(12)) COLLATE DATABASE_DEFAULT AS [Circuito],
           q.[VisitaTecnica],
           q.[FechaAfectacion],
           q.[ServicioId],
           q.[PropietarioUsuarioId],
           q.[AtributosExtendidos] COLLATE DATABASE_DEFAULT AS [AtributosExtendidos],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[FechaFinalizacion], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaFinMantenimiento], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Segmento]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Asunto]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[NumeroTicket]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Origen]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ProveedorExterno]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaModificacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TipoMantenimiento]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Descripcion]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[DepartamentoOrigen]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaCreacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Estado]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaSolicitud], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[CasoCrmId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Circuito]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[VisitaTecnica]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaAfectacion], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ServicioId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[PropietarioUsuarioId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[AtributosExtendidos]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_ServicioId],
           q.[o_PropietarioUsuarioId],
           q.[o_FechaFinalizacion],
           q.[o_FechaFinMantenimiento],
           q.[o_FechaModificacionOrigen],
           q.[o_FechaCreacionOrigen],
           q.[o_FechaSolicitud],
           q.[o_Circuito],
           q.[o_FechaAfectacion],
           q.[o_Eliminado],
           CONCAT_WS(N',', CASE WHEN LEN(q.[Segmento]) > 50 THEN N'Segmento' END, CASE WHEN LEN(q.[Asunto]) > 500 THEN N'Asunto' END, CASE WHEN LEN(q.[NumeroTicket]) > 50 THEN N'NumeroTicket' END, CASE WHEN LEN(q.[Origen]) > 50 THEN N'Origen' END, CASE WHEN LEN(q.[ProveedorExterno]) > 100 THEN N'ProveedorExterno' END, CASE WHEN LEN(q.[TipoMantenimiento]) > 100 THEN N'TipoMantenimiento' END, CASE WHEN LEN(q.[DepartamentoOrigen]) > 100 THEN N'DepartamentoOrigen' END, CASE WHEN LEN(q.[Estado]) > 50 THEN N'Estado' END, CASE WHEN LEN(q.[CasoCrmId]) > 30 THEN N'CasoCrmId' END, CASE WHEN LEN(q.[Circuito]) > 12 THEN N'Circuito' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT 'ZohoCRM' AS FuenteSistema,
               N'Zoho_Mirror' AS FuenteBase,
               N'Cases' AS FuenteTabla,
               ctl.fn_Texto(CONVERT(nvarchar(200), c.[id])) AS FuenteLlave,
               ctl.fn_FechaCR(CONVERT(nvarchar(60), c.[Created_Time])) AS FechaDato,
               ctl.fn_FechaCR(CONVERT(nvarchar(60), c.[Fecha_Hora_Finalizaci_n])) AS [FechaFinalizacion],
               ctl.fn_FechaCR(CONVERT(nvarchar(60), c.[Fecha_Hora_Fin_Mant])) AS [FechaFinMantenimiento],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[Segmento])) AS [Segmento],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[Subject])) AS [Asunto],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[N_mero_Ticket])) AS [NumeroTicket],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[Case_Origin])) AS [Origen],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[Proveedor_Externo])) AS [ProveedorExterno],
               ctl.fn_FechaCR(CONVERT(nvarchar(60), c.[Modified_Time])) AS [FechaModificacionOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[Tipo_Mantenimiento])) AS [TipoMantenimiento],
               ctl.fn_Texto(CONVERT(nvarchar(max), CONVERT(nvarchar(max), c.[Description]))) AS [Descripcion],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[Departamente_Origen])) AS [DepartamentoOrigen],
               ctl.fn_FechaCR(CONVERT(nvarchar(60), c.[Created_Time])) AS [FechaCreacionOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[Status])) AS [Estado],
               ctl.fn_FechaCR(CONVERT(nvarchar(60), c.[Fecha_Hora_de_Solicitud])) AS [FechaSolicitud],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[id])) AS [CasoCrmId],
               ctl.fn_Circuito(CONVERT(nvarchar(100), c.[N_mero_Circuito])) AS [Circuito],
               ctl.fn_Bit(CONVERT(nvarchar(20), c.[Visita_Tecnica])) AS [VisitaTecnica],
               ctl.fn_FechaCR(CONVERT(nvarchar(60), c.[Fecha_Hora_Afectacion])) AS [FechaAfectacion],
               fk_ServicioId_0.Id AS [ServicioId],
               ctl.fn_Texto(CONVERT(nvarchar(400), c.[Account_Name])) AS [o_ServicioId],
               fk_PropietarioUsuarioId_0.Id AS [PropietarioUsuarioId],
               ctl.fn_Texto(CONVERT(nvarchar(400), c.[Owner])) AS [o_PropietarioUsuarioId],
               ctl.fn_Texto(CONVERT(nvarchar(400), c.[Fecha_Hora_Finalizaci_n])) AS [o_FechaFinalizacion],
               ctl.fn_Texto(CONVERT(nvarchar(400), c.[Fecha_Hora_Fin_Mant])) AS [o_FechaFinMantenimiento],
               ctl.fn_Texto(CONVERT(nvarchar(400), c.[Modified_Time])) AS [o_FechaModificacionOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(400), c.[Created_Time])) AS [o_FechaCreacionOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(400), c.[Fecha_Hora_de_Solicitud])) AS [o_FechaSolicitud],
               ctl.fn_Texto(CONVERT(nvarchar(400), c.[N_mero_Circuito])) AS [o_Circuito],
               ctl.fn_Texto(CONVERT(nvarchar(400), c.[Fecha_Hora_Afectacion])) AS [o_FechaAfectacion],
               NULLIF((SELECT ctl.fn_Texto(CONVERT(nvarchar(max), c.[Tag])) AS [Tag], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Fecha_Coordinacion])) AS [Fecha_Coordinacion], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Creado_por])) AS [Creado_por], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Duraci_n_en_Minutos])) AS [Duraci_n_en_Minutos], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Solucion])) AS [Solucion], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Nombre_de_quien_reporta])) AS [Nombre_de_quien_reporta], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Duracion])) AS [Duracion], ctl.fn_Texto(CONVERT(nvarchar(max), c.[CDF_Revision])) AS [CDF_Revision], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Type])) AS [Type], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Pick_List_40])) AS [Pick_List_40], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Frecuencias_Probadas])) AS [Frecuencias_Probadas], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Ancho_de_Canal])) AS [Ancho_de_Canal], ctl.fn_Texto(CONVERT(nvarchar(max), c.[SSID])) AS [SSID], ctl.fn_Texto(CONVERT(nvarchar(max), c.[BW_Final_Download_Upload])) AS [BW_Final_Download_Upload], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Rol_en_la_Red])) AS [Rol_en_la_Red], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Single_Line_38])) AS [Single_Line_38], ctl.fn_Texto(CONVERT(nvarchar(max), c.[IP_SU])) AS [IP_SU], ctl.fn_Texto(CONVERT(nvarchar(max), c.[CCQ_Final])) AS [CCQ_Final], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Asignado_a])) AS [Asignado_a], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Frecuencia_Final])) AS [Frecuencia_Final], ctl.fn_Texto(CONVERT(nvarchar(max), c.[IP_Equipo_Down])) AS [IP_Equipo_Down], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Modelo_de_Equipo_CDF])) AS [Modelo_de_Equipo_CDF], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Cotizacion])) AS [Cotizacion], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Coordinacion])) AS [Coordinacion], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Motivo_Mantenimiento])) AS [Motivo_Mantenimiento], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Nodo_2])) AS [Nodo_2], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Consecutivo])) AS [Consecutivo], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Ticked_ID_Proveedor_Externo])) AS [Ticked_ID_Proveedor_Externo], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Stand_By])) AS [Stand_By], ctl.fn_Texto(CONVERT(nvarchar(max), c.[IP_PBX])) AS [IP_PBX], ctl.fn_Texto(CONVERT(nvarchar(max), c.[FINAL])) AS [FINAL], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Alcance])) AS [Alcance], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Plataforma])) AS [Plataforma], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Ancho_de_Canal_Final])) AS [Ancho_de_Canal_Final], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Red_Publica])) AS [Red_Publica], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Subjects])) AS [Subjects], ctl.fn_Texto(CONVERT(nvarchar(max), c.[CCQ_Inicial])) AS [CCQ_Inicial], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Apellido])) AS [Apellido], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Razon_Stand_By])) AS [Razon_Stand_By], ctl.fn_Texto(CONVERT(nvarchar(max), c.[IP_Router])) AS [IP_Router], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Resultado_Final])) AS [Resultado_Final], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Frecuencia_Inicial])) AS [Frecuencia_Inicial], ctl.fn_Texto(CONVERT(nvarchar(max), c.[IP_Base])) AS [IP_Base], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Cerrado_Por_2])) AS [Cerrado_Por_2], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Envio_de_reporte])) AS [Envio_de_reporte], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Numero1])) AS [Numero1], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Problema_Datos])) AS [Problema_Datos], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Tipo_PBX])) AS [Tipo_PBX] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER), N'{}') AS [AtributosExtendidos],
               CAST(ISNULL(c.[deleted], 0) AS int) AS [o_Eliminado]
        FROM Zoho_Mirror.dbo.[Cases] c
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[ServicioId]) END AS Id FROM core.Servicio zref WHERE zref.[CuentaCrmId] = ctl.fn_Texto(CONVERT(nvarchar(max), c.[Account_Name]))) fk_ServicioId_0
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[UsuarioId]) END AS Id FROM ref.Usuario zref WHERE zref.[ZohoUsuarioId] = ctl.fn_Texto(CONVERT(nvarchar(max), c.[Owner])) OR zref.[NombreCompleto] = ctl.fn_Texto(CONVERT(nvarchar(max), c.[Owner]))) fk_PropietarioUsuarioId_0
        WHERE NOT EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.Cases_Extended e WHERE e.CaseId = c.id)
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 2. Filtros de carga: filas excluidas con la regla que las excluye (DD-06) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'DD-06', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'Registro marcado como eliminado en el origen (deleted = 1)', @Ahora FROM #src s WHERE s.o_Eliminado = 1
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'DD-06' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE s FROM #src s WHERE s.o_Eliminado = 1;
    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'CasoCrmId obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[CasoCrmId] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FuenteLlave obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FuenteLlave] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE FROM #src WHERE [CasoCrmId] IS NULL OR [FuenteLlave] IS NULL;

    /* 2b. Duplicados por la llave del paso (DD-02); el orden es determinista */
    ;WITH r AS (
        SELECT s.FuenteSistema, s.FuenteTabla, s.FuenteLlave,
               ROW_NUMBER() OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.FechaModificacionOrigen DESC, s.HashContenido) AS rn,
               FIRST_VALUE(s.FuenteLlave) OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.FechaModificacionOrigen DESC, s.HashContenido ROWS UNBOUNDED PRECEDING) AS Conservada
        FROM #src s)
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, LlaveConservada, Motivo, FechaDescarte)
    SELECT @LoteId, 'DD-02', r.FuenteSistema, r.FuenteTabla, r.FuenteLlave, r.Conservada, N'Versión anterior del mismo registro en el espejo; se conserva la modificación más reciente', @Ahora
    FROM r WHERE r.rn > 1
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'DD-02' AND x.FuenteTabla = r.FuenteTabla AND x.FuenteLlave = r.FuenteLlave);
    ;WITH r AS (
        SELECT ROW_NUMBER() OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.FechaModificacionOrigen DESC, s.HashContenido) AS rn FROM #src s)
    DELETE FROM r WHERE rn > 1;
    DECLARE @Validas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 3. Imagen previa de las filas que van a cambiar (para el rollback) */
    DROP TABLE IF EXISTS #antes;
    SELECT t.[CasoId] AS RegistroId, t.FuenteLlave, (SELECT t.[CasoCrmId], t.[ServicioId], t.[Circuito], t.[NumeroTicket], t.[Asunto], t.[Descripcion], t.[Estado], t.[Origen], t.[Segmento], t.[TipoMantenimiento], t.[DepartamentoOrigen], t.[ProveedorExterno], t.[VisitaTecnica], t.[Escalado], t.[PropietarioUsuarioId], t.[FechaSolicitud], t.[FechaAfectacion], t.[FechaEscalamiento], t.[FechaFinMantenimiento], t.[FechaFinalizacion], t.[AtributosExtendidos], t.[FechaCreacionOrigen], t.[FechaModificacionOrigen], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.Caso t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido;

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.Caso WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido) THEN
        UPDATE SET t.[FechaFinalizacion] = s.[FechaFinalizacion], t.[FechaFinMantenimiento] = s.[FechaFinMantenimiento], t.[Segmento] = s.[Segmento], t.[Asunto] = s.[Asunto], t.[NumeroTicket] = s.[NumeroTicket], t.[Origen] = s.[Origen], t.[ProveedorExterno] = s.[ProveedorExterno], t.[FechaModificacionOrigen] = s.[FechaModificacionOrigen], t.[TipoMantenimiento] = s.[TipoMantenimiento], t.[Descripcion] = s.[Descripcion], t.[DepartamentoOrigen] = s.[DepartamentoOrigen], t.[FechaCreacionOrigen] = s.[FechaCreacionOrigen], t.[Estado] = s.[Estado], t.[FechaSolicitud] = s.[FechaSolicitud], t.[CasoCrmId] = s.[CasoCrmId], t.[Circuito] = s.[Circuito], t.[VisitaTecnica] = s.[VisitaTecnica], t.[FechaAfectacion] = s.[FechaAfectacion], t.[ServicioId] = s.[ServicioId], t.[PropietarioUsuarioId] = s.[PropietarioUsuarioId], t.[AtributosExtendidos] = s.[AtributosExtendidos], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([FechaFinalizacion], [FechaFinMantenimiento], [Segmento], [Asunto], [NumeroTicket], [Origen], [ProveedorExterno], [FechaModificacionOrigen], [TipoMantenimiento], [Descripcion], [DepartamentoOrigen], [FechaCreacionOrigen], [Estado], [FechaSolicitud], [CasoCrmId], [Circuito], [VisitaTecnica], [FechaAfectacion], [ServicioId], [PropietarioUsuarioId], [AtributosExtendidos], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[FechaFinalizacion], s.[FechaFinMantenimiento], s.[Segmento], s.[Asunto], s.[NumeroTicket], s.[Origen], s.[ProveedorExterno], s.[FechaModificacionOrigen], s.[TipoMantenimiento], s.[Descripcion], s.[DepartamentoOrigen], s.[FechaCreacionOrigen], s.[Estado], s.[FechaSolicitud], s.[CasoCrmId], s.[Circuito], s.[VisitaTecnica], s.[FechaAfectacion], s.[ServicioId], s.[PropietarioUsuarioId], s.[AtributosExtendidos], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[CasoId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.Caso', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.Caso', t.[CasoId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.Caso t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.Caso', t.[CasoId], N'ServicioId', LEFT(CONVERT(nvarchar(400), s.o_ServicioId), 400), N'Referencia sin correspondencia única en core.Servicio'
    FROM #src s JOIN core.Caso t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_ServicioId IS NOT NULL AND s.[ServicioId] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.Caso', t.[CasoId], N'PropietarioUsuarioId', LEFT(CONVERT(nvarchar(400), s.o_PropietarioUsuarioId), 400), N'Referencia sin correspondencia única en ref.Usuario'
    FROM #src s JOIN core.Caso t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_PropietarioUsuarioId IS NOT NULL AND s.[PropietarioUsuarioId] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.Caso', t.[CasoId], N'FechaFinalizacion', LEFT(CONVERT(nvarchar(400), s.o_FechaFinalizacion), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.Caso t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaFinalizacion IS NOT NULL AND s.[FechaFinalizacion] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.Caso', t.[CasoId], N'FechaFinMantenimiento', LEFT(CONVERT(nvarchar(400), s.o_FechaFinMantenimiento), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.Caso t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaFinMantenimiento IS NOT NULL AND s.[FechaFinMantenimiento] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.Caso', t.[CasoId], N'FechaModificacionOrigen', LEFT(CONVERT(nvarchar(400), s.o_FechaModificacionOrigen), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.Caso t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaModificacionOrigen IS NOT NULL AND s.[FechaModificacionOrigen] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.Caso', t.[CasoId], N'FechaCreacionOrigen', LEFT(CONVERT(nvarchar(400), s.o_FechaCreacionOrigen), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.Caso t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaCreacionOrigen IS NOT NULL AND s.[FechaCreacionOrigen] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.Caso', t.[CasoId], N'FechaSolicitud', LEFT(CONVERT(nvarchar(400), s.o_FechaSolicitud), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.Caso t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaSolicitud IS NOT NULL AND s.[FechaSolicitud] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ID-01', N'core.Caso', t.[CasoId], N'Circuito', LEFT(CONVERT(nvarchar(400), s.o_Circuito), 400), N'Circuito que no cumple el patrón aprobado'
    FROM #src s JOIN core.Caso t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Circuito IS NOT NULL AND s.[Circuito] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.Caso', t.[CasoId], N'FechaAfectacion', LEFT(CONVERT(nvarchar(400), s.o_FechaAfectacion), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.Caso t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaAfectacion IS NOT NULL AND s.[FechaAfectacion] IS NULL;

    SELECT @Leidas AS FilasLeidas, @Validas - (SELECT COUNT_BIG(*) FROM #cambios) AS FilasSinCambio;
END;
GO
