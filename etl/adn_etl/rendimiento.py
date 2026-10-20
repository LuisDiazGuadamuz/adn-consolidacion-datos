# -*- coding: utf-8 -*-
"""Rendimiento de las cargas (Sprint 4), medido desde ctl.Lote (inicio y fin de cada lote). Solo conteos y tiempos.

  - Por paso: duración y filas por segundo de la última carga confirmada y del último ensayo (dry-run) exitosos.
  - Corrida completa: suma de los últimos lotes de cada paso que no exige período (lo que tarda ./etl.ps1 ejecutar --todos).
  - Pasos por período (llamadas, ubicaciones): tiempo por mes cargado y proyección a 24 meses (D7).
  - Validación: duración de la última reconciliación (ctl.Reconciliacion).
Umbrales propuestos (a confirmar con José Hernández): corrida completa ≤ 2 h; un mes de llamadas ≤ 15 min por fuente.
"""
import csv
import datetime as dt
import os

from . import bd, registro, runner

UMBRAL_COMPLETA_MIN = 120
UMBRAL_MES_LLAMADAS_MIN = 15


def _ultimo(cur, paso, modo):
    """Último lote CONFIRM exitoso, o último ensayo con duración medida (los ensayos anteriores al Sprint 4 solo
    registraban el cierre, no el inicio)."""
    if modo == "CONFIRM":
        cond = "Modo = 'CONFIRM' AND Estado = 'Exitoso'"
    else:
        cond = "Modo = 'DRYRUN' AND Estado = 'Simulado' AND Mensaje LIKE N'%%Duración medida%%'"
    r = bd.filas(cur, f"""SELECT TOP 1 LoteId, DATEDIFF(second, FechaInicio, FechaFin), FilasLeidas, Parametros
                          FROM ctl.Lote WHERE Paso = %s AND {cond} AND FechaFin IS NOT NULL
                          ORDER BY LoteId DESC""", (paso,))
    return r[0] if r else None


