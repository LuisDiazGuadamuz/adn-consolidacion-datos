# -*- coding: utf-8 -*-
"""Especificación única del modelo unificado (fuente de verdad para el DDL, el diccionario y el diagrama).
Sprint 2 - American Data Networks. Autor: Luis Felipe Díaz Guadamuz.
"""

def N(n): return f"nvarchar({n})"
def V(n): return f"varchar({n})"
DT = "datetimeoffset(0)"; D = "date"; M = "decimal(19,4)"; TC = "decimal(19,6)"; MON = "char(3)"
B = "bit"; I = "int"; BI = "bigint"; TXT = "nvarchar(max)"; JSON = "nvarchar(max)"; GEO = "decimal(10,7)"; DUR = "decimal(12,2)"

def c(name, typ, null=True, desc="", regla=""):
    return dict(name=name, type=typ, null=null, desc=desc, regla=regla)

def pk(name, typ=I, desc="Llave sustituta del modelo"):
    return dict(name=name, type=typ, null=False, desc=desc, regla="", pk=True, identity=True)

def fk(name, ref, null=True, desc="", regla="IN-01"):
    return dict(name=name, type=I if not ref.endswith("Llamada") else BI, null=null, desc=desc, regla=regla, fk=ref)

def dinero(prefijo, desc):
    """Monto en moneda original y su equivalente en colones (D5)."""
    return [c(prefijo, M, True, desc + " en la moneda original", "ES-04"),
            c(prefijo + "CRC", M, True, desc + " convertido a colones con el tipo de cambio del día", "D5")]

MONEDA = [c("Moneda", MON, True, "Código ISO de la moneda original (CRC, USD)", "ES-04"),
          c("TipoCambio", TC, True, "Tipo de cambio a colones usado en la conversión (ref.TipoCambio o el del documento)", "D5")]
EXT = c("AtributosExtendidos", JSON, True, "Campos de origen sin columna propia, guardados como JSON {nombre_origen: valor}", "ES-05")
AUD = [c("FechaCreacionOrigen", DT, True, "Fecha de creación del registro en el sistema de origen", "ES-01"),
       c("FechaModificacionOrigen", DT, True, "Fecha de la última modificación en el sistema de origen", "ES-01")]

# Columnas de linaje que llevan todas las tablas de los esquemas core y ref (IN-05)
LINAJE = [
    c("FuenteSistema", V(20), False, "Sistema de origen: ZohoCRM, ZohoBooks, AppDataCR, ADNPayV2, Navsat, Trengo, HistoryTables", "IN-05"),
    c("FuenteBase", N(128), False, "Base de datos de origen (SQL Server) o base MongoDB", "IN-05"),
    c("FuenteTabla", N(128), False, "Tabla o colección de origen", "IN-05"),
    c("FuenteLlave", N(200), False, "Valor de la llave del registro en el origen", "IN-05"),
    c("FechaDato", DT, True, "Fecha de negocio del registro; define el período del dato", "IN-05"),
    c("PeriodoDato", "computed", True, "Año y mes del dato (AAAA-MM), calculado a partir de FechaDato", "IN-05"),
    c("LoteId", I, False, "Lote de carga que creó o actualizó el registro (ctl.Lote)", "IN-05"),
    c("FechaCarga", DT, False, "Fecha y hora de la carga, en hora de Costa Rica (-06:00)", "IN-05"),
    c("HashContenido", "binary(32)", True, "SHA-256 del contenido de origen; detecta duplicados y cambios", "DD-01"),
]

T = []  # lista de tablas

def tabla(schema, name, area, desc, grano, cols, uniques=None, linaje=True, origen=""):
    T.append(dict(schema=schema, name=name, area=area, desc=desc, grano=grano, cols=cols,
                  uniques=uniques or [], linaje=linaje, origen=origen))

# ---------------------------------------------------------------- CONTROL (ctl)
tabla("ctl", "Regla", "Control", "Catálogo de reglas aprobadas (v1.0, 06/10/2026)", "Una fila por regla o decisión",
      [c("ReglaId", V(10), False, "Código de la regla (ID-01, DD-01, D5...)"), c("Tipo", V(20), False, "Identidad, Deduplicación, Estandarización, Integridad o Decisión"),
       c("Descripcion", N(1000), False, "Texto de la regla"), c("Criticidad", V(10), False, "Crítica o Estándar"),
       c("OpcionAprobada", V(5), True, "Opción elegida en las decisiones"), c("Version", V(10), False, "Versión del catálogo"),
       c("FechaAprobacion", D, True, "Fecha de aprobación"), c("AprobadoPor", N(100), True, "Responsable que aprobó")],
      linaje=False, origen="Catálogo de reglas v1.0")
T[-1]["pkcol"] = "ReglaId"
tabla("ctl", "Fuente", "Control", "Catálogo de tablas y colecciones de origen", "Una fila por tabla de origen",
      [pk("FuenteId"), c("Sistema", V(20), False, "Sistema de origen"), c("Motor", V(20), False, "SQLServer o MongoDB"),
       c("Base", N(128), False, "Base de datos"), c("Tabla", N(128), False, "Tabla o colección"),
       c("Disposicion", V(20), False, "Cargada, Complemento o Descartada"), c("MotivoDisposicion", N(400), True, "Motivo, si se descarta"),
       c("PeriodoDesde", D, True, "Inicio del período de datos"), c("PeriodoHasta", D, True, "Fin del período de datos")],
      uniques=[["Motor", "Base", "Tabla"]], linaje=False, origen="Inventario del Sprint 1")
tabla("ctl", "Lote", "Control", "Ejecución de un proceso de carga", "Una fila por ejecución y fuente",
      [pk("LoteId"), fk("FuenteId", "ctl.Fuente", False, "Fuente cargada", ""), c("FechaInicio", DT, False, "Inicio de la ejecución"),
       c("FechaFin", DT, True, "Fin de la ejecución"), c("Estado", V(15), False, "EnCurso, Exitoso, Fallido"),
       c("FilasLeidas", BI, True, "Filas leídas del origen"), c("FilasCargadas", BI, True, "Filas insertadas o actualizadas"),
       c("FilasDescartadas", BI, True, "Filas enviadas a ctl.Descarte"), c("VersionReglas", V(10), False, "Versión del catálogo aplicada"),
       c("Usuario", N(100), False, "Usuario o proceso que ejecutó la carga")], linaje=False)
tabla("ctl", "Descarte", "Control", "Registros de origen no cargados, con la regla que los excluyó", "Una fila por registro descartado",
      [pk("DescarteId", BI), fk("LoteId", "ctl.Lote", False, "Lote", ""), fk("ReglaId", "ctl.Regla", False, "Regla aplicada", "DD-06"),
       c("FuenteSistema", V(20), False, "Sistema de origen", "IN-05"), c("FuenteTabla", N(128), False, "Tabla de origen", "IN-05"),
       c("FuenteLlave", N(200), True, "Llave de origen", "IN-05"), c("LlaveConservada", N(200), True, "Llave del registro que se conservó, si era duplicado", "DD-01"),
       c("Motivo", N(400), False, "Explicación del descarte"), c("ContenidoOrigen", JSON, True, "Copia del registro descartado en JSON", "DD-06"),
       c("FechaDescarte", DT, False, "Fecha del descarte")], linaje=False)
T[-1]["cols"][2]["type"] = V(10)
tabla("ctl", "Anomalia", "Control", "Valores marcados por una regla (fechas ficticias, futuras, huérfanos, cédulas inválidas)", "Una fila por valor marcado",
      [pk("AnomaliaId", BI), fk("LoteId", "ctl.Lote", False, "Lote", ""), fk("ReglaId", "ctl.Regla", False, "Regla", "ES-02"),
       c("TablaModelo", N(128), False, "Tabla del modelo"), c("RegistroId", BI, False, "Llave del registro en el modelo"),
       c("Columna", N(128), True, "Columna afectada"), c("ValorOriginal", N(400), True, "Valor tal como venía del origen"),
       c("Detalle", N(400), True, "Descripción de la anomalía")], linaje=False)
