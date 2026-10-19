# -*- coding: utf-8 -*-
"""Pasos generados desde la matriz de correspondencia aprobada (Sprint 2).

Para una tabla de origen y una tabla del modelo, `paso_matriz` arma el SELECT a partir de las filas 'Mapeada'
de la matriz y aplica la normalización según el tipo de la columna destino:

  texto → ctl.fn_Texto (ES-05) · fecha y hora → ctl.fn_FechaCR (ES-01, D4) · fecha → ctl.fn_FechaDia
  sí/no → ctl.fn_Bit (ES-07) · monto → ctl.fn_Monto (ES-04) y su equivalente en colones (D5)
  moneda → ctl.fn_Moneda · circuito → ctl.fn_Circuito (ID-01) · cédula → ctl.fn_Cedula (ID-02)
  coordenada → ctl.fn_CoordenadaSola · llave foránea → búsqueda con correspondencia única (IN-01)

Los valores que no se pudieron interpretar quedan marcados en ctl.Anomalia (ES-02 fechas, ES-04 montos,
IN-01 referencias, ID-01 circuitos). 'deleted = 1' va a ctl.Descarte (DD-06) y las versiones repetidas del
mismo registro se resuelven por la modificación más reciente (DD-02).
"""
import re

from . import modelo
from .matriz import atributos, de_tabla
from .paso import Anomalia, Paso

NUMERICOS = ("int", "bigint", "smallint", "tinyint", "decimal", "numeric", "float", "real", "money", "smallmoney")
FECHAS = ("datetime", "datetime2", "date", "smalldatetime", "datetimeoffset")
TEXTO_LARGO = ("text", "ntext")

# Catálogos que se buscan por su llave de origen (FuenteBase + FuenteLlave)
POR_LLAVE = {"core.Direccion": "ADNPayV2", "ref.Distrito": "ADNPayV2", "ref.ProveedorTelefonia": "ADNApp",
             "ref.PaqueteMinutos": "ADNApp", "core.Troncal": "ADNApp", "core.CorteVoIP": "ADNApp",
             "core.SolicitudEnLinea": "ADNPayV2"}

# Tabla del modelo → (llave del modelo, columnas por las que se busca, en orden de preferencia)
BUSQUEDA = {
    "core.Servicio": ("ServicioId", ["CuentaCrmId"]),
    "ref.Usuario": ("UsuarioId", ["ZohoUsuarioId", "NombreCompleto"]),
    "core.Contacto": ("ContactoId", ["ContactoCrmId"]),
    "core.Oportunidad": ("OportunidadId", ["OportunidadCrmId"]),
    "core.Cotizacion": ("CotizacionId", ["CotizacionCrmId"]),
    "core.OrdenVenta": ("OrdenVentaId", ["OrdenVentaCrmId"]),
    "core.Caso": ("CasoId", ["CasoCrmId"]),
    "core.Producto": ("ProductoId", ["ProductoCrmId", "ItemBooksId"]),
    "core.CuentaBancaria": ("CuentaBancariaId", ["CuentaBooksId"]),
    "core.Proveedor": ("ProveedorId", ["ContactoBooksId"]),
    "core.Factura": ("FacturaId", ["FacturaBooksId"]),
    "core.Pago": ("PagoId", ["PagoBooksId"]),
    "ref.UnidadFlota": ("UnidadFlotaId", ["Dispositivo"]),
    "core.Nodo": ("NodoId", ["NodoCrmId", "Nombre"]),
    "core.Condominio": ("CondominioId", ["CondominioCrmId", "Nombre"]),
    "ref.Impuesto": ("ImpuestoId", ["ImpuestoBooksId", "Nombre"]),
}


def _tipo_base(t):
    return (t or "").split("(")[0].strip().lower()


def _src(alias, col, tipo):
    x = f"{alias}.[{col}]"
    return f"CONVERT(nvarchar(max), {x})" if _tipo_base(tipo) in TEXTO_LARGO else x


def _es_texto(tipo):
    return _tipo_base(tipo) not in NUMERICOS + FECHAS + ("bit",)


