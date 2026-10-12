USE ADN_Unificado;
GO
/* Paso 220 · core_Servicio → core.Servicio
   Servicios = cuentas del CRM (D2): Accounts_Extended es la fuente principal; la tabla completa Accounts solo aporta cuentas ausentes (marcadas con anomalía D2). El cliente se asigna en el paso core_Servicio_Cliente.
   Reglas: ID-01, ID-04, D2, D4, D5, ES-01, ES-02, ES-04, ES-05, ES-07, ES-08, DD-02, DD-06, IN-01, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_Servicio @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 0. Preparación */
    /* Cantidad de cuentas por circuito normalizado (para marcar circuitos compartidos) */
    DROP TABLE IF EXISTS #cc;
    SELECT Circ, COUNT(*) AS Cuentas INTO #cc FROM (
        SELECT ctl.fn_Circuito(N_mero_Circuito) AS Circ FROM Zoho_Mirror.dbo.Accounts_Extended
        UNION ALL
        SELECT ctl.fn_Circuito(b.N_mero_Circuito) FROM Zoho_Mirror.dbo.Accounts b
        WHERE ISNULL(b.deleted, 0) = 0 AND NOT EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.Accounts_Extended e WHERE e.id = b.id)) x
    WHERE Circ IS NOT NULL GROUP BY Circ;
    CREATE UNIQUE CLUSTERED INDEX ix_cc ON #cc (Circ);

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT CAST(q.[Circuito] AS varchar(12)) COLLATE DATABASE_DEFAULT AS [Circuito],
           CAST(q.[CuentaCrmId] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [CuentaCrmId],
           CAST(q.[NombreCuenta] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [NombreCuenta],
           CAST(q.[TipoCuenta] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [TipoCuenta],
           CAST(q.[Estado] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Estado],
           CAST(q.[Plataforma] AS nvarchar(100)) COLLATE DATABASE_DEFAULT AS [Plataforma],
           q.[CapacidadMbps],
           q.[TieneIPTV],
           q.[TieneVoIP],
           CAST(q.[NumeroTroncal] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [NumeroTroncal],
           CAST(q.[LineaDID] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [LineaDID],
           CAST(q.[Moneda] AS char(3)) COLLATE DATABASE_DEFAULT AS [Moneda],
           q.[TipoCambio],
           q.[Mensualidad],
           q.[MensualidadCRC],
           q.[DistritoId],
           CAST(q.[Provincia] AS nvarchar(60)) COLLATE DATABASE_DEFAULT AS [Provincia],
           CAST(q.[Canton] AS nvarchar(80)) COLLATE DATABASE_DEFAULT AS [Canton],
           CAST(q.[DistritoTexto] AS nvarchar(80)) COLLATE DATABASE_DEFAULT AS [DistritoTexto],
           CAST(q.[DireccionExacta] AS nvarchar(1000)) COLLATE DATABASE_DEFAULT AS [DireccionExacta],
           q.[Latitud],
           q.[Longitud],
           q.[CondominioId],
           q.[EjecutivoUsuarioId],
           q.[FechaInstalacion],
           q.[FechaActivacion],
           q.[FechaRetiro],
           CAST(q.[EstadoCorrespondencia] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [EstadoCorrespondencia],
           q.[AtributosExtendidos] COLLATE DATABASE_DEFAULT AS [AtributosExtendidos],
           q.[FechaCreacionOrigen],
           q.[FechaModificacionOrigen],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[Circuito]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[CuentaCrmId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[NombreCuenta]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TipoCuenta]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Estado]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Plataforma]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[CapacidadMbps]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TieneIPTV]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TieneVoIP]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[NumeroTroncal]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[LineaDID]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Moneda]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TipoCambio]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Mensualidad]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[MensualidadCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[DistritoId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Provincia]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Canton]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[DistritoTexto]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[DireccionExacta]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Latitud]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Longitud]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[CondominioId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[EjecutivoUsuarioId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaInstalacion], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaActivacion], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaRetiro], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[EstadoCorrespondencia]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[AtributosExtendidos]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaCreacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaModificacionOrigen], 126), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_Eliminado],
           q.[o_Circuito],
           q.[o_Mensualidad],
           q.[o_Coordenadas],
           q.[o_Condominio],
           q.[o_Ejecutivo],
           q.[o_CircuitoCuentas],
           CONCAT_WS(N',', CASE WHEN LEN(q.[Circuito]) > 12 THEN N'Circuito' END, CASE WHEN LEN(q.[CuentaCrmId]) > 30 THEN N'CuentaCrmId' END, CASE WHEN LEN(q.[NombreCuenta]) > 200 THEN N'NombreCuenta' END, CASE WHEN LEN(q.[TipoCuenta]) > 50 THEN N'TipoCuenta' END, CASE WHEN LEN(q.[Estado]) > 50 THEN N'Estado' END, CASE WHEN LEN(q.[Plataforma]) > 100 THEN N'Plataforma' END, CASE WHEN LEN(q.[NumeroTroncal]) > 50 THEN N'NumeroTroncal' END, CASE WHEN LEN(q.[LineaDID]) > 50 THEN N'LineaDID' END, CASE WHEN LEN(q.[Moneda]) > 3 THEN N'Moneda' END, CASE WHEN LEN(q.[Provincia]) > 60 THEN N'Provincia' END, CASE WHEN LEN(q.[Canton]) > 80 THEN N'Canton' END, CASE WHEN LEN(q.[DistritoTexto]) > 80 THEN N'DistritoTexto' END, CASE WHEN LEN(q.[DireccionExacta]) > 1000 THEN N'DireccionExacta' END, CASE WHEN LEN(q.[EstadoCorrespondencia]) > 20 THEN N'EstadoCorrespondencia' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT q.*,
               CASE q.Moneda WHEN 'CRC' THEN CAST(1 AS decimal(19,6)) WHEN 'USD' THEN tc.Venta END AS TipoCambio,
               CASE q.Moneda WHEN 'CRC' THEN q.Mensualidad WHEN 'USD' THEN CAST(q.Mensualidad * tc.Venta AS decimal(19,4)) END AS MensualidadCRC,
               d.DistritoId, co.CondominioId, us.UsuarioId AS EjecutivoUsuarioId, cc.Cuentas AS o_CircuitoCuentas
        FROM (
            SELECT 'ZohoCRM' AS FuenteSistema, N'Zoho_Mirror' AS FuenteBase, N'Accounts_Extended' AS FuenteTabla, a.id AS FuenteLlave,
                   ctl.fn_FechaCR(CONVERT(nvarchar(30), a.Created_Time, 126)) AS FechaDato,
                   ctl.fn_Circuito(a.N_mero_Circuito) AS Circuito, a.id AS CuentaCrmId, ctl.fn_Texto(a.Account_Name) AS NombreCuenta,
                   ctl.fn_Texto(a.Account_Type) AS TipoCuenta, ctl.fn_Texto(a.Estado) AS Estado, ctl.fn_Texto(a.Plataforma_de_servicio) AS Plataforma,
                   CAST(ctl.fn_PrimerNumero(a.Capacidad_MPBS) AS decimal(9,2)) AS CapacidadMbps, a.IPTV AS TieneIPTV,
                   CASE WHEN a.Telefon_a = 1 OR a.VoIP_B2C = 1 THEN CAST(1 AS bit) WHEN a.Telefon_a = 0 OR a.VoIP_B2C = 0 THEN CAST(0 AS bit) END AS TieneVoIP,
                   ctl.fn_Texto(a.Numero_Troncal) AS NumeroTroncal, ctl.fn_Texto(a.Line_DID) AS LineaDID,
                   COALESCE(ctl.fn_MonedaTexto(a.Mensualidad), ctl.fn_Moneda(a.Currency)) AS Moneda,
                   ctl.fn_MontoLibre(a.Mensualidad) AS Mensualidad,
                   ctl.fn_Texto(a.Provincia) AS Provincia, ctl.fn_Texto(a.Cant_n) AS Canton, ctl.fn_Texto(a.Distritos) AS DistritoTexto,
                   ctl.fn_Texto(a.Direcci_n_Exacta) AS DireccionExacta,
                   COALESCE(ctl.fn_CoordenadaSola(CONVERT(nvarchar(60), a.latitude), 1), ctl.fn_Coordenada(a.coordinates, 1)) AS Latitud,
                   COALESCE(ctl.fn_CoordenadaSola(CONVERT(nvarchar(60), a.longitude), 2), ctl.fn_Coordenada(a.coordinates, 2)) AS Longitud,
                   ctl.fn_Texto(a.Condominio_C) AS o_Condominio, ctl.fn_Texto(a.Ejecutivo_Asignado) AS o_Ejecutivo,
                   ctl.fn_FechaDia(CONVERT(nvarchar(30), a.Fecha_de_instalaci_n, 23)) AS FechaInstalacion, ctl.fn_FechaCR(CONVERT(nvarchar(30), a.Fecha_Confirmacion, 126)) AS FechaActivacion,
                   ctl.fn_FechaDia(CONVERT(nvarchar(30), a.Fecha_de_Retiro, 23)) AS FechaRetiro,
                   'CRM' AS EstadoCorrespondencia,
                   NULLIF((SELECT ctl.fn_Texto(CONVERT(nvarchar(max), a.[Owner])) AS [Owner], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Created_By])) AS [Created_By], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Modified_By])) AS [Modified_By], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Last_Activity_Time])) AS [Last_Activity_Time], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Parent_Account])) AS [Parent_Account], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Aceptacion_Estudio_Wifi])) AS [Aceptacion_Estudio_Wifi], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Agent])) AS [Agent], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Antigua_Legal_ID1])) AS [Antigua_Legal_ID1], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Antigua_Razon_Social])) AS [Antigua_Razon_Social], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Aprovisionado])) AS [Aprovisionado], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Aprovisionamiento_Aumentos])) AS [Aprovisionamiento_Aumentos], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Aprovisionamiento_Cambio_Plataforma])) AS [Aprovisionamiento_Cambio_Plataforma], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Aprovisionamiento_Disminucion])) AS [Aprovisionamiento_Disminucion], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Aprovisionamiento_Enlace_Backup])) AS [Aprovisionamiento_Enlace_Backup], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Aprovisionamiento_IPTV])) AS [Aprovisionamiento_IPTV], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Aprovisionamiento_IP_Adicional])) AS [Aprovisionamiento_IP_Adicional], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Aprovisionamiento_Servicio_Administrado])) AS [Aprovisionamiento_Servicio_Administrado], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Aprovisionamiento_Servicio_WiFi_Administrado])) AS [Aprovisionamiento_Servicio_WiFi_Administrado], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Aprovisionamiento_Traslado])) AS [Aprovisionamiento_Traslado], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Aprovisionamiento_VoIP])) AS [Aprovisionamiento_VoIP], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Cambio_Razon_Social])) AS [Cambio_Razon_Social], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Cantidad_de_DIDs])) AS [Cantidad_de_DIDs], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Capacity_ISP_External_Mbps])) AS [Capacity_ISP_External_Mbps], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Cargo_Autom_tico])) AS [Cargo_Autom_tico], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Causa_de_retenci_n])) AS [Causa_de_retenci_n], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Check_CPostal])) AS [Check_CPostal], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Codigo_Postal])) AS [Codigo_Postal], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Cortesia])) AS [Cortesia], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Courtesy_Type])) AS [Courtesy_Type], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Discard])) AS [Discard], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Enrich_Status__s])) AS [Enrich_Status__s], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Enviar_notificaci_n])) AS [Enviar_notificaci_n], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Est_Act_de_Acc])) AS [Est_Act_de_Acc], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Estrategia_Segmento])) AS [Estrategia_Segmento], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Expiration_Date_ISP_Extenal])) AS [Expiration_Date_ISP_Extenal], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Fech_Act_Est_Actual_Acc])) AS [Fech_Act_Est_Actual_Acc], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Fecha_Aprovisionamiento_Aumentos])) AS [Fecha_Aprovisionamiento_Aumentos], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Fecha_Aprovisionamiento_Cambio_Plataforma])) AS [Fecha_Aprovisionamiento_Cambio_Plataforma], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Fecha_Aprovisionamiento_Disminucion])) AS [Fecha_Aprovisionamiento_Disminucion], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Fecha_Aprovisionamiento_Enlace_Backup])) AS [Fecha_Aprovisionamiento_Enlace_Backup], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Fecha_Aprovisionamiento_IPTV])) AS [Fecha_Aprovisionamiento_IPTV], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Fecha_Aprovisionamiento_IP_Adicional])) AS [Fecha_Aprovisionamiento_IP_Adicional], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Fecha_Aprovisionamiento_Servicio_WiFi_Administrado])) AS [Fecha_Aprovisionamiento_Servicio_WiFi_Administrado], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Fecha_Aprovisionamiento_Traslado])) AS [Fecha_Aprovisionamiento_Traslado], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Fecha_Aprovisionamiento_VoIP])) AS [Fecha_Aprovisionamiento_VoIP], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Fecha_Conversion])) AS [Fecha_Conversion], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Fecha_de_Cierre])) AS [Fecha_de_Cierre], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Fecha_de_Desconexion_Temporal])) AS [Fecha_de_Desconexion_Temporal], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Fecha_de_Ingreso])) AS [Fecha_de_Ingreso], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Fecha_de_Reconexion])) AS [Fecha_de_Reconexion], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Fuente_de_Ingreso])) AS [Fuente_de_Ingreso], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Gain_ADN])) AS [Gain_ADN], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Hora_Cambio_Estado])) AS [Hora_Cambio_Estado], ctl.fn_Texto(CONVERT(nvarchar(max), a.[ID_ISP])) AS [ID_ISP], ctl.fn_Texto(CONVERT(nvarchar(max), a.[ISP_Externo])) AS [ISP_Externo], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Identifiacion_2])) AS [Identifiacion_2], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Last_Update_ACC])) AS [Last_Update_ACC], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Link_Prtg])) AS [Link_Prtg], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Locked__s])) AS [Locked__s], ctl.fn_Texto(CONVERT(nvarchar(max), a.[MRC_Client])) AS [MRC_Client], ctl.fn_Texto(CONVERT(nvarchar(max), a.[MRC_ISP])) AS [MRC_ISP], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Menos_de_3_Meses])) AS [Menos_de_3_Meses], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Motivo_de_retenci_n])) AS [Motivo_de_retenci_n], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Municipalidad])) AS [Municipalidad], ctl.fn_Texto(CONVERT(nvarchar(max), a.[No_Sensor])) AS [No_Sensor], ctl.fn_Texto(CONVERT(nvarchar(max), a.[No_Sensor_Reason])) AS [No_Sensor_Reason], ctl.fn_Texto(CONVERT(nvarchar(max), a.[No_Sensor_Reason_Lista])) AS [No_Sensor_Reason_Lista], ctl.fn_Texto(CONVERT(nvarchar(max), a.[No_Sensor_Reason_Lista1])) AS [No_Sensor_Reason_Lista1], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Nodo_Dispobile])) AS [Nodo_Dispobile], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Nueva_Cuenta])) AS [Nueva_Cuenta], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Ownership])) AS [Ownership], ctl.fn_Texto(CONVERT(nvarchar(max), a.[PRUEBA_KIM])) AS [PRUEBA_KIM], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Pago_realizado])) AS [Pago_realizado], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Paquete_Minutos_Celular])) AS [Paquete_Minutos_Celular], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Paquete_Minutos_Fijo])) AS [Paquete_Minutos_Fijo], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Paused_Sensor])) AS [Paused_Sensor], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Peaje])) AS [Peaje], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Peajes])) AS [Peajes], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Platform_ISP_External])) AS [Platform_ISP_External], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Proveedor_IPTV])) AS [Proveedor_IPTV], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Provisioned_date])) AS [Provisioned_date], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Rate])) AS [Rate], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Referencia])) AS [Referencia], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Referido_por])) AS [Referido_por], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Retenci_n_Status])) AS [Retenci_n_Status], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Segmentacion_B2B])) AS [Segmentacion_B2B], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Segmentacion_Residencial])) AS [Segmentacion_Residencial], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Site])) AS [Site], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Tag])) AS [Tag], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Tiempo_des_meses])) AS [Tiempo_des_meses], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Tipo])) AS [Tipo], ctl.fn_Texto(CONVERT(nvarchar(max), a.[Zona_Cobertura])) AS [Zona_Cobertura], ctl.fn_Texto(CONVERT(nvarchar(max), a.[cost_by_mbps])) AS [cost_by_mbps], ctl.fn_Texto(CONVERT(nvarchar(max), a.[ftth])) AS [ftth], ctl.fn_Texto(CONVERT(nvarchar(max), a.[NotesCount])) AS [NotesCount] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER), N'{}') AS AtributosExtendidos,
                   ctl.fn_FechaCR(CONVERT(nvarchar(30), a.Created_Time, 126)) AS FechaCreacionOrigen, ctl.fn_FechaCR(CONVERT(nvarchar(30), a.Modified_Time, 126)) AS FechaModificacionOrigen,
                   0 AS o_Eliminado, ctl.fn_Texto(a.N_mero_Circuito) AS o_Circuito, ctl.fn_Texto(a.Mensualidad) AS o_Mensualidad,
                   ctl.fn_CoordenadaTexto(a.coordinates) AS o_Coordenadas
            FROM Zoho_Mirror.dbo.Accounts_Extended a
            UNION ALL
            SELECT 'ZohoCRM', N'Zoho_Mirror', N'Accounts', b.id, ctl.fn_FechaCR(b.Created_Time),
                   ctl.fn_Circuito(b.N_mero_Circuito), b.id, ctl.fn_Texto(b.Account_Name), ctl.fn_Texto(b.Account_Type), ctl.fn_Texto(b.Estado),
                   NULL, NULL, ctl.fn_Bit(b.IPTV),
                   CASE WHEN ctl.fn_Bit(b.Telefon_a) = 1 OR ctl.fn_Bit(b.VoIP_B2C) = 1 THEN CAST(1 AS bit)
                        WHEN ctl.fn_Bit(b.Telefon_a) = 0 OR ctl.fn_Bit(b.VoIP_B2C) = 0 THEN CAST(0 AS bit) END,
                   ctl.fn_Texto(b.Numero_Troncal), ctl.fn_Texto(b.Line_DID), ctl.fn_Moneda(b.Currency), NULL,
                   ctl.fn_Texto(b.Provincia), ctl.fn_Texto(b.Cant_n), ctl.fn_Texto(b.Distritos), ctl.fn_Texto(CONVERT(nvarchar(max), b.Direcci_n_Exacta)),
                   ctl.fn_Coordenada(b.Coordenadas, 1), ctl.fn_Coordenada(b.Coordenadas, 2),
                   ctl.fn_Texto(b.Condominio_C), ctl.fn_Texto(b.Ejecutivo_Asignado),
                   NULL, ctl.fn_FechaCR(b.Fecha_Confirmacion), ctl.fn_FechaDia(b.Fecha_de_Retiro), 'CRM',
                   NULLIF((SELECT ctl.fn_Texto(CONVERT(nvarchar(max), b.[Identifiacion_2])) AS [Identifiacion_2], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Penetraci_n])) AS [Penetraci_n], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Antigua_Legal_ID1])) AS [Antigua_Legal_ID1], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Parent_Account])) AS [Parent_Account], ctl.fn_Texto(CONVERT(nvarchar(max), b.[MRC_ISP])) AS [MRC_ISP], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Sobre_consumo])) AS [Sobre_consumo], ctl.fn_Texto(CONVERT(nvarchar(max), b.[High_Consumption_Status])) AS [High_Consumption_Status], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Fecha_Aprovisionamiento_Enlace_Backup])) AS [Fecha_Aprovisionamiento_Enlace_Backup], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Segmentacion_Residencial])) AS [Segmentacion_Residencial], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Cantidad_de_Casas])) AS [Cantidad_de_Casas], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Cambio_Razon_Social])) AS [Cambio_Razon_Social], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Aprovisionamiento_IP_Adicional])) AS [Aprovisionamiento_IP_Adicional], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Segmentacion_B2B])) AS [Segmentacion_B2B], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Fecha_Aprovisionamiento_Disminucion])) AS [Fecha_Aprovisionamiento_Disminucion], ctl.fn_Texto(CONVERT(nvarchar(max), b.[From_Odoo])) AS [From_Odoo], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Modified_By])) AS [Modified_By], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Fecha_Aprovisionamiento_Cambio_Plataforma])) AS [Fecha_Aprovisionamiento_Cambio_Plataforma], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Fecha_Aprovisionamiento_Servicio_WiFi_Administrado])) AS [Fecha_Aprovisionamiento_Servicio_WiFi_Administrado], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Created_in_CRM])) AS [Created_in_CRM], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Cortesia])) AS [Cortesia], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Ownership])) AS [Ownership], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Fecha_Aprovisionamiento_VoIP])) AS [Fecha_Aprovisionamiento_VoIP], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Aprovisionamiento_VoIP])) AS [Aprovisionamiento_VoIP], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Paquete_Minutos_Fijo])) AS [Paquete_Minutos_Fijo], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Peaje])) AS [Peaje], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Fecha_Aprovisionamiento_Aumentos])) AS [Fecha_Aprovisionamiento_Aumentos], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Estado_del_Proyecto])) AS [Estado_del_Proyecto], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Cantidad_de_Clientes])) AS [Cantidad_de_Clientes], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Nombre_Persona])) AS [Nombre_Persona], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Discard])) AS [Discard], ctl.fn_Texto(CONVERT(nvarchar(max), b.[No_Sensor])) AS [No_Sensor], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Enrich_Status__s])) AS [Enrich_Status__s], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Condominio])) AS [Condominio], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Aprovisionamiento_IPTV])) AS [Aprovisionamiento_IPTV], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Aprovisionamiento_Traslado])) AS [Aprovisionamiento_Traslado], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Odoo_Sync])) AS [Odoo_Sync], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Last_Activity_Time])) AS [Last_Activity_Time], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Actualizaci_n])) AS [Actualizaci_n], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Lead_Agent])) AS [Lead_Agent], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Link_Prtg])) AS [Link_Prtg], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Nodo_Dispobile])) AS [Nodo_Dispobile], ctl.fn_Texto(CONVERT(nvarchar(max), b.[ISP_Externo])) AS [ISP_Externo], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Non_Payment])) AS [Non_Payment], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Estrategia_Segmento])) AS [Estrategia_Segmento], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Estudio_WiFi_B2C])) AS [Estudio_WiFi_B2C], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Last_Enriched_Time__s])) AS [Last_Enriched_Time__s], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Tag])) AS [Tag], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Ingreso_Condominio])) AS [Ingreso_Condominio], ctl.fn_Texto(CONVERT(nvarchar(max), b.[s])) AS [s], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Tipo])) AS [Tipo], ctl.fn_Texto(CONVERT(nvarchar(max), b.[No_Sensor_Reason_Lista1])) AS [No_Sensor_Reason_Lista1], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Fecha_Activacion_Addendum])) AS [Fecha_Activacion_Addendum], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Peajes])) AS [Peajes], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Fecha_Conversion])) AS [Fecha_Conversion], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Paused_Sensor])) AS [Paused_Sensor], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Municipalidad])) AS [Municipalidad], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Antigua_Razon_Social])) AS [Antigua_Razon_Social], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Aprovisionamiento_Disminucion])) AS [Aprovisionamiento_Disminucion], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Courtesy_Type])) AS [Courtesy_Type], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Aprovisionamiento_Servicio_WiFi_Administrado])) AS [Aprovisionamiento_Servicio_WiFi_Administrado], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Referencia])) AS [Referencia], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Aprovisionamiento_Cambio_Plataforma])) AS [Aprovisionamiento_Cambio_Plataforma], ctl.fn_Texto(CONVERT(nvarchar(max), b.[No_Sensor_Reason])) AS [No_Sensor_Reason], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Pago_realizado])) AS [Pago_realizado], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Aprovisionamiento_Aumentos])) AS [Aprovisionamiento_Aumentos], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Fuente_de_Ingreso])) AS [Fuente_de_Ingreso], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Site])) AS [Site], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Nueva_Cuenta])) AS [Nueva_Cuenta], ctl.fn_Texto(CONVERT(nvarchar(max), b.[ID_ISP])) AS [ID_ISP], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Created_By])) AS [Created_By], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Zona_Cobertura])) AS [Zona_Cobertura], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Paquete_Minutos_Celular])) AS [Paquete_Minutos_Celular], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Fecha_Aprovisionamiento_IPTV])) AS [Fecha_Aprovisionamiento_IPTV], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Env_o_de_Factura])) AS [Env_o_de_Factura], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Rate])) AS [Rate], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Provisioned_date])) AS [Provisioned_date], ctl.fn_Texto(CONVERT(nvarchar(max), b.[No_Sensor_Reason_Lista])) AS [No_Sensor_Reason_Lista], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Aprovisionamiento_Enlace_Backup])) AS [Aprovisionamiento_Enlace_Backup], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Fecha_Aprovisionamiento_Traslado])) AS [Fecha_Aprovisionamiento_Traslado], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Proveedor_IPTV])) AS [Proveedor_IPTV], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Prioridad_de_atencion])) AS [Prioridad_de_atencion], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Fecha_Aprovisionamiento_IP_Adicional])) AS [Fecha_Aprovisionamiento_IP_Adicional], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Aprovisionado])) AS [Aprovisionado], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Proyecto])) AS [Proyecto], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Owner])) AS [Owner], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Fecha_Activacion_Contrato])) AS [Fecha_Activacion_Contrato], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Referido_por])) AS [Referido_por], ctl.fn_Texto(CONVERT(nvarchar(max), b.[in_odoo])) AS [in_odoo], ctl.fn_Texto(CONVERT(nvarchar(max), b.[Codigo_Postal])) AS [Codigo_Postal] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER), N'{}'),
                   ctl.fn_FechaCR(b.Created_Time), ctl.fn_FechaCR(b.Modified_Time),
                   CAST(ISNULL(b.deleted, 0) AS int), ctl.fn_Texto(b.N_mero_Circuito), NULL, ctl.fn_CoordenadaTexto(b.Coordenadas)
            FROM Zoho_Mirror.dbo.Accounts b
            WHERE NOT EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.Accounts_Extended e WHERE e.id = b.id)
        ) q
        LEFT JOIN #cc cc ON cc.Circ = q.Circuito
        OUTER APPLY (SELECT TOP 1 t.Venta FROM ref.TipoCambio t WHERE t.Fecha <= CAST(COALESCE(q.FechaModificacionOrigen, q.FechaCreacionOrigen) AS date) ORDER BY t.Fecha DESC) tc
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(d0.DistritoId) END AS DistritoId FROM ref.Distrito d0 JOIN ref.Canton c0 ON c0.CantonId = d0.CantonId
                     WHERE d0.Nombre = q.DistritoTexto AND c0.Nombre = q.Canton) d
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(c1.CondominioId) END AS CondominioId FROM core.Condominio c1
                     WHERE c1.CondominioCrmId = q.o_Condominio OR c1.Nombre = q.o_Condominio) co
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(u1.UsuarioId) END AS UsuarioId FROM ref.Usuario u1
                     WHERE u1.ZohoUsuarioId = q.o_Ejecutivo OR u1.NombreCompleto = q.o_Ejecutivo) us
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 2. Filtros de carga: filas excluidas con la regla que las excluye (DD-06) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'DD-06', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'Cuenta marcada como eliminada en Zoho (deleted = 1)', @Ahora FROM #src s WHERE s.o_Eliminado = 1
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'DD-06' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE s FROM #src s WHERE s.o_Eliminado = 1;
    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'EstadoCorrespondencia obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[EstadoCorrespondencia] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FuenteLlave obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FuenteLlave] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE FROM #src WHERE [EstadoCorrespondencia] IS NULL OR [FuenteLlave] IS NULL;

    /* 2b. Duplicados por la llave del paso (DD-02); el orden es determinista */
    ;WITH r AS (
        SELECT s.FuenteSistema, s.FuenteTabla, s.FuenteLlave,
               ROW_NUMBER() OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.FechaModificacionOrigen DESC, s.HashContenido) AS rn,
               FIRST_VALUE(s.FuenteLlave) OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.FechaModificacionOrigen DESC, s.HashContenido ROWS UNBOUNDED PRECEDING) AS Conservada
        FROM #src s)
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, LlaveConservada, Motivo, FechaDescarte)
    SELECT @LoteId, 'DD-02', r.FuenteSistema, r.FuenteTabla, r.FuenteLlave, r.Conservada, N'Versión anterior de la misma cuenta en el espejo de Zoho', @Ahora
    FROM r WHERE r.rn > 1
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'DD-02' AND x.FuenteTabla = r.FuenteTabla AND x.FuenteLlave = r.FuenteLlave);
    ;WITH r AS (
        SELECT ROW_NUMBER() OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.FechaModificacionOrigen DESC, s.HashContenido) AS rn FROM #src s)
    DELETE FROM r WHERE rn > 1;
    DECLARE @Validas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 3. Imagen previa de las filas que van a cambiar (para el rollback) */
    DROP TABLE IF EXISTS #antes;
    SELECT t.[ServicioId] AS RegistroId, t.FuenteLlave, (SELECT t.[ClienteId], t.[Circuito], t.[CuentaCrmId], t.[NombreCuenta], t.[TipoCuenta], t.[Estado], t.[Plataforma], t.[CapacidadMbps], t.[TieneIPTV], t.[TieneVoIP], t.[NumeroTroncal], t.[LineaDID], t.[Moneda], t.[TipoCambio], t.[Mensualidad], t.[MensualidadCRC], t.[DistritoId], t.[Provincia], t.[Canton], t.[DistritoTexto], t.[DireccionExacta], t.[Latitud], t.[Longitud], t.[CondominioId], t.[EjecutivoUsuarioId], t.[FechaInstalacion], t.[FechaActivacion], t.[FechaRetiro], t.[EstadoCorrespondencia], t.[AtributosExtendidos], t.[FechaCreacionOrigen], t.[FechaModificacionOrigen], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.Servicio t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido;

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.Servicio WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido) THEN
        UPDATE SET t.[Circuito] = s.[Circuito], t.[CuentaCrmId] = s.[CuentaCrmId], t.[NombreCuenta] = s.[NombreCuenta], t.[TipoCuenta] = s.[TipoCuenta], t.[Estado] = s.[Estado], t.[Plataforma] = s.[Plataforma], t.[CapacidadMbps] = s.[CapacidadMbps], t.[TieneIPTV] = s.[TieneIPTV], t.[TieneVoIP] = s.[TieneVoIP], t.[NumeroTroncal] = s.[NumeroTroncal], t.[LineaDID] = s.[LineaDID], t.[Moneda] = s.[Moneda], t.[TipoCambio] = s.[TipoCambio], t.[Mensualidad] = s.[Mensualidad], t.[MensualidadCRC] = s.[MensualidadCRC], t.[DistritoId] = s.[DistritoId], t.[Provincia] = s.[Provincia], t.[Canton] = s.[Canton], t.[DistritoTexto] = s.[DistritoTexto], t.[DireccionExacta] = s.[DireccionExacta], t.[Latitud] = s.[Latitud], t.[Longitud] = s.[Longitud], t.[CondominioId] = s.[CondominioId], t.[EjecutivoUsuarioId] = s.[EjecutivoUsuarioId], t.[FechaInstalacion] = s.[FechaInstalacion], t.[FechaActivacion] = s.[FechaActivacion], t.[FechaRetiro] = s.[FechaRetiro], t.[EstadoCorrespondencia] = s.[EstadoCorrespondencia], t.[AtributosExtendidos] = s.[AtributosExtendidos], t.[FechaCreacionOrigen] = s.[FechaCreacionOrigen], t.[FechaModificacionOrigen] = s.[FechaModificacionOrigen], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([Circuito], [CuentaCrmId], [NombreCuenta], [TipoCuenta], [Estado], [Plataforma], [CapacidadMbps], [TieneIPTV], [TieneVoIP], [NumeroTroncal], [LineaDID], [Moneda], [TipoCambio], [Mensualidad], [MensualidadCRC], [DistritoId], [Provincia], [Canton], [DistritoTexto], [DireccionExacta], [Latitud], [Longitud], [CondominioId], [EjecutivoUsuarioId], [FechaInstalacion], [FechaActivacion], [FechaRetiro], [EstadoCorrespondencia], [AtributosExtendidos], [FechaCreacionOrigen], [FechaModificacionOrigen], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[Circuito], s.[CuentaCrmId], s.[NombreCuenta], s.[TipoCuenta], s.[Estado], s.[Plataforma], s.[CapacidadMbps], s.[TieneIPTV], s.[TieneVoIP], s.[NumeroTroncal], s.[LineaDID], s.[Moneda], s.[TipoCambio], s.[Mensualidad], s.[MensualidadCRC], s.[DistritoId], s.[Provincia], s.[Canton], s.[DistritoTexto], s.[DireccionExacta], s.[Latitud], s.[Longitud], s.[CondominioId], s.[EjecutivoUsuarioId], s.[FechaInstalacion], s.[FechaActivacion], s.[FechaRetiro], s.[EstadoCorrespondencia], s.[AtributosExtendidos], s.[FechaCreacionOrigen], s.[FechaModificacionOrigen], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[ServicioId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.Servicio', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.Servicio', t.[ServicioId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.Servicio t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ID-01', N'core.Servicio', t.[ServicioId], N'Circuito', LEFT(CONVERT(nvarchar(400), s.o_Circuito), 400), N'Circuito que no cumple el patrón aprobado'
    FROM #src s JOIN core.Servicio t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Circuito IS NOT NULL AND s.Circuito IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ID-01', N'core.Servicio', t.[ServicioId], N'Circuito', LEFT(CONVERT(nvarchar(400), s.o_Circuito), 400), N'El mismo circuito normalizado está en varias cuentas'
    FROM #src s JOIN core.Servicio t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_CircuitoCuentas > 1;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-04', N'core.Servicio', t.[ServicioId], N'Mensualidad', LEFT(CONVERT(nvarchar(400), s.o_Mensualidad), 400), N'Mensualidad escrita de forma ambigua; se conserva el texto original'
    FROM #src s JOIN core.Servicio t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Mensualidad IS NOT NULL AND s.Mensualidad IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.Servicio', t.[ServicioId], N'Latitud', LEFT(CONVERT(nvarchar(400), s.o_Coordenadas), 400), N'Coordenadas ilegibles o fuera de Costa Rica'
    FROM #src s JOIN core.Servicio t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Coordenadas IS NOT NULL AND s.Latitud IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.Servicio', t.[ServicioId], N'CondominioId', LEFT(CONVERT(nvarchar(400), s.o_Condominio), 400), N'Condominio sin correspondencia'
    FROM #src s JOIN core.Servicio t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Condominio IS NOT NULL AND s.CondominioId IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.Servicio', t.[ServicioId], N'EjecutivoUsuarioId', LEFT(CONVERT(nvarchar(400), s.o_Ejecutivo), 400), N'Ejecutivo sin correspondencia en ref.Usuario'
    FROM #src s JOIN core.Servicio t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Ejecutivo IS NOT NULL AND s.EjecutivoUsuarioId IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'D2', N'core.Servicio', t.[ServicioId], N'CuentaCrmId', LEFT(CONVERT(nvarchar(400), s.FuenteLlave), 400), N'Cuenta presente solo en la tabla completa (no está en _Extended)'
    FROM #src s JOIN core.Servicio t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.FuenteTabla = N'Accounts';

    SELECT @Leidas AS FilasLeidas, @Validas - (SELECT COUNT_BIG(*) FROM #cambios) AS FilasSinCambio;
END;
GO