def ejecutar(cfg):
    ahora = dt.datetime.now(dt.timezone(dt.timedelta(hours=-6))).replace(microsecond=0)
    carpeta = os.path.join(runner.DIR_REPORTES, f"rendimiento_{ahora.strftime('%Y%m%d_%H%M%S')}")
    os.makedirs(carpeta, exist_ok=True)
    conn = bd.conectar(cfg, autocommit=True)
    filas, periodo = [], []
    try:
        ev = runner.evidencia_entorno(cfg, conn)
        cur = conn.cursor()
        for p in registro.todos():
            c = _ultimo(cur, p.nombre, "CONFIRM")
            d = _ultimo(cur, p.nombre, "DRYRUN")

            def tasa(x):
                return None if not x or not x[1] else round((x[2] or 0) / x[1], 0)
            filas.append(dict(Orden=p.orden, Paso=p.nombre, PorPeriodo="sí" if p.requiere_periodo else "no",
                              LoteConfirm=c[0] if c else None, SegConfirm=c[1] if c else None, FilasConfirm=c[2] if c else None,
                              FilasPorSegConfirm=tasa(c), LoteDryRun=d[0] if d else None, SegDryRun=d[1] if d else None,
                              FilasDryRun=d[2] if d else None, FilasPorSegDryRun=tasa(d)))
            if p.requiere_periodo:
                for r in bd.filas(cur, """SELECT LoteId, DATEDIFF(second, FechaInicio, FechaFin), FilasLeidas, Parametros
                                          FROM ctl.Lote WHERE Paso = %s AND Modo = 'CONFIRM' AND Estado = 'Exitoso'
                                            AND FechaFin IS NOT NULL ORDER BY LoteId""", (p.nombre,)):
                    periodo.append(dict(Paso=p.nombre, Lote=r[0], Segundos=r[1], Filas=r[2], Parametros=r[3] or ""))
        rec = bd.filas(cur, """SELECT TOP 1 Ejecucion, SUM(Segundos) OVER (PARTITION BY Ejecucion), COUNT(*) OVER (PARTITION BY Ejecucion)
                               FROM ctl.Reconciliacion ORDER BY Ejecucion DESC""")
    finally:
        conn.close()

    sin_per = [f for f in filas if f["PorPeriodo"] == "no"]
    # En modo confirm el runner primero ensaya (dry-run, revertido) y luego carga: el tiempo real de una corrida es la
    # suma de las dos fases. Si un paso no tiene ensayo con duración medida se estima igual a su carga.
    def real(f):
        return (f["SegConfirm"] or 0) + (f["SegDryRun"] if f["SegDryRun"] is not None else (f["SegConfirm"] or 0))
    estimados = [f["Paso"] for f in filas if f["SegDryRun"] is None and f["SegConfirm"]]
    t_conf = sum(f["SegConfirm"] or 0 for f in sin_per)
    t_dry = sum(f["SegDryRun"] or 0 for f in sin_per)
    t_real = sum(real(f) for f in sin_per)
    lent = sorted(sin_per, key=lambda f: -real(f))[:10]
    llam = [f for f in filas if f["Paso"].startswith("core_Llamada") and f["SegConfirm"]]
    peor_mes = max((real(f) for f in llam), default=0)
    prom_mes = (sum(real(f) for f in llam) / len(llam)) if llam else 0
    proy_24 = prom_mes * 24
    ok_comp = t_real / 60 <= UMBRAL_COMPLETA_MIN
    ok_mes = peor_mes / 60 <= UMBRAL_MES_LLAMADAS_MIN
    print(f"Corrida completa en modo confirm ({len(sin_per)} pasos sin período): {t_real/60:.1f} min "
          f"= ensayo {t_dry/60:.1f} + carga {t_conf/60:.1f} (umbral propuesto {UMBRAL_COMPLETA_MIN} min) → "
          f"{'CUMPLE' if ok_comp else 'NO CUMPLE'}")
    print(f"Llamadas (ensayo + carga): peor mes {peor_mes/60:.1f} min, promedio {prom_mes/60:.1f} min por fuente y mes "
          f"(umbral propuesto {UMBRAL_MES_LLAMADAS_MIN} min) → {'CUMPLE' if ok_mes else 'NO CUMPLE'}; 24 meses ≈ {proy_24/3600:.1f} h")
    if estimados:
        print("Ensayo estimado igual a la carga (sin duración medida): " + ", ".join(estimados))
    if rec:
        print(f"Última reconciliación: {rec[0][2]} grupos en {float(rec[0][1] or 0)/60:.1f} min")
    print("10 pasos más lentos (ensayo + carga):")
    for f in lent:
        print(f"  {f['Paso']:34s} {real(f):>6} s  {f['FilasConfirm'] or 0:>9} filas  {f['FilasPorSegConfirm'] or 0:>8} filas/s en la carga")

    cab = list(filas[0].keys())
    with open(os.path.join(carpeta, "rendimiento_por_paso.csv"), "w", encoding="utf-8-sig", newline="") as f:
        w = csv.DictWriter(f, fieldnames=cab, delimiter=";")
        w.writeheader()
        w.writerows(filas)
    if periodo:
        with open(os.path.join(carpeta, "rendimiento_por_periodo.csv"), "w", encoding="utf-8-sig", newline="") as f:
            w = csv.DictWriter(f, fieldnames=list(periodo[0].keys()), delimiter=";")
            w.writeheader()
            w.writerows(periodo)

    def n(x):
        return "" if x is None else f"{x:,.0f}".replace(",", ".")
    md = ["# Rendimiento de las cargas · ADN_Unificado", "",
          f"Ejecución: {ahora.strftime('%d/%m/%Y %H:%M')} (hora de Costa Rica) · entorno {ev.get('Marca ctl.Entorno', '')} "
          f"(Docker con 6 GB de memoria para SQL Server).", "",
          "| Prueba | Medición | Umbral propuesto | Resultado |", "|---|---|---|---|",
          f"| R-1 Corrida completa en modo confirm ({len(sin_per)} pasos sin período; ensayo + carga) | {t_real/60:.1f} min | ≤ {UMBRAL_COMPLETA_MIN} min | {'CUMPLE' if ok_comp else 'NO CUMPLE'} |",
          f"| R-2 Fase de ensayo / fase de carga | {t_dry/60:.1f} min / {t_conf/60:.1f} min | informativo | |",
          f"| R-3 Un mes de llamadas por fuente, ensayo + carga (peor caso) | {peor_mes/60:.1f} min | ≤ {UMBRAL_MES_LLAMADAS_MIN} min | {'CUMPLE' if ok_mes else 'NO CUMPLE'} |",
          f"| R-4 Proyección de 24 meses de llamadas (D7) | {proy_24/3600:.1f} h | informativo | |"]
    if rec:
        md.append(f"| R-5 Reconciliación completa | {float(rec[0][1] or 0)/60:.1f} min ({rec[0][2]} tablas de origen) | informativo | |")
    md += ["", "Los umbrales son una propuesta para una ventana nocturna de mantenimiento; deben confirmarse con José Hernández.", "",
           "En modo confirm cada paso se ensaya primero (dry-run revertido) y luego se carga; por eso el tiempo real es la suma "
           "de las dos fases." + (f" Ensayo estimado igual a la carga en: {', '.join(estimados)}." if estimados else ""), "",
           "## Pasos más lentos (ensayo + carga)", "", "| Paso | Segundos | Filas leídas | Filas/s en la carga |", "|---|---:|---:|---:|"]
    md += [f"| {f['Paso']} | {n(real(f))} | {n(f['FilasConfirm'])} | {n(f['FilasPorSegConfirm'])} |" for f in lent]
    md += ["", "Detalle de los " + str(len(filas)) + " pasos en `rendimiento_por_paso.csv`; cargas por período en `rendimiento_por_periodo.csv`."]
    with open(os.path.join(carpeta, "rendimiento.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(md) + "\n")
    print("Carpeta:", os.path.relpath(carpeta, runner.RAIZ))
