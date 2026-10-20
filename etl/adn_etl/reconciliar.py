# -*- coding: utf-8 -*-
"""Reconciliación origen-destino (Sprint 4).

Para cada tabla de origen que alimenta el modelo se recalcula, directamente sobre la copia del origen, la llave con la
que el paso escribe FuenteLlave, y cada registro del origen se clasifica en una sola categoría:

  Cargado          su llave está en la tabla del modelo (FuenteBase + FuenteTabla + FuenteLlave)
  Excluido         no está en el modelo, pero ctl.Descarte registra la regla que lo excluyó (lote CONFIRM exitoso)
  Sin conciliar    ni en el modelo ni en ctl.Descarte  → diferencia que hay que justificar o corregir

y en el sentido contrario:

  Destino sin origen   llaves del modelo que el origen ya no produce (debe ser 0)

Otros conceptos del reporte:
  FilasOrigen       COUNT(*) de la tabla de origen completa (o de los meses cargados, en los pasos por período)
  FueraDeAlcance    FilasOrigen − filas del universo del paso: las excluye un filtro documentado del paso
                    (p. ej. solo contactos tipo cliente, solo contrataciones aprobadas). Se muestra el filtro.
  Repetidas         filas del origen con la misma llave (versiones del espejo, filas idénticas): se consolidan en una
  LlaveVacia        filas sin llave; se justifican con los descartes sin llave (ES-05) del último lote confirmado

%Conciliado = filas del universo cuya llave quedó cargada o excluida con motivo (+ llaves vacías justificadas)
              / filas del universo. Criterio del DoD: ≥ 99 % o diferencias justificadas.

Las consultas son de solo lectura sobre el origen y el modelo; los resultados (solo conteos y llaves técnicas) se
guardan en ctl.Reconciliacion y ctl.ReconciliacionPendiente dentro del sandbox. Los reportes llevan solo conteos.
"""
import csv
import datetime as dt
import os
from dataclasses import dataclass, field
from typing import List

from . import bd, registro, runner

DIR_SQL = os.path.join(runner.RAIZ, "sql", "20_validacion")
UMBRAL = 99.0


@dataclass
class Grupo:
    pasos: List[str]          # pasos que escriben esta tabla de origen en el destino (para buscar sus descartes)
    destino: str
    base: str
    tabla: str                # FuenteTabla en el modelo
    desde: str                # FROM del universo del origen (alias + filtros del paso)
    llave: str                # expresión que reproduce FuenteLlave
    periodo: str = ""         # expresión de fecha (solo pasos por período)
    nota: str = ""
    filtro: str = field(default="")

    @property
    def nombre(self):
        return self.pasos[0] if len(self.pasos) == 1 else f"{self.pasos[0]}[{self.tabla}]"

    @property
    def primera(self):
        p = self.desde.strip().split("\n")[0]
        return None if p.lstrip().startswith("(") else p


def _q(x):
    return x.replace("'", "''")


