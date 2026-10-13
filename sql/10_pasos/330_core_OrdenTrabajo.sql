USE ADN_Unificado;
GO
/* Paso 330 · core_OrdenTrabajo → core.OrdenTrabajo
   Órdenes de trabajo. El servicio se vincula por circuito con correspondencia única (ID-01).
   Reglas: DD-06, ES-01, ES-02, ID-01, IN-01, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_OrdenTrabajo @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT q.[FechaEntregaEnlace],
           q.[FechaCreacionOT],
           q.[FechaCreacionOrigen],
           CAST(q.[CapacidadCarga] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [CapacidadCarga],
           q.[FechaFinalizacion],
           CAST(q.[Provincia] AS nvarchar(60)) COLLATE DATABASE_DEFAULT AS [Provincia],
           CAST(q.[Canton] AS nvarchar(80)) COLLATE DATABASE_DEFAULT AS [Canton],
           CAST(q.[CapacidadDescarga] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [CapacidadDescarga],
           CAST(q.[SubEstado] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [SubEstado],
           q.[FechaCoordinada],
           q.[Latitud],
           CAST(q.[Nombre] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [Nombre],
           CAST(q.[Tecnologia] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Tecnologia],
           q.[Longitud],
           CAST(q.[Distrito] AS nvarchar(80)) COLLATE DATABASE_DEFAULT AS [Distrito],
           q.[FechaEstimada],
           CAST(q.[Estado] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Estado],
           q.[FechaModificacionOrigen],
           CAST(q.[DireccionExacta] AS nvarchar(1000)) COLLATE DATABASE_DEFAULT AS [DireccionExacta],
           CAST(q.[Tipo] AS nvarchar(100)) COLLATE DATABASE_DEFAULT AS [Tipo],
           CAST(q.[TipoSolicitud] AS nvarchar(100)) COLLATE DATABASE_DEFAULT AS [TipoSolicitud],
           CAST(q.[OrdenTrabajoCrmId] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [OrdenTrabajoCrmId],
           q.[NodoId],
           q.[ServicioId],
           q.[AsignadoUsuarioId],
           q.[AtributosExtendidos] COLLATE DATABASE_DEFAULT AS [AtributosExtendidos],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[FechaEntregaEnlace], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaCreacionOT], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaCreacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[CapacidadCarga]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaFinalizacion], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Provincia]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Canton]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[CapacidadDescarga]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[SubEstado]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaCoordinada], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Latitud]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Nombre]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Tecnologia]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Longitud]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Distrito]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaEstimada], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Estado]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaModificacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[DireccionExacta]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Tipo]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TipoSolicitud]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[OrdenTrabajoCrmId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[NodoId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ServicioId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[AsignadoUsuarioId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[AtributosExtendidos]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_NodoId],
           q.[o_ServicioId],
           q.[o_AsignadoUsuarioId],
           q.[o_FechaEntregaEnlace],
           q.[o_FechaCreacionOT],
           q.[o_FechaCreacionOrigen],
           q.[o_FechaFinalizacion],
           q.[o_FechaCoordinada],
           q.[o_FechaEstimada],
           q.[o_FechaModificacionOrigen],
           q.[o_Eliminado],
           CONCAT_WS(N',', CASE WHEN LEN(q.[CapacidadCarga]) > 50 THEN N'CapacidadCarga' END, CASE WHEN LEN(q.[Provincia]) > 60 THEN N'Provincia' END, CASE WHEN LEN(q.[Canton]) > 80 THEN N'Canton' END, CASE WHEN LEN(q.[CapacidadDescarga]) > 50 THEN N'CapacidadDescarga' END, CASE WHEN LEN(q.[SubEstado]) > 50 THEN N'SubEstado' END, CASE WHEN LEN(q.[Nombre]) > 200 THEN N'Nombre' END, CASE WHEN LEN(q.[Tecnologia]) > 50 THEN N'Tecnologia' END, CASE WHEN LEN(q.[Distrito]) > 80 THEN N'Distrito' END, CASE WHEN LEN(q.[Estado]) > 50 THEN N'Estado' END, CASE WHEN LEN(q.[DireccionExacta]) > 1000 THEN N'DireccionExacta' END, CASE WHEN LEN(q.[Tipo]) > 100 THEN N'Tipo' END, CASE WHEN LEN(q.[TipoSolicitud]) > 100 THEN N'TipoSolicitud' END, CASE WHEN LEN(q.[OrdenTrabajoCrmId]) > 30 THEN N'OrdenTrabajoCrmId' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT 'ZohoCRM' AS FuenteSistema,
               N'Zoho_Mirror' AS FuenteBase,
               N'Ordenes_de_Trabajo' AS FuenteTabla,
               ctl.fn_Texto(CONVERT(nvarchar(200), t.[id])) AS FuenteLlave,
               ctl.fn_FechaCR(CONVERT(nvarchar(60), t.[Created_Time])) AS FechaDato,
               ctl.fn_FechaCR(CONVERT(nvarchar(60), t.[Fecha_de_entrega_de_enlace])) AS [FechaEntregaEnlace],
               ctl.fn_FechaCR(CONVERT(nvarchar(60), t.[Fecha_de_Creaci_n_de_la_OT])) AS [FechaCreacionOT],
               ctl.fn_FechaCR(CONVERT(nvarchar(60), t.[Created_Time])) AS [FechaCreacionOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(max), t.[Capacidad_Carga])) AS [CapacidadCarga],
               ctl.fn_FechaCR(CONVERT(nvarchar(60), t.[Fecha_de_finalizaci_n])) AS [FechaFinalizacion],
               ctl.fn_Texto(CONVERT(nvarchar(max), t.[Provincia])) AS [Provincia],
               ctl.fn_Texto(CONVERT(nvarchar(max), t.[Cant_n])) AS [Canton],
               ctl.fn_Texto(CONVERT(nvarchar(max), t.[Capacidad_Descarga])) AS [CapacidadDescarga],
               ctl.fn_Texto(CONVERT(nvarchar(max), t.[Sub_Estado])) AS [SubEstado],
               ctl.fn_FechaCR(CONVERT(nvarchar(60), t.[Fecha_Coordinada])) AS [FechaCoordinada],
               ctl.fn_CoordenadaSola(CONVERT(nvarchar(60), t.[Latitud]), 1) AS [Latitud],
               ctl.fn_Texto(CONVERT(nvarchar(max), t.[Name])) AS [Nombre],
               ctl.fn_Texto(CONVERT(nvarchar(max), t.[Tecnologia])) AS [Tecnologia],
               ctl.fn_CoordenadaSola(CONVERT(nvarchar(60), t.[Longitud]), 2) AS [Longitud],
               ctl.fn_Texto(CONVERT(nvarchar(max), t.[Distrito])) AS [Distrito],
               ctl.fn_FechaCR(CONVERT(nvarchar(60), t.[Fecha_Estimada])) AS [FechaEstimada],
               ctl.fn_Texto(CONVERT(nvarchar(max), t.[Estado])) AS [Estado],
               ctl.fn_FechaCR(CONVERT(nvarchar(60), t.[Modified_Time])) AS [FechaModificacionOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(max), CONVERT(nvarchar(max), t.[Direcci_n_Exacta]))) AS [DireccionExacta],
               ctl.fn_Texto(CONVERT(nvarchar(max), t.[Tipo_de_OT])) AS [Tipo],
               ctl.fn_Texto(CONVERT(nvarchar(max), t.[Tipo_de_solicitud])) AS [TipoSolicitud],
               ctl.fn_Texto(CONVERT(nvarchar(max), t.[id])) AS [OrdenTrabajoCrmId],
               fk_NodoId_0.Id AS [NodoId],
               ctl.fn_Texto(CONVERT(nvarchar(400), t.[Nodo])) AS [o_NodoId],
               fk_ServicioId_0.Id AS [ServicioId],
               ctl.fn_Texto(CONVERT(nvarchar(400), t.[N_mero_de_circuito_contrato])) AS [o_ServicioId],
               fk_AsignadoUsuarioId_0.Id AS [AsignadoUsuarioId],
               ctl.fn_Texto(CONVERT(nvarchar(400), t.[Asignado_a])) AS [o_AsignadoUsuarioId],
               ctl.fn_Texto(CONVERT(nvarchar(400), t.[Fecha_de_entrega_de_enlace])) AS [o_FechaEntregaEnlace],
               ctl.fn_Texto(CONVERT(nvarchar(400), t.[Fecha_de_Creaci_n_de_la_OT])) AS [o_FechaCreacionOT],
               ctl.fn_Texto(CONVERT(nvarchar(400), t.[Created_Time])) AS [o_FechaCreacionOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(400), t.[Fecha_de_finalizaci_n])) AS [o_FechaFinalizacion],
               ctl.fn_Texto(CONVERT(nvarchar(400), t.[Fecha_Coordinada])) AS [o_FechaCoordinada],
               ctl.fn_Texto(CONVERT(nvarchar(400), t.[Fecha_Estimada])) AS [o_FechaEstimada],
               ctl.fn_Texto(CONVERT(nvarchar(400), t.[Modified_Time])) AS [o_FechaModificacionOrigen],
               NULLIF((SELECT ctl.fn_Texto(CONVERT(nvarchar(max), t.[Owner])) AS [Owner], ctl.fn_Texto(CONVERT(nvarchar(max), t.[N_mero_de_Ticket])) AS [N_mero_de_Ticket], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Link_Waze])) AS [Link_Waze], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Tipo_de_Antena_Base])) AS [Tipo_de_Antena_Base], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Transporte])) AS [Transporte], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Download_Capacity])) AS [Download_Capacity], ctl.fn_Texto(CONVERT(nvarchar(max), t.[IP_Router])) AS [IP_Router], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Contrato_Relacionado])) AS [Contrato_Relacionado], ctl.fn_Texto(CONVERT(nvarchar(max), t.[OLT])) AS [OLT], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Currency])) AS [Currency], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Tipo_de_recepci_n])) AS [Tipo_de_recepci_n], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Relaci_n])) AS [Relaci_n], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Raz_n_Social])) AS [Raz_n_Social], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Direcci_n_IP_SU_Nano])) AS [Direcci_n_IP_SU_Nano], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Fecha_de_Solicitud_IP_Completada])) AS [Fecha_de_Solicitud_IP_Completada], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Puerto_a_utilizar])) AS [Puerto_a_utilizar], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Pagina_utilizada_para_la_prueba_de_navegaci_n])) AS [Pagina_utilizada_para_la_prueba_de_navegaci_n], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Detalles_de_instalaci_n])) AS [Detalles_de_instalaci_n], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Consecutivo])) AS [Consecutivo], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Agenda_Estudio])) AS [Agenda_Estudio], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Tipo_de_Antena_SU])) AS [Tipo_de_Antena_SU], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Campo_de_agregaci_n_1])) AS [Campo_de_agregaci_n_1], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Respuesta_de_Ping])) AS [Respuesta_de_Ping], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Nodo_Factible_3])) AS [Nodo_Factible_3], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Navegaci_n_Confirmada])) AS [Navegaci_n_Confirmada], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Nodo_Factible_2])) AS [Nodo_Factible_2], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Nodo_Factible_1])) AS [Nodo_Factible_1], ctl.fn_Texto(CONVERT(nvarchar(max), t.[IP_Nano_SU])) AS [IP_Nano_SU], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Puerto_Wan_del_Router])) AS [Puerto_Wan_del_Router], ctl.fn_Texto(CONVERT(nvarchar(max), t.[IP_SU])) AS [IP_SU], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Fecha_de_creaci_n_de_la_solicitud])) AS [Fecha_de_creaci_n_de_la_solicitud], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Direcci_n_IP_Base_Nano])) AS [Direcci_n_IP_Base_Nano], ctl.fn_Texto(CONVERT(nvarchar(max), t.[IP_de_red])) AS [IP_de_red], ctl.fn_Texto(CONVERT(nvarchar(max), t.[IP_Nano_Base])) AS [IP_Nano_Base], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Switch_a_utilizar_en_el_nodo])) AS [Switch_a_utilizar_en_el_nodo], ctl.fn_Texto(CONVERT(nvarchar(max), t.[SSID])) AS [SSID], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Ticket])) AS [Ticket], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Tipo_Recepci_n])) AS [Tipo_Recepci_n], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Ancho_de_Canal])) AS [Ancho_de_Canal], ctl.fn_Texto(CONVERT(nvarchar(max), t.[N_mero_Serial])) AS [N_mero_Serial], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Propietario_Poste])) AS [Propietario_Poste], ctl.fn_Texto(CONVERT(nvarchar(max), t.[IP_BASE])) AS [IP_BASE], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Cierre])) AS [Cierre], ctl.fn_Texto(CONVERT(nvarchar(max), t.[ATA])) AS [ATA], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Enlace_factible])) AS [Enlace_factible], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Equipos_adicionales])) AS [Equipos_adicionales], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Permisos])) AS [Permisos], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Segmento])) AS [Segmento], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Tipo_de_Conexion])) AS [Tipo_de_Conexion], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Vlan_de_gestion])) AS [Vlan_de_gestion], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Fecha_Inspeccion_Cliente])) AS [Fecha_Inspeccion_Cliente], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Mascara])) AS [Mascara], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Upload_Capacity])) AS [Upload_Capacity], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Nodo_Fibra])) AS [Nodo_Fibra], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Orden_de_Instalaci_n_Numero])) AS [Orden_de_Instalaci_n_Numero], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Solicitud_IP_Completada])) AS [Solicitud_IP_Completada], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Comentarios])) AS [Comentarios], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Departamento_Operaciones])) AS [Departamento_Operaciones], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Last_Activity_Time])) AS [Last_Activity_Time], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Coordenadas_GPS])) AS [Coordenadas_GPS], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Direcci_n_IP_Router_2])) AS [Direcci_n_IP_Router_2], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Numero_de_Solicitud_de_IP_relacionada])) AS [Numero_de_Solicitud_de_IP_relacionada], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Nodo_Solicitado])) AS [Nodo_Solicitado], ctl.fn_Texto(CONVERT(nvarchar(max), t.[ID_Proveedor])) AS [ID_Proveedor], ctl.fn_Texto(CONVERT(nvarchar(max), t.[T_cnico_asignado_en_SU])) AS [T_cnico_asignado_en_SU], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Otro_Equipo])) AS [Otro_Equipo], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Vlan_publica])) AS [Vlan_publica], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Transportador])) AS [Transportador], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Ancho_de_banda_speedtest_data_cr])) AS [Ancho_de_banda_speedtest_data_cr], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Recibido_por])) AS [Recibido_por], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Distancia_KM])) AS [Distancia_KM], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Solicitud_realizada_por])) AS [Solicitud_realizada_por], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Cuenta_principal])) AS [Cuenta_principal], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Fecha_Ducteria])) AS [Fecha_Ducteria], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Actualizacion_Sensores])) AS [Actualizacion_Sensores], ctl.fn_Texto(CONVERT(nvarchar(max), t.[IPTV])) AS [IPTV], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Capacidad])) AS [Capacidad], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Numero_de_Solicitud_de_IP])) AS [Numero_de_Solicitud_de_IP], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Puerto_Utilizable])) AS [Puerto_Utilizable], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Gateway])) AS [Gateway], ctl.fn_Texto(CONVERT(nvarchar(max), t.[OLT_Nodo])) AS [OLT_Nodo], ctl.fn_Texto(CONVERT(nvarchar(max), t.[IP_publica])) AS [IP_publica], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Fecha_de_finalizaci_n_de_la_Instalaci_n])) AS [Fecha_de_finalizaci_n_de_la_Instalaci_n], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Observaciones1])) AS [Observaciones1], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Fecha_Area])) AS [Fecha_Area], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Altura_Mastil])) AS [Altura_Mastil], ctl.fn_Texto(CONVERT(nvarchar(max), t.[M_vil_Asignada_SU])) AS [M_vil_Asignada_SU], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Orden_de_trabajo_de])) AS [Orden_de_trabajo_de], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Nombre_del_cliente])) AS [Nombre_del_cliente], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Frecuencia])) AS [Frecuencia], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Identificaci_n])) AS [Identificaci_n], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Direcci_n_IP_AP2])) AS [Direcci_n_IP_AP2], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Tiempo_de_respuesta_D_as])) AS [Tiempo_de_respuesta_D_as], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Direcci_n_IP_AP3])) AS [Direcci_n_IP_AP3], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Direcci_n_IP_AP1])) AS [Direcci_n_IP_AP1], ctl.fn_Texto(CONVERT(nvarchar(max), t.[Vlan_admin])) AS [Vlan_admin] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER), N'{}') AS [AtributosExtendidos],
               CAST(ISNULL(t.[deleted], 0) AS int) AS [o_Eliminado]
        FROM Zoho_Mirror.dbo.[Ordenes_de_Trabajo] t
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[NodoId]) END AS Id FROM core.Nodo zref WHERE zref.[NodoCrmId] = ctl.fn_Texto(CONVERT(nvarchar(max), t.[Nodo])) OR zref.[Nombre] = ctl.fn_Texto(CONVERT(nvarchar(max), t.[Nodo]))) fk_NodoId_0
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[ServicioId]) END AS Id FROM core.Servicio zref WHERE zref.Circuito = ctl.fn_Circuito(CONVERT(nvarchar(100), t.[N_mero_de_circuito_contrato]))) fk_ServicioId_0
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[UsuarioId]) END AS Id FROM ref.Usuario zref WHERE zref.[ZohoUsuarioId] = ctl.fn_Texto(CONVERT(nvarchar(max), t.[Asignado_a])) OR zref.[NombreCompleto] = ctl.fn_Texto(CONVERT(nvarchar(max), t.[Asignado_a]))) fk_AsignadoUsuarioId_0
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
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'OrdenTrabajoCrmId obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[OrdenTrabajoCrmId] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FuenteLlave obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FuenteLlave] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE FROM #src WHERE [OrdenTrabajoCrmId] IS NULL OR [FuenteLlave] IS NULL;

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
    SELECT t.[OrdenTrabajoId] AS RegistroId, t.FuenteLlave, (SELECT t.[OrdenTrabajoCrmId], t.[ServicioId], t.[NodoId], t.[Nombre], t.[Tipo], t.[TipoSolicitud], t.[Estado], t.[SubEstado], t.[Tecnologia], t.[CapacidadDescarga], t.[CapacidadCarga], t.[Provincia], t.[Canton], t.[Distrito], t.[DireccionExacta], t.[Latitud], t.[Longitud], t.[FechaCreacionOT], t.[FechaCoordinada], t.[FechaEstimada], t.[FechaFinalizacion], t.[FechaEntregaEnlace], t.[AsignadoUsuarioId], t.[AtributosExtendidos], t.[FechaCreacionOrigen], t.[FechaModificacionOrigen], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.OrdenTrabajo t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato);

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.OrdenTrabajo WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato)) THEN
        UPDATE SET t.[FechaEntregaEnlace] = s.[FechaEntregaEnlace], t.[FechaCreacionOT] = s.[FechaCreacionOT], t.[FechaCreacionOrigen] = s.[FechaCreacionOrigen], t.[CapacidadCarga] = s.[CapacidadCarga], t.[FechaFinalizacion] = s.[FechaFinalizacion], t.[Provincia] = s.[Provincia], t.[Canton] = s.[Canton], t.[CapacidadDescarga] = s.[CapacidadDescarga], t.[SubEstado] = s.[SubEstado], t.[FechaCoordinada] = s.[FechaCoordinada], t.[Latitud] = s.[Latitud], t.[Nombre] = s.[Nombre], t.[Tecnologia] = s.[Tecnologia], t.[Longitud] = s.[Longitud], t.[Distrito] = s.[Distrito], t.[FechaEstimada] = s.[FechaEstimada], t.[Estado] = s.[Estado], t.[FechaModificacionOrigen] = s.[FechaModificacionOrigen], t.[DireccionExacta] = s.[DireccionExacta], t.[Tipo] = s.[Tipo], t.[TipoSolicitud] = s.[TipoSolicitud], t.[OrdenTrabajoCrmId] = s.[OrdenTrabajoCrmId], t.[NodoId] = s.[NodoId], t.[ServicioId] = s.[ServicioId], t.[AsignadoUsuarioId] = s.[AsignadoUsuarioId], t.[AtributosExtendidos] = s.[AtributosExtendidos], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([FechaEntregaEnlace], [FechaCreacionOT], [FechaCreacionOrigen], [CapacidadCarga], [FechaFinalizacion], [Provincia], [Canton], [CapacidadDescarga], [SubEstado], [FechaCoordinada], [Latitud], [Nombre], [Tecnologia], [Longitud], [Distrito], [FechaEstimada], [Estado], [FechaModificacionOrigen], [DireccionExacta], [Tipo], [TipoSolicitud], [OrdenTrabajoCrmId], [NodoId], [ServicioId], [AsignadoUsuarioId], [AtributosExtendidos], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[FechaEntregaEnlace], s.[FechaCreacionOT], s.[FechaCreacionOrigen], s.[CapacidadCarga], s.[FechaFinalizacion], s.[Provincia], s.[Canton], s.[CapacidadDescarga], s.[SubEstado], s.[FechaCoordinada], s.[Latitud], s.[Nombre], s.[Tecnologia], s.[Longitud], s.[Distrito], s.[FechaEstimada], s.[Estado], s.[FechaModificacionOrigen], s.[DireccionExacta], s.[Tipo], s.[TipoSolicitud], s.[OrdenTrabajoCrmId], s.[NodoId], s.[ServicioId], s.[AsignadoUsuarioId], s.[AtributosExtendidos], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[OrdenTrabajoId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.OrdenTrabajo', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.OrdenTrabajo', t.[OrdenTrabajoId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.OrdenTrabajo t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.OrdenTrabajo', t.[OrdenTrabajoId], N'NodoId', LEFT(CONVERT(nvarchar(400), s.o_NodoId), 400), N'Referencia sin correspondencia única en core.Nodo'
    FROM #src s JOIN core.OrdenTrabajo t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_NodoId IS NOT NULL AND s.[NodoId] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.OrdenTrabajo', t.[OrdenTrabajoId], N'ServicioId', LEFT(CONVERT(nvarchar(400), s.o_ServicioId), 400), N'Referencia sin correspondencia única en core.Servicio'
    FROM #src s JOIN core.OrdenTrabajo t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_ServicioId IS NOT NULL AND s.[ServicioId] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.OrdenTrabajo', t.[OrdenTrabajoId], N'AsignadoUsuarioId', LEFT(CONVERT(nvarchar(400), s.o_AsignadoUsuarioId), 400), N'Referencia sin correspondencia única en ref.Usuario'
    FROM #src s JOIN core.OrdenTrabajo t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_AsignadoUsuarioId IS NOT NULL AND s.[AsignadoUsuarioId] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.OrdenTrabajo', t.[OrdenTrabajoId], N'FechaEntregaEnlace', LEFT(CONVERT(nvarchar(400), s.o_FechaEntregaEnlace), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.OrdenTrabajo t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaEntregaEnlace IS NOT NULL AND s.[FechaEntregaEnlace] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.OrdenTrabajo', t.[OrdenTrabajoId], N'FechaCreacionOT', LEFT(CONVERT(nvarchar(400), s.o_FechaCreacionOT), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.OrdenTrabajo t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaCreacionOT IS NOT NULL AND s.[FechaCreacionOT] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.OrdenTrabajo', t.[OrdenTrabajoId], N'FechaCreacionOrigen', LEFT(CONVERT(nvarchar(400), s.o_FechaCreacionOrigen), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.OrdenTrabajo t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaCreacionOrigen IS NOT NULL AND s.[FechaCreacionOrigen] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.OrdenTrabajo', t.[OrdenTrabajoId], N'FechaFinalizacion', LEFT(CONVERT(nvarchar(400), s.o_FechaFinalizacion), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.OrdenTrabajo t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaFinalizacion IS NOT NULL AND s.[FechaFinalizacion] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.OrdenTrabajo', t.[OrdenTrabajoId], N'FechaCoordinada', LEFT(CONVERT(nvarchar(400), s.o_FechaCoordinada), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.OrdenTrabajo t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaCoordinada IS NOT NULL AND s.[FechaCoordinada] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.OrdenTrabajo', t.[OrdenTrabajoId], N'FechaEstimada', LEFT(CONVERT(nvarchar(400), s.o_FechaEstimada), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.OrdenTrabajo t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaEstimada IS NOT NULL AND s.[FechaEstimada] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.OrdenTrabajo', t.[OrdenTrabajoId], N'FechaModificacionOrigen', LEFT(CONVERT(nvarchar(400), s.o_FechaModificacionOrigen), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.OrdenTrabajo t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaModificacionOrigen IS NOT NULL AND s.[FechaModificacionOrigen] IS NULL;

    SELECT @Leidas AS FilasLeidas, @Validas - (SELECT COUNT_BIG(*) FROM #cambios) AS FilasSinCambio;
END;
GO