T[-1]["cols"][2]["type"] = V(10)
tabla("ctl", "LinajeCampo", "Control", "Origen de cada campo en las tablas que consolidan varios sistemas (Cliente, Servicio, Producto)", "Una fila por registro, columna y fuente ganadora",
      [pk("LinajeCampoId", BI), c("TablaModelo", N(128), False, "Tabla del modelo"), c("RegistroId", BI, False, "Llave del registro en el modelo"),
       c("Columna", N(128), False, "Columna del modelo"), c("FuenteSistema", V(20), False, "Sistema que aportó el valor", "D9"),
       c("FuenteTabla", N(128), False, "Tabla de origen", "IN-05"), c("FuenteLlave", N(200), False, "Llave de origen", "IN-05"),
       c("FechaDato", DT, True, "Fecha del dato en el origen", "IN-05"), fk("LoteId", "ctl.Lote", False, "Lote", "")],
      uniques=[["TablaModelo", "RegistroId", "Columna"]], linaje=False)

# ---------------------------------------------------------------- REFERENCIA (ref)
tabla("ref", "TipoCambio", "Referencia", "Tipo de cambio del dólar por día", "Una fila por fecha",
      [pk("TipoCambioId"), c("Fecha", D, False, "Fecha"), c("Compra", TC, True, "Tipo de cambio de compra"),
       c("Venta", TC, True, "Tipo de cambio de venta; se usa para convertir a colones", "D5")],
      uniques=[["Fecha"]], origen="ADNApp / app.data.cr: Telephony_usdexchange")
tabla("ref", "Usuario", "Referencia", "Usuarios de Zoho (ejecutivos, técnicos, agentes)", "Una fila por usuario de Zoho",
      [pk("UsuarioId"), c("ZohoUsuarioId", N(30), False, "ID de usuario en Zoho"), c("NombreCompleto", N(200), True, ""),
       c("Correo", N(200), True, ""), c("Telefono", N(30), True, ""), c("Rol", N(100), True, ""), c("Perfil", N(100), True, ""),
       c("Division", N(100), True, ""), c("Estado", N(30), True, ""), EXT] + AUD,
      uniques=[["ZohoUsuarioId"]], origen="Zoho_Mirror.Users; ADNApp.ZohoEngine_zohouser")
tabla("ref", "Provincia", "Referencia", "Provincias de Costa Rica", "Una fila por provincia",
      [pk("ProvinciaId"), c("Nombre", N(60), False, "")], uniques=[["Nombre"]], origen="ADNPayV2.AddressProvince")
tabla("ref", "Canton", "Referencia", "Cantones", "Una fila por cantón",
      [pk("CantonId"), fk("ProvinciaId", "ref.Provincia", False, "Provincia"), c("Nombre", N(80), False, "")], origen="ADNPayV2.AddressCanton")
tabla("ref", "Distrito", "Referencia", "Distritos", "Una fila por distrito",
      [pk("DistritoId"), fk("CantonId", "ref.Canton", False, "Cantón"), c("Nombre", N(80), False, "")], origen="ADNPayV2.AddressDistrict")
tabla("ref", "Impuesto", "Referencia", "Impuestos configurados en Zoho Books", "Una fila por impuesto",
      [pk("ImpuestoId"), c("ImpuestoBooksId", N(30), False, ""), c("Nombre", N(100), True, ""), c("Porcentaje", "decimal(9,4)", True, ""),
       c("Tipo", N(50), True, ""), c("EsPredeterminado", B, True, "", "ES-07"), EXT], uniques=[["ImpuestoBooksId"]], origen="ZBooks_Mirror.taxes")
tabla("ref", "CuentaContable", "Referencia", "Catálogo de cuentas contables de Zoho Books", "Una fila por cuenta",
      [pk("CuentaContableId"), c("CuentaBooksId", N(30), False, ""), fk("CuentaPadreId", "ref.CuentaContable", True, "Cuenta padre"),
       c("Codigo", N(50), True, ""), c("Nombre", N(200), True, ""), c("Tipo", N(50), True, ""), c("Descripcion", N(500), True, ""),
       c("EsDeSistema", B, True, "", "ES-07"), c("Activa", B, True, "", "ES-07"), EXT] + AUD,
      uniques=[["CuentaBooksId"]], origen="ZBooks_Mirror.chartofaccounts")
tabla("ref", "ProveedorTelefonia", "Referencia", "Proveedores de terminación de llamadas", "Una fila por proveedor",
      [pk("ProveedorTelefoniaId"), c("Nombre", N(100), False, ""), c("FechaActualizacionTarifas", DT, True, "", "ES-01")], origen="Telephony_provider")
tabla("ref", "TroncalProveedor", "Referencia", "Troncales de los proveedores de telefonía", "Una fila por troncal de proveedor",
      [pk("TroncalProveedorId"), fk("ProveedorTelefoniaId", "ref.ProveedorTelefonia", False, ""), c("CodigoTroncal", N(50), False, ""),
       c("Estado", N(30), True, "")], origen="Telephony_providertrunk")
tabla("ref", "TarifaDestino", "Referencia", "Tarifas por código de marcación (país y números especiales)", "Una fila por proveedor y código",
      [pk("TarifaDestinoId"), fk("ProveedorTelefoniaId", "ref.ProveedorTelefonia", True, "Nulo en números especiales"),
       c("CodigoMarcacion", V(20), False, ""), c("Nombre", N(150), True, ""), c("Tarifa", M, True, "", "ES-04"),
       c("Redondeo", "decimal(9,2)", True, ""), c("Costo", M, True, "", "ES-04"), c("EsNumeroEspecial", B, False, "")],
      origen="Telephony_countrydialcoderate; Telephony_specialnumberrate")
tabla("ref", "PaqueteMinutos", "Referencia", "Paquetes de minutos de telefonía", "Una fila por paquete",
      [pk("PaqueteMinutosId"), c("Codigo", N(30), False, ""), c("Descripcion", N(200), True, "")], origen="Telephony_minutepackage")
tabla("ref", "PaqueteMinutosCodigo", "Referencia", "Códigos de marcación incluidos en cada paquete", "Una fila por paquete y código",
      [pk("PaqueteMinutosCodigoId"), fk("PaqueteMinutosId", "ref.PaqueteMinutos", False, ""), c("CodigoMarcacion", V(20), False, "")],
      origen="Telephony_minutepackagedialcode")
tabla("ref", "CodigoPromocion", "Referencia", "Códigos promocionales de ADNPayV2", "Una fila por código",
      [pk("CodigoPromocionId"), c("Codigo", V(50), False, ""), c("Categoria", V(50), True, ""), c("Activo", B, True, "")],
      origen="ADNPayV2.Code; ADNPayV2.code_promo_condo")
tabla("ref", "UnidadFlota", "Referencia", "Vehículos y dispositivos de rastreo de Navsat", "Una fila por dispositivo",
      [pk("UnidadFlotaId"), c("Dispositivo", N(100), False, ""), c("Placa", N(30), True, "Solo cuando el valor es una placa", "ES-09"),
       c("TipoUnidad", V(20), False, "VehiculoEmpresa, VehiculoPropio o Colaborador", "ES-09"), c("Descripcion", N(200), True, "Valor original de plateNumber")],
      uniques=[["Dispositivo"]], origen="Navsat (todas las tablas)")

# ---------------------------------------------------------------- CLIENTE Y SERVICIO (core)
tabla("core", "Cliente", "Cliente y servicio", "Persona o empresa cliente, identificada por su cédula", "Una fila por cédula válida, o por cliente sin cédula",
      [pk("ClienteId"), c("Cedula", V(12), True, "Cédula normalizada: solo dígitos", "ID-02"),
       c("TipoIdentificacion", V(10), False, "FISICA (9), JURIDICA (10), DIMEX (12), INVALIDA o SIN_DATO", "ID-02"),
       c("Nombre", N(200), True, "Nombre o razón social comercial", "D9"), c("RazonSocial", N(200), True, "Razón social fiscal", "D9"),
       c("TipoFiscal", N(50), True, "", "D9"), c("Exonerado", B, True, "Exoneración fiscal", "D9"),
       c("Correo", N(200), True, "", "D9"), c("Telefono", N(30), True, "", "D9"), c("Segmento", N(50), True, "", "D9"),
       c("Industria", N(100), True, "", "D9"),
       c("EstadoCorrespondencia", V(20), False, "CRM, SOLO_BOOKS, SOLO_ADNPAY o SIN_CORRESPONDENCIA", "D8")],
      uniques=[["Cedula"]], origen="Consolidado: Zoho CRM, Zoho Books, ADNPayV2, app.data.cr")