def expresion(col, tipo_dest, x, tipo_src):
    """Expresión T-SQL que normaliza el valor de origen x al tipo de la columna del modelo."""
    td, ts = tipo_dest.lower(), _tipo_base(tipo_src)
    if col == "Circuito":
        return f"ctl.fn_Circuito(CONVERT(nvarchar(100), {x}))"
    if col in ("Cedula", "EmisorCedula"):
        return f"ctl.fn_Cedula(CONVERT(nvarchar(100), {x}))"
    if col in ("Latitud", "Longitud"):
        return f"ctl.fn_CoordenadaSola(CONVERT(nvarchar(60), {x}), {1 if col == 'Latitud' else 2})"
    if col == "Moneda" or td == "char(3)":
        return f"ctl.fn_Moneda(CONVERT(nvarchar(20), {x}))"
    if td.startswith("datetimeoffset"):
        if ts in FECHAS:
            return f"ctl.fn_FechaCR(CONVERT(nvarchar(30), {x}, 126))"
        return f"ctl.fn_FechaCR(CONVERT(nvarchar(60), {x}))"
    if td == "date":
        if ts in FECHAS:
            return f"CAST({x} AS date)"
        return f"ctl.fn_FechaDia(CONVERT(nvarchar(60), {x}))"
    if td == "bit":
        if ts == "bit":
            return x
        if ts in NUMERICOS:
            return f"CASE WHEN {x} = 0 THEN CAST(0 AS bit) WHEN {x} IS NOT NULL THEN CAST(1 AS bit) END"
        return f"ctl.fn_Bit(CONVERT(nvarchar(20), {x}))"
    if td.startswith(("decimal", "numeric")):
        if ts in NUMERICOS:
            return f"TRY_CONVERT({td}, {x})"
        if td == "decimal(19,4)":
            return f"ctl.fn_Monto(CONVERT(nvarchar(60), {x}))"
        return f"TRY_CONVERT({td}, ctl.fn_PrimerNumero(CONVERT(nvarchar(255), {x})))"
    if td in ("int", "bigint", "smallint", "tinyint"):
        if ts in NUMERICOS:
            return f"TRY_CONVERT({td}, {x})"
        return f"TRY_CONVERT({td}, ctl.fn_PrimerNumero(CONVERT(nvarchar(255), {x})))"
    if td.startswith(("nvarchar", "varchar", "nchar", "char")):
        return f"ctl.fn_Texto(CONVERT(nvarchar(max), {x}))"
    return x


def _destinos(texto, cols_modelo):
    """Columnas del modelo a las que va una columna de origen según la matriz ('A; B', 'ServicioId (ID-01)')."""
    res = []
    for e in (texto or "").split(";"):
        e = e.strip()
        if not e or "validación" in e or "(hora)" in e or e.lower().startswith("vínculo"):
            continue
        tok = e.split(" ")[0]
        if tok in cols_modelo or tok == "FuenteLlave":
            res.append(tok)
    return res


_FECHAS_DATO = ("FechaCreacionOrigen", "FechaHora", "Fecha", "FechaSolicitud", "FechaCreacion", "FechaInicio",
                "FechaEmision", "FechaRegistro", "FechaInsercion", "FechaBloqueo")


