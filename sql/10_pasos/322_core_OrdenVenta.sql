USE ADN_Unificado;
GO
/* Paso 322 · core_OrdenVenta → core.OrdenVenta
   Órdenes de venta: Sales_Orders_Extended es la fuente principal (D2). El servicio se vincula por cuenta y, si falta, por circuito con correspondencia única (ID-01).
   Reglas: D5, ES-01, ES-04, ID-01, IN-01, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_OrdenVenta @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT CAST(q.[OrdenVentaCrmId] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [OrdenVentaCrmId],
           q.[FechaCreacionOrigen],
           q.[FechaModificacionOrigen],
           CAST(q.[Asunto] AS nvarchar(300)) COLLATE DATABASE_DEFAULT AS [Asunto],
           CAST(q.[Estado] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Estado],
           q.[CapacidadCargaMbps],
           q.[CapacidadDescargaMbps],
           CAST(q.[Moneda] AS char(3)) COLLATE DATABASE_DEFAULT AS [Moneda],
           q.[Descuento],
           q.[FechaFirma],
           q.[FechaInactivacion],
           q.[Total],
           q.[Mensualidad],
           q.[PlazoMeses],
           CAST(q.[Circuito] AS varchar(14)) COLLATE DATABASE_DEFAULT AS [Circuito],
           q.[SubTotal],
           q.[Impuesto],
           CAST(q.[TipoContrato] AS nvarchar(100)) COLLATE DATABASE_DEFAULT AS [TipoContrato],
           q.[PropietarioUsuarioId],
           q.[ServicioId],
           q.[ContactoId],
           q.[OportunidadId],
           q.[CotizacionId],
           q.[AtributosExtendidos] COLLATE DATABASE_DEFAULT AS [AtributosExtendidos],
           q.[SubTotalCRC],
           q.[ImpuestoCRC],
           q.[DescuentoCRC],
           q.[TotalCRC],
           q.[MensualidadCRC],
           q.[TipoCambio],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[OrdenVentaCrmId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaCreacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaModificacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Asunto]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Estado]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[CapacidadCargaMbps]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[CapacidadDescargaMbps]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Moneda]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Descuento]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaFirma], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaInactivacion], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Total]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Mensualidad]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[PlazoMeses]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Circuito]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[SubTotal]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Impuesto]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TipoContrato]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[PropietarioUsuarioId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ServicioId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ContactoId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[OportunidadId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[CotizacionId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[AtributosExtendidos]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[SubTotalCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ImpuestoCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[DescuentoCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TotalCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[MensualidadCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TipoCambio]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_PropietarioUsuarioId],
           q.[o_ServicioId],
           q.[o_ContactoId],
           q.[o_OportunidadId],
           q.[o_CotizacionId],
           q.[o_Circuito],
           CONCAT_WS(N',', CASE WHEN LEN(q.[OrdenVentaCrmId]) > 30 THEN N'OrdenVentaCrmId' END, CASE WHEN LEN(q.[Asunto]) > 300 THEN N'Asunto' END, CASE WHEN LEN(q.[Estado]) > 50 THEN N'Estado' END, CASE WHEN LEN(q.[Moneda]) > 3 THEN N'Moneda' END, CASE WHEN LEN(q.[Circuito]) > 14 THEN N'Circuito' END, CASE WHEN LEN(q.[TipoContrato]) > 100 THEN N'TipoContrato' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT q.*,
               tx.Tasa AS TipoCambio,
               CASE q.Moneda WHEN 'CRC' THEN q.[SubTotal] WHEN 'USD' THEN CAST(q.[SubTotal] * tx.Tasa AS decimal(19,4)) END AS [SubTotalCRC],
               CASE q.Moneda WHEN 'CRC' THEN q.[Impuesto] WHEN 'USD' THEN CAST(q.[Impuesto] * tx.Tasa AS decimal(19,4)) END AS [ImpuestoCRC],
               CASE q.Moneda WHEN 'CRC' THEN q.[Descuento] WHEN 'USD' THEN CAST(q.[Descuento] * tx.Tasa AS decimal(19,4)) END AS [DescuentoCRC],
               CASE q.Moneda WHEN 'CRC' THEN q.[Total] WHEN 'USD' THEN CAST(q.[Total] * tx.Tasa AS decimal(19,4)) END AS [TotalCRC],
               CASE q.Moneda WHEN 'CRC' THEN q.[Mensualidad] WHEN 'USD' THEN CAST(q.[Mensualidad] * tx.Tasa AS decimal(19,4)) END AS [MensualidadCRC]
        FROM (
        SELECT 'ZohoCRM' AS FuenteSistema,
               N'Zoho_Mirror' AS FuenteBase,
               N'Sales_Orders_Extended' AS FuenteTabla,
               ctl.fn_Texto(CONVERT(nvarchar(200), o.[id])) AS FuenteLlave,
               ctl.fn_FechaCR(CONVERT(nvarchar(30), o.[Created_Time], 126)) AS FechaDato,
               ctl.fn_Texto(CONVERT(nvarchar(max), o.[id])) AS [OrdenVentaCrmId],
               ctl.fn_FechaCR(CONVERT(nvarchar(30), o.[Created_Time], 126)) AS [FechaCreacionOrigen],
               ctl.fn_FechaCR(CONVERT(nvarchar(30), o.[Modified_Time], 126)) AS [FechaModificacionOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(max), o.[Subject])) AS [Asunto],
               ctl.fn_Texto(CONVERT(nvarchar(max), o.[Status])) AS [Estado],
               TRY_CONVERT(decimal(9,2), o.[Capacidad_Mbps_Carga]) AS [CapacidadCargaMbps],
               TRY_CONVERT(decimal(9,2), o.[Capacidad_Mbps_Descarga]) AS [CapacidadDescargaMbps],
               ctl.fn_Moneda(CONVERT(nvarchar(20), o.[Currency])) AS [Moneda],
               TRY_CONVERT(decimal(19,4), o.[Discount]) AS [Descuento],
               CAST(o.[Fecha_de_Firma] AS date) AS [FechaFirma],
               CAST(o.[Fecha_de_Inactivaci_n] AS date) AS [FechaInactivacion],
               TRY_CONVERT(decimal(19,4), o.[Grand_Total]) AS [Total],
               TRY_CONVERT(decimal(19,4), o.[Mensualidad_Actual]) AS [Mensualidad],
               TRY_CONVERT(int, o.[Meses_de_Plazo_Contrato]) AS [PlazoMeses],
               ctl.fn_Circuito(CONVERT(nvarchar(100), o.[N_mero_Circuito])) AS [Circuito],
               TRY_CONVERT(decimal(19,4), o.[Sub_Total]) AS [SubTotal],
               TRY_CONVERT(decimal(19,4), o.[Tax]) AS [Impuesto],
               ctl.fn_Texto(CONVERT(nvarchar(max), o.[Tipo_de_Contrato])) AS [TipoContrato],
               fk_PropietarioUsuarioId_0.Id AS [PropietarioUsuarioId],
               ctl.fn_Texto(CONVERT(nvarchar(400), o.[Owner])) AS [o_PropietarioUsuarioId],
               COALESCE(fk_ServicioId_0.Id, fk_ServicioId_1.Id) AS [ServicioId],
               COALESCE(ctl.fn_Texto(CONVERT(nvarchar(400), o.[Account_Name])), ctl.fn_Texto(CONVERT(nvarchar(400), o.[N_mero_Circuito]))) AS [o_ServicioId],
               fk_ContactoId_0.Id AS [ContactoId],
               ctl.fn_Texto(CONVERT(nvarchar(400), o.[Contact_Name])) AS [o_ContactoId],
               fk_OportunidadId_0.Id AS [OportunidadId],
               ctl.fn_Texto(CONVERT(nvarchar(400), o.[Deal_Name])) AS [o_OportunidadId],
               fk_CotizacionId_0.Id AS [CotizacionId],
               ctl.fn_Texto(CONVERT(nvarchar(400), o.[Quote_Name])) AS [o_CotizacionId],
               ctl.fn_Texto(CONVERT(nvarchar(400), o.[N_mero_Circuito])) AS [o_Circuito],
               NULLIF((SELECT ctl.fn_Texto(CONVERT(nvarchar(max), o.[Created_By])) AS [Created_By], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Modified_By])) AS [Modified_By], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Last_Activity_Time])) AS [Last_Activity_Time], ctl.fn_Texto(CONVERT(nvarchar(max), o.[ADNPAY])) AS [ADNPAY], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Adjustment])) AS [Adjustment], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Aplica_Promoci_n])) AS [Aplica_Promoci_n], ctl.fn_Texto(CONVERT(nvarchar(max), o.[CHURN])) AS [CHURN], ctl.fn_Texto(CONVERT(nvarchar(max), o.[C_dula_Contrato_Sucursal])) AS [C_dula_Contrato_Sucursal], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Cant_n])) AS [Cant_n], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Changes])) AS [Changes], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Codigo_Actividad_Economica_Cliente])) AS [Codigo_Actividad_Economica_Cliente], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Codigo_FTTH])) AS [Codigo_FTTH], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Comision])) AS [Comision], ctl.fn_Texto(CONVERT(nvarchar(max), o.[ComsionADN])) AS [ComsionADN], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Condici_n_adicional])) AS [Condici_n_adicional], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Condominio])) AS [Condominio], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Condominio_C])) AS [Condominio_C], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Condominio_sin_Cobertura])) AS [Condominio_sin_Cobertura], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Contacto_Facturaci_n])) AS [Contacto_Facturaci_n], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Contacto_T_cnico_a])) AS [Contacto_T_cnico_a], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Contrato_Asociado])) AS [Contrato_Asociado], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Coordenadas])) AS [Coordenadas], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Cortes_a])) AS [Cortes_a], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Costo_Instalaci_n_Proveedor])) AS [Costo_Instalaci_n_Proveedor], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Costo_Instalacion])) AS [Costo_Instalacion], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Costo_Mensual_Proveedor])) AS [Costo_Mensual_Proveedor], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Costo_Recurrente_ADN])) AS [Costo_Recurrente_ADN], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Costo_de_Equipo])) AS [Costo_de_Equipo], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Description])) AS [Description], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Detalle1])) AS [Detalle1], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Diferencia])) AS [Diferencia], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Direcci_n_Exacta])) AS [Direcci_n_Exacta], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Districts1])) AS [Districts1], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Distrito])) AS [Distrito], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Drop_Cliente])) AS [Drop_Cliente], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Due_Date])) AS [Due_Date], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Duracion_Aprobacion])) AS [Duracion_Aprobacion], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Encargado_Retencion])) AS [Encargado_Retencion], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Enlace_Provisional])) AS [Enlace_Provisional], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Enlace_provisional_con_costo])) AS [Enlace_provisional_con_costo], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Envio_Revision_Fase_1])) AS [Envio_Revision_Fase_1], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Envio_Revision_Fase_2])) AS [Envio_Revision_Fase_2], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Envio_Revision_Fase_3])) AS [Envio_Revision_Fase_3], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Exonerado])) AS [Exonerado], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Fase_1_Duracion_Aprobacion])) AS [Fase_1_Duracion_Aprobacion], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Fase_2_Duracion_Aprobacion])) AS [Fase_2_Duracion_Aprobacion], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Fecha_Envio_Revision])) AS [Fecha_Envio_Revision], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Fecha_Proyeccion_Venta])) AS [Fecha_Proyeccion_Venta], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Generar_OT])) AS [Generar_OT], ctl.fn_Texto(CONVERT(nvarchar(max), o.[IPTV])) AS [IPTV], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Layout])) AS [Layout], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Locked__s])) AS [Locked__s], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Loss_ADN])) AS [Loss_ADN], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Menos_de_3_Meses])) AS [Menos_de_3_Meses], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Mensualidad1])) AS [Mensualidad1], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Mensualidad_Nueva1])) AS [Mensualidad_Nueva1], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Mensualidad_Pasada])) AS [Mensualidad_Pasada], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Mes])) AS [Mes], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Mes_al_que_aplica_la_promoci_n])) AS [Mes_al_que_aplica_la_promoci_n], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Mes_que_aplica_la_promoci_n])) AS [Mes_que_aplica_la_promoci_n], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Modo_de_Pago])) AS [Modo_de_Pago], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Motivo])) AS [Motivo], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Numero_Telefonico])) AS [Numero_Telefonico], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Orden_de_Compra])) AS [Orden_de_Compra], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Pago_Realizado])) AS [Pago_Realizado], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Pais])) AS [Pais], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Plataforma_Actual])) AS [Plataforma_Actual], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Plazo_Contrato])) AS [Plazo_Contrato], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Promo_Monte_Sol])) AS [Promo_Monte_Sol], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Promoci_n])) AS [Promoci_n], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Prorrateo])) AS [Prorrateo], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Proveedor])) AS [Proveedor], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Proveedor1])) AS [Proveedor1], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Provincia])) AS [Provincia], ctl.fn_Texto(CONVERT(nvarchar(max), o.[ROI])) AS [ROI], ctl.fn_Texto(CONVERT(nvarchar(max), o.[ROIAADN])) AS [ROIAADN], ctl.fn_Texto(CONVERT(nvarchar(max), o.[ROI_EX_ISP])) AS [ROI_EX_ISP], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Relaci_n])) AS [Relaci_n], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Retencion])) AS [Retencion], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Revenue])) AS [Revenue], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Revision_1])) AS [Revision_1], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Revision_2])) AS [Revision_2], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Revision_3])) AS [Revision_3], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Revision_Completa_Fase_1])) AS [Revision_Completa_Fase_1], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Revision_Completada_Fase_2])) AS [Revision_Completada_Fase_2], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Revision_Completada_Fase_3])) AS [Revision_Completada_Fase_3], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Segmentacion_Contrato_B2B])) AS [Segmentacion_Contrato_B2B], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Segmento])) AS [Segmento], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Sistema_de_facturaci_n])) AS [Sistema_de_facturaci_n], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Submotivo])) AS [Submotivo], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Tag])) AS [Tag], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Tipo])) AS [Tipo], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Tipo_Fiscal])) AS [Tipo_Fiscal], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Tramite_de_Permisos])) AS [Tramite_de_Permisos], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Ultima_Mensualidad])) AS [Ultima_Mensualidad], ctl.fn_Texto(CONVERT(nvarchar(max), o.[borrador])) AS [borrador], ctl.fn_Texto(CONVERT(nvarchar(max), o.[borrador2])) AS [borrador2], ctl.fn_Texto(CONVERT(nvarchar(max), o.[flag_expiration])) AS [flag_expiration], ctl.fn_Texto(CONVERT(nvarchar(max), o.[ftth])) AS [ftth], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Billing_City])) AS [Billing_City], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Billing_Country])) AS [Billing_Country], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Shipping_City])) AS [Shipping_City], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Shipping_Country])) AS [Shipping_Country], ctl.fn_Texto(CONVERT(nvarchar(max), o.[Terms_and_Conditions])) AS [Terms_and_Conditions] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER), N'{}') AS [AtributosExtendidos],
               TRY_CONVERT(decimal(19,6), TRY_CONVERT(decimal(19,6), o.[Exchange_Rate])) AS [d_TipoCambio]
        FROM Zoho_Mirror.dbo.[Sales_Orders_Extended] o
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[UsuarioId]) END AS Id FROM ref.Usuario zref WHERE zref.[ZohoUsuarioId] = ctl.fn_Texto(CONVERT(nvarchar(max), o.[Owner])) OR zref.[NombreCompleto] = ctl.fn_Texto(CONVERT(nvarchar(max), o.[Owner]))) fk_PropietarioUsuarioId_0
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[ServicioId]) END AS Id FROM core.Servicio zref WHERE zref.[CuentaCrmId] = ctl.fn_Texto(CONVERT(nvarchar(max), o.[Account_Name]))) fk_ServicioId_0
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[ServicioId]) END AS Id FROM core.Servicio zref WHERE zref.Circuito = ctl.fn_Circuito(CONVERT(nvarchar(100), o.[N_mero_Circuito]))) fk_ServicioId_1
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[ContactoId]) END AS Id FROM core.Contacto zref WHERE zref.[ContactoCrmId] = ctl.fn_Texto(CONVERT(nvarchar(max), o.[Contact_Name]))) fk_ContactoId_0
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[OportunidadId]) END AS Id FROM core.Oportunidad zref WHERE zref.[OportunidadCrmId] = ctl.fn_Texto(CONVERT(nvarchar(max), o.[Deal_Name]))) fk_OportunidadId_0
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[CotizacionId]) END AS Id FROM core.Cotizacion zref WHERE zref.[CotizacionCrmId] = ctl.fn_Texto(CONVERT(nvarchar(max), o.[Quote_Name]))) fk_CotizacionId_0
        ) q
        OUTER APPLY (SELECT TOP 1 t.Venta FROM ref.TipoCambio t WHERE t.Fecha <= CAST(COALESCE(q.FechaFirma, q.FechaCreacionOrigen) AS date) ORDER BY t.Fecha DESC) tc
        CROSS APPLY (SELECT CASE q.Moneda WHEN 'CRC' THEN CAST(1 AS decimal(19,6)) WHEN 'USD' THEN COALESCE(tc.Venta, CASE WHEN q.d_TipoCambio > 1 THEN q.d_TipoCambio END) END AS Tasa) tx
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);
    /* Conciliación: llaves leídas, para comprobar al final que toda fila excluida tiene su motivo en ctl.Descarte */
    DROP TABLE IF EXISTS #leidas;
    SELECT DISTINCT FuenteTabla, FuenteLlave INTO #leidas FROM #src;

    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'OrdenVentaCrmId obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[OrdenVentaCrmId] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FuenteLlave obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FuenteLlave] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE FROM #src WHERE [OrdenVentaCrmId] IS NULL OR [FuenteLlave] IS NULL;

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
    SELECT t.[OrdenVentaId] AS RegistroId, t.FuenteLlave, (SELECT t.[OrdenVentaCrmId], t.[ServicioId], t.[ContactoId], t.[OportunidadId], t.[CotizacionId], t.[Circuito], t.[Asunto], t.[Estado], t.[TipoContrato], t.[PlazoMeses], t.[CapacidadDescargaMbps], t.[CapacidadCargaMbps], t.[Moneda], t.[TipoCambio], t.[SubTotal], t.[SubTotalCRC], t.[Impuesto], t.[ImpuestoCRC], t.[Descuento], t.[DescuentoCRC], t.[Total], t.[TotalCRC], t.[Mensualidad], t.[MensualidadCRC], t.[FechaFirma], t.[FechaInactivacion], t.[PropietarioUsuarioId], t.[AtributosExtendidos], t.[FechaCreacionOrigen], t.[FechaModificacionOrigen], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.OrdenVenta t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato);

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.OrdenVenta WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido OR EXISTS (SELECT t.FechaDato EXCEPT SELECT s.FechaDato)) THEN
        UPDATE SET t.[OrdenVentaCrmId] = s.[OrdenVentaCrmId], t.[FechaCreacionOrigen] = s.[FechaCreacionOrigen], t.[FechaModificacionOrigen] = s.[FechaModificacionOrigen], t.[Asunto] = s.[Asunto], t.[Estado] = s.[Estado], t.[CapacidadCargaMbps] = s.[CapacidadCargaMbps], t.[CapacidadDescargaMbps] = s.[CapacidadDescargaMbps], t.[Moneda] = s.[Moneda], t.[Descuento] = s.[Descuento], t.[FechaFirma] = s.[FechaFirma], t.[FechaInactivacion] = s.[FechaInactivacion], t.[Total] = s.[Total], t.[Mensualidad] = s.[Mensualidad], t.[PlazoMeses] = s.[PlazoMeses], t.[Circuito] = s.[Circuito], t.[SubTotal] = s.[SubTotal], t.[Impuesto] = s.[Impuesto], t.[TipoContrato] = s.[TipoContrato], t.[PropietarioUsuarioId] = s.[PropietarioUsuarioId], t.[ServicioId] = s.[ServicioId], t.[ContactoId] = s.[ContactoId], t.[OportunidadId] = s.[OportunidadId], t.[CotizacionId] = s.[CotizacionId], t.[AtributosExtendidos] = s.[AtributosExtendidos], t.[SubTotalCRC] = s.[SubTotalCRC], t.[ImpuestoCRC] = s.[ImpuestoCRC], t.[DescuentoCRC] = s.[DescuentoCRC], t.[TotalCRC] = s.[TotalCRC], t.[MensualidadCRC] = s.[MensualidadCRC], t.[TipoCambio] = s.[TipoCambio], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([OrdenVentaCrmId], [FechaCreacionOrigen], [FechaModificacionOrigen], [Asunto], [Estado], [CapacidadCargaMbps], [CapacidadDescargaMbps], [Moneda], [Descuento], [FechaFirma], [FechaInactivacion], [Total], [Mensualidad], [PlazoMeses], [Circuito], [SubTotal], [Impuesto], [TipoContrato], [PropietarioUsuarioId], [ServicioId], [ContactoId], [OportunidadId], [CotizacionId], [AtributosExtendidos], [SubTotalCRC], [ImpuestoCRC], [DescuentoCRC], [TotalCRC], [MensualidadCRC], [TipoCambio], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[OrdenVentaCrmId], s.[FechaCreacionOrigen], s.[FechaModificacionOrigen], s.[Asunto], s.[Estado], s.[CapacidadCargaMbps], s.[CapacidadDescargaMbps], s.[Moneda], s.[Descuento], s.[FechaFirma], s.[FechaInactivacion], s.[Total], s.[Mensualidad], s.[PlazoMeses], s.[Circuito], s.[SubTotal], s.[Impuesto], s.[TipoContrato], s.[PropietarioUsuarioId], s.[ServicioId], s.[ContactoId], s.[OportunidadId], s.[CotizacionId], s.[AtributosExtendidos], s.[SubTotalCRC], s.[ImpuestoCRC], s.[DescuentoCRC], s.[TotalCRC], s.[MensualidadCRC], s.[TipoCambio], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[OrdenVentaId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.OrdenVenta', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.OrdenVenta', t.[OrdenVentaId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.OrdenVenta t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.OrdenVenta', t.[OrdenVentaId], N'PropietarioUsuarioId', LEFT(CONVERT(nvarchar(400), s.o_PropietarioUsuarioId), 400), N'Referencia sin correspondencia única en ref.Usuario'
    FROM #src s JOIN core.OrdenVenta t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_PropietarioUsuarioId IS NOT NULL AND s.[PropietarioUsuarioId] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.OrdenVenta', t.[OrdenVentaId], N'ServicioId', LEFT(CONVERT(nvarchar(400), s.o_ServicioId), 400), N'Referencia sin correspondencia única en core.Servicio'
    FROM #src s JOIN core.OrdenVenta t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_ServicioId IS NOT NULL AND s.[ServicioId] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.OrdenVenta', t.[OrdenVentaId], N'ContactoId', LEFT(CONVERT(nvarchar(400), s.o_ContactoId), 400), N'Referencia sin correspondencia única en core.Contacto'
    FROM #src s JOIN core.OrdenVenta t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_ContactoId IS NOT NULL AND s.[ContactoId] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.OrdenVenta', t.[OrdenVentaId], N'OportunidadId', LEFT(CONVERT(nvarchar(400), s.o_OportunidadId), 400), N'Referencia sin correspondencia única en core.Oportunidad'
    FROM #src s JOIN core.OrdenVenta t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_OportunidadId IS NOT NULL AND s.[OportunidadId] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.OrdenVenta', t.[OrdenVentaId], N'CotizacionId', LEFT(CONVERT(nvarchar(400), s.o_CotizacionId), 400), N'Referencia sin correspondencia única en core.Cotizacion'
    FROM #src s JOIN core.OrdenVenta t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_CotizacionId IS NOT NULL AND s.[CotizacionId] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ID-01', N'core.OrdenVenta', t.[OrdenVentaId], N'Circuito', LEFT(CONVERT(nvarchar(400), s.o_Circuito), 400), N'Circuito que no cumple el patrón aprobado'
    FROM #src s JOIN core.OrdenVenta t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Circuito IS NOT NULL AND s.[Circuito] IS NULL;

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
