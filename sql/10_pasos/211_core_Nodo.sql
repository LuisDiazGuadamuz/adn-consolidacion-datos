USE ADN_Unificado;
GO
/* Paso 211 · core_Nodo → core.Nodo
   Nodos de red.
   Reglas: ES-01, ES-05, DD-02, DD-06, IN-05
   GENERADO por adn_etl.generador: no editar a mano. */
CREATE OR ALTER PROCEDURE etl.usp_core_Nodo @LoteId int, @Desde date = NULL, @Hasta date = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');

    /* 1. Origen normalizado */
    DROP TABLE IF EXISTS #src;
    SELECT CAST(q.[NodoCrmId] AS nvarchar(30)) COLLATE DATABASE_DEFAULT AS [NodoCrmId],
           CAST(q.[Nombre] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [Nombre],
           CAST(q.[Nomenclatura] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Nomenclatura],
           CAST(q.[Estado] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Estado],
           CAST(q.[Capacidad] AS nvarchar(50)) COLLATE DATABASE_DEFAULT AS [Capacidad],
           q.[CantidadClientes],
           CAST(q.[Provincia] AS nvarchar(60)) COLLATE DATABASE_DEFAULT AS [Provincia],
           CAST(q.[Direccion] AS nvarchar(1000)) COLLATE DATABASE_DEFAULT AS [Direccion],
           q.[Latitud],
           q.[Longitud],
           q.[AtributosExtendidos] COLLATE DATABASE_DEFAULT AS [AtributosExtendidos],
           q.[FechaCreacionOrigen],
           q.[FechaModificacionOrigen],
           CAST(q.[FuenteSistema] AS varchar(20)) COLLATE DATABASE_DEFAULT AS [FuenteSistema],
           CAST(q.[FuenteBase] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteBase],
           CAST(q.[FuenteTabla] AS nvarchar(128)) COLLATE DATABASE_DEFAULT AS [FuenteTabla],
           CAST(q.[FuenteLlave] AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS [FuenteLlave],
           q.[FechaDato],
           HASHBYTES('SHA2_256', CONCAT_WS(N'|', ISNULL(CONVERT(nvarchar(max), q.[NodoCrmId]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Nombre]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Nomenclatura]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Estado]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Capacidad]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[CantidadClientes]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Provincia]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Direccion]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Latitud]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[Longitud]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[AtributosExtendidos]), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaCreacionOrigen], 126), N'~'), ISNULL(CONVERT(nvarchar(max), q.[FechaModificacionOrigen], 126), N'~'), CAST(NULL AS nvarchar(1)))) AS HashContenido,
           q.[o_Eliminado],
           CONCAT_WS(N',', CASE WHEN LEN(q.[NodoCrmId]) > 30 THEN N'NodoCrmId' END, CASE WHEN LEN(q.[Nombre]) > 200 THEN N'Nombre' END, CASE WHEN LEN(q.[Nomenclatura]) > 50 THEN N'Nomenclatura' END, CASE WHEN LEN(q.[Estado]) > 50 THEN N'Estado' END, CASE WHEN LEN(q.[Capacidad]) > 50 THEN N'Capacidad' END, CASE WHEN LEN(q.[Provincia]) > 60 THEN N'Provincia' END, CASE WHEN LEN(q.[Direccion]) > 1000 THEN N'Direccion' END, CAST(NULL AS nvarchar(1))) AS _Recortadas
    INTO #src
    FROM (
        SELECT 'ZohoCRM' AS FuenteSistema, N'Zoho_Mirror' AS FuenteBase, N'Nodos' AS FuenteTabla, ctl.fn_Texto(n.id) AS FuenteLlave,
               ctl.fn_FechaCR(n.Created_Time) AS FechaDato,
               ctl.fn_Texto(n.id) AS NodoCrmId, ctl.fn_Texto(n.Name) AS Nombre, ctl.fn_Texto(n.Nomenclatura) AS Nomenclatura,
               ctl.fn_Texto(n.Estado_de_Nodo) AS Estado, ctl.fn_Texto(n.Capacidad) AS Capacidad,
               TRY_CONVERT(int, ctl.fn_PrimerNumero(n.Cantidad_de_Clientes)) AS CantidadClientes, ctl.fn_Texto(n.Provincia) AS Provincia,
               ctl.fn_Texto(CONVERT(nvarchar(max), n.Direcci_n)) AS Direccion,
               ctl.fn_Coordenada(n.Coordenadas, 1) AS Latitud, ctl.fn_Coordenada(n.Coordenadas, 2) AS Longitud,
               NULLIF((SELECT ctl.fn_Texto(CONVERT(nvarchar(max), n.[Enviar_Correo])) AS [Enviar_Correo], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Modelo_Switch_Secundario])) AS [Modelo_Switch_Secundario], ctl.fn_Texto(CONVERT(nvarchar(max), n.[MRC_ISP])) AS [MRC_ISP], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Tiempo_de_Respaldo_de_Baterias])) AS [Tiempo_de_Respaldo_de_Baterias], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Marca_del_Router])) AS [Marca_del_Router], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Horario_de_Ingreso])) AS [Horario_de_Ingreso], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Backup_En_Nodo])) AS [Backup_En_Nodo], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Esperar_Permisos_de_Admin])) AS [Esperar_Permisos_de_Admin], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Modified_By])) AS [Modified_By], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Cantidad_de_Baterias])) AS [Cantidad_de_Baterias], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Nodo_Asociado1])) AS [Nodo_Asociado1], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Celular_1])) AS [Celular_1], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Proveedore_de_Servicio_El_ctrico])) AS [Proveedore_de_Servicio_El_ctrico], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Celular_2])) AS [Celular_2], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Correo_electronico_2])) AS [Correo_electronico_2], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Llamar_antes])) AS [Llamar_antes], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Guarda])) AS [Guarda], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Tipo_de_Generador])) AS [Tipo_de_Generador], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Tipo_de_Inversor])) AS [Tipo_de_Inversor], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Modelo_Router])) AS [Modelo_Router], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Condici_n])) AS [Condici_n], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Tel_fono_2])) AS [Tel_fono_2], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Tel_fono_1])) AS [Tel_fono_1], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Fecha_fabricacion_baterias_Inversor])) AS [Fecha_fabricacion_baterias_Inversor], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Sensor_de_Temperatura])) AS [Sensor_de_Temperatura], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Exchange_Rate])) AS [Exchange_Rate], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Unsubscribed_Mode])) AS [Unsubscribed_Mode], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Sensor_de_Puerta])) AS [Sensor_de_Puerta], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Last_Activity_Time])) AS [Last_Activity_Time], ctl.fn_Texto(CONVERT(nvarchar(max), n.[ISP_Externo])) AS [ISP_Externo], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Aire_Acondicionado])) AS [Aire_Acondicionado], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Sensor_de_Movimiento])) AS [Sensor_de_Movimiento], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Email])) AS [Email], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Tag])) AS [Tag], ctl.fn_Texto(CONVERT(nvarchar(max), n.[N_Medidor_Electrico])) AS [N_Medidor_Electrico], ctl.fn_Texto(CONVERT(nvarchar(max), n.[UPS_de_Back_Up])) AS [UPS_de_Back_Up], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Due_o_Medidor])) AS [Due_o_Medidor], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Camara_de_Seguridad])) AS [Camara_de_Seguridad], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Contrato_o_NISE])) AS [Contrato_o_NISE], ctl.fn_Texto(CONVERT(nvarchar(max), n.[IP_Inversor])) AS [IP_Inversor], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Seguridad_o_Guarda])) AS [Seguridad_o_Guarda], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Email_Opt_Out])) AS [Email_Opt_Out], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Fecha_Fabricaci_n_de_Baterias])) AS [Fecha_Fabricaci_n_de_Baterias], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Vehiculo_para_ingreso])) AS [Vehiculo_para_ingreso], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Record_Image])) AS [Record_Image], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Cantidad_de_Baterias_Inversor])) AS [Cantidad_de_Baterias_Inversor], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Contacto_2])) AS [Contacto_2], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Contacto_1])) AS [Contacto_1], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Telefono_Proveedor_electrico_2])) AS [Telefono_Proveedor_electrico_2], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Banco_de_Baterias_Inversor])) AS [Banco_de_Baterias_Inversor], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Telefono_Proveedor_electrico_1])) AS [Telefono_Proveedor_electrico_1], ctl.fn_Texto(CONVERT(nvarchar(max), n.[ID_ISP])) AS [ID_ISP], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Modelo_Switch])) AS [Modelo_Switch], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Created_By])) AS [Created_By], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Altura_Torre])) AS [Altura_Torre], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Generador])) AS [Generador], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Banco_de_Bateria])) AS [Banco_de_Bateria], ctl.fn_Texto(CONVERT(nvarchar(max), n.[N_Localizacion])) AS [N_Localizacion], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Monitoreo_Electrico])) AS [Monitoreo_Electrico], ctl.fn_Texto(CONVERT(nvarchar(max), n.[IP_UPS])) AS [IP_UPS], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Modelo_Router_MikroTik])) AS [Modelo_Router_MikroTik], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Currency])) AS [Currency], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Tipo_de_Torre])) AS [Tipo_de_Torre], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Tipo_UPS])) AS [Tipo_UPS], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Marca_del_Switch])) AS [Marca_del_Switch], ctl.fn_Texto(CONVERT(nvarchar(max), n.[IP_Monitoreo_Electrico])) AS [IP_Monitoreo_Electrico], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Ordenes_de_trabajo])) AS [Ordenes_de_trabajo], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Marca_Switch_Secundario])) AS [Marca_Switch_Secundario], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Tiempo_de_Traslado_desde_San_Jose])) AS [Tiempo_de_Traslado_desde_San_Jose], ctl.fn_Texto(CONVERT(nvarchar(max), n.[Owner])) AS [Owner] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER), N'{}') AS AtributosExtendidos,
               ctl.fn_FechaCR(n.Created_Time) AS FechaCreacionOrigen, ctl.fn_FechaCR(n.Modified_Time) AS FechaModificacionOrigen,
               CAST(ISNULL(n.deleted, 0) AS int) AS o_Eliminado
        FROM Zoho_Mirror.dbo.Nodos n
    ) AS q;
    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 2. Filtros de carga: filas excluidas con la regla que las excluye (DD-06) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'DD-06', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'Registro marcado como eliminado en Zoho (deleted = 1)', @Ahora FROM #src s WHERE s.o_Eliminado = 1
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'DD-06' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE s FROM #src s WHERE s.o_Eliminado = 1;
    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'NodoCrmId obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[NodoCrmId] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)
    SELECT @LoteId, 'ES-05', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'FuenteLlave obligatorio vacío o sin correspondencia', @Ahora
    FROM #src s WHERE s.[FuenteLlave] IS NULL
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'ES-05' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);
    DELETE FROM #src WHERE [NodoCrmId] IS NULL OR [FuenteLlave] IS NULL;

    /* 2b. Duplicados por la llave del paso (DD-02); el orden es determinista */
    ;WITH r AS (
        SELECT s.FuenteSistema, s.FuenteTabla, s.FuenteLlave,
               ROW_NUMBER() OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.FechaModificacionOrigen DESC, s.HashContenido) AS rn,
               FIRST_VALUE(s.FuenteLlave) OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.FechaModificacionOrigen DESC, s.HashContenido ROWS UNBOUNDED PRECEDING) AS Conservada
        FROM #src s)
    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, LlaveConservada, Motivo, FechaDescarte)
    SELECT @LoteId, 'DD-02', r.FuenteSistema, r.FuenteTabla, r.FuenteLlave, r.Conservada, N'Versión anterior del mismo nodo en el espejo de Zoho', @Ahora
    FROM r WHERE r.rn > 1
      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'
                      WHERE x.ReglaId = 'DD-02' AND x.FuenteTabla = r.FuenteTabla AND x.FuenteLlave = r.FuenteLlave);
    ;WITH r AS (
        SELECT ROW_NUMBER() OVER (PARTITION BY s.[FuenteSistema], s.[FuenteTabla], s.[FuenteLlave] ORDER BY s.FechaModificacionOrigen DESC, s.HashContenido) AS rn FROM #src s)
    DELETE FROM r WHERE rn > 1;
    DECLARE @Validas bigint = (SELECT COUNT_BIG(*) FROM #src);

    /* 3. Imagen previa de las filas que van a cambiar (para el rollback) */
    DROP TABLE IF EXISTS #antes;
    SELECT t.[NodoId] AS RegistroId, t.FuenteLlave, (SELECT t.[NodoCrmId], t.[Nombre], t.[Nomenclatura], t.[Estado], t.[Capacidad], t.[CantidadClientes], t.[Provincia], t.[Direccion], t.[Latitud], t.[Longitud], t.[AtributosExtendidos], t.[FechaCreacionOrigen], t.[FechaModificacionOrigen], t.[FuenteSistema], t.[FuenteBase], t.[FuenteTabla], t.[FuenteLlave], t.[FechaDato], t.[LoteId], t.[FechaCarga], CONVERT(varchar(66), t.[HashContenido], 1) AS [HashContenido] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS Json
    INTO #antes FROM core.Nodo t JOIN #src s ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido;

    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */
    DROP TABLE IF EXISTS #cambios;
    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);
    MERGE core.Nodo WITH (HOLDLOCK) AS t
    USING #src AS s
       ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido) THEN
        UPDATE SET t.[NodoCrmId] = s.[NodoCrmId], t.[Nombre] = s.[Nombre], t.[Nomenclatura] = s.[Nomenclatura], t.[Estado] = s.[Estado], t.[Capacidad] = s.[Capacidad], t.[CantidadClientes] = s.[CantidadClientes], t.[Provincia] = s.[Provincia], t.[Direccion] = s.[Direccion], t.[Latitud] = s.[Latitud], t.[Longitud] = s.[Longitud], t.[AtributosExtendidos] = s.[AtributosExtendidos], t.[FechaCreacionOrigen] = s.[FechaCreacionOrigen], t.[FechaModificacionOrigen] = s.[FechaModificacionOrigen], t.[FuenteSistema] = s.[FuenteSistema], t.[FuenteBase] = s.[FuenteBase], t.[FuenteTabla] = s.[FuenteTabla], t.[FuenteLlave] = s.[FuenteLlave], t.[FechaDato] = s.[FechaDato], t.[HashContenido] = s.[HashContenido], t.LoteId = @LoteId, t.FechaCarga = @Ahora
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([NodoCrmId], [Nombre], [Nomenclatura], [Estado], [Capacidad], [CantidadClientes], [Provincia], [Direccion], [Latitud], [Longitud], [AtributosExtendidos], [FechaCreacionOrigen], [FechaModificacionOrigen], [FuenteSistema], [FuenteBase], [FuenteTabla], [FuenteLlave], [FechaDato], [HashContenido], LoteId, FechaCarga)
        VALUES (s.[NodoCrmId], s.[Nombre], s.[Nomenclatura], s.[Estado], s.[Capacidad], s.[CantidadClientes], s.[Provincia], s.[Direccion], s.[Latitud], s.[Longitud], s.[AtributosExtendidos], s.[FechaCreacionOrigen], s.[FechaModificacionOrigen], s.[FuenteSistema], s.[FuenteBase], s.[FuenteTabla], s.[FuenteLlave], s.[FechaDato], s.[HashContenido], @LoteId, @Ahora)
    OUTPUT $action, inserted.[NodoId], inserted.FuenteLlave INTO #cambios;

    /* 5. Bitácora por registro */
    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)
    SELECT @LoteId, N'core.Nodo', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json
    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';

    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),
       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */
    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)
    SELECT @LoteId, 'ES-05', N'core.Nodo', t.[NodoId], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'
    FROM #src s JOIN core.Nodo t ON t.[FuenteSistema] = s.[FuenteSistema] AND t.[FuenteTabla] = s.[FuenteTabla] AND t.[FuenteLlave] = s.[FuenteLlave]
    WHERE s._Recortadas <> N'';
    -- sin reglas de anomalía en este paso

    SELECT @Leidas AS FilasLeidas, @Validas - (SELECT COUNT_BIG(*) FROM #cambios) AS FilasSinCambio;
END;
GO