T[-1]["filtered_unique"] = {"Cedula": "Cedula IS NOT NULL"}
T[-1]["uniques"] = []  # la unicidad la da el índice filtrado (admite varios NULL, D8)
tabla("core", "ClienteOrigen", "Cliente y servicio", "Tabla de correspondencia: cada identificador de origen y el cliente o servicio al que se vinculó", "Una fila por registro de origen",
      [pk("ClienteOrigenId"), fk("ClienteId", "core.Cliente", True, "Cliente vinculado", "ID-05"), fk("ServicioId", "core.Servicio", True, "Servicio vinculado", "ID-05"),
       c("Sistema", V(20), False, "", "ID-04"), c("TablaOrigen", N(128), False, "", "ID-04"), c("LlaveOrigen", N(200), False, "ID en el origen", "ID-04"),
       c("CedulaOriginal", N(50), True, "Valor sin normalizar", "ES-08"), c("CircuitoOriginal", N(100), True, "Valor sin normalizar", "ES-08"),
       c("MetodoEmparejamiento", V(20), False, "CIRCUITO, CEDULA, LLAVE_DIRECTA o SIN_CORRESPONDENCIA", "ID-05"),
       c("FechaEmparejamiento", DT, False, "")],
      uniques=[["Sistema", "TablaOrigen", "LlaveOrigen"]], origen="Generada en la carga")
tabla("core", "Servicio", "Cliente y servicio", "Servicio contratado, identificado por el número de circuito; corresponde a una cuenta del CRM", "Una fila por cuenta del CRM o circuito",
      [pk("ServicioId"), fk("ClienteId", "core.Cliente", True, "Titular del servicio", "ID-03"),
       c("Circuito", V(12), True, "Número de circuito normalizado", "ID-01"), c("CuentaCrmId", N(30), True, "ID de la cuenta en Zoho CRM", "ID-04"),
       c("NombreCuenta", N(200), True, ""), c("TipoCuenta", N(50), True, ""), c("Estado", N(50), True, ""),
       c("Plataforma", N(100), True, "Plataforma o tecnología del servicio"), c("CapacidadMbps", "decimal(9,2)", True, ""),
       c("TieneIPTV", B, True, "", "ES-07"), c("TieneVoIP", B, True, "", "ES-07"), c("NumeroTroncal", N(50), True, ""), c("LineaDID", N(50), True, ""),
       *MONEDA, *dinero("Mensualidad", "Mensualidad del servicio"),
       fk("DistritoId", "ref.Distrito", True, ""), c("Provincia", N(60), True, ""), c("Canton", N(80), True, ""), c("DistritoTexto", N(80), True, ""),
       c("DireccionExacta", N(1000), True, ""), c("Latitud", GEO, True, ""), c("Longitud", GEO, True, ""),
       fk("CondominioId", "core.Condominio", True, ""), fk("EjecutivoUsuarioId", "ref.Usuario", True, ""),
       c("FechaInstalacion", D, True, "", "ES-01"), c("FechaActivacion", DT, True, "", "ES-01"), c("FechaRetiro", D, True, "", "ES-01"),
       c("EstadoCorrespondencia", V(20), False, "", "D8"), EXT] + AUD,
      uniques=[["CuentaCrmId"]], origen="Zoho_Mirror.Accounts_Extended (principal) y Accounts (complemento)")
T[-1]["filtered_unique"] = {"Circuito": "Circuito IS NOT NULL", "CuentaCrmId": "CuentaCrmId IS NOT NULL"}
T[-1]["uniques"] = []
tabla("core", "Contacto", "Cliente y servicio", "Personas de contacto del CRM", "Una fila por contacto del CRM",
      [pk("ContactoId"), fk("ClienteId", "core.Cliente", True, "", "ID-05"), fk("ServicioId", "core.Servicio", True, "Cuenta del CRM asociada", "IN-01"),
       c("ContactoCrmId", N(30), False, "", "ID-04"), c("Nombre", N(100), True, ""), c("Apellido", N(100), True, ""), c("NombreCompleto", N(200), True, ""),
       c("Cedula", V(12), True, "Normalizada", "ID-02"), c("Correo", N(200), True, ""), c("Telefono", N(30), True, ""), c("Movil", N(30), True, ""),
       c("TipoContacto", N(50), True, ""), fk("PropietarioUsuarioId", "ref.Usuario", True, ""), EXT] + AUD,
      uniques=[["ContactoCrmId"]], origen="Zoho_Mirror.Contacts")
tabla("core", "Prospecto", "Comercial", "Prospectos de venta (CRM y registros en línea de ADNPayV2)", "Una fila por prospecto de origen",
      [pk("ProspectoId"), fk("ClienteId", "core.Cliente", True, "Cliente si se convirtió", "ID-05"), c("Cedula", V(12), True, "", "ID-02"),
       c("Nombre", N(100), True, ""), c("Apellido", N(100), True, ""), c("Empresa", N(200), True, ""), c("Correo", N(200), True, ""),
       c("Telefono", N(30), True, ""), c("Movil", N(30), True, ""), c("Estado", N(50), True, ""), c("Origen", N(100), True, ""),
       c("Segmento", N(50), True, ""), c("CondominioSolicitado", N(200), True, ""), fk("DireccionId", "core.Direccion", True, ""),
       c("Provincia", N(60), True, ""), c("Canton", N(80), True, ""), c("FechaRegistro", DT, True, "", "ES-01"),
       c("FechaConversion", DT, True, "", "ES-01"), c("CompraRealizada", B, True, "", "ES-07"), fk("PropietarioUsuarioId", "ref.Usuario", True, ""), EXT] + AUD,
      origen="Zoho_Mirror.Leads; ADNPayV2.CustomerProspect")
tabla("core", "Direccion", "Comercial", "Direcciones registradas en ADNPayV2", "Una fila por dirección",
      [pk("DireccionId"), fk("DistritoId", "ref.Distrito", True, ""), c("Descripcion", N(500), True, ""), c("Alias", N(100), True, ""),
       c("CodigoPostal", N(20), True, ""), c("Pais", N(60), True, "")], origen="ADNPayV2.AddressMain")

# ---------------------------------------------------------------- INFRAESTRUCTURA
tabla("core", "Condominio", "Infraestructura", "Condominios con cobertura o en proyecto", "Una fila por condominio",
      [pk("CondominioId"), c("CondominioCrmId", N(30), False, ""), c("Nombre", N(200), True, ""), c("Tipo", N(50), True, ""),
       c("TipoConstruccion", N(50), True, ""), c("CantidadCasas", I, True, ""), c("CapacidadMaxima", I, True, ""), c("AplicaFTTH", B, True, "", "ES-07"),
       c("Provincia", N(60), True, ""), c("Canton", N(80), True, ""), c("Distrito", N(80), True, ""), c("Direccion", N(1000), True, ""),
       c("Latitud", GEO, True, ""), c("Longitud", GEO, True, ""), c("FechaInstalacion", D, True, "", "ES-01"), EXT] + AUD,
      uniques=[["CondominioCrmId"]], origen="Zoho_Mirror.Condominios")
tabla("core", "Nodo", "Infraestructura", "Nodos de red", "Una fila por nodo",
      [pk("NodoId"), c("NodoCrmId", N(30), False, ""), c("Nombre", N(200), True, ""), c("Nomenclatura", N(50), True, ""),
       c("Estado", N(50), True, ""), c("Capacidad", N(50), True, ""), c("CantidadClientes", I, True, ""), c("Provincia", N(60), True, ""),
       c("Direccion", N(1000), True, ""), c("Latitud", GEO, True, ""), c("Longitud", GEO, True, ""), EXT] + AUD,
      uniques=[["NodoCrmId"]], origen="Zoho_Mirror.Nodos")
