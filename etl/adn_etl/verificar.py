# -*- coding: utf-8 -*-
"""Verificaciones del DoD del Sprint 3: reproducibilidad y trazabilidad por muestreo."""
import json
import os

from . import bd, modelo, registro, runner

DIR_SNAP = os.path.join(runner.DIR_REPORTES, "instantaneas")
EXCLUIR = {"LoteId", "FechaCarga", "PeriodoDato"}


def _tablas():
    return [t for t in modelo.T if t["linaje"]]


def instantanea(cfg, nombre):
    """Huella de contenido de cada tabla del modelo, sin columnas propias de cada ejecución (LoteId, FechaCarga)."""
    conn = bd.conectar(cfg, autocommit=True)
    try:
        ev = runner.evidencia_entorno(cfg, conn)
        cur = conn.cursor()
        res = {}
        for t in _tablas():
            full = f"{t['schema']}.{t['name']}"
            cols = [c["name"] for c in t["cols"] + modelo.LINAJE if c["name"] not in EXCLUIR and c["type"] != "computed"]
            expr = ", ".join(f"[{c}]" for c in cols)
            cur.execute(f"SELECT COUNT_BIG(*), ISNULL(CHECKSUM_AGG(BINARY_CHECKSUM({expr})), 0) FROM {full}")
            n, h = cur.fetchone()
            res[full] = [int(n), int(h)]
        os.makedirs(DIR_SNAP, exist_ok=True)
        with open(os.path.join(DIR_SNAP, f"{nombre}.json"), "w", encoding="utf-8") as f:
            json.dump(res, f, indent=1, ensure_ascii=False)
        total = sum(v[0] for v in res.values())
        print(f"Instantánea '{nombre}': {len(res)} tablas, {total} filas.")
        runner.reporte(f"instantanea_{nombre}", ["Entorno verificado:"] + [f"  {k}: {v}" for k, v in ev.items()] +
                       [""] + [f"{k}: filas={v[0]} huella={v[1]}" for k, v in res.items() if v[0]])
    finally:
        conn.close()


def comparar(a, b):
    with open(os.path.join(DIR_SNAP, f"{a}.json"), encoding="utf-8") as f:
        A = json.load(f)
    with open(os.path.join(DIR_SNAP, f"{b}.json"), encoding="utf-8") as f:
        B = json.load(f)
    difs = [k for k in sorted(set(A) | set(B)) if A.get(k) != B.get(k)]
    lineas = [f"Comparación de instantáneas '{a}' y '{b}'", f"  Tablas comparadas: {len(set(A) | set(B))}",
              f"  Tablas con diferencias: {len(difs)}"]
    lineas += [f"    {k}: {A.get(k)} → {B.get(k)}" for k in difs]
    lineas.append("  RESULTADO: " + ("IDÉNTICAS (reproducible)" if not difs else "DIFERENTES"))
    print("\n".join(lineas))
    runner.reporte(f"reproducibilidad_{a}_vs_{b}", lineas)
    return not difs


def muestreo(cfg, n=10):
    """Para una muestra de filas de cada paso, comprueba que la fila de origen existe (FuenteBase.FuenteTabla
    con la llave FuenteLlave) y muestra el período del dato."""
    conn = bd.conectar(cfg, autocommit=True)
    try:
        ev = runner.evidencia_entorno(cfg, conn)
        cur = conn.cursor()
        lineas = []
        ok_total = tot = 0
        for p in registro.todos():
            if not p.llave_origen or p.solo_actualizar or p.fuente[1] != "SQLServer":
                continue
            base, tabla = p.fuente[2], p.fuente[3]
            cur.execute(f"""SELECT TOP ({int(n)}) FuenteBase, FuenteTabla, FuenteLlave, PeriodoDato
                            FROM {p.destino} WHERE FuenteBase = %s AND FuenteTabla = %s
                            ORDER BY CHECKSUM(FuenteLlave), FuenteLlave""", (base, tabla))
            muestra = cur.fetchall()
            ok = 0
            for fb, ft, fl, per in muestra:
                cur.execute(f"SELECT COUNT_BIG(*) FROM [{fb}].dbo.[{ft}] WHERE ctl.fn_Texto(CAST([{p.llave_origen}] AS nvarchar(200))) = %s", (fl,))
                ok += 1 if cur.fetchone()[0] > 0 else 0
            ok_total += ok
            tot += len(muestra)
            lineas.append(f"{p.nombre}: {ok}/{len(muestra)} filas encontradas en {base}.{tabla} por FuenteLlave"
                          + (f" · períodos {sorted({m[3] for m in muestra if m[3]})[:3]}" if muestra else ""))
        lineas.append(f"TOTAL: {ok_total}/{tot} filas de muestra trazadas hasta su origen")
        print("\n".join(lineas))
        runner.reporte("muestreo_trazabilidad", ["Entorno verificado:"] + [f"  {k}: {v}" for k, v in ev.items()] + [""] + lineas)
    finally:
        conn.close()
