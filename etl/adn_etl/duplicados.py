# -*- coding: utf-8 -*-
"""Duplicados: línea base del diagnóstico (Sprint 1) frente al modelo unificado (Sprint 4).

Indicador del DoD: reducción de duplicados no justificados ≥ 95 % respecto a la línea base.

  Línea base   duplicados medidos HOY sobre las mismas copias del origen que se usaron en el diagnóstico, con la
               definición de cada categoría. Donde el diagnóstico publicó una cifra, se muestra al lado para
               comprobar que la línea base recalculada coincide.
  Modelo       duplicados que quedan en ADN_Unificado con la misma definición.
  Justificados duplicados que quedan en el modelo por una decisión aprobada (se documenta cuál).
  Reducción    (línea base − no justificados en el modelo) / línea base.

Categorías:
  1. Repetidos por llave en cada tabla de origen (copias exactas y versiones del espejo: p. ej. el 17,8 % de las
     facturas de Books del diagnóstico) frente a llaves repetidas en el modelo.
  2. Registros en dos versiones de la misma tabla de Zoho (base y _Extended) frente al mismo id del CRM repetido
     en el modelo.
  3. Llamadas idénticas (todas las columnas salvo el id) en los meses cargados frente a llamadas con el mismo
     contenido en el modelo.
  4. Clientes repetidos entre sistemas (misma cédula en CRM, Books y ADNPayV2) frente a clientes con la misma
     cédula en el modelo.
Solo conteos.
"""
import csv
import datetime as dt
import os

from . import bd, reconciliar, runner
from .pasos import telefonia

UMBRAL = 95.0

# Cifras publicadas en los informes del diagnóstico (Informe_ZBooks_Mirror, sección 3.3: filas − IDs distintos)
DIAGNOSTICO = {
    ("core.Factura", "invoices"): 67685,
    ("core.MovimientoBancario", "banktransactions"): 9318,
    ("core.Pago", "customerpayments"): 3558,
    ("core.Gasto", "expenses"): 289,
}


def _q(x):
    return x.replace("'", "''")


def _sql_llave(g):
    """Llaves repetidas en el universo del origen y en el modelo, para una tabla de origen."""
    per, fu, fd = "", "", ""
    if g.periodo:
        per = f", {g.periodo} AS f"
        fu = "\nWHERE x.f >= @Ini AND x.f < @Fin AND CONVERT(char(7), x.f, 126) IN (SELECT Mes FROM #m)"
        fd = " AND CONVERT(char(7), t.FechaDato, 126) IN (SELECT Mes FROM #m)"
    return f"""/* ===== Llaves repetidas · {g.nombre} · {g.destino} ← {g.base}.{g.tabla} ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM {g.destino} t WHERE t.FuenteBase = N'{_q(g.base)}' AND t.FuenteTabla = N'{_q(g.tabla)}' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));
DECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));
SELECT (SELECT COUNT_BIG(x.k) - COUNT_BIG(DISTINCT x.k)
        FROM (SELECT CAST({g.llave} AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k{per}
              FROM {g.desde}) x{fu}) AS Origen,
       (SELECT COUNT_BIG(t.FuenteLlave) - COUNT_BIG(DISTINCT t.FuenteLlave) FROM {g.destino} t
        WHERE t.FuenteBase = N'{_q(g.base)}' AND t.FuenteTabla = N'{_q(g.tabla)}'{fd}) AS Modelo,
       CAST(0 AS bigint) AS Justificados;
"""


_DOS_VERSIONES = [   # (tabla base, tabla _Extended, columna id en _Extended, destino, id del CRM en el modelo)
    ("Accounts", "Accounts_Extended", "id", "core.Servicio", "CuentaCrmId"),
    ("Cases", "Cases_Extended", "CaseId", "core.Caso", "CasoCrmId"),
    ("Sales_Orders", "Sales_Orders_Extended", "id", "core.OrdenVenta", "OrdenVentaCrmId"),
]


