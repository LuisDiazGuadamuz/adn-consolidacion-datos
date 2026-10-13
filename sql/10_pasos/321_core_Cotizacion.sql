USE ADN_Unificado;
GO
/* Paso 321 · core_Cotizacion → core.Cotizacion
   Cotizaciones del CRM. Las líneas (Product_Details) se guardan como texto dentro de los atributos extendidos.
   Reglas: D5, DD-06, ES-01, ES-02, ES-04, IN-01, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_Cotizacion @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT CAST(q.[Tipo] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Tipo],
           CAST(q.[Asunto] AS nvarchar(300)) COLLATE DATABASE_DEFAULT AS [Asunto],
           q.[SubTotal],
           q.[FechaModificacionOrigen],
           CAST(q.[Etapa] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Etapa],
           q.[Descuento],
           q.[FechaCreacionOrigen],
           q.[Total],
           CAST(q.[CotizacionCrmId] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [CotizacionCrmId],
           CAST(q.[Moneda] AS char(3)) COLLATE DATABASE_DEFAULT AS [Moneda],
           q.[Impuesto],
           q.[FechaCotizacion],
           q.[ContactoId],
           q.[ServicioId],
           q.[OportunidadId],
           q.[AtributosExtendidos] COLLATE DATABASE_DEFAULT AS [AtributosExtendidos],
           q.[SubTotalCRC],
           q.[ImpuestoCRC],
           q.[DescuentoCRC],
           q.[TotalCRC],
           q.[TipoCambio],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[Tipo]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Asunto]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[SubTotal]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaModificacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Etapa]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Descuento]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaCreacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Total]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[CotizacionCrmId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Moneda]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Impuesto]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaCotizacion], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ContactoId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ServicioId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[OportunidadId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[AtributosExtendidos]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[SubTotalCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[ImpuestoCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[DescuentoCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TotalCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TipoCambio]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_ContactoId],
           q.[o_ServicioId],
           q.[o_OportunidadId],
           q.[o_SubTotal],
           q.[o_FechaModificacionOrigen],
           q.[o_Descuento],
           q.[o_FechaCreacionOrigen],
           q.[o_Total],
           q.[o_Impuesto],
           q.[o_FechaCotizacion],
           q.[o_Eliminado],
           CONCAT_WS(N',', CASE WHEN LEN(q.[Tipo]) > 50 THEN N'Tipo' END, CASE WHEN LEN(q.[Asunto]) > 300 THEN N'Asunto' END, CASE WHEN LEN(q.[Etapa]) > 50 THEN N'Etapa' END, CASE WHEN LEN(q.[CotizacionCrmId]) > 30 THEN N'CotizacionCrmId' END, CASE WHEN LEN(q.[Moneda]) > 3 THEN N'Moneda' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT q.*,
               CASE q.Moneda WHEN 'CRC' THEN CAST(1 AS decimal(19,6)) WHEN 'USD' THEN tc.Venta END AS TipoCambio,
               CASE q.Moneda WHEN 'CRC' THEN q.[SubTotal] WHEN 'USD' THEN CAST(q.[SubTotal] * tc.Venta AS decimal(19,4)) END AS [SubTotalCRC],
               CASE q.Moneda WHEN 'CRC' THEN q.[Impuesto] WHEN 'USD' THEN CAST(q.[Impuesto] * tc.Venta AS decimal(19,4)) END AS [ImpuestoCRC],
               CASE q.Moneda WHEN 'CRC' THEN q.[Descuento] WHEN 'USD' THEN CAST(q.[Descuento] * tc.Venta AS decimal(19,4)) END AS [DescuentoCRC],
               CASE q.Moneda WHEN 'CRC' THEN q.[Total] WHEN 'USD' THEN CAST(q.[Total] * tc.Venta AS decimal(19,4)) END AS [TotalCRC]
        FROM (
        SELECT 'ZohoCRM' AS FuenteSistema,
               N'Zoho_Mirror' AS FuenteBase,
               N'Quotes' AS FuenteTabla,
               ctl.fn_Texto(CONVERT(nvarchar(200), c.[id])) AS FuenteLlave,
               ctl.fn_FechaCR(CONVERT(nvarchar(60), c.[Created_Time])) AS FechaDato,
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[Tipo])) AS [Tipo],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[Subject])) AS [Asunto],
               ctl.fn_Monto(CONVERT(nvarchar(60), c.[Sub_Total])) AS [SubTotal],
               ctl.fn_FechaCR(CONVERT(nvarchar(60), c.[Modified_Time])) AS [FechaModificacionOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[Quote_Stage])) AS [Etapa],
               ctl.fn_Monto(CONVERT(nvarchar(60), c.[Discount])) AS [Descuento],
               ctl.fn_FechaCR(CONVERT(nvarchar(60), c.[Created_Time])) AS [FechaCreacionOrigen],
               ctl.fn_Monto(CONVERT(nvarchar(60), c.[Grand_Total])) AS [Total],
               ctl.fn_Texto(CONVERT(nvarchar(max), c.[id])) AS [CotizacionCrmId],
               ctl.fn_Moneda(CONVERT(nvarchar(20), c.[Currency])) AS [Moneda],
               ctl.fn_Monto(CONVERT(nvarchar(60), c.[Tax])) AS [Impuesto],
               ctl.fn_FechaDia(CONVERT(nvarchar(60), c.[Fecha_Actual])) AS [FechaCotizacion],
               fk_ContactoId_0.Id AS [ContactoId],
               ctl.fn_Texto(CONVERT(nvarchar(400), c.[Contact_Name])) AS [o_ContactoId],
               fk_ServicioId_0.Id AS [ServicioId],
               ctl.fn_Texto(CONVERT(nvarchar(400), c.[Account_Name])) AS [o_ServicioId],
               fk_OportunidadId_0.Id AS [OportunidadId],
               ctl.fn_Texto(CONVERT(nvarchar(400), c.[Deal_Name])) AS [o_OportunidadId],
               JSON_MODIFY(ISNULL(NULLIF((SELECT ctl.fn_Texto(CONVERT(nvarchar(max), c.[Tag])) AS [Tag], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Fecha_Cierre_Aproximado])) AS [Fecha_Cierre_Aproximado], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Layout])) AS [Layout], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Numeraci_n])) AS [Numeraci_n], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Terms_and_Conditions])) AS [Terms_and_Conditions], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Motivo_del_rechazo])) AS [Motivo_del_rechazo], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Categoria])) AS [Categoria], ctl.fn_Texto(CONVERT(nvarchar(max), c.[precio])) AS [precio], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Modified_By])) AS [Modified_By], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Masive_Edition_Control_Field])) AS [Masive_Edition_Control_Field], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Past_Currency])) AS [Past_Currency], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Minutos_a_movil])) AS [Minutos_a_movil], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Sub_Categor_a])) AS [Sub_Categor_a], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Created_By])) AS [Created_By], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Minutos_a_fijo])) AS [Minutos_a_fijo], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Numero_de_Canales])) AS [Numero_de_Canales], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Adjustment])) AS [Adjustment], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Validez_Propuesta])) AS [Validez_Propuesta], ctl.fn_Texto(CONVERT(nvarchar(max), c.[ISP_Externo])) AS [ISP_Externo], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Owner])) AS [Owner], ctl.fn_Texto(CONVERT(nvarchar(max), c.[Duraci_n_del_compromiso])) AS [Duraci_n_del_compromiso] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER), N'{}'), N'{}'), '$.Product_Details', ctl.fn_Texto(CONVERT(nvarchar(max), c.Product_Details))) AS [AtributosExtendidos],
               ctl.fn_Texto(CONVERT(nvarchar(400), c.[Sub_Total])) AS [o_SubTotal],
               ctl.fn_Texto(CONVERT(nvarchar(400), c.[Modified_Time])) AS [o_FechaModificacionOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(400), c.[Discount])) AS [o_Descuento],
               ctl.fn_Texto(CONVERT(nvarchar(400), c.[Created_Time])) AS [o_FechaCreacionOrigen],
               ctl.fn_Texto(CONVERT(nvarchar(400), c.[Grand_Total])) AS [o_Total],
               ctl.fn_Texto(CONVERT(nvarchar(400), c.[Tax])) AS [o_Impuesto],
               ctl.fn_Texto(CONVERT(nvarchar(400), c.[Fecha_Actual])) AS [o_FechaCotizacion],
               CAST(ISNULL(c.[deleted], 0) AS int) AS [o_Eliminado]
        FROM Zoho_Mirror.dbo.[Quotes] c
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[ContactoId]) END AS Id FROM core.Contacto zref WHERE zref.[ContactoCrmId] = ctl.fn_Texto(CONVERT(nvarchar(max), c.[Contact_Name]))) fk_ContactoId_0
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[ServicioId]) END AS Id FROM core.Servicio zref WHERE zref.[CuentaCrmId] = ctl.fn_Texto(CONVERT(nvarchar(max), c.[Account_Name]))) fk_ServicioId_0
        OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[OportunidadId]) END AS Id FROM core.Oportunidad zref WHERE zref.[OportunidadCrmId] = ctl.fn_Texto(CONVERT(nvarchar(max), c.[Deal_Name]))) fk_OportunidadId_0
        ) q
        OUTER APPLY (SELECT TOP 1 t.Venta FROM ref.TipoCambio t WHERE t.Fecha <= CAST(COALESCE(q.FechaCotizacion, q.FechaCreacionOrigen) AS date) ORDER BY t.Fecha DESC) tc
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
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'CotizacionCrmId obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[CotizacionCrmId] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FuenteLlave obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FuenteLlave] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE FROM #src WHERE [CotizacionCrmId] IS NULL OR [FuenteLlave] IS NULL;

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
    SELECT t.[CotizacionId] AS RegistroId, t.FuenteLlave, (SELECT t.[CotizacionCrmId], t.[OportunidadId], t.[ServicioId], t.[ContactoId], t.[Asunto], t.[Etapa], t.[Tipo], t.[Moneda], t.[TipoCambio], t.[SubTotal], t.[SubTotalCRC], t.[Impuesto], t.[ImpuestoCRC], t.[Descuento], t.[DescuentoCRC], t.[Total], t.[TotalCRC], t.[FechaCotizacion], t.[AtributosExtendidos], t.[FechaCreacionOrigen], t.[FechaModificacionOrigen], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.Cotizacion t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido;

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.Cotizacion WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido) THEN
        UPDATE SET t.[Tipo] = s.[Tipo], t.[Asunto] = s.[Asunto], t.[SubTotal] = s.[SubTotal], t.[FechaModificacionOrigen] = s.[FechaModificacionOrigen], t.[Etapa] = s.[Etapa], t.[Descuento] = s.[Descuento], t.[FechaCreacionOrigen] = s.[FechaCreacionOrigen], t.[Total] = s.[Total], t.[CotizacionCrmId] = s.[CotizacionCrmId], t.[Moneda] = s.[Moneda], t.[Impuesto] = s.[Impuesto], t.[FechaCotizacion] = s.[FechaCotizacion], t.[ContactoId] = s.[ContactoId], t.[ServicioId] = s.[ServicioId], t.[OportunidadId] = s.[OportunidadId], t.[AtributosExtendidos] = s.[AtributosExtendidos], t.[SubTotalCRC] = s.[SubTotalCRC], t.[ImpuestoCRC] = s.[ImpuestoCRC], t.[DescuentoCRC] = s.[DescuentoCRC], t.[TotalCRC] = s.[TotalCRC], t.[TipoCambio] = s.[TipoCambio], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([Tipo], [Asunto], [SubTotal], [FechaModificacionOrigen], [Etapa], [Descuento], [FechaCreacionOrigen], [Total], [CotizacionCrmId], [Moneda], [Impuesto], [FechaCotizacion], [ContactoId], [ServicioId], [OportunidadId], [AtributosExtendidos], [SubTotalCRC], [ImpuestoCRC], [DescuentoCRC], [TotalCRC], [TipoCambio], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[Tipo], s.[Asunto], s.[SubTotal], s.[FechaModificacionOrigen], s.[Etapa], s.[Descuento], s.[FechaCreacionOrigen], s.[Total], s.[CotizacionCrmId], s.[Moneda], s.[Impuesto], s.[FechaCotizacion], s.[ContactoId], s.[ServicioId], s.[OportunidadId], s.[AtributosExtendidos], s.[SubTotalCRC], s.[ImpuestoCRC], s.[DescuentoCRC], s.[TotalCRC], s.[TipoCambio], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[CotizacionId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.Cotizacion', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.Cotizacion', t.[CotizacionId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.Cotizacion t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.Cotizacion', t.[CotizacionId], N'ContactoId', LEFT(CONVERT(nvarchar(400), s.o_ContactoId), 400), N'Referencia sin correspondencia única en core.Contacto'
    FROM #src s JOIN core.Cotizacion t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_ContactoId IS NOT NULL AND s.[ContactoId] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.Cotizacion', t.[CotizacionId], N'ServicioId', LEFT(CONVERT(nvarchar(400), s.o_ServicioId), 400), N'Referencia sin correspondencia única en core.Servicio'
    FROM #src s JOIN core.Cotizacion t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_ServicioId IS NOT NULL AND s.[ServicioId] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.Cotizacion', t.[CotizacionId], N'OportunidadId', LEFT(CONVERT(nvarchar(400), s.o_OportunidadId), 400), N'Referencia sin correspondencia única en core.Oportunidad'
    FROM #src s JOIN core.Cotizacion t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_OportunidadId IS NOT NULL AND s.[OportunidadId] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-04', N'core.Cotizacion', t.[CotizacionId], N'SubTotal', LEFT(CONVERT(nvarchar(400), s.o_SubTotal), 400), N'Monto ilegible; se conserva el texto original'
    FROM #src s JOIN core.Cotizacion t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_SubTotal IS NOT NULL AND s.[SubTotal] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.Cotizacion', t.[CotizacionId], N'FechaModificacionOrigen', LEFT(CONVERT(nvarchar(400), s.o_FechaModificacionOrigen), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.Cotizacion t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaModificacionOrigen IS NOT NULL AND s.[FechaModificacionOrigen] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-04', N'core.Cotizacion', t.[CotizacionId], N'Descuento', LEFT(CONVERT(nvarchar(400), s.o_Descuento), 400), N'Monto ilegible; se conserva el texto original'
    FROM #src s JOIN core.Cotizacion t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Descuento IS NOT NULL AND s.[Descuento] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.Cotizacion', t.[CotizacionId], N'FechaCreacionOrigen', LEFT(CONVERT(nvarchar(400), s.o_FechaCreacionOrigen), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.Cotizacion t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaCreacionOrigen IS NOT NULL AND s.[FechaCreacionOrigen] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-04', N'core.Cotizacion', t.[CotizacionId], N'Total', LEFT(CONVERT(nvarchar(400), s.o_Total), 400), N'Monto ilegible; se conserva el texto original'
    FROM #src s JOIN core.Cotizacion t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Total IS NOT NULL AND s.[Total] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-04', N'core.Cotizacion', t.[CotizacionId], N'Impuesto', LEFT(CONVERT(nvarchar(400), s.o_Impuesto), 400), N'Monto ilegible; se conserva el texto original'
    FROM #src s JOIN core.Cotizacion t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Impuesto IS NOT NULL AND s.[Impuesto] IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-02', N'core.Cotizacion', t.[CotizacionId], N'FechaCotizacion', LEFT(CONVERT(nvarchar(400), s.o_FechaCotizacion), 400), N'Fecha ilegible o ficticia; se conserva el texto original'
    FROM #src s JOIN core.Cotizacion t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_FechaCotizacion IS NOT NULL AND s.[FechaCotizacion] IS NULL;

    SELECT @Leidas AS FilasLeidas, @Validas - (SELECT COUNT_BIG(*) FROM #cambios) AS FilasSinCambio;
END;
GO