tabla("core", "ClusterFTTH", "Infraestructura", "Clústeres de fibra hasta el hogar", "Una fila por clúster",
      [pk("ClusterFTTHId"), c("ClusterCrmId", N(30), False, ""), c("Nombre", N(200), True, ""), c("CodigoCluster", N(50), True, ""),
       fk("NodoId", "core.Nodo", True, ""), c("Fase", N(50), True, ""), c("CapacidadRed", I, True, ""), c("CantidadClientes", I, True, ""),
       c("Provincia", N(60), True, ""), c("Canton", N(80), True, ""), c("Distrito", N(80), True, ""), c("FechaInstalacion", D, True, "", "ES-01"), EXT] + AUD,
      uniques=[["ClusterCrmId"]], origen="Zoho_Mirror.FTTHs")

# ---------------------------------------------------------------- COMERCIAL (CRM)
tabla("core", "Oportunidad", "Comercial", "Oportunidades de venta del CRM", "Una fila por oportunidad",
      [pk("OportunidadId"), c("OportunidadCrmId", N(30), False, ""), fk("ServicioId", "core.Servicio", True, "Cuenta asociada"),
       fk("ContactoId", "core.Contacto", True, ""), c("Nombre", N(200), True, ""), c("Etapa", N(50), True, ""), c("Probabilidad", "decimal(5,2)", True, ""),
       *MONEDA, *dinero("Monto", "Monto de la oportunidad"), c("FechaCierre", D, True, "", "ES-01"), c("Segmento", N(50), True, ""),
       fk("PropietarioUsuarioId", "ref.Usuario", True, ""), EXT] + AUD, uniques=[["OportunidadCrmId"]], origen="Zoho_Mirror.Deals")
tabla("core", "Cotizacion", "Comercial", "Cotizaciones del CRM", "Una fila por cotización",
      [pk("CotizacionId"), c("CotizacionCrmId", N(30), False, ""), fk("OportunidadId", "core.Oportunidad", True, ""),
       fk("ServicioId", "core.Servicio", True, ""), fk("ContactoId", "core.Contacto", True, ""), c("Asunto", N(300), True, ""),
       c("Etapa", N(50), True, ""), c("Tipo", N(50), True, ""), *MONEDA, *dinero("SubTotal", "Subtotal"), *dinero("Impuesto", "Impuesto"),
       *dinero("Descuento", "Descuento"), *dinero("Total", "Total"), c("FechaCotizacion", D, True, "", "ES-01"), EXT] + AUD,
      uniques=[["CotizacionCrmId"]], origen="Zoho_Mirror.Quotes")
tabla("core", "OrdenVenta", "Comercial", "Órdenes de venta y contratos del CRM", "Una fila por orden de venta",
      [pk("OrdenVentaId"), c("OrdenVentaCrmId", N(30), False, ""), fk("ServicioId", "core.Servicio", True, "Por cuenta o circuito", "ID-01"),
       fk("ContactoId", "core.Contacto", True, ""), fk("OportunidadId", "core.Oportunidad", True, ""), fk("CotizacionId", "core.Cotizacion", True, ""),
       c("Circuito", V(12), True, "", "ID-01"), c("Asunto", N(300), True, ""), c("Estado", N(50), True, ""), c("TipoContrato", N(100), True, ""),
       c("PlazoMeses", I, True, ""), c("CapacidadDescargaMbps", "decimal(9,2)", True, ""), c("CapacidadCargaMbps", "decimal(9,2)", True, ""),
       *MONEDA, *dinero("SubTotal", "Subtotal"), *dinero("Impuesto", "Impuesto"), *dinero("Descuento", "Descuento"), *dinero("Total", "Total"),
       *dinero("Mensualidad", "Mensualidad contratada"), c("FechaFirma", D, True, "", "ES-01"), c("FechaInactivacion", D, True, "", "ES-01"),
       fk("PropietarioUsuarioId", "ref.Usuario", True, ""), EXT] + AUD, uniques=[["OrdenVentaCrmId"]],
      origen="Zoho_Mirror.Sales_Orders_Extended (principal) y Sales_Orders (complemento)")
tabla("core", "OrdenVentaLinea", "Comercial", "Productos de cada orden de venta", "Una fila por línea",
      [pk("OrdenVentaLineaId"), fk("OrdenVentaId", "core.OrdenVenta", False, ""), fk("ProductoId", "core.Producto", True, ""),
       c("Descripcion", N(1000), True, ""), c("Cantidad", "decimal(12,2)", True, ""), *MONEDA, *dinero("PrecioUnitario", "Precio unitario"),
       *dinero("Descuento", "Descuento"), *dinero("Impuesto", "Impuesto"), *dinero("Total", "Total de la línea")],
      origen="Zoho_Mirror.Sales_Orders_Products")
tabla("core", "Producto", "Comercial", "Catálogo unificado de productos y planes (CRM, Books y ADNPayV2)", "Una fila por producto de origen consolidado",
      [pk("ProductoId"), c("Sistema", V(20), False, "Sistema principal del producto", "D9"), c("ProductoCrmId", N(30), True, "", "ID-04"),
       c("ItemBooksId", N(30), True, "Vinculado por zcrm_product_id", "ID-04"), c("CodigoOrigen", N(50), True, "Código en ADNPayV2"),
       c("Nombre", N(200), True, ""), c("Descripcion", N(1000), True, ""), c("Tipo", N(50), True, ""), c("Categoria", N(100), True, ""),
       c("Unidad", N(30), True, ""), c("CodigoCabys", N(30), True, ""), fk("ImpuestoId", "ref.Impuesto", True, ""),
       *MONEDA, *dinero("Precio", "Precio con impuesto"), *dinero("PrecioSinImpuesto", "Precio sin impuesto"),
       c("VelocidadDescargaMbps", "decimal(9,2)", True, ""), c("VelocidadCargaMbps", "decimal(9,2)", True, ""), c("IncluyeIPTV", B, True, "", "ES-07"),
       c("IncluyeTelefonia", B, True, "", "ES-07"), c("IncluyeIPPublica", B, True, "", "ES-07"), c("Activo", B, True, "", "ES-07"), EXT] + AUD,
      origen="Zoho_Mirror.Products; ZBooks_Mirror.items; ADNPayV2.Service, Product, IPTVService, OnvoProduct, OnvoPrice")

# ---------------------------------------------------------------- OPERACIÓN Y SOPORTE
tabla("core", "OrdenTrabajo", "Operación y soporte", "Órdenes de trabajo de instalación y mantenimiento", "Una fila por orden de trabajo",
      [pk("OrdenTrabajoId"), c("OrdenTrabajoCrmId", N(30), False, ""), fk("ServicioId", "core.Servicio", True, "Por circuito del contrato", "ID-01"),
       fk("NodoId", "core.Nodo", True, ""), c("Nombre", N(200), True, ""), c("Tipo", N(100), True, ""), c("TipoSolicitud", N(100), True, ""),
       c("Estado", N(50), True, ""), c("SubEstado", N(50), True, ""), c("Tecnologia", N(50), True, ""), c("CapacidadDescarga", N(50), True, ""),
       c("CapacidadCarga", N(50), True, ""), c("Provincia", N(60), True, ""), c("Canton", N(80), True, ""), c("Distrito", N(80), True, ""),
       c("DireccionExacta", N(1000), True, ""), c("Latitud", GEO, True, ""), c("Longitud", GEO, True, ""),
       c("FechaCreacionOT", DT, True, "", "ES-01"), c("FechaCoordinada", DT, True, "", "ES-01"), c("FechaEstimada", DT, True, "", "ES-01"),
       c("FechaFinalizacion", DT, True, "", "ES-01"), c("FechaEntregaEnlace", DT, True, "", "ES-01"), fk("AsignadoUsuarioId", "ref.Usuario", True, ""), EXT] + AUD,
      uniques=[["OrdenTrabajoCrmId"]], origen="Zoho_Mirror.Ordenes_de_Trabajo")
tabla("core", "OrdenServicioVoIP", "Operación y soporte", "Órdenes de instalación o retiro de servicios de voz", "Una fila por orden",
      [pk("OrdenServicioVoIPId"), c("OrdenCrmId", N(30), False, ""), fk("ServicioId", "core.Servicio", True, "", "ID-01"),
       c("Nombre", N(200), True, ""), c("TipoServicio", N(100), True, ""), c("TipoSolicitud", N(100), True, ""), c("Estado", N(50), True, ""),
       c("FechaSolicitud", D, True, "", "ES-01"), c("FechaInstalacion", D, True, "", "ES-01"), c("FechaDesinstalacion", D, True, "", "ES-01"), EXT] + AUD,
      uniques=[["OrdenCrmId"]], origen="Zoho_Mirror.Orden_de_Servicio_Voz_IP")