def _sql_dos_versiones(base_t, ext_t, ext_id, destino, col):
    return f"""/* ===== Dos versiones · Zoho_Mirror.{base_t} y {ext_t} → {destino}.{col} ===== */
SET NOCOUNT ON;
SELECT (SELECT COUNT_BIG(*) FROM (SELECT DISTINCT b.id FROM Zoho_Mirror.dbo.[{base_t}] b
                                  WHERE EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.[{ext_t}] e WHERE e.[{ext_id}] = b.id)) z) AS Origen,
       (SELECT COUNT_BIG(t.[{col}]) - COUNT_BIG(DISTINCT t.[{col}]) FROM {destino} t) AS Modelo,
       CAST(0 AS bigint) AS Justificados;
"""


def _sql_llamadas(paso, desde, alias, base, tabla):
    huella = telefonia._huella_fila(alias, telefonia._CONTENIDO)
    return f"""/* ===== Llamadas idénticas · {paso} ({base}.{tabla}, meses cargados) ===== */
SET NOCOUNT ON;
DROP TABLE IF EXISTS #m;
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM core.Llamada t WHERE t.FuenteBase = N'{base}' AND t.FuenteTabla = N'{tabla}' AND t.FechaDato IS NOT NULL;
DECLARE @Ini datetime2 = (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m);
DECLARE @Fin datetime2 = DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m));
SELECT (SELECT COUNT_BIG(*) - COUNT_BIG(DISTINCT {huella}) FROM {desde} {alias}
        WHERE {alias}.StartDateTime >= @Ini AND {alias}.StartDateTime < @Fin
          AND CONVERT(char(7), {alias}.StartDateTime, 126) IN (SELECT Mes FROM #m)) AS Origen,
       (SELECT COUNT_BIG(*) - COUNT_BIG(DISTINCT t.HashContenido) FROM core.Llamada t
        WHERE t.FuenteBase = N'{base}' AND t.FuenteTabla = N'{tabla}') AS Modelo,
       CAST(0 AS bigint) AS Justificados;
"""


_SQL_CLIENTES = """/* ===== Clientes repetidos entre sistemas (misma cédula válida) ===== */
SET NOCOUNT ON;
DROP TABLE IF EXISTS #ced;
SELECT ctl.fn_Cedula(a.Cedula_Jurida_Persona) AS Ced INTO #ced
FROM (SELECT x.*, ROW_NUMBER() OVER (PARTITION BY x.id ORDER BY x.Modified_Time DESC) AS rn FROM Zoho_Mirror.dbo.Accounts_Extended x) a
WHERE a.rn = 1
UNION ALL
SELECT ctl.fn_Cedula(b.Cedula_Jurida_Persona)
FROM (SELECT x.*, ROW_NUMBER() OVER (PARTITION BY x.id ORDER BY ctl.fn_FechaCR(x.Modified_Time) DESC) AS rn FROM Zoho_Mirror.dbo.Accounts x
      WHERE ISNULL(x.deleted, 0) = 0 AND NOT EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.Accounts_Extended e WHERE e.id = x.id)) b
WHERE b.rn = 1
UNION ALL
SELECT ctl.fn_Cedula(c.cf_identificaci_n_unformatted)
FROM (SELECT x.*, ROW_NUMBER() OVER (PARTITION BY x.contact_id ORDER BY ctl.fn_FechaCR(x.last_modified_time) DESC, x.contact_name) AS rn
      FROM ZBooks_Mirror.dbo.contacts x WHERE x.contact_type = 'customer' AND NULLIF(LTRIM(x.contact_id), '') IS NOT NULL) c
WHERE c.rn = 1
UNION ALL
SELECT ctl.fn_Cedula(p.id) FROM ADNPayV2.dbo.Customer p WHERE p.status = 'approved';
SELECT (SELECT COUNT_BIG(Ced) - COUNT_BIG(DISTINCT Ced) FROM #ced) AS Origen,
       (SELECT COUNT_BIG(Cedula) - COUNT_BIG(DISTINCT Cedula) FROM core.Cliente) AS Modelo,
       CAST(0 AS bigint) AS Justificados;
"""


# Tablas que no entran en la medición de duplicados: catálogos derivados (cada nombre de unidad se repite en cada
# posición: no son registros duplicados) y relaciones que reutilizan filas de otro paso (se contarían dos veces)
_NO_MEDIR = {"ref_UnidadFlota": "catálogo derivado de las posiciones", "core_PagoFactura": "mismas filas que core_Pago"}


