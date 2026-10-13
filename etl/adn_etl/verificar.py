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


def _traza(p):
    """(from completo, expresión de la llave, primera línea del from, columna simple) para recalcular FuenteLlave."""
    if p.traza_llave:
        desde = p.traza_from
        return desde, p.traza_llave, desde.split("\n")[0], p.traza_columna
    if p.llave_origen:
        base, tabla = p.fuente[2], p.fuente[3]
        desde = f"[{base}].dbo.[{tabla}] x"
        return desde, f"ctl.fn_Texto(CAST(x.[{p.llave_origen}] AS nvarchar(200)))", desde, f"x.[{p.llave_origen}]"
    return None


def _en_origen(cur, muestra, tz):
    """Cuántas llaves de la muestra existen en el origen. Primero búsqueda directa por la columna llave (usa índice);
    las que no aparecen (huellas, llaves con limpieza) se recalculan con la expresión completa en un solo recorrido."""
    desde, llave, primera, col = tz
    faltan = []
    for fl in muestra:
        hallado = False
        if col:
            try:
                cur.execute(f"SELECT TOP 1 1 FROM {primera} WHERE {col} = %s", (fl,))
                hallado = cur.fetchone() is not None
            except Exception:
                hallado = False
        if not hallado:
            faltan.append(fl)
    ok = len(muestra) - len(faltan)
    if faltan:
        cur.execute("IF OBJECT_ID('tempdb..#k') IS NOT NULL DROP TABLE #k; "
                    "CREATE TABLE #k (k nvarchar(200) COLLATE DATABASE_DEFAULT PRIMARY KEY);")
        for fl in set(faltan):
            cur.execute("INSERT #k VALUES (%s)", (fl,))
        cur.execute(f"""DECLARE @Desde date = NULL, @Hasta date = NULL;
                        SELECT COUNT(DISTINCT k.k) FROM (SELECT {llave} AS v FROM {desde}) x
                        JOIN #k k ON k.k = x.v COLLATE DATABASE_DEFAULT""")
        ok += cur.fetchone()[0]
    return ok


