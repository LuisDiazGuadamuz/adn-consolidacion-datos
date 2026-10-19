# -*- coding: utf-8 -*-
"""Línea de comandos del ETL.

  python -m adn_etl verificar-entorno
  python -m adn_etl instalar                      # objetos de control + procedimientos de los pasos
  python -m adn_etl plan
  python -m adn_etl ejecutar --paso ref_TipoCambio --modo dry-run
  python -m adn_etl ejecutar --paso ref_TipoCambio --modo confirm
  python -m adn_etl ejecutar --todos --modo confirm --si
  python -m adn_etl rollback --lote 12 [--ensayo]
  python -m adn_etl lotes [--ultimos 20]
  python -m adn_etl instantanea --nombre corrida1
  python -m adn_etl comparar --a corrida1 --b corrida2
  python -m adn_etl muestreo [--n 10] [--paso core_Factura]
  python -m adn_etl bitacora                      # bitácora técnica de ejecución (reportes/bitacora_<fecha>/)
"""
import argparse
import glob
import os
import sys

from . import bd, config, generador, registro, runner, verificar


def _instalar(cfg):
    conn = bd.conectar(cfg, autocommit=True)
    try:
        archivos = sorted(glob.glob(os.path.join(runner.RAIZ, "sql", "01_control", "*.sql")))
        cur = conn.cursor()
        cur.execute("SELECT COUNT(*) FROM sys.tables WHERE name = 'Entorno' AND schema_id = SCHEMA_ID('ctl')")
        if cur.fetchone()[0]:
            print(runner.evidencia_entorno(cfg, conn))
        else:
            # primera instalación: la marca aún no existe; se verifica solo la configuración
            from . import seguridad
            print(seguridad.verificar_configuracion(cfg))
        # Se instalan los pasos tal como están versionados (no se regeneran aquí; para cambiarlos: 'generar' y commit)
        archivos += sorted(glob.glob(os.path.join(runner.RAIZ, "sql", "10_pasos", "*.sql")))
        for a in archivos:
            with open(a, encoding="utf-8") as f:
                bd.ejecutar_script(conn, f.read())
            print("Instalado", os.path.relpath(a, runner.RAIZ))
    finally:
        conn.close()


