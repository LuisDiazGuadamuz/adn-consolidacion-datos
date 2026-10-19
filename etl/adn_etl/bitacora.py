# -*- coding: utf-8 -*-
"""Bitácora técnica de ejecución del ETL (Sprint 3).

Resume, desde los objetos de control del modelo (ctl.Lote, ctl.Bitacora, ctl.Descarte, ctl.Anomalia), qué se ejecutó,
cuándo, con qué resultado y qué evidencia de verificación existe. Genera en reportes/bitacora_<fecha>/:
  - bitacora_ejecucion.md      documento legible (para el informe y para José)
  - lotes.csv                  historial completo de lotes (una fila por lote)
  - estado_por_paso.csv        último lote confirmado de cada paso y filas actuales de su tabla
  - descartes.csv              filas excluidas por paso y regla (llaves distintas)
  - anomalias_vigentes.csv     anomalías del último lote confirmado de cada paso, por regla y columna
Solo contiene conteos, fechas y nombres técnicos: ningún dato de clientes.
"""
import csv
import glob
import os
import re

from . import bd, registro, runner

_EST = ("Exitoso", "Simulado", "Revertido", "Fallido", "EnCurso")


def _n(x):
    return f"{int(x):,}".replace(",", ".") if x is not None else ""


def _csv(ruta, cab, filas):
    with open(ruta, "w", encoding="utf-8-sig", newline="") as f:
        w = csv.writer(f, delimiter=";")
        w.writerow(cab)
        for r in filas:
            w.writerow(["" if v is None else v for v in r])


def _md_tabla(cab, filas, alin=None):
    alin = alin or ["---"] * len(cab)
    out = ["| " + " | ".join(cab) + " |", "|" + "|".join(alin) + "|"]
    out += ["| " + " | ".join("" if v is None else str(v) for v in r) + " |" for r in filas]
    return out


def _mensaje_seguro(m):
    """Solo el código y el tipo de error: los mensajes de SQL Server pueden incluir valores de la fila."""
    if not m:
        return ""
    c = re.search(r"\((\d{3,5}),", m)
    tipo = re.search(r"(The \w+ statement conflicted with the [A-Z ]+constraint|Invalid column name|Cannot insert duplicate key|"
                      r"Violation of [A-Z ]+ constraint|Interrumpido[^.]*|Arithmetic overflow|Conversion failed|"
                      r"unexpected EOF|Error de [^.]*)", m)
    return " ".join(x for x in [f"error {c.group(1)}" if c else "", tipo.group(1) if tipo else m[:60]] if x)