def paso_matriz(nombre, orden, destino, sistema, base, tabla, alias="x", *, override=None, omitir=(), extra_from="",
                where="", llave=None, fecha_dato=None, fecha_tc=None, moneda=None, descripcion="", depende=None,
                reglas_extra=(), filtros_extra=(), anomalias_extra=(), auxiliares_extra=None, preparacion="",
                excluir_atributos=(), clave=None, dedup=True, solo_actualizar=False, fuente_tabla=None, llave_expr=None,
                tc_respaldo=None, requiere_periodo=False):
    """Arma un Paso desde la matriz.

    override: {columna_modelo: expresión T-SQL sobre el alias de origen} (reemplaza o agrega columnas)
    omitir:   columnas del modelo que este paso no carga aunque la matriz las mapee
    llave:    columna de origen que identifica el registro (FuenteLlave); por defecto la que la matriz manda a FuenteLlave
    moneda:   expresión de moneda cuando el origen no la trae (p. ej. "'CRC'")
    fecha_tc: expresión sobre q con la fecha del tipo de cambio (D5); por defecto la fecha de creación
    """
    override = dict(override or {})
    t = modelo.TABLAS[destino]
    cols_modelo = {c["name"]: c for c in t["cols"]}
    pk = t.get("pkcol") or next(c["name"] for c in t["cols"] if c.get("pk"))
    filas = [r for r in de_tabla(base, tabla) if r["Disposicion"] == "Mapeada"
             and destino in [x.strip() for x in r["TablaDestino"].split("/")]]
    eliminado = any(r["Disposicion"] == "Filtro de carga" and r["ColumnaOrigen"].lower() == "deleted"
                    for r in de_tabla(base, tabla))

    sel = {}            # columna del modelo → expresión
    fuentes = {}        # columna del modelo → (expresión original de texto, tipo origen)
    crc_directo = {}    # XCRC → expresión, cuando el origen ya trae el monto en moneda base (bcy_*, D5)
    attr_extra = []     # columnas de origen que la matriz manda enteras a AtributosExtendidos
    fks = {}            # columna fk → lista de (expresión del valor, columna de origen)
    reglas = set(reglas_extra) | {"IN-05"}
    llave_src = llave
    for r in filas:
        col_o, tipo_o = r["ColumnaOrigen"], r["TipoOrigen"]
        x = _src(alias, col_o, tipo_o)
        dests = _destinos(r["ColumnaDestino"], cols_modelo)
        for d in dests:
            if d == "FuenteLlave":
                if llave_src is None:
                    llave_src = col_o
                continue
            if d in omitir or d in override or d == pk:
                continue
            if d == "AtributosExtendidos":      # la matriz manda la columna entera a los atributos: va como clave del JSON
                if col_o not in attr_extra:
                    attr_extra.append(col_o)
                continue
            if d.endswith("CRC") and d[:-3] in cols_modelo:     # el equivalente en colones se calcula (D5)
                if len(dests) == 1:                              # ... salvo que el origen lo traiga en moneda base
                    crc_directo[d] = expresion(d, "decimal(19,4)", x, tipo_o)
                continue
            c = cols_modelo[d]
            for rg in re.findall(r"[A-Z]{2}-\d{2}|D\d+", r["Regla"] or ""):
                reglas.add(rg)
            if c.get("fk"):
                fks.setdefault(d, []).append((x, col_o))
                continue
            if d in sel:            # la matriz manda dos columnas al mismo destino: gana la primera
                continue
            sel[d] = expresion(d, c["type"], x, tipo_o)
            fuentes[d] = (x, tipo_o)
    if llave_src is None and llave_expr:
        llave_src = ""
    if llave_src is None:
        raise ValueError(f"{nombre}: la matriz no indica la llave de {base}.{tabla}")
    llave_tipo = next((r["TipoOrigen"] for r in filas if r["ColumnaOrigen"] == llave_src), "nvarchar")

    aux, anoms, applies = list(auxiliares_extra or []), list(anomalias_extra), []
    # Referencias (IN-01): se vinculan solo con correspondencia única
    for d, orígenes in fks.items():
        ref = cols_modelo[d]["fk"]
        orígenes.sort(key=lambda o: "ircuit" in o[1])   # primero la llave directa, después el circuito
        partes = []
        for i, (x, col_o) in enumerate(orígenes):
            a = f"fk_{d}_{i}"
            v = f"ctl.fn_Texto(CONVERT(nvarchar(max), {x}))"
            if ref in ("core.Cliente", "core.Servicio") and "custome" in col_o.lower():
                # registro ligado a un cliente de Books/ADNPayV2: se resuelve por la tabla de correspondencia (ID-04, ID-06)
                pkr = "ClienteId" if ref == "core.Cliente" else "ServicioId"
                applies.append(f"OUTER APPLY (SELECT CASE WHEN COUNT(DISTINCT zref.[{pkr}]) = 1 THEN MIN(zref.[{pkr}]) END AS Id "
                               f"FROM core.ClienteOrigen zref WHERE zref.Sistema = '{sistema}' AND zref.LlaveOrigen = {v}) {a}")
                partes.append(f"{a}.Id")
                continue
            if ref == "core.Servicio" and "ircuit" in col_o:
                cond = f"zref.Circuito = ctl.fn_Circuito(CONVERT(nvarchar(100), {x}))"
                pkr = "ServicioId"
            elif ref == "core.Cliente" and any(k in col_o.lower() for k in ("legal", "idcard", "id_card")):
                cond = (f"zref.FuenteTabla = N'Cedula' AND zref.FuenteLlave = ctl.fn_Cedula(CONVERT(nvarchar(100), {x}))"
                        " AND EXISTS (SELECT 1 FROM core.ClienteOrigen vo WHERE vo.ClienteId = zref.ClienteId AND vo.Sistema IN ('ZohoCRM', 'ZohoBooks', 'ADNPayV2'))")  # solo clientes vigentes (con origen en CRM, Books o ADNPayV2)
                pkr = "ClienteId"
            elif ref in POR_LLAVE:                                     # catálogos por su llave de origen
                cond = f"zref.FuenteBase = N'{POR_LLAVE[ref]}' AND zref.FuenteLlave = {v}"
                pkr = modelo.TABLAS[ref].get("pkcol") or next(c["name"] for c in modelo.TABLAS[ref]["cols"] if c.get("pk"))
            elif ref in BUSQUEDA:
                pkr, claves = BUSQUEDA[ref]
                cond = " OR ".join(f"zref.[{k}] = {v}" for k in claves)
            else:
                continue
            applies.append(f"OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(zref.[{pkr}]) END AS Id FROM {ref} zref WHERE {cond}) {a}")
            partes.append(f"{a}.Id")
        if not partes:
            continue
        sel[d] = partes[0] if len(partes) == 1 else f"COALESCE({', '.join(partes)})"
        o = f"o_{d}"
        vals = [ctl_texto(x) for x, _ in orígenes]
        sel[o] = vals[0] if len(vals) == 1 else f"COALESCE({', '.join(vals)})"
        aux.append(o)
        anoms.append(Anomalia("IN-01", d, f"s.{o}", f"s.{o} IS NOT NULL AND s.[{d}] IS NULL",
                              f"Referencia sin correspondencia única en {ref}"))
        reglas.add("IN-01")

    sel.update(override)
    # Valores que no se pudieron interpretar (solo cuando el origen es texto)
    for d, (x, tipo_o) in fuentes.items():
        if d in override or not _es_texto(tipo_o):
            continue
        td = cols_modelo[d]["type"].lower()
        regla = None
        if td.startswith("datetimeoffset") or td == "date":
            regla, det = "ES-02", "Fecha ilegible o ficticia; se conserva el texto original"
        elif td == "decimal(19,4)":
            regla, det = "ES-04", "Monto ilegible; se conserva el texto original"
        elif d == "Circuito":
            regla, det = "ID-01", "Circuito que no cumple el patrón aprobado"
        if regla:
            o = f"o_{d}"
            sel[o] = f"ctl.fn_Texto(CONVERT(nvarchar(400), {x}))"
            aux.append(o)
            anoms.append(Anomalia(regla, d, f"s.{o}", f"s.{o} IS NOT NULL AND s.[{d}] IS NULL", det))
            reglas.add(regla)

    if "AtributosExtendidos" in cols_modelo and "AtributosExtendidos" not in sel:
        sel["AtributosExtendidos"] = atributos(base, tabla, alias, excluir=excluir_atributos, incluir=attr_extra)
    if moneda and "Moneda" in cols_modelo and "Moneda" not in override:
        sel["Moneda"] = moneda

    # Montos y su equivalente en colones (D5)
    pares = [c for c in cols_modelo if c + "CRC" in cols_modelo and c in sel]
    tiene_tc = "TipoCambio" in cols_modelo and "Moneda" in sel
    tc_origen = sel.pop("TipoCambio", None)          # tipo de cambio que trae el origen: solo respaldo (D5)
    tc_resp = tc_respaldo or tc_origen
    filtros = list(filtros_extra)
    if eliminado and not solo_actualizar:
        sel["o_Eliminado"] = f"CAST(ISNULL({alias}.[deleted], 0) AS int)"
        aux.append("o_Eliminado")
        filtros.append(("s.o_Eliminado = 1", "DD-06", "Registro marcado como eliminado en el origen (deleted = 1)"))
        reglas.add("DD-06")

    ft = fuente_tabla or tabla
    # Período del dato (trazabilidad a fuente y período): la fecha propia del registro, en este orden de preferencia
    fdato = fecha_dato or next((c for c in _FECHAS_DATO if c in sel), None)
    llave_sql = llave_expr or f"ctl.fn_Texto(CONVERT(nvarchar(200), {_src(alias, llave_src, llave_tipo)}))"
    lineas = [f"'{sistema}' AS FuenteSistema", f"N'{base}' AS FuenteBase", f"N'{ft}' AS FuenteTabla",
              f"{llave_sql} AS FuenteLlave",
              (f"{sel[fdato]} AS FechaDato" if fdato in sel else (f"{fdato} AS FechaDato" if fdato else "CAST(NULL AS datetimeoffset(0)) AS FechaDato"))]
    lineas += [f"{e} AS [{c}]" for c, e in sel.items()]
    lineas += [f"{e} AS [d_{c}]" for c, e in crc_directo.items()]
    if tc_resp and tiene_tc and pares:
        lineas.append(f"TRY_CONVERT(decimal(19,6), {tc_resp}) AS [d_TipoCambio]")
    interno = "SELECT " + ",\n       ".join(lineas) + f"\nFROM {base}.dbo.[{tabla}] {alias}"
    if extra_from:
        interno += "\n" + extra_from.strip()
    if applies:
        interno += "\n" + "\n".join(applies)
    if where:
        interno += f"\nWHERE {where}"

    columnas = [c for c in sel if c in cols_modelo]
    if tiene_tc and pares:
        f_tc = fecha_tc or ("q.FechaCreacionOrigen" if "FechaCreacionOrigen" in sel else "q.FechaDato")
        resp = "CASE WHEN q.d_TipoCambio > 1 THEN q.d_TipoCambio END" if tc_resp else "NULL"
        ext = ["q.*", "tx.Tasa AS TipoCambio"]
        for c in pares:
            calc = f"CASE q.Moneda WHEN 'CRC' THEN q.[{c}] WHEN 'USD' THEN CAST(q.[{c}] * tx.Tasa AS decimal(19,4)) END"
            if c + "CRC" in crc_directo:      # el valor contable de Books en moneda base manda; el cálculo solo si falta
                calc = f"COALESCE(q.[d_{c}CRC], {calc})"
            ext.append(f"{calc} AS [{c}CRC]")
            columnas.append(c + "CRC")
        for c, e in crc_directo.items():      # monto en colones sin su par en moneda original
            if c[:-3] not in pares:
                ext.append(f"q.[d_{c}] AS [{c}]")
                columnas.append(c)
        columnas.append("TipoCambio")
        select = ("SELECT " + ",\n       ".join(ext) + "\nFROM (\n" + interno + "\n) q\n"
                  f"OUTER APPLY (SELECT TOP 1 t.Venta FROM ref.TipoCambio t WHERE t.Fecha <= CAST({f_tc} AS date) ORDER BY t.Fecha DESC) tc\n"
                  f"CROSS APPLY (SELECT CASE q.Moneda WHEN 'CRC' THEN CAST(1 AS decimal(19,6)) "
                  f"WHEN 'USD' THEN COALESCE(tc.Venta, {resp}) END AS Tasa) tx")
        reglas.add("D5")
    else:
        select = interno

    tiene_mod = "FechaModificacionOrigen" in columnas
    return Paso(
        nombre=nombre, orden=orden, destino=destino, fuente=(sistema, "SQLServer", base, tabla), llave_origen=llave_src,
        descripcion=descripcion or f"{destino} desde {base}.{tabla} según la matriz de correspondencia.",
        reglas=sorted(reglas), columnas=columnas, auxiliares=aux, anomalias=anoms, filtros=filtros,
        preparacion=preparacion, clave=clave, depende=list(depende or []), solo_actualizar=solo_actualizar,
        requiere_periodo=requiere_periodo,
        traza_from=f"{base}.dbo.[{tabla}] {alias}" + ("\n" + extra_from.strip() if extra_from else "") + (f"\nWHERE {where}" if where else ""),
        traza_llave=llave_sql, traza_columna="" if llave_expr else f"{alias}.[{llave_src}]",
        dedup_regla="DD-02" if (dedup and tiene_mod) else "DD-04",
        dedup_orden="s.FechaModificacionOrigen DESC, s.HashContenido" if (dedup and tiene_mod) else "",
        dedup_motivo=("Versión anterior del mismo registro en el espejo; se conserva la modificación más reciente"
                      if (dedup and tiene_mod) else "Registro repetido por la llave del paso; se conserva uno según el orden definido"),
        select="\n" + select + "\n")


def ctl_texto(x):
    return f"ctl.fn_Texto(CONVERT(nvarchar(400), {x}))"