tabla("core", "Caso", "Operación y soporte", "Casos de soporte y mantenimiento", "Una fila por caso",
      [pk("CasoId"), c("CasoCrmId", N(30), False, ""), fk("ServicioId", "core.Servicio", True, "Cuenta del caso", "IN-01"),
       c("Circuito", V(12), True, "", "ID-01"), c("NumeroTicket", N(50), True, ""), c("Asunto", N(500), True, ""), c("Descripcion", TXT, True, ""),
       c("Estado", N(50), True, ""), c("Origen", N(50), True, ""), c("Segmento", N(50), True, ""), c("TipoMantenimiento", N(100), True, ""),
       c("DepartamentoOrigen", N(100), True, ""), c("ProveedorExterno", N(100), True, ""), c("VisitaTecnica", B, True, "", "ES-07"),
       c("Escalado", B, True, "", "ES-07"), fk("PropietarioUsuarioId", "ref.Usuario", True, ""),
       c("FechaSolicitud", DT, True, "", "ES-01"), c("FechaAfectacion", DT, True, "", "ES-01"), c("FechaEscalamiento", DT, True, "", "ES-01"),
       c("FechaFinMantenimiento", DT, True, "", "ES-01"), c("FechaFinalizacion", DT, True, "", "ES-01"), EXT] + AUD,
      uniques=[["CasoCrmId"]], origen="Zoho_Mirror.Cases_Extended (principal) y Cases (complemento)")
tabla("core", "Nota", "Operación y soporte", "Notas de cuentas, casos y contactos de facturación; principal fuente de texto para el RAG", "Una fila por nota",
      [pk("NotaId"), c("NotaOrigenId", N(40), False, ""), c("Entidad", V(15), False, "SERVICIO, CASO o CLIENTE"),
       fk("ServicioId", "core.Servicio", True, ""), fk("CasoId", "core.Caso", True, ""), fk("ClienteId", "core.Cliente", True, ""),
       c("Titulo", N(500), True, ""), c("Contenido", TXT, True, "", "D6"), c("CompartidaConCliente", B, True, "", "ES-07"),
       fk("AutorUsuarioId", "ref.Usuario", True, ""), c("Autor", N(200), True, "Nombre del autor cuando no es usuario de Zoho CRM")] + AUD,
      origen="Zoho_Mirror.Accounts_Notes, Cases_Notes; ZBooks_Mirror.comments_contacts")
tabla("core", "Tarea", "Operación y soporte", "Tareas y seguimientos del CRM", "Una fila por tarea",
      [pk("TareaId"), c("TareaCrmId", N(30), False, ""), c("RelacionadoCrmId", N(30), True, "What_Id: registro relacionado"),
       fk("ServicioId", "core.Servicio", True, "Si What_Id es una cuenta"), fk("ContactoId", "core.Contacto", True, "Who_Id"),
       c("Asunto", N(500), True, ""), c("Tipo", N(50), True, ""), c("Estado", N(50), True, ""), c("Prioridad", N(20), True, ""),
       c("Descripcion", TXT, True, ""), c("FechaVencimiento", D, True, "", "ES-01"), c("FechaCierre", DT, True, "", "ES-01"),
       fk("AsignadoUsuarioId", "ref.Usuario", True, ""), EXT] + AUD, uniques=[["TareaCrmId"]], origen="Zoho_Mirror.Tasks")
tabla("core", "TicketAtencion", "Operación y soporte", "Conversaciones de atención al cliente en Trengo", "Una fila por ticket",
      [pk("TicketAtencionId"), c("TicketTrengoId", N(50), False, ""), fk("ContactoId", "core.Contacto", True, "Vía Zoho2Trengo (ID_ZCRM)", "ID-09"),
       fk("ServicioId", "core.Servicio", True, "Cuenta del contacto", "ID-09"), c("Canal", N(50), True, ""), c("Departamento", N(100), True, ""),
       c("Responsable", N(100), True, ""), c("Telefono", N(30), True, "", "D6"), c("Etiquetas", JSON, True, ""), c("DatosAdicionales", JSON, True, ""),
       c("DuracionMinutos", DUR, True, ""), c("FechaCreacion", DT, True, "", "ES-01"), c("FechaAsignacion", DT, True, "", "ES-01"),
       c("FechaCierre", DT, True, "", "ES-01"), c("FechaActualizacion", DT, True, "", "ES-01")],
      uniques=[["TicketTrengoId"]], origen="ZCRM2Trengo.trengo_data_tickets; Zoho2Trengo")
tabla("core", "Adjunto", "Operación y soporte", "Metadatos de archivos adjuntos del CRM", "Una fila por adjunto",
      [pk("AdjuntoId"), c("AdjuntoCrmId", N(30), False, ""), c("Modulo", N(50), True, ""), c("RegistroCrmId", N(30), True, ""),
       c("NombreArchivo", N(500), True, ""), c("TamanoBytes", BI, True, ""), c("TipoArchivo", N(50), True, ""), c("RutaNube", N(1000), True, "")] + AUD,
      uniques=[["AdjuntoCrmId"]], origen="Zoho_Mirror.Zoho_Attachments")

# ---------------------------------------------------------------- FACTURACIÓN (Books)
tabla("core", "Proveedor", "Facturación", "Proveedores registrados en Zoho Books", "Una fila por contacto proveedor",
      [pk("ProveedorId"), c("ContactoBooksId", N(30), False, "", "ID-04"), c("Nombre", N(200), True, ""), c("Empresa", N(200), True, ""),
       c("Cedula", V(12), True, "", "ID-02"), c("Correo", N(200), True, ""), c("Telefono", N(30), True, ""), c("Estado", N(30), True, ""), EXT] + AUD,
      uniques=[["ContactoBooksId"]], origen="ZBooks_Mirror.contacts (contact_type = vendor)")
tabla("core", "Factura", "Facturación", "Facturas de venta de Zoho Books", "Una fila por factura (sin versiones duplicadas)",
      [pk("FacturaId"), c("FacturaBooksId", N(30), False, "", "DD-02"), fk("ClienteId", "core.Cliente", True, "", "ID-06"),
       fk("ServicioId", "core.Servicio", True, "Por el circuito del contacto de Books", "ID-06"), c("ContactoBooksId", N(30), False, "", "ID-04"),
       c("Numero", N(50), True, ""), c("Referencia", N(200), True, ""), c("Estado", N(30), True, ""), c("Fecha", D, False, "", "ES-01"),
       c("FechaVencimiento", D, True, "", "ES-01"), *MONEDA, *dinero("Total", "Total"), *dinero("Saldo", "Saldo pendiente"),
       *dinero("Ajuste", "Ajuste"), *dinero("CargoEnvio", "Cargo de envío"), *dinero("MontoCancelado", "Monto dado de baja"),
       c("Sucursal", N(100), True, ""), c("Vendedor", N(200), True, ""), c("FechaUltimoPago", D, True, "", "ES-01"), EXT] + AUD,
      uniques=[["FacturaBooksId"]], origen="ZBooks_Mirror.invoices (depurada por DD-02)")
tabla("core", "FacturaLinea", "Facturación", "Líneas de las facturas", "Una fila por línea",
      [pk("FacturaLineaId"), c("LineaBooksId", N(30), False, ""), fk("FacturaId", "core.Factura", False, ""), fk("ProductoId", "core.Producto", True, ""),
       c("Nombre", N(300), True, ""), c("Descripcion", TXT, True, ""), c("Cantidad", "decimal(12,2)", True, ""), *MONEDA,
       *dinero("PrecioUnitario", "Precio unitario"), *dinero("Total", "Total de la línea")],
      uniques=[["LineaBooksId"]], origen="ZBooks_Mirror.invoices_items")
