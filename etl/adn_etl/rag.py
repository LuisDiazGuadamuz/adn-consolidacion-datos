# -*- coding: utf-8 -*-
"""Disponibilidad del modelo unificado como fuente para ask.data.cr y futuros sistemas RAG (Sprint 5).

Aplica la decisión D6 (Sprint 2): el modelo guarda los datos completos con acceso restringido; lo que se entrega a un
corpus RAG va sin datos que identifiquen a personas. Cada columna recibe una de cuatro categorías:

  Disponible               se puede exponer tal cual (vistas del esquema rag, sql/30_rag/vistas_rag.sql)
  Requiere anonimización   texto libre o nombre de registro que puede contener nombres, teléfonos o correos;
                           solo entra al corpus después de un proceso de anonimización (no construido en este proyecto)
  No: dato personal        identifica a un cliente, contacto o colaborador (D6)
  No: técnico              llaves de otros sistemas, rutas, contenidos sin revisar, control del ETL

Una tabla es Disponible (todas sus columnas útiles lo son), Disponible con restricciones (alguna columna queda fuera
o requiere anonimización) o No disponible (la tabla completa queda fuera, con su motivo).
"""

SI, ANON, PERSONAL, TECNICO = "Disponible", "Requiere anonimización", "No: dato personal", "No: técnico"

# Tablas que quedan fuera completas
TABLA_FUERA = {
    "ctl.Lote": "Control técnico del ETL",
    "ctl.Descarte": "Guarda el contenido original de registros excluidos, con datos personales",
    "ctl.Anomalia": "Guarda valores originales marcados por las reglas, con datos personales",
    "ctl.LinajeCampo": "Control técnico del ETL",
    "ctl.Bitacora": "Guarda los valores anteriores de cada registro, con datos personales",
    "ctl.Entorno": "Control técnico del ETL",
    "ctl.Reconciliacion": "Control técnico de la validación",
    "ctl.ReconciliacionPendiente": "Control técnico de la validación",
    "core.ClienteOrigen": "Correspondencia entre sistemas con cédulas y llaves originales: permite reidentificar clientes",
    "core.Direccion": "Direcciones de personas",
    "core.UbicacionFlota": "Posiciones GPS minuto a minuto de vehículos que conducen colaboradores",
    "core.CheckInCampo": "Llegadas del personal de campo con nombre, ubicación y fotos",
    "core.PagoEnLinea": "Sesiones de pago con tarjeta en la pasarela; identificadores de la pasarela",
    "core.AprovisionamientoOdoo": "Integración técnica con Odoo",
    "core.ArchivoCDR": "Control técnico de archivos procesados",
}

# Columnas con datos personales (D6), en cualquier tabla
PERSONAL_COL = {
    "Cedula", "CedulaOriginal", "EmisorCedula", "Apellido", "NombreCompleto", "RazonSocial", "NombreCuenta",
    "NombreCliente", "Correo", "Telefono", "Movil", "NumeroOrigen", "NumeroMarcado", "NumeroFacturacion",
    "Direccion", "DireccionExacta", "Empleado", "Conductor", "Responsable", "Autor", "RealizadoPor", "Beneficiario",
    "ReferidoPor", "ClienteReferencia", "DireccionesIP", "LineaDID", "TollFreeEntrante", "DIDEntrante", "Vendedor",
}
# "Nombre" es personal solo en tablas de personas
NOMBRE_PERSONAL = {"Cliente", "Contacto", "Prospecto", "Usuario", "LineaGratuita"}
PERSONAL_TABLA = {"LineaGratuita.Linea", "Prospecto.Empresa", "Servicio.Latitud", "Servicio.Longitud",
                  "OrdenTrabajo.Latitud", "OrdenTrabajo.Longitud", "SolicitudEnLinea.Latitud", "SolicitudEnLinea.Longitud",
                  "EventoFlota.Latitud", "EventoFlota.Longitud", "EventoFlota.Lugar", "ViajeFlota.LugarInicio",
                  "ViajeFlota.LugarFin", "IncidenteConduccion.Lugar", "ReservaInstalacion.Direccion",
                  "SolicitudEnLinea.Direccion", "SolicitudEnLinea.Condominio", "Prospecto.CondominioSolicitado"}