# Universos que no se pueden deducir de la traza del paso (consolidación de clientes, pasos con UNION)
_CLIENTE = [
    ("Zoho_Mirror", "Accounts_Extended", "Zoho_Mirror.dbo.Accounts_Extended x", "x.id", ""),
    ("Zoho_Mirror", "Accounts", "Zoho_Mirror.dbo.Accounts x\nWHERE ISNULL(x.deleted, 0) = 0\n"
                                "  AND NOT EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.Accounts_Extended e WHERE e.id = x.id)", "x.id",
     "las cuentas que también están en Accounts_Extended se cargan desde esa tabla; las eliminadas no son clientes"),
    ("ZBooks_Mirror", "contacts", "ZBooks_Mirror.dbo.contacts x\nWHERE x.contact_type = 'customer' AND NULLIF(LTRIM(x.contact_id), '') IS NOT NULL",
     "x.contact_id", "los contactos tipo proveedor van a core.Proveedor"),
    ("ADNPayV2", "Customer", "ADNPayV2.dbo.Customer x\nWHERE x.status = 'approved'", "CAST(x.[index] AS nvarchar(200))",
     "solo las contrataciones aprobadas identifican clientes (D9)"),
    ("ADNApp", "ZohoEngine_zohocustomer", "ADNApp.dbo.ZohoEngine_zohocustomer x", "CAST(x.id AS nvarchar(200))", ""),
]
_ESPECIALES = {
    "ref_TipoCambio": [
        ("ADNApp", "Telephony_usdexchange", "ADNApp.dbo.Telephony_usdexchange x", "CAST(x.id AS nvarchar(200))", ""),
        ("developer_adn_app_db", "Telephony_usdexchange", "stg.mongo_Telephony_usdexchange x", "CAST(x._id AS nvarchar(200))",
         "origen: copia de solo lectura de MongoDB (stg)"),
    ],
    "core_Servicio": [
        ("Zoho_Mirror", "Accounts_Extended", "Zoho_Mirror.dbo.Accounts_Extended x", "x.id", ""),
        ("Zoho_Mirror", "Accounts", "Zoho_Mirror.dbo.Accounts x\n"
                                    "WHERE NOT EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.Accounts_Extended e WHERE e.id = x.id)", "x.id",
         "las cuentas que también están en Accounts_Extended se cargan desde esa tabla"),
    ],
    "ref_Usuario_ADNApp": [
        ("ADNApp", "ZohoEngine_zohouser", "ADNApp.dbo.ZohoEngine_zohouser x\n"
                                          "WHERE NOT EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.Users u WHERE ctl.fn_Texto(u.id) = ctl.fn_Texto(x.zoho_id))",
         "ctl.fn_Texto(x.zoho_id)", "los usuarios que ya están en Zoho CRM (Users) se cargan desde allí"),
    ],
    "core_ClienteOrigen": _CLIENTE,
}
# Motivo de los filtros de alcance de pasos generados desde la matriz (se muestran en el reporte)
_NOTA_FILTRO = {
    "core_Producto_Books": "artículos de Books vinculados a un producto del CRM: se cargan como ese producto (core_Producto_BooksVinculo)",
    "core_OrdenVenta_Complemento": "órdenes que también están en Sales_Orders_Extended: se cargan desde esa tabla",
    "core_Caso_Complemento": "casos que también están en Cases_Extended: se cargan desde esa tabla",
    "core_Proveedor": "solo contactos tipo proveedor; los tipo cliente van a la consolidación de clientes",
}
_OMITIR = {"core_Cliente": "cliente consolidado (por cédula o por cuenta): se reconcilia por sus orígenes en core.ClienteOrigen"}


def grupos():
    """Una entrada por (destino, tabla de origen). Los pasos de solo actualización no agregan registros."""
    pasos = [p for p in registro.todos() if not p.solo_actualizar]
    por_destino = {}
    for p in pasos:
        por_destino.setdefault(p.destino, []).append(p.nombre)
    res, vistos = [], {}
    for p in pasos:
        if p.nombre in _OMITIR:
            continue
        if p.nombre in _ESPECIALES:
            defs = _ESPECIALES[p.nombre]
        else:
            if p.traza_llave:
                desde, llave = p.traza_from, p.traza_llave
            elif p.llave_origen:
                desde, llave = f"[{p.fuente[2]}].dbo.[{p.fuente[3]}] x", f"ctl.fn_Texto(CAST(x.[{p.llave_origen}] AS nvarchar(200)))"
            else:
                continue
            nota = "origen: copia de solo lectura de MongoDB (stg)" if p.fuente[1] == "MongoDB" else _NOTA_FILTRO.get(p.nombre, "")
            defs = [(p.fuente[2], p.linaje_tabla or p.fuente[3], desde, llave, nota)]
        for base, tabla, desde, llave, nota in defs:
            k = (p.destino, base, tabla)
            if k in vistos:                     # otro paso ya cubre esta tabla de origen en el mismo destino
                vistos[k].pasos.append(p.nombre)
                continue
            g = Grupo([p.nombre], p.destino, base, tabla, desde, llave, p.periodo_origen, nota)
            lineas = desde.strip().split("\n")
            g.filtro = " ".join(l.strip() for l in lineas[1:] if "@Desde" not in l and "@Hasta" not in l).strip()
            vistos[k] = g
            res.append(g)
    # los descartes se buscan en todos los pasos del destino que leen la misma tabla
    for g in res:
        g.pasos_descarte = por_destino[g.destino]
    return res