def categorias():
    """(categoría, detalle, sql, cifra del diagnóstico, en_diagnostico) en orden de reporte.
    en_diagnostico = la categoría fue identificada en los informes del diagnóstico (Sprint 1): forma la línea base del
    indicador. Las demás son repetidos hallados después (Sprint 3) y se informan aparte."""
    res = []
    otros = []
    for g in reconciliar.grupos():
        if g.nombre in _NO_MEDIR:
            continue
        cifra = DIAGNOSTICO.get((g.destino, g.tabla))
        if cifra is not None:
            res.append(("1. Copias exactas en Zoho Books", f"{g.nombre} ← {g.base}.{g.tabla}", _sql_llave(g), cifra, True))
        else:
            otros.append(("5. Llaves repetidas en otras tablas", f"{g.nombre} ← {g.base}.{g.tabla}", _sql_llave(g), None, False))
    for b, e, eid, d, c in _DOS_VERSIONES:
        res.append(("2. Dos versiones de la misma tabla (Zoho)", f"{b} y {e} → {d}.{c}", _sql_dos_versiones(b, e, eid, d, c),
                    None, True))
    for paso, desde, alias, base, tabla in [
            ("core_Llamada_Historico", "ADNApp.dbo.Telephony_cdr_historico", "c", "ADNApp", "Telephony_cdr_historico"),
            ("core_Llamada_SQL", "ADNApp.dbo.Telephony_cdr", "c", "ADNApp", "Telephony_cdr"),
            ("core_Llamada", "stg.mongo_Telephony_cdr", "c", "developer_adn_app_db", "Telephony_cdr")]:
        res.append(("3. Llamadas idénticas", f"{paso} ← {base}.{tabla}", _sql_llamadas(paso, desde, alias, base, tabla), None, True))
    res.append(("4. Clientes repetidos entre sistemas", "misma cédula en CRM, Books y ADNPayV2 → core.Cliente", _SQL_CLIENTES,
                None, True))
    return res + otros


def generar_sql():
    os.makedirs(reconciliar.DIR_SQL, exist_ok=True)
    ruta = os.path.join(reconciliar.DIR_SQL, "duplicados_linea_base_vs_modelo.sql")
    with open(ruta, "w", encoding="utf-8", newline="\n") as f:
        f.write("/* Duplicados: línea base del diagnóstico (origen) frente al modelo unificado · Sprint 4. SOLO LECTURA.\n"
                "   Generado por etl/adn_etl/duplicados.py (no editar a mano). Cada bloque devuelve Origen, Modelo, Justificados.\n"
                "   Ejecutar con ./etl.ps1 duplicados (reporte) o por bloques en SSMS. */\n"
                "SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON;\nUSE ADN_Unificado;\nGO\n")
        for cat, det, sql, _, _ in categorias():
            f.write("\n" + sql + "GO\n")
    return ruta