# Texto libre: requiere anonimización antes de entrar al corpus
TEXTO_COL = {"Descripcion", "Asunto", "Contenido", "Titulo", "Comentario", "Mensaje", "DatosAdicionales", "Reporte"}
TEXTO_TABLA = {"Oportunidad.Nombre", "OrdenTrabajo.Nombre", "OrdenServicioVoIP.Nombre", "FacturaRecurrente.Nombre",
               "TicketAtencion.Etiquetas", "Gasto.Etiquetas", "Factura.Referencia", "Pago.Referencia",
               "MovimientoBancario.Referencia", "Adjunto.NombreArchivo", "AlertaTroncal.Motivo"}
# Descripciones de catálogos: no son texto de personas
TEXTO_SEGURO = {"Regla.Descripcion", "CuentaContable.Descripcion", "Producto.Descripcion", "PaqueteMinutos.Descripcion",
                "UnidadFlota.Descripcion", "FacturaLinea.Descripcion", "OrdenVentaLinea.Descripcion",
                "OrdenEnLineaLinea.Descripcion", "MinutosContratadosHistorico.Descripcion", "Fuente.MotivoDisposicion",
                "Condominio.Direccion", "Nodo.Direccion"}  # direcciones de infraestructura, no de personas

# Técnicas
TECNICO_COL = {"AtributosExtendidos", "RutaArchivo", "RutaNube", "Ruta", "UrlDescarga", "RutaContrato", "ArchivoId",
               "TextoPlano", "NombreArchivo", "HashContenido", "FuenteLlave", "FuenteBase", "FuenteTabla", "LoteId",
               "FechaCarga", "IntentoPagoId", "SesionId", "PrecioId", "UltimoError", "ErroresIP", "ContenidoOrigen",
               "ValorOriginal", "DigitosRuteo", "Dispositivo"}


def _es_llave_origen(col):
    """Llaves de los sistemas de origen (CRM, Books, Trengo, Odoo...): permiten cruzar con los sistemas y reidentificar."""
    return (col.endswith("CrmId") or col.endswith("BooksId") or col in {
        "ContactoBooksId", "ZohoUsuarioId", "TicketTrengoId", "NotaOrigenId", "ClienteVoIPOrigenId", "TablaOrigen",
        "LlaveOrigen", "CodigoOrigen", "ItemBooksId", "ImpuestoBooksId", "CuentaBooksId"} or col.startswith("Odoo"))


def columna(schema, tabla, col):
    """(categoría, motivo) de una columna."""
    nombre = f"{schema}.{tabla}"
    if nombre in TABLA_FUERA:
        return ("No: técnico" if TABLA_FUERA[nombre].startswith("Control") or "técnic" in TABLA_FUERA[nombre]
                else PERSONAL), "Tabla no disponible: " + TABLA_FUERA[nombre]
    k = f"{tabla}.{col}"
    if k in TEXTO_SEGURO:
        return SI, ""
    if col in PERSONAL_COL or k in PERSONAL_TABLA or (col == "Nombre" and tabla in NOMBRE_PERSONAL):
        return PERSONAL, "Identifica a una persona (D6)"
    if col in TECNICO_COL:
        return TECNICO, ("JSON con campos de origen sin revisar; puede traer datos personales" if col == "AtributosExtendidos"
                         else "Dato técnico o de control, sin valor para consultas")
    if _es_llave_origen(col):
        return TECNICO, "Llave de un sistema de origen: permite cruzar y reidentificar"
    if col in TEXTO_COL or k in TEXTO_TABLA:
        return ANON, "Texto libre que puede contener nombres, teléfonos o correos"
    return SI, ""


def tabla(schema, tabla, cols):
    """(nivel, motivo) de la tabla a partir de sus columnas."""
    nombre = f"{schema}.{tabla}"
    if nombre in TABLA_FUERA:
        return "No disponible", TABLA_FUERA[nombre]
    cats = [columna(schema, tabla, c)[0] for c in cols]
    fuera = [c for c, k in zip(cols, cats) if k in (PERSONAL, ANON)]
    if not fuera:
        return "Disponible", ""
    return "Disponible con restricciones", "Fuera o con anonimización previa: " + ", ".join(fuera)