def sql_grupo(g):
    """Consulta de reconciliación de un grupo. Autocontenida: se puede ejecutar tal cual en SSMS."""
    pasos_in = ", ".join(f"N'{_q(x)}'" for x in g.pasos_descarte)
    filtro_mes_u = filtro_mes_d = ""
    per = ""
    if g.periodo:
        per = f", {g.periodo} AS f"
        filtro_mes_u = "\nWHERE x.f >= @Ini AND x.f < @Fin AND CONVERT(char(7), x.f, 126) IN (SELECT Mes FROM #m)"
        filtro_mes_d = " AND CONVERT(char(7), t.FechaDato, 126) IN (SELECT Mes FROM #m)"
    rango = ""
    if g.periodo:   # rango con un día de margen (búsqueda por índice); el filtro exacto es por mes
        rango = ("\nDECLARE @Ini datetime2 = DATEADD(day, -1, (SELECT CAST(MIN(Mes) + '-01' AS datetime2) FROM #m));"
                 "\nDECLARE @Fin datetime2 = DATEADD(day, 1, DATEADD(month, 1, (SELECT CAST(MAX(Mes) + '-01' AS datetime2) FROM #m)));")
    if g.primera:
        crudo = f"(SELECT COUNT_BIG(*) FROM {g.primera}" + (f" WHERE {g.periodo} >= @Ini AND {g.periodo} < @Fin AND CONVERT(char(7), {g.periodo}, 126) IN (SELECT Mes FROM #m)" if g.periodo else "") + ")"
    else:
        crudo = "CAST(NULL AS bigint)"
    return f"""/* ===== {g.nombre} · {g.destino} ← {g.base}.{g.tabla} ===== */
SET NOCOUNT ON;
DECLARE @Desde date = NULL, @Hasta date = NULL;   -- las trazas de los pasos por período usan estas variables (sin filtro)
DROP TABLE IF EXISTS #m, #u, #o, #d, #e;
/* 0. Meses cargados (solo pasos por período: se compara el mismo período en origen y destino) */
SELECT DISTINCT CONVERT(char(7), t.FechaDato, 126) AS Mes INTO #m
FROM {g.destino} t WHERE t.FuenteBase = N'{_q(g.base)}' AND t.FuenteTabla = N'{_q(g.tabla)}' AND t.FechaDato IS NOT NULL;{rango}
/* 1. Universo del origen: una fila por registro, con la llave recalculada como la escribe el paso */
SELECT CAST(x.k AS nvarchar(200)) COLLATE DATABASE_DEFAULT AS k INTO #u
FROM (SELECT {g.llave} AS k{per}
      FROM {g.desde}) x{filtro_mes_u};
DECLARE @FilasOrigen bigint = {crudo};
DECLARE @FilasUniverso bigint = (SELECT COUNT_BIG(*) FROM #u);
DECLARE @LlaveVacia bigint = (SELECT COUNT_BIG(*) FROM #u WHERE k IS NULL);
SELECT DISTINCT k INTO #o FROM #u WHERE k IS NOT NULL;
CREATE UNIQUE CLUSTERED INDEX ix ON #o (k);
/* 2. Llaves en el modelo */
SELECT DISTINCT t.FuenteLlave COLLATE DATABASE_DEFAULT AS k INTO #d
FROM {g.destino} t WHERE t.FuenteBase = N'{_q(g.base)}' AND t.FuenteTabla = N'{_q(g.tabla)}' AND t.FuenteLlave IS NOT NULL{filtro_mes_d};
CREATE UNIQUE CLUSTERED INDEX ix ON #d (k);
/* 3. Llaves excluidas con su regla (descartes de lotes CONFIRM exitosos de los pasos de este destino) */
SELECT d.FuenteLlave COLLATE DATABASE_DEFAULT AS k, MIN(d.ReglaId) AS Regla INTO #e
FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
WHERE l.Paso IN ({pasos_in}) AND d.FuenteTabla = N'{_q(g.tabla)}' AND d.FuenteLlave IS NOT NULL
GROUP BY d.FuenteLlave;
CREATE UNIQUE CLUSTERED INDEX ix ON #e (k);
/* Llaves vacías justificadas: descartes sin llave del último lote confirmado de cada paso */
DECLARE @VaciaJust bigint = (SELECT COUNT_BIG(*) FROM ctl.Descarte d
    WHERE d.FuenteTabla = N'{_q(g.tabla)}' AND d.FuenteLlave IS NULL
      AND d.LoteId IN (SELECT MAX(l.LoteId) FROM ctl.Lote l WHERE l.Paso IN ({pasos_in}) AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso' GROUP BY l.Paso));
/* 4. Resultado */
SELECT @FilasOrigen AS FilasOrigen, @FilasUniverso AS FilasUniverso, @LlaveVacia AS LlaveVacia,
       CASE WHEN @VaciaJust < @LlaveVacia THEN @VaciaJust ELSE @LlaveVacia END AS LlaveVaciaJustificada,
       (SELECT COUNT_BIG(*) FROM #o) AS Llaves,
       (SELECT COUNT_BIG(*) FROM #o o WHERE EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)) AS Cargadas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS Excluidas,
       (SELECT COUNT_BIG(*) FROM #o o WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k)
                                       AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)) AS SinConciliar,
       (SELECT COUNT_BIG(*) FROM #d d WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)) AS DestinoSinOrigen,
       (SELECT COUNT_BIG(*) FROM #u u WHERE u.k IS NOT NULL
               AND (EXISTS (SELECT 1 FROM #d d WHERE d.k = u.k) OR EXISTS (SELECT 1 FROM #e e WHERE e.k = u.k))) AS FilasConciliadas;
/* 5. Justificación de las excluidas, por regla */
SELECT e.Regla, COUNT_BIG(*) AS Llaves FROM #o o JOIN #e e ON e.k = o.k
WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) GROUP BY e.Regla ORDER BY 2 DESC;
"""