def main(argv=None):
    ap = argparse.ArgumentParser(prog="adn_etl", description="ETL de consolidación ADN_Unificado (solo sandbox)")
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("verificar-entorno")
    sub.add_parser("instalar")
    sub.add_parser("generar")
    sub.add_parser("plan")
    e = sub.add_parser("ejecutar")
    g = e.add_mutually_exclusive_group(required=True)
    g.add_argument("--paso")
    g.add_argument("--todos", action="store_true")
    g.add_argument("--desde-paso")
    e.add_argument("--modo", choices=["dry-run", "confirm"], required=True)
    e.add_argument("--si", action="store_true", help="no pedir confirmación (solo modo confirm)")
    e.add_argument("--desde")
    e.add_argument("--hasta")
    r = sub.add_parser("rollback")
    r.add_argument("--lote", type=int, required=True)
    r.add_argument("--ensayo", action="store_true")
    lo = sub.add_parser("lotes")
    lo.add_argument("--ultimos", type=int, default=20)
    i = sub.add_parser("instantanea")
    i.add_argument("--nombre", required=True)
    c = sub.add_parser("comparar")
    c.add_argument("--a", required=True)
    c.add_argument("--b", required=True)
    st = sub.add_parser("stage-mongo", help="copia una colección de mongo-lab a stg.* (solo lectura en MongoDB)")
    st.add_argument("--coleccion", required=True)
    st.add_argument("--desde")
    st.add_argument("--hasta")
    mc = sub.add_parser("mongo-campos", help="inventario de campos de una colección de MongoDB (solo lectura, sin valores)")
    mc.add_argument("--coleccion", required=True)
    mc.add_argument("--muestra", type=int, default=5000)
    m = sub.add_parser("muestreo")
    m.add_argument("--n", type=int, default=10)
    m.add_argument("--paso", help="solo este paso")
    sub.add_parser("bitacora", help="bitácora técnica de ejecución (md + csv) desde los objetos de control")
    a = ap.parse_args(argv)

    if a.cmd == "generar":
        for x in generador.generar():
            print(os.path.relpath(x, runner.RAIZ))
        return
    if a.cmd == "plan":
        for p in registro.todos():
            print(f"{p.orden:03d}  {p.nombre:32s} → {p.destino:28s} {p.fuente[2]}.{p.fuente[3]}")
        return
    if a.cmd == "comparar":
        sys.exit(0 if verificar.comparar(a.a, a.b) else 1)

    cfg = config.cargar()
    if a.cmd == "verificar-entorno":
        conn = bd.conectar(cfg, autocommit=True)
        try:
            ev = runner.evidencia_entorno(cfg, conn)
        finally:
            conn.close()
        lineas = ["Entorno verificado: el ETL solo puede conectarse a la copia del sandbox."] + [f"  {k}: {v}" for k, v in ev.items()]
        print("\n".join(lineas))
        print("Reporte:", os.path.relpath(runner.reporte("verificacion_entorno", lineas), runner.RAIZ))
    elif a.cmd == "instalar":
        _instalar(cfg)
    elif a.cmd == "ejecutar":
        pasos = registro.todos()
        if a.paso:
            pasos = [registro.por_nombre(a.paso)]
        elif a.desde_paso:
            n = registro.por_nombre(a.desde_paso).orden
            pasos = [p for p in pasos if p.orden >= n]
        sin_periodo = not (a.desde or a.hasta)
        if sin_periodo and a.paso and pasos[0].requiere_periodo:
            sys.exit(f"{a.paso} es una tabla grande: se carga por período. Agregue --desde AAAA-MM-DD --hasta AAAA-MM-DD "
                     "(hasta exclusivo), p. ej. un año o un mes por corrida.")
        if sin_periodo and len(pasos) > 1:
            omitidos = [p.nombre for p in pasos if p.requiere_periodo]
            if omitidos:
                print("Se omiten (se cargan aparte, por período con --paso y --desde/--hasta): " + ", ".join(omitidos))
                pasos = [p for p in pasos if not p.requiere_periodo]
        if a.modo == "dry-run" and len(pasos) > 1:
            print("Aviso: en dry-run cada paso se ensaya por separado; los pasos que dependen de otros "
                  "verán el modelo sin los cambios ensayados de los anteriores.")
        for p in pasos:
            runner.ejecutar(cfg, p, a.modo, a.desde, a.hasta, confirmar_sin_preguntar=a.si)
            print()
    elif a.cmd == "rollback":
        runner.revertir(cfg, a.lote, a.ensayo)
    elif a.cmd == "lotes":
        conn = bd.conectar(cfg, autocommit=True)
        try:
            cur = conn.cursor()
            cur.execute("""SELECT TOP (%s) LoteId, Paso, Modo, Estado, FilasLeidas, FilasCargadas, FilasActualizadas,
                                  FilasSinCambio, FilasDescartadas, Anomalias, CONVERT(varchar(19), FechaInicio, 120), ArchivoRollback,
                                  FilasExcluidas, LlavesSinMotivo
                           FROM ctl.Lote WHERE Paso IS NOT NULL ORDER BY LoteId DESC""", (a.ultimos,))
            print(f"{'Lote':>5} {'Paso':28s} {'Modo':7s} {'Estado':10s} {'Leídas':>8} {'Ins':>7} {'Act':>6} {'Igual':>7} {'Desc':>6} {'Anom':>5} {'Excl':>7} {'SinMot':>6}  Inicio")
            for r in cur.fetchall():
                sm = "" if r[13] is None else str(r[13])
                ex = "" if r[12] is None else str(r[12])
                print(f"{r[0]:>5} {r[1]:28s} {r[2] or '':7s} {r[3]:10s} {r[4] or 0:>8} {r[5] or 0:>7} {r[6] or 0:>6} {r[7] or 0:>7} {r[8] or 0:>6} {r[9] or 0:>5} {ex:>7} {sm:>6}  {r[10]}")
        finally:
            conn.close()
    elif a.cmd == "instantanea":
        verificar.instantanea(cfg, a.nombre)
    elif a.cmd == "stage-mongo":
        from . import mongo_stage
        mongo_stage.copiar(cfg, a.coleccion, a.desde, a.hasta)
    elif a.cmd == "mongo-campos":
        from . import mongo_stage
        mongo_stage.campos(cfg, a.coleccion, a.muestra)
    elif a.cmd == "bitacora":
        from . import bitacora
        bitacora.generar(cfg)
    elif a.cmd == "muestreo":
        verificar.muestreo(cfg, a.n, a.paso)


if __name__ == "__main__":
    main()