tabla("core", "FacturaRecurrente", "Facturación", "Perfiles de facturación recurrente", "Una fila por perfil",
      [pk("FacturaRecurrenteId"), c("RecurrenteBooksId", N(30), False, "", "DD-02"), fk("ClienteId", "core.Cliente", True, "", "ID-06"),
       fk("ServicioId", "core.Servicio", True, "", "ID-06"), c("ContactoBooksId", N(30), False, ""), c("Nombre", N(200), True, ""),
       c("Estado", N(30), True, ""), c("Frecuencia", N(30), True, ""), c("RepetirCada", I, True, ""), *MONEDA, *dinero("Total", "Total"),
       c("FechaInicio", D, True, "", "ES-01"), c("FechaFin", D, True, "", "ES-01"), c("FechaUltimoEnvio", D, True, "", "ES-01"),
       c("FechaProximaFactura", D, True, "", "ES-01"), c("MedioPago", N(50), True, ""), c("Vendedor", N(200), True, ""), EXT] + AUD,
      uniques=[["RecurrenteBooksId"]], origen="ZBooks_Mirror.recurringinvoices")
tabla("core", "Pago", "Facturación", "Pagos de clientes", "Una fila por pago",
      [pk("PagoId"), c("PagoBooksId", N(30), False, "", "DD-02"), fk("ClienteId", "core.Cliente", True, "", "ID-06"),
       fk("ServicioId", "core.Servicio", True, "", "ID-06"), c("ContactoBooksId", N(30), False, ""), c("Numero", N(50), True, ""),
       c("Fecha", D, False, "", "ES-03"), c("MedioPago", N(50), True, ""), fk("CuentaBancariaId", "core.CuentaBancaria", True, ""),
       c("Referencia", N(200), True, ""), c("Descripcion", N(1000), True, ""), *MONEDA, *dinero("Monto", "Monto pagado"),
       *dinero("MontoNoAplicado", "Monto sin aplicar"), *dinero("MontoReembolsado", "Monto reembolsado"), *dinero("ImpuestoRetenido", "Impuesto retenido"),
       c("Sucursal", N(100), True, ""), EXT] + AUD, uniques=[["PagoBooksId"]], origen="ZBooks_Mirror.customerpayments")
tabla("core", "PagoFactura", "Facturación", "Facturas cubiertas por cada pago", "Una fila por pago y factura",
      [pk("PagoFacturaId"), fk("PagoId", "core.Pago", False, ""), fk("FacturaId", "core.Factura", True, "Nulo si el número no existe", "IN-01"),
       c("NumeroFactura", N(50), False, "Número tal como aparece en el pago")],
      origen="ZBooks_Mirror.customerpayments.invoice_numbers")
tabla("core", "CuentaBancaria", "Facturación", "Cuentas bancarias registradas en Books", "Una fila por cuenta",
      [pk("CuentaBancariaId"), c("CuentaBooksId", N(30), False, ""), c("Nombre", N(200), True, ""), c("Codigo", N(50), True, ""),
       c("Banco", N(100), True, ""), c("Tipo", N(50), True, ""), c("Activa", B, True, "", "ES-07"), *MONEDA, *dinero("Saldo", "Saldo en libros"),
       *dinero("SaldoBanco", "Saldo según banco"), EXT], uniques=[["CuentaBooksId"]], origen="ZBooks_Mirror.bankaccounts")
tabla("core", "MovimientoBancario", "Facturación", "Movimientos bancarios", "Una fila por movimiento",
      [pk("MovimientoBancarioId"), c("MovimientoBooksId", N(30), False, "", "DD-02"), fk("CuentaBancariaId", "core.CuentaBancaria", True, ""),
       fk("ClienteId", "core.Cliente", True, "", "ID-06"), c("Fecha", D, False, "", "ES-03"), c("Tipo", N(50), True, ""), c("DebitoCredito", V(10), True, ""),
       c("Estado", N(30), True, ""), c("Origen", N(50), True, ""), c("Beneficiario", N(200), True, ""), c("Descripcion", N(1000), True, ""),
       c("Referencia", N(200), True, ""), c("EstadoConciliacion", N(30), True, ""), *MONEDA, *dinero("Monto", "Monto"),
       c("Sucursal", N(100), True, ""), EXT], uniques=[["MovimientoBooksId"]], origen="ZBooks_Mirror.banktransactions")
tabla("core", "Gasto", "Facturación", "Gastos registrados en Books", "Una fila por gasto",
      [pk("GastoId"), c("GastoBooksId", N(30), False, "", "DD-02"), fk("ProveedorId", "core.Proveedor", True, ""),
       fk("ClienteId", "core.Cliente", True, "Cliente al que se refactura, si aplica"), c("Fecha", D, False, "", "ES-03"),
       c("Cuenta", N(200), True, ""), c("PagadoDesde", N(200), True, ""), c("Descripcion", N(1000), True, ""), c("Estado", N(30), True, ""),
       c("Referencia", N(200), True, ""), *MONEDA, *dinero("Total", "Total"), *dinero("TotalSinImpuesto", "Total sin impuesto"),
       c("Etiquetas", JSON, True, "De expense_tags"), c("Sucursal", N(100), True, ""), EXT] + AUD,
      uniques=[["GastoBooksId"]], origen="ZBooks_Mirror.expenses; expense_tags")
tabla("core", "OrdenCompra", "Facturación", "Órdenes de compra a proveedores", "Una fila por orden",
      [pk("OrdenCompraId"), c("OrdenCompraBooksId", N(30), False, ""), fk("ProveedorId", "core.Proveedor", True, ""),
       c("Numero", N(50), True, ""), c("Referencia", N(200), True, ""), c("Estado", N(30), True, ""), c("EstadoFacturacion", N(30), True, ""),
       c("EstadoRecepcion", N(30), True, ""), c("Fecha", D, True, "", "ES-01"), c("FechaEntrega", D, True, "", "ES-01"), *MONEDA,
       *dinero("Total", "Total"), c("Sucursal", N(100), True, ""), EXT] + AUD, uniques=[["OrdenCompraBooksId"]], origen="ZBooks_Mirror.purchaseorders")
tabla("core", "HistorialEstadoCliente", "Facturación", "Cambios de estado de clientes en Books (activo, suspendido, retirado)", "Una fila por cambio",
      [pk("HistorialEstadoClienteId"), fk("ClienteId", "core.Cliente", True, "", "ID-10"), c("ContactoBooksId", N(30), False, "", "ID-10"),
       c("Estado", N(50), True, ""), c("Segmento", N(50), True, ""), c("RealizadoPor", N(100), True, ""), c("FechaCambio", DT, True, "", "ES-01")],
      origen="History_Tables.customer_status_zbooks")

# ---------------------------------------------------------------- TELEFONÍA
tabla("core", "Troncal", "Telefonía", "Troncales SIP de los clientes", "Una fila por troncal",
      [pk("TroncalId"), fk("ServicioId", "core.Servicio", True, "Cliente VoIP vinculado por circuito", "ID-07"), c("CodigoTroncal", N(50), False, ""),
       c("Tipo", N(30), True, ""), c("TollFreeEntrante", B, True, ""), c("DIDEntrante", B, True, ""), c("Estado", N(30), True, ""),
       c("CodigoEstadoPredeterminado", N(30), True, ""), c("EstadoSIP", N(30), True, ""), c("SinRestriccion", B, True, "De Telephony_trunkpermissions")],
      uniques=[["CodigoTroncal"]], origen="Telephony_trunk; Telephony_trunkpermissions")
tabla("core", "TroncalPermisoCodigo", "Telefonía", "Códigos de marcación permitidos por troncal", "Una fila por troncal y código",
      [pk("TroncalPermisoCodigoId"), fk("TroncalId", "core.Troncal", False, ""), c("CodigoMarcacion", V(20), False, ""),
       c("Minutos", I, True, ""), c("SinRestriccion", B, True, "")], origen="Telephony_trunkpermissiondialcode")
tabla("core", "AlertaTroncal", "Telefonía", "Bloqueos y alertas de troncales", "Una fila por alerta",
      [pk("AlertaTroncalId"), fk("TroncalId", "core.Troncal", False, ""), c("Operacion", N(50), True, ""), c("Motivo", N(500), True, ""),
       c("FechaBloqueo", DT, True, "", "ES-01")], origen="Telephony_alertblockedtrunk")
tabla("core", "LineaGratuita", "Telefonía", "Líneas gratuitas y DID de los clientes", "Una fila por línea",
      [pk("LineaGratuitaId"), fk("ServicioId", "core.Servicio", True, "", "ID-07"), c("Linea", N(50), False, ""),
       c("TollFreeEntrante", B, True, ""), c("DIDEntrante", B, True, ""), c("Estado", N(30), True, "")], origen="Telephony_freelines")