def ejecutar(cfg):
    ahora = dt.datetime.now(dt.timezone(dt.timedelta(hours=-6))).replace(microsecond=0)
    carpeta = os.path.join(runner.DIR_REPORTES, f"duplicados_{ahora.strftime('%Y%m%d_%H%M%S')}")
    os.makedirs(carpeta, exist_ok=True)
    conn = bd.conectar(cfg, autocommit=True)
    filas, consultas = [], []
    try:
        ev = runner.evidencia_entorno(cfg, conn)
        cur = conn.cursor()
        for cat, det, sql, diag, en_diag in categorias():
            consultas.append(sql)
            t0 = dt.datetime.now()
            r = bd.filas(cur, sql)[0]
            o, m, j = (int(x or 0) for x in r)
            noj = max(m - j, 0)
            red = 100.0 if o == 0 else round(100.0 * (o - noj) / o, 2)
            filas.append(dict(Categoria=cat, Detalle=det, Diagnostico=diag, LineaBase=o, Modelo=m, Justificados=j,
                              NoJustificados=noj, Reduccion=red, EnDiagnostico=en_diag,
                              Segundos=round((dt.datetime.now() - t0).total_seconds(), 1)))
            if o or m:
                print(f"{cat[:28]:28s} {det[:60]:60s} línea base {o:>8}  modelo {m:>6}  no justificados {noj:>6}  reducción {red:6.2f} %")
    finally:
        conn.close()

    dg = [f for f in filas if f["EnDiagnostico"]]
    base = sum(f["LineaBase"] for f in dg)
    noj = sum(f["NoJustificados"] for f in dg)
    red = 100.0 if not base else round(100.0 * (base - noj) / base, 2)
    base_t = sum(f["LineaBase"] for f in filas)
    noj_t = sum(f["NoJustificados"] for f in filas)
    red_t = 100.0 if not base_t else round(100.0 * (base_t - noj_t) / base_t, 2)
    print(f"\nINDICADOR (categorías del diagnóstico): línea base {base} · quedan {noj} no justificados · reducción {red:.2f} % "
          f"(umbral {UMBRAL:.0f} %) → {'CUMPLE' if red >= UMBRAL else 'NO CUMPLE'}")
    print(f"AMPLIADO (con los repetidos hallados después): línea base {base_t} · quedan {noj_t} · reducción {red_t:.2f} %")

    with open(os.path.join(carpeta, "duplicados.csv"), "w", encoding="utf-8-sig", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(filas[0].keys()), delimiter=";")
        w.writeheader()
        w.writerows(filas)
    with open(os.path.join(carpeta, "consultas.sql"), "w", encoding="utf-8", newline="\n") as f:
        f.write("USE ADN_Unificado;\nGO\n" + "GO\n".join(consultas) + "GO\n")

    def n(x):
        return "" if x is None else f"{x:,}".replace(",", ".")
    md = ["# Duplicados: línea base del diagnóstico vs modelo unificado", "",
          f"Ejecución: {ahora.strftime('%d/%m/%Y %H:%M')} (hora de Costa Rica) · entorno {ev.get('Marca ctl.Entorno', '')}", "",
          f"**Reducción de duplicados no justificados: {red:.2f} %** (línea base {n(base)}, quedan {n(noj)} en el modelo; "
          f"umbral {UMBRAL:.0f} %: {'cumple' if red >= UMBRAL else 'no cumple'}). La línea base son las categorías de "
          f"duplicados identificadas en los informes del diagnóstico (categorías 1 a 4).", "",
          f"Medición ampliada, con los repetidos hallados después en otras tablas (categoría 5): línea base {n(base_t)}, "
          f"quedan {n(noj_t)}, reducción {red_t:.2f} %. No se miden {', '.join(f'{k} ({v})' for k, v in _NO_MEDIR.items())}.", "",
          "La línea base se recalcula sobre las mismas copias del origen que usó el diagnóstico; la columna Diagnóstico "
          "muestra la cifra publicada en los informes cuando existe. Consultas en `consultas.sql` y versionadas en "
          "`sql/20_validacion/duplicados_linea_base_vs_modelo.sql`.", "", "## Resumen por categoría", "",
          "| Categoría | Línea base | En el modelo | Justificados | No justificados | Reducción |", "|---|---:|---:|---:|---:|---:|"]
    cats = {}
    for f_ in filas:
        c = cats.setdefault(f_["Categoria"], [0, 0, 0, 0])
        c[0] += f_["LineaBase"]; c[1] += f_["Modelo"]; c[2] += f_["Justificados"]; c[3] += f_["NoJustificados"]
    for c, v in cats.items():
        r = 100.0 if not v[0] else 100.0 * (v[0] - v[3]) / v[0]
        md.append(f"| {c} | {n(v[0])} | {n(v[1])} | {n(v[2])} | {n(v[3])} | {r:.2f} % |")
    md += ["", "## Detalle (solo filas con duplicados en el origen o en el modelo)", "",
           "| Categoría | Detalle | Diagnóstico | Línea base | En el modelo | No justificados | Reducción |", "|---|---|---:|---:|---:|---:|---:|"]
    for f_ in filas:
        if f_["LineaBase"] or f_["Modelo"] or f_["Diagnostico"]:
            md.append(f"| {f_['Categoria']} | {f_['Detalle']} | {n(f_['Diagnostico'])} | {n(f_['LineaBase'])} | {n(f_['Modelo'])} | "
                      f"{n(f_['NoJustificados'])} | {f_['Reduccion']:.2f} % |")
    with open(os.path.join(carpeta, "duplicados.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(md) + "\n")
    print("Carpeta:", os.path.relpath(carpeta, runner.RAIZ))