def muestreo(cfg, n=10, solo=None):
    """Trazabilidad por muestreo (DoD). Para una muestra determinista de filas de cada paso (y de cada tabla de
    origen en las tablas consolidadas) comprueba:
    1) origen: la fila existe en FuenteBase.FuenteTabla recalculando FuenteLlave (llave simple, compuesta o huella);
    2) lote: la fila apunta a un lote CONFIRM exitoso y la bitácora registra el alta o el cambio de ese registro;
    3) período: la fila trae FechaDato (período del dato).
    Solo imprime conteos (sin datos de clientes)."""
    conn = bd.conectar(cfg, autocommit=True)
    try:
        ev = runner.evidencia_entorno(cfg, conn)
        cur = conn.cursor()
        pasos = registro.todos()
        trazas = {}                               # (base, tabla de origen) → cómo recalcular su llave
        for p in pasos:
            tz = _traza(p)
            if tz and not p.solo_actualizar:
                trazas.setdefault((p.fuente[2], p.linaje_tabla or p.fuente[3]), tz)
        lineas, filas_csv = [], ["Paso;TablaModelo;Origen;Muestra;EnOrigen;LoteYBitacora;ConPeriodo;Periodos;Nota"]
        tot = {"m": 0, "o": 0, "om": 0, "l": 0, "f": 0}

        def grupo(nombre, destino, pk, base, tabla, tz, nota=""):
            cur.execute(f"""SELECT TOP ({int(n)}) t.[{pk}], t.FuenteLlave, CONVERT(char(7), t.FechaDato, 126)
                            FROM {destino} t WHERE t.FuenteBase = %s AND t.FuenteTabla = %s
                            ORDER BY CHECKSUM(t.FuenteLlave), t.FuenteLlave""", (base, tabla))
            muestra = cur.fetchall()
            if not muestra:
                lineas.append(f"{nombre:32s} sin filas cargadas desde {base}.{tabla}")
                filas_csv.append(";".join([nombre, destino, f"{base}.{tabla}", "0", "", "", "", "", "sin filas cargadas"]))
                return
            ids = ",".join(str(int(r[0])) for r in muestra)
            cur.execute(f"""SELECT COUNT(*) FROM {destino} t
                            JOIN ctl.Lote l ON l.LoteId = t.LoteId AND l.Modo = 'CONFIRM' AND l.Estado = 'Exitoso'
                            WHERE t.[{pk}] IN ({ids}) AND EXISTS (SELECT 1 FROM ctl.Bitacora b WHERE b.LoteId = t.LoteId
                                  AND b.TablaModelo = N'{destino}' AND b.RegistroId = t.[{pk}])""")
            lb = cur.fetchone()[0]
            con_per = sum(1 for r in muestra if r[2])
            periodos = sorted({r[2] for r in muestra if r[2]})
            if tz == "cedula":                    # cliente consolidado por cédula: se traza por sus orígenes
                cur.execute(f"SELECT COUNT(DISTINCT o.ClienteId) FROM core.ClienteOrigen o WHERE o.ClienteId IN ({ids})")
                en_origen = cur.fetchone()[0]
                nota = nota or "cliente consolidado por cédula: trazado por core.ClienteOrigen"
            elif tz is None:
                en_origen = None
                nota = nota or "sin regla de traza para esta tabla de origen"
            else:
                en_origen = _en_origen(cur, [r[1] for r in muestra], tz)
            m = len(muestra)
            tot["m"] += m
            tot["l"] += lb
            tot["f"] += con_per
            if en_origen is not None:
                tot["o"] += en_origen
                tot["om"] += m
            txt_o = f"{en_origen}/{m}" if en_origen is not None else "n/a"
            lineas.append(f"{nombre:32s} origen {txt_o:>6} · lote+bitácora {lb}/{m} · período {con_per}/{m}"
                          + (f" {periodos[0]}…{periodos[-1]}" if periodos else "") + (f"  ({nota})" if nota else ""))
            filas_csv.append(";".join(map(str, [nombre, destino, f"{base}.{tabla}", m, txt_o, lb, con_per,
                                                 f"{periodos[0]}..{periodos[-1]}" if periodos else "", nota])))

        vistos = set()
        for p in pasos:
            if (solo and p.nombre != solo) or p.solo_actualizar:
                continue                          # los pasos de solo actualización tocan filas que ya trazó otro paso
            if p.destino in ("core.Cliente", "core.ClienteOrigen"):
                if p.destino in vistos:
                    continue
                vistos.add(p.destino)
                cur.execute(f"SELECT DISTINCT FuenteBase, FuenteTabla FROM {p.destino} ORDER BY 1, 2")
                for base, tabla in cur.fetchall():
                    tz = "cedula" if tabla == "Cedula" else trazas.get((base, tabla))
                    grupo(f"{p.nombre}[{tabla}]", p.destino, p.pk, base, tabla, tz)
                continue
            base, tabla = p.fuente[2], p.linaje_tabla or p.fuente[3]
            if (p.destino, base, tabla) in vistos:
                continue
            vistos.add((p.destino, base, tabla))
            nota = "trazado contra la copia stg.mongo_* (copia de solo lectura de MongoDB)" if p.fuente[1] == "MongoDB" else ""
            grupo(p.nombre, p.destino, p.pk, base, tabla, _traza(p), nota)

        lineas.append(f"TOTAL: origen {tot['o']}/{tot['om']} · lote+bitácora {tot['l']}/{tot['m']} · período {tot['f']}/{tot['m']}")
        print("\n".join(lineas))
        ruta = runner.reporte("muestreo_trazabilidad", ["Entorno verificado:"] + [f"  {k}: {v}" for k, v in ev.items()] + [""] + lineas)
        with open(os.path.splitext(ruta)[0] + ".csv", "w", encoding="utf-8-sig") as f:
            f.write("\n".join(filas_csv) + "\n")
        print("Reporte:", os.path.relpath(ruta, runner.RAIZ))
    finally:
        conn.close()