tabla("core", "ServicioPaqueteMinutos", "Telefonía", "Paquetes de minutos asignados a cada servicio", "Una fila por servicio y paquete",
      [pk("ServicioPaqueteMinutosId"), fk("ServicioId", "core.Servicio", True, "", "ID-07"), fk("PaqueteMinutosId", "ref.PaqueteMinutos", False, ""),
       c("Minutos", I, True, "")], origen="Telephony_customerminutepackage")
tabla("core", "MinutosContratadosHistorico", "Telefonía", "Minutos contratados registrados a mano en 2022 (histórico, decisión del 12/10/2026)", "Una fila por registro de origen",
      [pk("MinutosContratadosHistoricoId"), fk("ClienteId", "core.Cliente", True, "Por cédula (MinutosLegalId) o vía el cliente VoIP", "ID-02"),
       fk("ServicioId", "core.Servicio", True, "Vía el cliente VoIP (Minutos_Customer)", "ID-01"),
       c("TablaOrigen", V(30), False, "Minutos_Customer o MinutosLegalId"), c("ClienteVoIPOrigenId", BI, True, "Customer_id de Minutos_Customer"),
       c("CedulaOriginal", N(50), True, "IDCard de MinutosLegalId, sin normalizar", "ES-08"), c("Descripcion", N(200), True, ""),
       c("Minutos", DUR, True, "Minutos (Minutos_Customer)"), c("MinutosFijo", DUR, True, "Minutos a fijos (MinutosLegalId)"),
       c("MinutosCelular", DUR, True, "Minutos a celulares (MinutosLegalId)")],
      origen="ADNApp.Minutos_Customer; ADNApp.MinutosLegalId")
tabla("core", "ArchivoCDR", "Telefonía", "Archivos de llamadas procesados", "Una fila por archivo (única)",
      [pk("ArchivoCDRId"), c("NombreArchivo", N(300), False, "", "DD-05"), c("Dispositivo", N(100), True, ""),
       c("FechaInsercion", D, True, "", "ES-01")], uniques=[["NombreArchivo", "Dispositivo"]], origen="Telephony_insertedcdrfiles")
tabla("core", "Llamada", "Telefonía", "Registros de llamadas (CDR) sin duplicados", "Una fila por llamada única (DD-01)",
      [pk("LlamadaId", BI), fk("ServicioId", "core.Servicio", True, "Por CustomerCircuitNumber", "ID-07"),
       fk("TroncalEntradaId", "core.Troncal", True, ""), fk("TroncalSalidaId", "core.Troncal", True, ""),
       c("Circuito", V(12), True, "", "ID-01"), c("TipoCDR", I, True, "CDRTypeCode"), c("RazonCDR", N(100), True, ""),
       c("FechaInicio", DT, False, "", "ES-01"), c("FechaRespuesta", DT, True, "Vacía si la llamada no fue contestada", "ES-02"),
       c("FechaFin", DT, True, "", "ES-01"), c("NumeroOrigen", N(50), True, "", "D6"), c("NumeroMarcado", N(50), True, "", "D6"),
       c("NumeroFacturacion", N(50), True, "", "D6"), c("DigitosRuteo", N(50), True, ""), c("Destino", N(150), True, ""),
       c("CodigoDestino", V(20), True, ""), c("Dispositivo", N(100), True, ""), c("DuracionSegundos", DUR, True, ""),
       c("DuracionSegundosRedondeada", DUR, True, ""), c("DuracionMinutos", DUR, True, ""), c("RedondeoDestino", I, True, ""),
       c("IncrementoCliente", I, True, ""), c("PorcentajeCliente", "decimal(9,4)", True, ""),
       *MONEDA, *dinero("TarifaDestino", "Tarifa por minuto"), *dinero("TarifaSinMargen", "Tarifa sin margen"),
       *dinero("Costo", "Costo de la llamada"), *dinero("CostoSinMargen", "Costo sin margen"), EXT],
      origen="MongoDB Telephony_cdr (desde 2024); ADNApp.Telephony_cdr_historico (2022-2023)")
T[-1]["unique_hash"] = True
tabla("core", "CorteVoIP", "Telefonía", "Cortes de facturación de telefonía por cliente y período", "Una fila por corte",
      [pk("CorteVoIPId"), fk("ServicioId", "core.Servicio", True, "", "ID-01"), fk("ClienteId", "core.Cliente", True, "", "ID-02"),
       c("NombreCliente", N(200), True, ""), c("FechaInicio", D, True, "", "ES-01"), c("FechaFin", D, True, "", "ES-01"),
       c("MinutosMovilDisponibles", DUR, True, ""), c("MinutosFijoDisponibles", DUR, True, ""), c("MinutosMovilAplicados", DUR, True, ""),
       c("MinutosFijoAplicados", DUR, True, ""), c("Reporte", TXT, True, ""), c("Estado", N(30), True, "")],
      origen="ZohoEngine_zohocustomervoipbill")
tabla("core", "ConsumoVoIP", "Telefonía", "Consumo de telefonía por servicio, período y tipo de destino", "Una fila por corte o período y tipo",
      [pk("ConsumoVoIPId"), fk("CorteVoIPId", "core.CorteVoIP", True, ""), fk("ServicioId", "core.Servicio", True, "", "ID-01"),
       fk("ClienteId", "core.Cliente", True, "", "ID-02"), c("TipoServicioVoIP", N(50), True, ""), c("FechaInicio", D, True, "", "ES-01"),
       c("FechaFin", D, True, "", "ES-01"), c("Llamadas", I, True, ""), c("Minutos", DUR, True, ""), *MONEDA, *dinero("Costo", "Costo"),
       c("RutaArchivo", N(1000), True, ""), c("Procesado", B, True, "", "ES-07")],
      origen="ZohoEngine_zohocustomervoipbillservice; ZohoEngine_invoicevoip")
tabla("core", "FacturaElectronicaProveedor", "Telefonía", "Facturas electrónicas (XML) recibidas de proveedores", "Una fila por factura",
      [pk("FacturaElectronicaProveedorId"), c("Numero", N(60), False, ""), c("EmisorNombre", N(200), True, ""), c("EmisorCedula", V(12), True, "", "ID-02"),
       c("FechaEmision", DT, True, "", "ES-01"), c("NombreArchivo", N(300), True, ""), c("Ruta", N(1000), True, ""),
       c("TextoPlano", TXT, True, ""), c("Procesada", B, True, "", "ES-07")], uniques=[["Numero"]], origen="XMLEngine_invoicexmlfiles")

# ---------------------------------------------------------------- VENTA EN LÍNEA (ADNPayV2)
tabla("core", "SolicitudEnLinea", "Venta en línea", "Contrataciones hechas en ADNPayV2", "Una fila por solicitud",
      [pk("SolicitudEnLineaId"), fk("ClienteId", "core.Cliente", True, "Por cédula", "ID-02"), fk("ProductoId", "core.Producto", True, "Plan contratado"),
       c("Referencia", V(50), True, ""), c("Estado", N(50), True, ""), c("TipoCliente", N(30), True, ""), c("Condominio", N(200), True, ""),
       c("CodigoFTTH", N(50), True, ""), c("Provincia", N(60), True, ""), c("Canton", N(80), True, ""), c("Distrito", N(80), True, ""),
       c("Direccion", N(1000), True, ""), c("Latitud", GEO, True, ""), c("Longitud", GEO, True, ""), c("IPTVAdicionales", I, True, ""),
       c("CantidadFirestick", I, True, ""), c("Telefonia", B, True, "", "ES-07"), c("IPPublica", B, True, "", "ES-07"),
       c("TienePromocion", B, True, "", "ES-07"), c("TipoPromocion", V(50), True, ""), c("CodigoPromocion", N(50), True, ""), c("FechaPromocion", D, True, "", "ES-01"),
       c("TipoPago", V(30), True, ""), *MONEDA, *dinero("Total", "Precio total"), c("Referido", B, True, "", "ES-07"),
       c("ReferidoPor", N(200), True, ""), c("DatosInvalidos", B, True, "", "ES-07"), c("EnviadoCRM", B, True, "", "ES-07"),
       c("RutaContrato", N(1000), True, "Ruta del contrato firmado en S3"), c("IntentoPagoId", V(100), True, ""), c("FechaSolicitud", DT, True, "", "ES-01"), EXT],
      origen="ADNPayV2.Customer")