def generar(cfg):
    conn = bd.conectar(cfg, autocommit=True)
    try:
        ev = runner.evidencia_entorno(cfg, conn)
        cur = conn.cursor()
        ts = runner._ahora()
        carpeta = os.path.join(runner.DIR_REPORTES, f"bitacora_{ts}")
        os.makedirs(carpeta, exist_ok=True)
        pasos = registro.todos()
        orden = {p.nombre: p for p in pasos}

        # ---- historial de lotes
        cur.execute("""SELECT l.LoteId, l.Paso, l.Modo, l.Estado, CONVERT(varchar(19), l.FechaInicio, 120),
                              CONVERT(varchar(19), l.FechaFin, 120), DATEDIFF(SECOND, l.FechaInicio, l.FechaFin),
                              l.FilasLeidas, l.FilasCargadas, l.FilasActualizadas, l.FilasSinCambio, l.FilasDescartadas,
                              l.Anomalias, l.FilasExcluidas, l.LlavesSinMotivo, l.Parametros, l.ArchivoRollback, l.Mensaje
                       FROM ctl.Lote l WHERE l.Paso IS NOT NULL ORDER BY l.LoteId""")
        lotes = cur.fetchall()
        _csv(os.path.join(carpeta, "lotes.csv"),
             ["Lote", "Paso", "Modo", "Estado", "Inicio", "Fin", "Segundos", "Leidas", "Insertadas", "Actualizadas",
              "SinCambio", "Descartadas", "Anomalias", "Excluidas", "LlavesSinMotivo", "Parametros", "ArchivoRollback", "Mensaje"],
             [list(r[:17]) + [_mensaje_seguro(r[17]) if r[3] == "Fallido" else (r[17] or "")[:120]] for r in lotes])

        # ---- estado vigente por paso (último CONFIRM exitoso)
        cur.execute("""SELECT l.Paso, l.LoteId, CONVERT(varchar(16), l.FechaInicio, 120), l.FilasLeidas, l.FilasCargadas,
                              l.FilasActualizadas, l.FilasSinCambio, l.FilasExcluidas, l.LlavesSinMotivo, l.Parametros
                       FROM ctl.Lote l
                       WHERE l.LoteId IN (SELECT MAX(LoteId) FROM ctl.Lote WHERE Modo = 'CONFIRM' AND Estado = 'Exitoso' GROUP BY Paso)""")
        ultimo = {r[0]: r for r in cur.fetchall()}
        cur.execute("""SELECT Paso, COUNT_BIG(*) FROM ctl.vw_AnomaliaVigente GROUP BY Paso""")
        anom_paso = dict(cur.fetchall())
        cur.execute("""SELECT s.name + '.' + t.name, SUM(p.rows) FROM sys.tables t JOIN sys.schemas s ON s.schema_id = t.schema_id
                       JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0, 1)
                       WHERE s.name IN ('core', 'ref', 'ctl') GROUP BY s.name, t.name""")
        filas_tabla = dict(cur.fetchall())
        estado = []
        for p in pasos:
            u = ultimo.get(p.nombre)
            estado.append([p.orden, p.nombre, p.destino, f"{p.fuente[2]}.{p.fuente[3]}",
                           u[1] if u else "", u[2] if u else "", u[3] if u else "", u[4] if u else "", u[5] if u else "",
                           u[6] if u else "", u[7] if u else "", u[8] if u else "", anom_paso.get(p.nombre, 0),
                           (u[9] or "") if u else "", filas_tabla.get(p.destino, "")])
        cab_estado = ["Orden", "Paso", "TablaModelo", "Origen", "UltimoLote", "Fecha", "Leidas", "Insertadas", "Actualizadas",
                      "SinCambio", "Excluidas", "LlavesSinMotivo", "AnomaliasVigentes", "Periodo", "FilasTablaModelo"]
        _csv(os.path.join(carpeta, "estado_por_paso.csv"), cab_estado, estado)

        # ---- descartes (cada llave se registra una vez, en el primer lote exitoso que la excluyó)
        cur.execute("""SELECT l.Paso, d.ReglaId, LEFT(d.Motivo, 120), COUNT(DISTINCT d.FuenteLlave), COUNT_BIG(*)
                       FROM ctl.Descarte d JOIN ctl.Lote l ON l.LoteId = d.LoteId AND l.Estado = 'Exitoso' AND l.Modo = 'CONFIRM'
                       GROUP BY l.Paso, d.ReglaId, LEFT(d.Motivo, 120) ORDER BY l.Paso, COUNT_BIG(*) DESC""")
        desc = cur.fetchall()
        _csv(os.path.join(carpeta, "descartes.csv"), ["Paso", "Regla", "Motivo", "LlavesDistintas", "Registros"], desc)

        # ---- anomalías vigentes
        cur.execute("""SELECT a.Paso, a.ReglaId, a.Columna, LEFT(a.Detalle, 120), COUNT_BIG(*)
                       FROM ctl.vw_AnomaliaVigente a GROUP BY a.Paso, a.ReglaId, a.Columna, LEFT(a.Detalle, 120)
                       ORDER BY a.Paso, COUNT_BIG(*) DESC""")
        anom = cur.fetchall()
        _csv(os.path.join(carpeta, "anomalias_vigentes.csv"), ["Paso", "Regla", "Columna", "Detalle", "Anomalias"], anom)

        cur.execute("SELECT COUNT_BIG(*) FROM ctl.Bitacora")
        n_bit = cur.fetchone()[0]
        cur.execute("SELECT COUNT_BIG(*) FROM ctl.LinajeCampo")
        n_lin = cur.fetchone()[0]
    finally:
        conn.close()

    # ---- documento legible
    conf = [r for r in lotes if r[2] == "CONFIRM"]
    por_estado = {}
    for r in lotes:
        por_estado[(r[2] or "", r[3])] = por_estado.get((r[2] or "", r[3]), 0) + 1
    exit_ = [r for r in conf if r[3] == "Exitoso"]
    tot = lambda i: sum(int(r[i] or 0) for r in exit_)
    sin_motivo = [r for r in lotes if r[14] not in (None, 0)]
    md = [f"# Bitácora técnica de ejecución del ETL · ADN_Unificado",
          "",
          f"Generada: {ts[:4]}-{ts[4:6]}-{ts[6:8]} {ts[9:11]}:{ts[11:13]} · desde los objetos de control del modelo "
          "(ctl.Lote, ctl.Bitacora, ctl.Descarte, ctl.Anomalia). Solo conteos y nombres técnicos; ningún dato de clientes.",
          "",
          "## 1. Entorno verificado",
          ""] + [f"- **{k}:** {v}" for k, v in ev.items() if k in ("ETL_ENTORNO", "Base", "Servidor SQL", "Versión SQL", "Marca ctl.Entorno")] + [
          "",
          "## 2. Resumen",
          "",
          f"- Lotes registrados: **{_n(len(lotes))}** (del {lotes[0][0]} al {lotes[-1][0]}; primer lote {lotes[0][4]}, último {lotes[-1][4]})." if lotes else "- Sin lotes.",
          f"- Confirmaciones exitosas: **{_n(len(exit_))}** · filas insertadas {_n(tot(8))} · actualizadas {_n(tot(9))} · "
          f"descartadas {_n(tot(11))} · anomalías registradas {_n(tot(12))}.",
          f"- Registros en la bitácora por registro (ctl.Bitacora): **{_n(n_bit)}** · linaje por campo (ctl.LinajeCampo): **{_n(n_lin)}**.",
          f"- Lotes con llaves excluidas sin motivo (conciliación): **{len(sin_motivo)}**.",
          ""]
    md += _md_tabla(["Modo", "Estado", "Lotes"],
                    [[m, e, _n(c)] for (m, e), c in sorted(por_estado.items())], ["---", "---", "---:"])
    md += ["",
           "Notas de lectura:",
           "- **DRYRUN / Simulado:** ensayo completo que se revierte; queda constancia sin datos.",
           "- **CONFIRM / Exitoso:** cambios aplicados, con archivo de rollback en `rollback/`.",
           "- **Revertido:** lote deshecho con su archivo de rollback.",
           "- **Fallido:** error durante la corrida; la transacción se deshizo y no dejó datos.",
           "- Los saltos de ~1000 en el número de lote se deben a la caché de IDENTITY de SQL Server al reiniciarse.",
           "",
           "## 3. Estado vigente por paso",
           "",
           "Último lote confirmado de cada paso. *Excluidas* = leídas − válidas (descartes y repetidas); "
           "*Sin motivo* debe ser 0. Los pasos de llamadas y ubicaciones se cargan por período (columna *Período*).",
           ""]
    filas_md = []
    for e in estado:
        per = ""
        if e[13]:
            m = re.findall(r'"(\d{4}-\d{2}-\d{2})"', e[13])
            per = " a ".join(m) if m else ""
        filas_md.append([e[0], e[1], e[2], e[4] or "—", e[5] or "", _n(e[6]) if e[6] != "" else "", _n(e[7]) if e[7] != "" else "",
                         _n(e[8]) if e[8] != "" else "", _n(e[9]) if e[9] != "" else "", _n(e[10]) if e[10] not in ("", None) else "",
                         "" if e[11] in ("", None) else e[11], _n(e[12]), per, _n(e[14]) if e[14] != "" else ""])
    md += _md_tabla(["Orden", "Paso", "Tabla", "Lote", "Fecha", "Leídas", "Ins.", "Act.", "Sin cambio", "Excluidas",
                     "Sin motivo", "Anomalías", "Período", "Filas en tabla"],
                    filas_md, ["---:", "---", "---", "---:", "---", "---:", "---:", "---:", "---:", "---:", "---:", "---:", "---", "---:"])

    # descartes: top por paso
    md += ["", "## 4. Filas excluidas por regla", "",
           "Cada llave excluida se registra una vez, en el primer lote exitoso que la excluyó (detalle completo en `descartes.csv`).", ""]
    agg = {}
    for paso, regla, motivo, llaves, n in desc:
        agg.setdefault(regla, [0, 0])
        agg[regla][0] += int(n)
        agg[regla][1] += 1
    md += _md_tabla(["Regla", "Filas excluidas", "Pasos"], [[r, _n(v[0]), v[1]] for r, v in sorted(agg.items())], ["---", "---:", "---:"])
    md += [""]
    md += _md_tabla(["Paso", "Regla", "Motivo", "Filas"], [[p, r, m, _n(n)] for p, r, m, _, n in sorted(desc, key=lambda x: -int(x[4]))[:25]],
                    ["---", "---", "---", "---:"])

    md += ["", "## 5. Anomalías vigentes", "",
           "Anomalías del último lote confirmado de cada paso (se evalúan sobre todas las filas válidas en cada corrida). "
           "Detalle en `anomalias_vigentes.csv`.", ""]
    aggr = {}
    for paso, regla, col, det, n in anom:
        aggr[regla] = aggr.get(regla, 0) + int(n)
    md += _md_tabla(["Regla", "Anomalías"], [[r, _n(v)] for r, v in sorted(aggr.items())], ["---", "---:"])
    md += [""]
    md += _md_tabla(["Paso", "Regla", "Columna", "Detalle", "Anomalías"],
                    [[p, r, c, d, _n(n)] for p, r, c, d, n in sorted(anom, key=lambda x: -int(x[4]))[:25]],
                    ["---", "---", "---", "---", "---:"])

    rev = [r for r in lotes if r[3] == "Revertido"]
    fal = [r for r in lotes if r[3] == "Fallido"]
    md += ["", "## 6. Rollbacks", ""]
    md += _md_tabla(["Lote", "Paso", "Fecha del lote", "Insertadas", "Actualizadas", "Detalle"],
                    [[r[0], r[1], r[4], _n(r[8]), _n(r[9]), (r[17] or "")[:80]] for r in rev],
                    ["---:", "---", "---", "---:", "---:", "---"]) if rev else ["Ningún lote revertido."]
    md += ["", "## 7. Lotes fallidos", "",
           "La transacción se deshizo en todos los casos; se muestra solo el código y el tipo de error.", ""]
    md += _md_tabla(["Lote", "Paso", "Fecha", "Error"], [[r[0], r[1], r[4], _mensaje_seguro(r[17])] for r in fal],
                    ["---:", "---", "---", "---"]) if fal else ["Ningún lote fallido."]

    # evidencia en reportes/
    md += ["", "## 8. Evidencia de verificación (archivos en `reportes/`)", ""]
    ev_arch = []
    for patron, tipo in [("*_muestreo_trazabilidad.txt", "Muestreo de trazabilidad"), ("*_reproducibilidad_*.txt", "Comparación de instantáneas"),
                         ("*_instantanea_*.txt", "Instantánea"), ("*_verificacion_entorno.txt", "Verificación de entorno")]:
        for a in sorted(glob.glob(os.path.join(runner.DIR_REPORTES, patron)))[-5:]:
            ev_arch.append([tipo, os.path.basename(a)])
    md += _md_tabla(["Tipo", "Archivo"], ev_arch) if ev_arch else ["Sin archivos de evidencia en reportes/."]
    md += ["", "Pruebas de funciones de limpieza: `sql/90_verificacion/pruebas_funciones.sql` (salida guardada aparte).", ""]

    ruta = os.path.join(carpeta, "bitacora_ejecucion.md")
    with open(ruta, "w", encoding="utf-8") as f:
        f.write("\n".join(md) + "\n")
    print(f"Bitácora generada: {len(lotes)} lotes, {len(exit_)} confirmaciones exitosas, {len(rev)} revertidos, {len(fal)} fallidos.")
    print("Carpeta:", os.path.relpath(carpeta, runner.RAIZ))
    for a in sorted(os.listdir(carpeta)):
        print("  ", a)
    return carpeta
