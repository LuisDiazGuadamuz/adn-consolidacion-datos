USE ADN_Unificado;
GO
/* Paso 531 · core_Llamada → core.Llamada
   Llamadas desde la primera fecha de la copia de MongoDB (D1), copiadas antes a stg.mongo_Telephony_cdr con stage-mongo. Cargar por período con --desde/--hasta.
   Reglas: D1, D4, D5, D6, D10, ID-01, ID-07, ES-01, ES-02, ES-04, DD-01, IN-01, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_Llamada @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 0. Preparación */
    /* Corte entre fuentes (D1): primera fecha con llamadas en la copia de MongoDB; sin copia, todo sale de SQL Server */
    DECLARE @Corte datetime2 = ISNULL((SELECT MIN(StartDateTime) FROM stg.mongo_Telephony_cdr), '9999-12-31');
    DECLARE @CorteSQL datetime2 = ISNULL((SELECT MIN(StartDateTime) FROM ADNApp.dbo.Telephony_cdr), '9999-12-31');
    /* Búsquedas precalculadas (una vez por ejecución, no por llamada) */
    DROP TABLE IF EXISTS #circ, #tron;
    SELECT Circuito, MIN(ServicioId) AS ServicioId, COUNT(*) AS n INTO #circ FROM core.Servicio WHERE Circuito IS NOT NULL GROUP BY Circuito;
    CREATE UNIQUE CLUSTERED INDEX ix ON #circ (Circuito);
    SELECT TRY_CONVERT(int, CodigoTroncal) AS Codigo, MIN(TroncalId) AS TroncalId, COUNT(*) AS n INTO #tron
    FROM core.Troncal WHERE TRY_CONVERT(int, CodigoTroncal) IS NOT NULL GROUP BY TRY_CONVERT(int, CodigoTroncal);
    CREATE UNIQUE CLUSTERED INDEX ix ON #tron (Codigo);
    /* Troncales de proveedores (carriers): no son troncales de clientes, pero tampoco son anomalía */
    DROP TABLE IF EXISTS #tprov;
    SELECT DISTINCT TRY_CONVERT(int, CodigoTroncal) AS Codigo INTO #tprov FROM ref.TroncalProveedor WHERE TRY_CONVERT(int, CodigoTroncal) IS NOT NULL;
    CREATE UNIQUE CLUSTERED INDEX ix ON #tprov (Codigo);

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT q.[ServicioId],
           q.[TroncalEntradaId],
           q.[TroncalSalidaId],
           CAST(q.[Circuito] AS varchar(12)) COLLATE DATABASE_DEFAULT AS [Circuito],
           q.[TipoCDR],
           CAST(q.[RazonCDR] AS nvarchar(100)) COLLATE DATABASE_DEFAULT AS [RazonCDR],
           q.[FechaInicio],
           q.[FechaRespuesta],
           q.[FechaFin],
           CAST(q.[NumeroOrigen] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [NumeroOrigen],
           CAST(q.[NumeroMarcado] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [NumeroMarcado],
           CAST(q.[NumeroFacturacion] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [NumeroFacturacion],
           CAST(q.[DigitosRuteo] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [DigitosRuteo],
           CAST(q.[Destino] AS nvarchar(150)) COLLATE DATABASE_DEFAULT AS [Destino],
           CAST(q.[CodigoDestino] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [CodigoDestino],
           CAST(q.[Dispositivo] AS nvarchar(100)) COLLATE DATABASE_DEFAULT AS [Dispositivo],
           q.[DuracionSegundos],
           q.[DuracionSegundosRedondeada],
           q.[DuracionMinutos],
           q.[RedondeoDestino],
           q.[IncrementoCliente],
           q.[PorcentajeCliente],
           CAST(q.[Moneda] AS char(3)) COLLATE DATABASE_DEFAULT AS [Moneda],
           q.[TipoCambio],
           q.[TarifaDestino],
           q.[TarifaDestinoCRC],
           q.[TarifaSinMargen],
           q.[TarifaSinMargenCRC],
           q.[Costo],
           q.[CostoCRC],
           q.[CostoSinMargen],
           q.[CostoSinMargenCRC],
           q.[AtributosExtendidos] COLLATE DATABASE_DEFAULT AS [AtributosExtendidos],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[ServicioId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TroncalEntradaId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TroncalSalidaId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Circuito]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TipoCDR]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[RazonCDR]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaInicio], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaRespuesta], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaFin], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[NumeroOrigen]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[NumeroMarcado]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[NumeroFacturacion]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[DigitosRuteo]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Destino]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[CodigoDestino]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Dispositivo]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[DuracionSegundos]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[DuracionSegundosRedondeada]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[DuracionMinutos]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[RedondeoDestino]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[IncrementoCliente]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[PorcentajeCliente]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Moneda]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TipoCambio]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TarifaDestino]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TarifaDestinoCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TarifaSinMargen]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[TarifaSinMargenCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Costo]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[CostoCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[CostoSinMargen]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[CostoSinMargenCRC]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[AtributosExtendidos]), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_TipoCambio],
           q.[o_Circuito],
           q.[o_ServicioCircuito],
           q.[o_TroncalEntrada],
           q.[o_TroncalSalida],
           q.[o_Repetida],
           CONCAT_WS(N',', CASE WHEN LEN(q.[Circuito]) > 12 THEN N'Circuito' END, CASE WHEN LEN(q.[RazonCDR]) > 100 THEN N'RazonCDR' END, CASE WHEN LEN(q.[NumeroOrigen]) > 50 THEN N'NumeroOrigen' END, CASE WHEN LEN(q.[NumeroMarcado]) > 50 THEN N'NumeroMarcado' END, CASE WHEN LEN(q.[NumeroFacturacion]) > 50 THEN N'NumeroFacturacion' END, CASE WHEN LEN(q.[DigitosRuteo]) > 50 THEN N'DigitosRuteo' END, CASE WHEN LEN(q.[Destino]) > 150 THEN N'Destino' END, CASE WHEN LEN(q.[CodigoDestino]) > 20 THEN N'CodigoDestino' END, CASE WHEN LEN(q.[Dispositivo]) > 100 THEN N'Dispositivo' END, CASE WHEN LEN(q.[Moneda]) > 3 THEN N'Moneda' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT q.*,
               CASE q.Moneda WHEN 'CRC' THEN CAST(1 AS decimal(19,6))
                             WHEN 'USD' THEN COALESCE(CASE WHEN q.o_TipoCambio > 1 THEN CAST(q.o_TipoCambio AS decimal(19,6)) END, tc.Venta) END AS TipoCambio,
               CASE q.Moneda WHEN 'CRC' THEN q.TarifaDestino WHEN 'USD' THEN CAST(q.TarifaDestino * COALESCE(CASE WHEN q.o_TipoCambio > 1 THEN q.o_TipoCambio END, tc.Venta) AS decimal(19,4)) END AS TarifaDestinoCRC,
               CASE q.Moneda WHEN 'CRC' THEN q.TarifaSinMargen WHEN 'USD' THEN CAST(q.TarifaSinMargen * COALESCE(CASE WHEN q.o_TipoCambio > 1 THEN q.o_TipoCambio END, tc.Venta) AS decimal(19,4)) END AS TarifaSinMargenCRC,
               CASE q.Moneda WHEN 'CRC' THEN q.Costo WHEN 'USD' THEN CAST(q.Costo * COALESCE(CASE WHEN q.o_TipoCambio > 1 THEN q.o_TipoCambio END, tc.Venta) AS decimal(19,4)) END AS CostoCRC,
               CASE q.Moneda WHEN 'CRC' THEN q.CostoSinMargen WHEN 'USD' THEN CAST(q.CostoSinMargen * COALESCE(CASE WHEN q.o_TipoCambio > 1 THEN q.o_TipoCambio END, tc.Venta) AS decimal(19,4)) END AS CostoSinMargenCRC
        FROM (
            SELECT 'AppDataCR' AS FuenteSistema, N'developer_adn_app_db' AS FuenteBase, N'Telephony_cdr' AS FuenteTabla,
                   CAST(c._id AS nvarchar(200)) AS FuenteLlave, CASE WHEN c.StartDateTime >= '1990-01-01' THEN TODATETIMEOFFSET(CAST(c.StartDateTime AS datetime2(0)), '-06:00') END AS FechaDato,
                   ci.ServicioId, ti.TroncalId AS TroncalEntradaId, te.TroncalId AS TroncalSalidaId,
                   v.Circuito, c.CDRTypeCode AS TipoCDR, NULLIF(LTRIM(RTRIM(CAST(c.CDRTypeReason AS nvarchar(100)))), N'') AS RazonCDR,
                   CASE WHEN c.StartDateTime >= '1990-01-01' THEN TODATETIMEOFFSET(CAST(c.StartDateTime AS datetime2(0)), '-06:00') END AS FechaInicio, CASE WHEN c.AnswerTimeOfDate >= '1990-01-01' THEN TODATETIMEOFFSET(CAST(c.AnswerTimeOfDate AS datetime2(0)), '-06:00') END AS FechaRespuesta,
                   CASE WHEN c.DisconnectDateTime >= '1990-01-01' THEN TODATETIMEOFFSET(CAST(c.DisconnectDateTime AS datetime2(0)), '-06:00') END AS FechaFin,
                   NULLIF(LTRIM(RTRIM(CAST(c.CallingNumber AS nvarchar(50)))), N'') AS NumeroOrigen, NULLIF(LTRIM(RTRIM(CAST(c.DialedNumber AS nvarchar(50)))), N'') AS NumeroMarcado,
                   NULLIF(LTRIM(RTRIM(CAST(c.BillingNumber AS nvarchar(50)))), N'') AS NumeroFacturacion, NULLIF(LTRIM(RTRIM(CAST(c.RoutingDigits AS nvarchar(50)))), N'') AS DigitosRuteo,
                   NULLIF(LTRIM(RTRIM(CAST(c.Destination AS nvarchar(150)))), N'') AS Destino, NULLIF(LTRIM(RTRIM(CAST(c.DestinationCode AS nvarchar(20)))), N'') AS CodigoDestino,
                   NULLIF(LTRIM(RTRIM(CAST(c.VoipDevice AS nvarchar(100)))), N'') AS Dispositivo,
                   TRY_CONVERT(decimal(12,2), c.DurationInSeconds) AS DuracionSegundos,
                   TRY_CONVERT(decimal(12,2), c.DurationInRoundedSeconds) AS DuracionSegundosRedondeada,
                   TRY_CONVERT(decimal(12,2), c.DurationInMinutes) AS DuracionMinutos,
                   c.DestinationRound AS RedondeoDestino, c.CustomerIncrement AS IncrementoCliente,
                   TRY_CONVERT(decimal(9,4), c.CustomerPorcentage) AS PorcentajeCliente,
                   ctl.fn_MonedaLlamada(c.DestinationCode) AS Moneda,
                   TRY_CONVERT(decimal(19,4), c.DestinationRate) AS TarifaDestino,
                   TRY_CONVERT(decimal(19,4), c.DestinationRateNoProfit) AS TarifaSinMargen,
                   TRY_CONVERT(decimal(19,4), c.CallCost) AS Costo,
                   TRY_CONVERT(decimal(19,4), c.CallCostNoProfit) AS CostoSinMargen,
                   NULLIF((SELECT c.IngressTrunk AS [IngressTrunk], c.EgressTrunk AS [EgressTrunk], NULLIF(LTRIM(RTRIM(CAST(c.[IngressTrunkAlias] AS nvarchar(400)))), N'') AS [IngressTrunkAlias], NULLIF(LTRIM(RTRIM(CAST(c.[EgressTrunkAlias] AS nvarchar(400)))), N'') AS [EgressTrunkAlias], NULLIF(LTRIM(RTRIM(CAST(c.[OriginationSourceIP] AS nvarchar(400)))), N'') AS [OriginationSourceIP], NULLIF(LTRIM(RTRIM(CAST(c.[OriginationDestinationIP] AS nvarchar(400)))), N'') AS [OriginationDestinationIP], NULLIF(LTRIM(RTRIM(CAST(c.[Rpid_PAI] AS nvarchar(400)))), N'') AS [Rpid_PAI] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER), N'{}') AS AtributosExtendidos,
                   c.usd_exchange AS o_TipoCambio,
                   NULLIF(LTRIM(RTRIM(CAST(c.CustomerCircuitNumber AS nvarchar(100)))), N'') AS o_Circuito,
                   CASE WHEN v.Circuito IS NOT NULL AND ci.ServicioId IS NULL THEN v.Circuito END AS o_ServicioCircuito,
                   CASE WHEN c.IngressTrunk IS NOT NULL AND ti.TroncalId IS NULL AND pi.Codigo IS NULL THEN CAST(c.IngressTrunk AS nvarchar(20)) END AS o_TroncalEntrada,
                   CASE WHEN c.EgressTrunk IS NOT NULL AND te.TroncalId IS NULL AND pe.Codigo IS NULL THEN CAST(c.EgressTrunk AS nvarchar(20)) END AS o_TroncalSalida,
                   ROW_NUMBER() OVER (PARTITION BY CONVERT(nvarchar(66), HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(4000), c.[CDRTypeCode]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[CDRTypeReason]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[StartDateTime]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[AnswerTimeOfDate]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[DisconnectDateTime]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[IngressTrunk]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[EgressTrunk]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[DialedNumber]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[usd_exchange]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[Destination]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[DestinationCode]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[DestinationRate]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[DestinationRateNoProfit]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[DestinationRound]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[DurationInSeconds]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[DurationInRoundedSeconds]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[DurationInMinutes]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[CallCost]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[CallCostNoProfit]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[CallingNumber]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[BillingNumber]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[VoipDevice]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[CustomerIncrement]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[CustomerPorcentage]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[CustomerCircuitNumber]), N'~'), ISNULL(CONVERT(nvarchar(4000), c.[RoutingDigits]), N'~'))), 2) ORDER BY CAST(c._id AS nvarchar(200))) AS o_Repetida
            FROM stg.mongo_Telephony_cdr c
            CROSS APPLY (SELECT ctl.fn_Circuito(CONVERT(nvarchar(100), c.CustomerCircuitNumber)) AS Circuito) v
            LEFT JOIN #circ ci0 ON ci0.Circuito = v.Circuito
            OUTER APPLY (SELECT CASE WHEN ci0.n = 1 THEN ci0.ServicioId END AS ServicioId) ci
            LEFT JOIN #tron ti ON ti.Codigo = c.IngressTrunk AND ti.n = 1
            LEFT JOIN #tron te ON te.Codigo = c.EgressTrunk AND te.n = 1
            LEFT JOIN #tprov pi ON pi.Codigo = c.IngressTrunk
            LEFT JOIN #tprov pe ON pe.Codigo = c.EgressTrunk
            WHERE c.StartDateTime IS NOT NULL AND c.StartDateTime >= @Corte
              AND (@Desde IS NULL OR c.StartDateTime >= @Desde) AND (@Hasta IS NULL OR c.StartDateTime < @Hasta)
        ) q
        OUTER APPLY (SELECT TOP 1 t.Venta FROM ref.TipoCambio t WHERE t.Fecha <= CAST(q.FechaInicio AS date) ORDER BY t.Fecha DESC) tc
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 2. Filtros de carga: filas excluidas con la regla que las excluye (DD-06) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'DD-01', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'Llamada idéntica a otra del mismo período (todas las columnas salvo el id)', @Ahora FROM #src s WHERE s.o_Repetida > 1
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'DD-01' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE s FROM #src s WHERE s.o_Repetida > 1;
    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FechaInicio obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FechaInicio] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FuenteLlave obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FuenteLlave] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE FROM #src WHERE [FechaInicio] IS NULL OR [FuenteLlave] IS NULL;

    /* 2b. Duplicados por la llave del paso (DD-04); el orden es determinista */
    ;WITH r AS (
        SELECT s.FuenteSistema, s.FuenteTabla, s.FuenteLlave,
               ROW_NUMBER() OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.FuenteLlave) AS rn,
               FIRST_VALUE(s.FuenteLlave) OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.FuenteLlave ROWS UNBOUNDED PRECEDING) AS Conservada
        FROM #src s)
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, LlaveConservada, Motivo, FechaDescarte)
    SELECT @LoteId, 'DD-04', r.FuenteSistema, r.FuenteTabla, r.FuenteLlave, r.Conservada, N'Registro repetido por la llave del paso; se conserva uno según el orden definido', @Ahora
    FROM r WHERE r.rn > 1
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'DD-04' AND x.FuenteTabla = r.FuenteTabla AND x.FuenteLlave = r.FuenteLlave);
    ;WITH r AS (
        SELECT ROW_NUMBER() OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.FuenteLlave) AS rn FROM #src s)
    DELETE FROM r WHERE rn > 1;
    DECLARE @Validas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 3. Imagen previa de las filas que van a cambiar (para el rollback) */
    DROP TABLE IF EXISTS #antes;
    SELECT t.[LlamadaId] AS RegistroId, t.FuenteLlave, (SELECT t.[ServicioId], t.[TroncalEntradaId], t.[TroncalSalidaId], t.[Circuito], t.[TipoCDR], t.[RazonCDR], t.[FechaInicio], t.[FechaRespuesta], t.[FechaFin], t.[NumeroOrigen], t.[NumeroMarcado], t.[NumeroFacturacion], t.[DigitosRuteo], t.[Destino], t.[CodigoDestino], t.[Dispositivo], t.[DuracionSegundos], t.[DuracionSegundosRedondeada], t.[DuracionMinutos], t.[RedondeoDestino], t.[IncrementoCliente], t.[PorcentajeCliente], t.[Moneda], t.[TipoCambio], t.[TarifaDestino], t.[TarifaDestinoCRC], t.[TarifaSinMargen], t.[TarifaSinMargenCRC], t.[Costo], t.[CostoCRC], t.[CostoSinMargen], t.[CostoSinMargenCRC], t.[AtributosExtendidos], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.Llamada t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido;

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.Llamada WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido) THEN
        UPDATE SET t.[ServicioId] = s.[ServicioId], t.[TroncalEntradaId] = s.[TroncalEntradaId], t.[TroncalSalidaId] = s.[TroncalSalidaId], t.[Circuito] = s.[Circuito], t.[TipoCDR] = s.[TipoCDR], t.[RazonCDR] = s.[RazonCDR], t.[FechaInicio] = s.[FechaInicio], t.[FechaRespuesta] = s.[FechaRespuesta], t.[FechaFin] = s.[FechaFin], t.[NumeroOrigen] = s.[NumeroOrigen], t.[NumeroMarcado] = s.[NumeroMarcado], t.[NumeroFacturacion] = s.[NumeroFacturacion], t.[DigitosRuteo] = s.[DigitosRuteo], t.[Destino] = s.[Destino], t.[CodigoDestino] = s.[CodigoDestino], t.[Dispositivo] = s.[Dispositivo], t.[DuracionSegundos] = s.[DuracionSegundos], t.[DuracionSegundosRedondeada] = s.[DuracionSegundosRedondeada], t.[DuracionMinutos] = s.[DuracionMinutos], t.[RedondeoDestino] = s.[RedondeoDestino], t.[IncrementoCliente] = s.[IncrementoCliente], t.[PorcentajeCliente] = s.[PorcentajeCliente], t.[Moneda] = s.[Moneda], t.[TipoCambio] = s.[TipoCambio], t.[TarifaDestino] = s.[TarifaDestino], t.[TarifaDestinoCRC] = s.[TarifaDestinoCRC], t.[TarifaSinMargen] = s.[TarifaSinMargen], t.[TarifaSinMargenCRC] = s.[TarifaSinMargenCRC], t.[Costo] = s.[Costo], t.[CostoCRC] = s.[CostoCRC], t.[CostoSinMargen] = s.[CostoSinMargen], t.[CostoSinMargenCRC] = s.[CostoSinMargenCRC], t.[AtributosExtendidos] = s.[AtributosExtendidos], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([ServicioId], [TroncalEntradaId], [TroncalSalidaId], [Circuito], [TipoCDR], [RazonCDR], [FechaInicio], [FechaRespuesta], [FechaFin], [NumeroOrigen], [NumeroMarcado], [NumeroFacturacion], [DigitosRuteo], [Destino], [CodigoDestino], [Dispositivo], [DuracionSegundos], [DuracionSegundosRedondeada], [DuracionMinutos], [RedondeoDestino], [IncrementoCliente], [PorcentajeCliente], [Moneda], [TipoCambio], [TarifaDestino], [TarifaDestinoCRC], [TarifaSinMargen], [TarifaSinMargenCRC], [Costo], [CostoCRC], [CostoSinMargen], [CostoSinMargenCRC], [AtributosExtendidos], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[ServicioId], s.[TroncalEntradaId], s.[TroncalSalidaId], s.[Circuito], s.[TipoCDR], s.[RazonCDR], s.[FechaInicio], s.[FechaRespuesta], s.[FechaFin], s.[NumeroOrigen], s.[NumeroMarcado], s.[NumeroFacturacion], s.[DigitosRuteo], s.[Destino], s.[CodigoDestino], s.[Dispositivo], s.[DuracionSegundos], s.[DuracionSegundosRedondeada], s.[DuracionMinutos], s.[RedondeoDestino], s.[IncrementoCliente], s.[PorcentajeCliente], s.[Moneda], s.[TipoCambio], s.[TarifaDestino], s.[TarifaDestinoCRC], s.[TarifaSinMargen], s.[TarifaSinMargenCRC], s.[Costo], s.[CostoCRC], s.[CostoSinMargen], s.[CostoSinMargenCRC], s.[AtributosExtendidos], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[LlamadaId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.Llamada', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.Llamada', t.[LlamadaId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.Llamada t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ID-01', N'core.Llamada', t.[LlamadaId], N'Circuito', LEFT(CONVERT(nvarchar(400), s.o_Circuito), 400), N'Circuito que no cumple el patrón aprobado'
    FROM #src s JOIN core.Llamada t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_Circuito IS NOT NULL AND s.Circuito IS NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ID-07', N'core.Llamada', t.[LlamadaId], N'ServicioId', LEFT(CONVERT(nvarchar(400), s.o_ServicioCircuito), 400), N'Circuito de la llamada sin un único servicio en el modelo'
    FROM #src s JOIN core.Llamada t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_ServicioCircuito IS NOT NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.Llamada', t.[LlamadaId], N'TroncalEntradaId', LEFT(CONVERT(nvarchar(400), s.o_TroncalEntrada), 400), N'Troncal de entrada que no es de un cliente ni de un proveedor'
    FROM #src s JOIN core.Llamada t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_TroncalEntrada IS NOT NULL;
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'IN-01', N'core.Llamada', t.[LlamadaId], N'TroncalSalidaId', LEFT(CONVERT(nvarchar(400), s.o_TroncalSalida), 400), N'Troncal de salida que no es de un cliente ni de un proveedor'
    FROM #src s JOIN core.Llamada t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s.o_TroncalSalida IS NOT NULL;

    SELECT @Leidas AS FilasLeidas, @Validas - (SELECT COUNT_BIG(*) FROM #cambios) AS FilasSinCambio;
END;
GO