def generar_sql():
    """Versiona las consultas de reconciliación (documentación del DoD)."""
    os.makedirs(DIR_SQL, exist_ok=True)
    ruta = os.path.join(DIR_SQL, "reconciliacion_origen_destino.sql")
    gs = grupos()
    with open(ruta, "w", encoding="utf-8", newline="\n") as f:
        f.write("/* Reconciliación origen-destino · ADN_Unificado (Sprint 4). SOLO LECTURA sobre el origen y el modelo.\n"
                "   Generado por etl/adn_etl/reconciliar.py (no editar a mano): una consulta por tabla de origen.\n"
                "   Ejecutar con ./etl.ps1 reconciliar (guarda resultados y reporte) o por bloques en SSMS. */\n"
                "SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON;\nUSE ADN_Unificado;\nGO\n")
        for p, motivo in _OMITIR.items():
            f.write(f"/* {p}: {motivo} */\n")
        for g in gs:
            f.write("\n" + sql_grupo(g) + "GO\n")
    return ruta, len(gs)


def _pct(num, den):
    return 100.0 if not den else round(100.0 * num / den, 4)


def ejecutar(cfg, solo=None):
    gs = [g for g in grupos() if not solo or solo in g.pasos]
    if solo and not gs:
        raise SystemExit(f"No hay grupos de reconciliación para el paso {solo}.")
    conn = bd.conectar(cfg, autocommit=True)
    ahora = dt.datetime.now(dt.timezone(dt.timedelta(hours=-6))).replace(microsecond=0)
    sello = ahora.strftime("%Y%m%d_%H%M%S")
    carpeta = os.path.join(runner.DIR_REPORTES, f"reconciliacion_{sello}")
    os.makedirs(carpeta, exist_ok=True)
    filas, just, consultas = [], [], []
    try:
        ev = runner.evidencia_entorno(cfg, conn)
        cur = conn.cursor()
        for g in gs:
            q = sql_grupo(g)
            consultas.append(q)
            t0 = dt.datetime.now()
            cur.execute(q)
            res = None
            sets = []
            while True:
                if cur.description:
                    sets.append(cur.fetchall())
                if not cur.nextset():
                    break
            res, reglas = sets[0][0], sets[1] if len(sets) > 1 else []
            seg = (dt.datetime.now() - t0).total_seconds()
            (f_or, f_un, vacia, vacia_j, llaves, carg, excl, sinc, dso, f_conc) = [None if x is None else int(x) for x in res]
            repetidas = f_un - vacia - llaves
            fuera = (f_or - f_un) if (f_or is not None and f_or > f_un) else 0
            conc = f_conc + vacia_j
            pct = _pct(conc, f_un)
            estado = "OK" if (pct >= UMBRAL and dso == 0) else "REVISAR"
            filas.append(dict(Paso=g.nombre, TablaModelo=g.destino, Origen=f"{g.base}.{g.tabla}", FilasOrigen=f_or,
                              FueraDeAlcance=fuera, FilasUniverso=f_un, Repetidas=repetidas, LlaveVacia=vacia,
                              LlaveVaciaJustificada=vacia_j, Llaves=llaves, Cargadas=carg, Excluidas=excl, SinConciliar=sinc,
                              DestinoSinOrigen=dso, FilasConciliadas=conc, PctConciliado=pct, Estado=estado,
                              Segundos=round(seg, 1), Filtro=g.filtro, Nota=g.nota))
            for r in reglas:
                just.append((g.nombre, r[0], int(r[1])))
            # resultados y llaves pendientes (solo identificadores técnicos) quedan en el sandbox para el análisis
            cur.execute("""INSERT ctl.Reconciliacion (Ejecucion, Paso, TablaModelo, FuenteBase, FuenteTabla, FilasOrigen, FueraDeAlcance,
                                FilasUniverso, Repetidas, LlaveVacia, LlaveVaciaJustificada, Llaves, Cargadas, Excluidas, SinConciliar,
                                DestinoSinOrigen, FilasConciliadas, PctConciliado, Estado, Segundos)
                           VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)""",
                        (ahora, g.nombre, g.destino, g.base, g.tabla, f_or, fuera, f_un, repetidas, vacia, vacia_j, llaves, carg,
                         excl, sinc, dso, conc, pct, estado, round(seg, 1)))
            if sinc or dso:
                cur.execute(f"""INSERT ctl.ReconciliacionPendiente (Ejecucion, Paso, FuenteBase, FuenteTabla, FuenteLlave, Tipo)
                                SELECT TOP (2000) %s, %s, %s, %s, o.k, 'SinConciliar' FROM #o o
                                WHERE NOT EXISTS (SELECT 1 FROM #d d WHERE d.k = o.k) AND NOT EXISTS (SELECT 1 FROM #e e WHERE e.k = o.k)
                                UNION ALL
                                SELECT TOP (2000) %s, %s, %s, %s, d.k, 'DestinoSinOrigen' FROM #d d
                                WHERE NOT EXISTS (SELECT 1 FROM #o o WHERE o.k = d.k)""",
                            (ahora, g.nombre, g.base, g.tabla, ahora, g.nombre, g.base, g.tabla))
            print(f"{g.nombre:44s} {estado:7s} {pct:9.4f} %  universo {f_un:>9}  cargadas {carg:>9}  excluidas {excl:>8}  "
                  f"sin conciliar {sinc:>6}  destino sin origen {dso:>5}  ({seg:.0f} s)")
    finally:
        conn.close()

    tot_u = sum(f["FilasUniverso"] for f in filas)
    tot_c = sum(f["FilasConciliadas"] for f in filas)
    tot_s = sum(f["SinConciliar"] for f in filas)
    tot_d = sum(f["DestinoSinOrigen"] for f in filas)
    pct_g = _pct(tot_c, tot_u)
    revisar = [f for f in filas if f["Estado"] != "OK"]
    print(f"\nTOTAL: {tot_c} de {tot_u} filas del origen conciliadas ({pct_g:.4f} %) · llaves sin conciliar {tot_s} · "
          f"destino sin origen {tot_d} · grupos a revisar {len(revisar)} de {len(filas)}")

    cab = list(filas[0].keys()) if filas else []
    with open(os.path.join(carpeta, "reconciliacion.csv"), "w", encoding="utf-8-sig", newline="") as f:
        w = csv.DictWriter(f, fieldnames=cab, delimiter=";")
        w.writeheader()
        w.writerows(filas)
    with open(os.path.join(carpeta, "justificaciones.csv"), "w", encoding="utf-8-sig", newline="") as f:
        w = csv.writer(f, delimiter=";")
        w.writerow(["Paso", "Regla", "LlavesExcluidas"])
        w.writerows(just)
    with open(os.path.join(carpeta, "consultas.sql"), "w", encoding="utf-8", newline="\n") as f:
        f.write("USE ADN_Unificado;\nGO\n" + "\nGO\n".join(consultas) + "\nGO\n")

    def n(x):
        return "" if x is None else f"{x:,}".replace(",", ".")
    md = [f"# Reconciliación origen-destino · ADN_Unificado", "",
          f"Ejecución: {ahora.strftime('%d/%m/%Y %H:%M')} (hora de Costa Rica) · entorno {ev.get('Marca ctl.Entorno', '')}", "",
          f"**Resultado global: {n(tot_c)} de {n(tot_u)} filas del origen conciliadas ({pct_g:.2f} %).** "
          f"Llaves sin conciliar: {n(tot_s)}. Llaves del modelo sin origen: {n(tot_d)}. "
          f"Grupos bajo el umbral de {UMBRAL:.0f} %: {len(revisar)} de {len(filas)}.", "",
          "Conciliada = la llave del registro de origen está cargada en el modelo, o excluida con su regla en `ctl.Descarte`. "
          "Las consultas están en `consultas.sql` (una por tabla de origen) y versionadas en "
          "`sql/20_validacion/reconciliacion_origen_destino.sql`.", "",
          "| Paso | Origen | Filas origen | Fuera de alcance | Universo | Repetidas | Cargadas | Excluidas | Sin conciliar | Destino sin origen | % conciliado | Estado |",
          "|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|"]
    for f_ in filas:
        md.append(f"| {f_['Paso']} | {f_['Origen']} | {n(f_['FilasOrigen'])} | {n(f_['FueraDeAlcance'])} | {n(f_['FilasUniverso'])} | "
                  f"{n(f_['Repetidas'])} | {n(f_['Cargadas'])} | {n(f_['Excluidas'])} | {n(f_['SinConciliar'])} | "
                  f"{n(f_['DestinoSinOrigen'])} | {f_['PctConciliado']:.2f} | {f_['Estado']} |")
    filtros = [f_ for f_ in filas if f_["Filtro"] and f_["FueraDeAlcance"]]
    if filtros:
        md += ["", "## Fuera de alcance: filtros documentados de cada paso", "", "| Paso | Filas | Filtro | Motivo |", "|---|---:|---|---|"]
        for f_ in filtros:
            md.append(f"| {f_['Paso']} | {n(f_['FueraDeAlcance'])} | `{f_['Filtro'][:200]}` | {f_['Nota']} |")
    md += ["", "## Exclusiones por regla", "", "Detalle por paso en `justificaciones.csv`.", "", "| Regla | Llaves excluidas |", "|---|---:|"]
    por_regla = {}
    for _, r, c in just:
        por_regla[r] = por_regla.get(r, 0) + c
    for r, c in sorted(por_regla.items(), key=lambda x: -x[1]):
        md.append(f"| {r} | {n(c)} |")
    md += ["", f"Pendientes (llaves técnicas, hasta 2.000 por grupo) en `ctl.ReconciliacionPendiente` del sandbox, ejecución "
               f"{ahora.isoformat()}. Este reporte solo contiene conteos."]
    with open(os.path.join(carpeta, "reconciliacion.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(md) + "\n")
    print("Carpeta:", os.path.relpath(carpeta, runner.RAIZ))
    for x in sorted(os.listdir(carpeta)):
        print("  ", x)