tabla("core", "PagoEnLinea", "Venta en línea", "Sesiones de pago con tarjeta (pasarela Onvo)", "Una fila por sesión",
      [pk("PagoEnLineaId"), fk("SolicitudEnLineaId", "core.SolicitudEnLinea", True, ""), c("SesionId", N(100), True, ""),
       c("IntentoPagoId", N(100), True, ""), c("Modo", N(30), True, ""), c("EstadoPago", N(30), True, ""), c("Expirada", B, True, "", "ES-07"),
       *MONEDA, *dinero("Monto", "Monto cobrado"), c("PrecioId", N(100), True, ""), c("FechaCreacion", DT, True, "", "ES-01"), c("FechaExpiracion", DT, True, "", "ES-01")],
      origen="ADNPayV2.OnvoCheckoutSession")
tabla("core", "ReservaInstalacion", "Venta en línea", "Citas de instalación reservadas", "Una fila por reserva",
      [pk("ReservaInstalacionId"), fk("SolicitudEnLineaId", "core.SolicitudEnLinea", True, ""), c("FechaReservada", D, True, "", "ES-01"),
       c("Franja", "time(0)", True, ""), c("Estado", V(30), True, ""), c("FechaRegistro", DT, True, "", "ES-01"), c("FechaExpiracion", DT, True, "", "ES-01"),
       c("Direccion", N(1000), True, "")], origen="ADNPayV2.ServiceReservations; Visitdate")
tabla("core", "OrdenEnLinea", "Venta en línea", "Carritos y órdenes de compra en línea", "Una fila por carrito u orden",
      [pk("OrdenEnLineaId"), fk("SolicitudEnLineaId", "core.SolicitudEnLinea", True, ""), c("ClienteReferencia", N(50), True, ""),
       c("Tipo", V(10), False, "CARRITO u ORDEN"), c("Estado", N(30), True, ""), c("Bloqueado", B, True, "", "ES-07"), *MONEDA,
       *dinero("Total", "Total con impuesto"), *dinero("TotalSinImpuesto", "Total sin impuesto"), c("Fecha", DT, True, "", "ES-01")],
      origen="ADNPayV2.Cart; SaleOrder")
tabla("core", "OrdenEnLineaLinea", "Venta en línea", "Productos de cada carrito u orden", "Una fila por línea",
      [pk("OrdenEnLineaLineaId"), fk("OrdenEnLineaId", "core.OrdenEnLinea", False, ""), fk("ProductoId", "core.Producto", True, ""),
       c("Nombre", N(200), True, ""), c("Descripcion", N(1000), True, ""), c("Cantidad", I, True, ""), *MONEDA,
       *dinero("PrecioUnitario", "Precio unitario"), *dinero("PrecioUnitarioSinImpuesto", "Precio unitario sin impuesto"),
       *dinero("Total", "Total de la línea"), *dinero("TotalSinImpuesto", "Total de la línea sin impuesto")],
      origen="ADNPayV2.CartLine; SaleOrderLine")
tabla("core", "AprovisionamientoOdoo", "Venta en línea", "Envío de clientes nuevos a Odoo", "Una fila por intento",
      [pk("AprovisionamientoOdooId"), fk("SolicitudEnLineaId", "core.SolicitudEnLinea", True, ""), c("Estado", N(30), True, ""),
       c("OdooLeadId", I, True, ""), c("OdooPartnerId", I, True, ""), c("OdooSitioId", I, True, ""), c("OdooOrdenId", I, True, ""),
       c("OdooContratoId", I, True, ""), c("OdooTareaId", I, True, ""), c("Circuito", V(12), True, "", "ID-01"), c("Intentos", I, True, ""),
       c("UltimoError", N(2000), True, "")] + AUD, origen="ADNPayV2.OdooProvisioning")

# ---------------------------------------------------------------- FLOTA (Navsat)
tabla("core", "UbicacionFlota", "Flota", "Posiciones reportadas por los dispositivos de rastreo", "Una fila por posición única (DD-03)",
      [pk("UbicacionFlotaId", BI), fk("UnidadFlotaId", "ref.UnidadFlota", False, ""), c("FechaHora", DT, False, "", "ES-01"),
       c("Latitud", GEO, True, ""), c("Longitud", GEO, True, ""), c("Odometro", "decimal(12,2)", True, ""), c("Velocidad", "decimal(7,2)", True, ""),
       c("Lugar", N(500), True, ""), c("Estado", N(50), True, "")], origen="Navsat.Ultima_ubicacion")
tabla("core", "ViajeFlota", "Flota", "Viajes finalizados", "Una fila por viaje único (DD-03)",
      [pk("ViajeFlotaId", BI), fk("UnidadFlotaId", "ref.UnidadFlota", False, ""), c("FechaInicio", DT, False, "", "ES-01"),
       c("FechaFin", DT, True, "", "ES-01"), c("Kilometros", "decimal(10,2)", True, ""), c("DuracionMinutos", DUR, True, ""),
       c("LugarInicio", N(500), True, ""), c("LugarFin", N(500), True, ""), c("Estado", N(50), True, "")], origen="Navsat.viajes_ayer_finalizado")
tabla("core", "EventoFlota", "Flota", "Eventos y alertas de los dispositivos", "Una fila por evento único (DD-03)",
      [pk("EventoFlotaId", BI), fk("UnidadFlotaId", "ref.UnidadFlota", False, ""), c("FechaHora", DT, False, "", "ES-01"),
       c("Evento", N(100), True, ""), c("Mensaje", N(500), True, ""), c("Regla", N(200), True, ""), c("Latitud", GEO, True, ""),
       c("Longitud", GEO, True, ""), c("Lugar", N(500), True, "")], origen="Navsat.eventos")
tabla("core", "IncidenteConduccion", "Flota", "Incidentes de conducción (eco-driving)", "Una fila por incidente único (DD-03)",
      [pk("IncidenteConduccionId"), fk("UnidadFlotaId", "ref.UnidadFlota", False, ""), c("TipoEventoCodigo", I, True, "id_evento: código de tipo, no identificador"),
       c("TipoIncidente", N(100), True, ""), c("Conductor", N(150), True, ""), c("FechaHora", DT, False, "", "ES-01"), c("Lugar", N(500), True, ""),
       c("DuracionSegundos", I, True, ""), c("VelocidadMaxima", I, True, ""), c("VecesExcesoVelocidad", I, True, ""), c("Penalidad", "decimal(9,2)", True, "")],
      origen="Navsat.Eco_Driving")
tabla("core", "CheckInCampo", "Flota", "Registros de llegada del personal de campo", "Una fila por registro",
      [pk("CheckInCampoId"), c("Empleado", N(150), True, "", "D6"), c("FechaHora", DT, False, "", "ES-01"), c("Direccion", N(500), True, ""),
       c("Latitud", GEO, True, ""), c("Longitud", GEO, True, ""), c("Comentario", N(1000), True, ""), c("RutaArchivo", N(1000), True, ""),
       c("UrlDescarga", N(1000), True, ""), c("ArchivoId", I, True, "")], origen="History_Tables.check_in_navsat")
tabla("core", "EventoConexion", "Operación y soporte", "Conexiones y desconexiones de servicio realizadas", "Una fila por operación",
      [pk("EventoConexionId"), fk("ClienteId", "core.Cliente", True, "Cliente, vía el contacto de Books", "ID-04"),
       c("ContactoBooksId", N(30), True, "ID del contacto en Zoho Books (en el origen se llama customer_name)", "ID-04"), c("Tipo", N(50), True, ""),
       c("RealizadoPor", N(100), True, ""), c("Fecha", DT, True, "", "ES-01"), c("TipoDesconexionReconexion", N(50), True, ""),
       c("FechaDesconexionReconexion", DT, True, "", "ES-02"), c("DireccionesIP", JSON, True, ""), c("ErroresIP", JSON, True, "")],
      origen="History_Tables.Conexiones_desconexiones_realizadas")

TABLAS = {f"{t['schema']}.{t['name']}": t for t in T}
