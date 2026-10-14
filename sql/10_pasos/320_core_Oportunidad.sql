USE ADN_Unificado;
GO
/* Paso 320 · core_Oportunidad → core.Oportunidad
   Oportunidades del CRM, con monto en moneda original y en colones (D5).
   Reglas: D5, DD-06, ES-01, ES-02, ES-04, IN-01, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_Oportunidad @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT q.[FechaModificacionOrigen],
           q.[FechaCierre],
           CAST(q.[Nombre] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [Nombre],
           CAST(q.[Segmento] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Segmento],
           q.[Probabilidad],
           q.[Monto],
           q.[FechaCreacionOrigen],
           CAST(q.[OportunidadCrmId] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [OportunidadCrmId],
           CAST(q.[Etapa] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Etapa],
           CAST(q.[Moneda] AS char(3)) COLLATE DATABASE_DEFAULT AS [Moneda],
           q.[ContactoId],
           q.[ServicioId],
           q.[PropietarioUsuarioId],
           q.[AtributosExtendidos] COLLATE DATABASE_DEFAULT AS [AtributosExtendidos],
           q.[MontoCRC],
           q.[TipoCambio],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[FechaModificacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaCierre], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Nombre]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Segmento]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Probabilidad]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Monto]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaCreacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[OportunidadCrmId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Etapa]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Moneda]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ContactoId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ServicioId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[PropietarioUsuarioId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[AtributosExtendidos]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[MontoCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TipoCambio]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_ContactoId],
           q.[o_ServicioId],
           q.[o_PropietarioUsuarioId],
           q.[o_FechaModificacionOrigen],
           q.[o_FechaCierre],
           q.[o_Monto],
           q.[o_FechaCreacionOrigen],
           q.[o_Eliminado],
           CONCAT_WS(N',', CASE WHEN LEN(q.[Nombre]) > 200 THEN N'Nombre' END, CASE WHEN LEN(q.[Segmento]) > 50 THEN N'Segmento' END, CASE WHEN LEN(q.[OportunidadCrmId]) > 30 THEN N'OportunidadCrmId' END, CASE WHEN LEN(q.[Etapa]) > 50 THEN N'Etapa' END, CASE WHEN LEN(q.[Moneda]) > 3 THEN N'Moneda' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT q.*,
               tx.Tasa AS TipoCambio,
               CASE q.Moneda WHEN 'CRC' THEN q.[Monto] WHEN 'USD' THEN CAST(q.[Monto] * tx.Tasa AS decimal(19,4)) END AS [MontoCRC]
        FROM (
        SELECT 'ZohoCRM' AS FuenteSistema,
               N'Zoho_Mirror' AS FuenteBase,
               N'Deals' AS FuenteTabla,
               ctl.fn_Texto(CONVERT(nvarchar(200), d.[id])) AS FuenteLlave,
               ctl.fn_FechaCR(CONVERT(nvarchar(60), d.[Created_Time])) AS FechaDato,
               ctl.fn_FechaCR(CONVERT(nvarchar(60), d.[Modified_Time])) AS [FechaModificacionOrigen],
               ctl.fn_FechaDia(CONVERT(nvarchar(60), d.[Closing_Date])) AS [FechaCierre],
               ctl.fn_Texto(CONVERT(nvarchar(max), d.[Deal_Name])) AS [Nombre],
               ctl.fn_Texto(CONVERT(nvarchar(max), d.[Segmento])) AS [Segmento],
               TRY_CONVERT(decimal(5,2), ctl.fn_PrimerNumero(CONVERT(nvarchar(255), d.[Probability]))) AS [Probabilidad],
               ctl.fn_Monto(CONVERT(nvarchar(60), d.[Amount])) AS [Monto],
               ctl.fn_FechaCR(CONVERT(nvarchar(60), d.[Created_Time])) AS [FechaCreacionOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(max), d.[id])) AS [OportunidadCrmId],
               ctl.fn_Texto(CONVERT(nvarchar(max), d.[Stage])) AS [Etapa],
               ctl.fn_Moneda(CONVERT(nvarchar(20), d.[Currency])) AS [Moneda],
               fk_ContactoId_0.Id AS [ContactoId],
               ctl.fn_Texto(CONVERT(nvarchar(400), d.[Contact_Name])) AS [o_ContactoId],
               fk_ServicioId_0.Id AS [ServicioId],
               ctl.fn_Texto(CONVERT(nvarchar(400), d.[Account_Name])) AS [o_ServicioId],
               fk_PropietarioUsuarioId_0.Id AS [PropietarioUsuarioId],
               ctl.fn_Texto(CONVERT(nvarchar(400), d.[Owner])) AS [o_PropietarioUsuarioId],
               ctl.fn_Texto(CONVERT(nvarchar(400), d.[Modified_Time])) AS [o_FechaModificacionOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(400), d.[Closing_Date])) AS [o_FechaCierre],
               ctl.fn_Texto(CONVERT(nvarchar(400), d.[Amount])) AS [o_Monto],
               ctl.fn_Texto(CONVERT(nvarchar(400), d.[Created_Time])) AS [o_FechaCreacionOrigen],
               NULLIF((SELECT ctl.fn_Texto(CONVERT(nvarchar(max), d.[Plataforma_de_Enlace])) AS [Plataforma_de_Enlace], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Costo_Dist_Interna])) AS [Costo_Dist_Interna], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Costo_Equipo])) AS [Costo_Equipo], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Coordenadas])) AS [Coordenadas], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Empresa_Owner])) AS [Empresa_Owner], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Antenas_Op_2])) AS [Antenas_Op_2], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Direcci_n_Exacta])) AS [Direcci_n_Exacta], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Router_2])) AS [Router_2], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Router_3])) AS [Router_3], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Antenas_Op_3])) AS [Antenas_Op_3], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Sales_Cycle_Duration])) AS [Sales_Cycle_Duration], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Costo_No_Recurrente_ADN])) AS [Costo_No_Recurrente_ADN], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Obra_Civil])) AS [Obra_Civil], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Viaticos])) AS [Viaticos], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Capacidad_Primer_Enlace])) AS [Capacidad_Primer_Enlace], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Device_Type])) AS [Device_Type], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Segundo_Equipo])) AS [Segundo_Equipo], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Complejidad])) AS [Complejidad], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Comentarios_Notas1])) AS [Comentarios_Notas1], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Cuarto_Equipo])) AS [Cuarto_Equipo], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Tercer_Equipo])) AS [Tercer_Equipo], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Cantidad_Casas])) AS [Cantidad_Casas], ctl.fn_Texto(CONVERT(nvarchar(max), d.[VPN])) AS [VPN], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Capacidad_Mbps_Carga])) AS [Capacidad_Mbps_Carga], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Modified_By])) AS [Modified_By], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Condominio_Aprobado])) AS [Condominio_Aprobado], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Cost_per_Conversion])) AS [Cost_per_Conversion], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Conversion_Export_Status])) AS [Conversion_Export_Status], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Costo_del_dispositivo_de_fibra_ADN_2])) AS [Costo_del_dispositivo_de_fibra_ADN_2], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Comentarios_Notas_2])) AS [Comentarios_Notas_2], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Comentarios_Notas])) AS [Comentarios_Notas], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Costo_No_Recurrente_ISP_Externo])) AS [Costo_No_Recurrente_ISP_Externo], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Comentarios_Notas_3])) AS [Comentarios_Notas_3], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Costo_Recurrente_ISP_Externo])) AS [Costo_Recurrente_ISP_Externo], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Fecha_Inspeccion])) AS [Fecha_Inspeccion], ctl.fn_Texto(CONVERT(nvarchar(max), d.[AdGroup_Name])) AS [AdGroup_Name], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Costo_Cuarto_Equipo])) AS [Costo_Cuarto_Equipo], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Condominio_C])) AS [Condominio_C], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Click_Type])) AS [Click_Type], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Conversion_Exported_On])) AS [Conversion_Exported_On], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Capacidad_Mbps_Descarga])) AS [Capacidad_Mbps_Descarga], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Nombre_Proyecto])) AS [Nombre_Proyecto], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Costo_Recurrente_ADN])) AS [Costo_Recurrente_ADN], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Viaticos1])) AS [Viaticos1], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Last_Activity_Time])) AS [Last_Activity_Time], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Costo_Final])) AS [Costo_Final], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Enlace_de_Datos_GPS])) AS [Enlace_de_Datos_GPS], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Costo_Fibra])) AS [Costo_Fibra], ctl.fn_Texto(CONVERT(nvarchar(max), d.[CPO])) AS [CPO], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Estrategia_Segmento])) AS [Estrategia_Segmento], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Reason_for_Conversion_Failure])) AS [Reason_for_Conversion_Failure], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Tag])) AS [Tag], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Proveedor_1])) AS [Proveedor_1], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Ad_Campaign_Name])) AS [Ad_Campaign_Name], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Proveedor_2])) AS [Proveedor_2], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Layout])) AS [Layout], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Costo_Tercer_Equipo])) AS [Costo_Tercer_Equipo], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Equipo])) AS [Equipo], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Necesita_permisos])) AS [Necesita_permisos], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Motivo_de_rechazo])) AS [Motivo_de_rechazo], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Keyword])) AS [Keyword], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Costo_Troncal])) AS [Costo_Troncal], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Requiere_permisos])) AS [Requiere_permisos], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Antenas])) AS [Antenas], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Moitvo_de_Perdida])) AS [Moitvo_de_Perdida], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Overall_Sales_Duration])) AS [Overall_Sales_Duration], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Alta_Prioridad])) AS [Alta_Prioridad], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Equipo_Fibra_ADN1])) AS [Equipo_Fibra_ADN1], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Materiales])) AS [Materiales], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Lead_Conversion_Time])) AS [Lead_Conversion_Time], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Aprobaci_n_Comercial])) AS [Aprobaci_n_Comercial], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Drop_Internet_IPTV])) AS [Drop_Internet_IPTV], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Nodo_Factible])) AS [Nodo_Factible], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Drop_Triple_Play])) AS [Drop_Triple_Play], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Search_Partner_Network])) AS [Search_Partner_Network], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Ad])) AS [Ad], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Description])) AS [Description], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Viaticos_ISP_1])) AS [Viaticos_ISP_1], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Total_General_1])) AS [Total_General_1], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Created_By])) AS [Created_By], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Servicio_Asim_trico])) AS [Servicio_Asim_trico], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Consecutivo])) AS [Consecutivo], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Costo_Recurrente_ISP_Externo_2])) AS [Costo_Recurrente_ISP_Externo_2], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Router])) AS [Router], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Costo_Double_Play])) AS [Costo_Double_Play], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Costo_Drop])) AS [Costo_Drop], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Tiempo_Estimado])) AS [Tiempo_Estimado], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Cost_per_Click])) AS [Cost_per_Click], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Plazo_ISP_1])) AS [Plazo_ISP_1], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Ad_Network])) AS [Ad_Network], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Plazo_ISP_2])) AS [Plazo_ISP_2], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Viaticos_Extras_2])) AS [Viaticos_Extras_2], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Viaticos_Extras_3])) AS [Viaticos_Extras_3], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Materiales_2])) AS [Materiales_2], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Costo_No_Recurrente_ISP_Externo_2])) AS [Costo_No_Recurrente_ISP_Externo_2], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Materiales_3])) AS [Materiales_3], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Costo_Segundo_Equipo])) AS [Costo_Segundo_Equipo], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Costo_Tiple_Play])) AS [Costo_Tiple_Play], ctl.fn_Texto(CONVERT(nvarchar(max), d.[Total_General_2])) AS [Total_General_2] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER), N'{}') AS [AtributosExtendidos],
               CAST(ISNULL(d.[deleted], 0) AS int) AS [o_Eliminado],
               TRY_CONVERT(decimal(19,6), TRY_CONVERT(decimal(19,6), ctl.fn_PrimerNumero(CONVERT(nvarchar(255), d.[Exchange_Rate])))) AS [d_TipoCambio]
        FROM Zoho_Mirror.dbo.[Deals] d
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[ContactoId]) END AS Id FROM core.Contacto zref WHERE zref.[ContactoCrmId] = ctl.fn_Texto(CONVERT(nvarchar(max), d.[Contact_Name]))) fk_ContactoId_0
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[ServicioId]) END AS Id FROM core.Servicio zref WHERE zref.[CuentaCrmId] = ctl.fn_Texto(CONVERT(nvarchar(max), d.[Account_Name]))) fk_ServicioId_0
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[UsuarioId]) END AS Id FROM ref.Usuario zref WHERE zref.[ZohoUsuarioId] = ctl.fn_Texto(CONVERT(nvarchar(max), d.[Owner])) OR zref.[NombreCompleto] = ctl.fn_Texto(CONVERT(nvarchar(max), d.[Owner]))) fk_PropietarioUsuarioId_0
        ) q
        OUTER APPLY (SELECT TOP 1 t.Venta FROM ref.TipoCambio t WHERE t.Fecha <= CAST(COALESCE(q.FechaModificacionOrigen, q.FechaCreacionOrigen) AS date) ORDER BY t.Fecha DESC) tc
        CROSS APPLY (SELECT CASE q.Moneda WHEN 'CRC' THEN CAST(1 AS decimal(19,6)) WHEN 'USD' THEN COALESCE(tc.Venta, CASE WHEN q.d_TipoCambio > 1 THEN q.d_TipoCambio END) END AS Tasa) tx
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);
    /* Conciliación: llaves leídas, para comprobar al final que toda fila excluida tiene su motivo en ctl.Descarte */
    DROP TABLE IF EXISTS #leidas;
    SELECT DISTINCT FuenteTabla, FuenteLlave INTO #leidas FROM #src;

    /* 2. Filtros de carga: filas excluidas con la regla que las excluye (DD-06) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'DD-06', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'Registro marcado como eliminado en el origen (deleted = 1)', @Ahora FROM #src s WHERE s.o_Eliminado = 1
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'DD-06' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE s FROM #src s WHERE s.o_Eliminado = 1;
    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'OportunidadCrmId obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[OportunidadCrmId] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FuenteLlave obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FuenteLlave] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE FROM #src WHERE [OportunidadCrmId] IS NULL OR [FuenteLlave] IS NULL;

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
    SELECT t.[OportunidadId] AS RegistroId, t.FuenteLlave, (SELECT t.[OportunidadCrmId], t.[ServicioId], t.[ContactoId], t.[Nombre], t.[Etapa], t.[Probabilidad], t.[Moneda], t.[TipoCambio], t.[Monto], t.[MontoCRC], t.[FechaCierre], t.[Segmento], t.[PropietarioUsuarioId], t.[AtributosExtendidos], t.[FechaCreacionOrigen], t.[FechaModificacionOrigen], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.Oportunidad t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato);

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.Oportunidad WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato)) THEN
        UPDATE SET t.[FechaModificacionOrigen] = s.[FechaModificacionOrigen], t.[FechaCierre] = s.[FechaCierre], t.[Nombre] = s.[Nombre], t.[Segmento] = s.[Segmento], t.[Probabilidad] = s.[Probabilidad], t.[Monto] = s.[Monto], t.[FechaCreacionOrigen] = s.[FechaCreacionOrigen], t.[OportunidadCrmId] = s.[OportunidadCrmId], t.[Etapa] = s.[Etapa], t.[Moneda] = s.[Moneda], t.[ContactoId] = s.[ContactoId], t.[ServicioId] = s.[ServicioId], t.[PropietarioUsuarioId] = s.[PropietarioUsuarioId], t.[AtributosExtendidos] = s.[AtributosExtendidos], t.[MontoCRC] = s.[MontoCRC], t.[TipoCambio] = s.[TipoCambio], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([FechaModificacionOrigen], [FechaCierre], [Nombre], [Segmento], [Probabilidad], [Monto], [FechaCreacionOrigen], [OportunidadCrmId], [Etapa], [Moneda], [ContactoId], [ServicioId], [PropietarioUsuarioId], [AtributosExtendidos], [MontoCRC], [TipoCambio], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[FechaModificacionOrigen], s.[FechaCierre], s.[Nombre], s.[Segmento], s.[Probabilidad], s.[Monto], s.[FechaCreacionOrigen], s.[OportunidadCrmId], s.[Etapa], s.[Moneda], s.[ContactoId], s.[ServicioId], s.[PropietarioUsuarioId], s.[AtributosExtendidos], s.[MontoCRC], s.[TipoCambio], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[OportunidadId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.Oportunidad', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.Oportunidad', t.[OportunidadId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.Oportunidad t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.Oportunidad', t.[OportunidadId], N'ContactoId', LEFT(CONVERT(nvarchar(400), s.o_ContactoId), 400), N'Referencia sin correspondencia única en core.Contacto'
    FROM #src s JOIN core.Oportunidad t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_ContactoId IS NOT NULL AND s.[ContactoId] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.Oportunidad', t.[OportunidadId], N'ServicioId', LEFT(CONVERT(nvarchar(400), s.o_ServicioId), 400), N'Referencia sin correspondencia única en core.Servicio'
    FROM #src s JOIN core.Oportunidad t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_ServicioId IS NOT NULL AND s.[ServicioId] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.Oportunidad', t.[OportunidadId], N'PropietarioUsuarioId', LEFT(CONVERT(nvarchar(400), s.o_PropietarioUsuarioId), 400), N'Referencia sin correspondencia única en ref.Usuario'
    FROM #src s JOIN core.Oportunidad t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_PropietarioUsuarioId IS NOT NULL AND s.[PropietarioUsuarioId] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.Oportunidad', t.[OportunidadId], N'FechaModificacionOrigen', LEFT(CONVERT(nvarchar(400), s.o_FechaModificacionOrigen), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.Oportunidad t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaModificacionOrigen IS NOT NULL AND s.[FechaModificacionOrigen] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.Oportunidad', t.[OportunidadId], N'FechaCierre', LEFT(CONVERT(nvarchar(400), s.o_FechaCierre), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.Oportunidad t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaCierre IS NOT NULL AND s.[FechaCierre] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-04', N'core.Oportunidad', t.[OportunidadId], N'Monto', LEFT(CONVERT(nvarchar(400), s.o_Monto), 400), N'Monto ilegible; se conserva el texto original'
    FROM #src s JOIN core.Oportunidad t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Monto IS NOT NULL AND s.[Monto] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.Oportunidad', t.[OportunidadId], N'FechaCreacionOrigen', LEFT(CONVERT(nvarchar(400), s.o_FechaCreacionOrigen), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.Oportunidad t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaCreacionOrigen IS NOT NULL AND s.[FechaCreacionOrigen] IS NULL;

    /* 7. Conciliación: leídas = válidas + excluidas; cada llave excluida debe tener su motivo en ctl.Descarte
       (de este lote o de un lote exitoso anterior). Las repetidas (DD) conservan su llave en una fila válida. */
    DECLARE @SinMotivo bigint = (
        SELECT COUNT_BIG(*) FROM #leidas r
        WHERE NOT EXISTS (SELECT 1 FROM #src s WHERE s.FuenteTabla = r.FuenteTabla
                          AND (s.FuenteLlave = r.FuenteLlave OR (s.FuenteLlave IS NULL AND r.FuenteLlave IS NULL)))
          AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x LEFT JOIN ctl.Lote l ON l.LoteId = x.LoteId
                          WHERE x.FuenteTabla = r.FuenteTabla
                            AND (x.FuenteLlave = r.FuenteLlave OR (x.FuenteLlave IS NULL AND r.FuenteLlave IS NULL AND x.LoteId = @LoteId))
                            AND (x.LoteId = @LoteId OR l.Estado = 'Exitoso')));
    SELECT @Leidas AS FilasLeidas, @Validas - (SELECT COUNT_BIG(*) FROM #cambios) AS FilasSinCambio,
           @Leidas - @Validas AS FilasExcluidas, @SinMotivo AS LlavesSinMotivo;
END;
GO
