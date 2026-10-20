# -*- coding: utf-8 -*-
"""Ejecución de pasos con el patrón dry-run / confirm / rollback."""
import datetime as dt
import json
import os

from . import bd, rollback, seguridad

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
DIR_REPORTES = os.path.join(RAIZ, "reportes")


def _ahora():
    return dt.datetime.now().strftime("%Y%m%d_%H%M%S")


def reporte(nombre, lineas):
    os.makedirs(DIR_REPORTES, exist_ok=True)
    ruta = os.path.join(DIR_REPORTES, f"{_ahora()}_{nombre}.txt")
    with open(ruta, "w", encoding="utf-8") as f:
        f.write("\n".join(lineas) + "\n")
    return ruta


def _tx(conn, orden):
    cur = conn.cursor()
    if orden == "BEGIN":
        cur.execute("BEGIN TRANSACTION")
    elif orden == "COMMIT":
        cur.execute("IF @@TRANCOUNT > 0 COMMIT TRANSACTION")
    else:
        cur.execute("IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION")


def evidencia_entorno(cfg, conn):
    ev = seguridad.verificar_configuracion(cfg)
    ev.update(seguridad.verificar_base(conn.cursor()))
    return ev


def _iniciar(cur, paso, modo, cfg, params):
    s, m, b, t = paso.fuente
    cur.execute("""SET NOCOUNT ON; DECLARE @L int;
                   EXEC ctl.usp_IniciarLote @Paso = %s, @Sistema = %s, @Motor = %s, @Base = %s, @Tabla = %s,
                        @Modo = %s, @Usuario = %s, @Parametros = %s, @LoteId = @L OUTPUT;
                   SELECT @L;""", (paso.nombre, s, m, b, t, modo, cfg.usuario, params))
    return int(cur.fetchone()[0])


def _correr(conn, cfg, paso, modo, desde, hasta):
    """Ejecuta el paso dentro de una transacción abierta. Devuelve (lote, leidas, sin_cambio, resumen)."""
    cur = conn.cursor()
    params = json.dumps({"desde": desde, "hasta": hasta}) if (desde or hasta) else None
    lote = _iniciar(cur, paso, modo, cfg, params)
    res = bd.filas(cur, f"EXEC {paso.proc} @LoteId = %s, @Desde = %s, @Hasta = %s", (lote, desde, hasta))
    leidas, sin_cambio = (int(res[-1][0]), int(res[-1][1])) if res else (0, 0)
    excl = sin_motivo = None
    if res and len(res[-1]) >= 4 and res[-1][2] is not None:
        excl, sin_motivo = int(res[-1][2]), int(res[-1][3])
    estado = "Exitoso" if modo == "CONFIRM" else "Simulado"
    cur.execute("EXEC ctl.usp_CerrarLote @LoteId = %s, @Estado = %s, @FilasLeidas = %s, @FilasSinCambio = %s",
                (lote, estado, leidas, sin_cambio))
    cur.execute("UPDATE ctl.Lote SET FilasExcluidas = %s, LlavesSinMotivo = %s WHERE LoteId = %s", (excl, sin_motivo, lote))
    resumen = [tuple(r) for r in bd.filas(cur, "EXEC ctl.usp_ResumenLote @LoteId = %s", (lote,))]
    if excl is not None:
        resumen.append(("Conciliación", "C", (excl, sin_motivo)))
    return lote, leidas, sin_cambio, resumen


def _texto_resumen(paso, modo, lote, leidas, sin_cambio, resumen):
    acc = {"I": "insertadas", "U": "actualizadas", "R": "retiradas (sin origen vigente)", "D": "descartadas", "A": "anomalías"}
    lineas = [f"Paso {paso.nombre} ({paso.destino}) · modo {modo} · lote {lote}",
              f"  Filas leídas del origen: {leidas}", f"  Filas sin cambio: {sin_cambio}"]
    for tabla, a, n in resumen:
        if a == "C":
            excl, sin_motivo = n
            lineas.append(f"  Conciliación: {leidas} leídas = {leidas - excl} válidas + {excl} excluidas; "
                          f"llaves excluidas sin motivo registrado: {sin_motivo}" + ("" if sin_motivo == 0 else "  ← REVISAR"))
            continue
        lineas.append(f"  {tabla}: {n} {acc.get(a, a)}")
    return lineas


def _hora_servidor(conn):
    cur = conn.cursor()
    cur.execute("SELECT SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')")
    return cur.fetchone()[0]


def _registrar_simulacion(conn, cfg, paso, leidas, sin_cambio, resumen, params, inicio=None):
    """El dry-run se revierte completo; aquí se deja constancia del ensayo en ctl.Lote (sin datos). FechaInicio es la
    hora en que empezó el ensayo, para medir su duración (rendimiento)."""
    cur = conn.cursor()
    lote = _iniciar(cur, paso, "DRYRUN", cfg, params)
    if inicio is not None:
        cur.execute("UPDATE ctl.Lote SET FechaInicio = %s WHERE LoteId = %s", (inicio, lote))
    cnt = {a: sum(n for _, x, n in resumen if x == a) for a in "IUDA"}
    conc = next((n for _, x, n in resumen if x == "C"), (None, None))
    cur.execute("""UPDATE ctl.Lote SET Estado = 'Simulado', FechaFin = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00'),
                   FilasLeidas = %s, FilasSinCambio = %s, FilasCargadas = %s, FilasActualizadas = %s,
                   FilasDescartadas = %s, Anomalias = %s, FilasExcluidas = %s, LlavesSinMotivo = %s,
                   Mensaje = N'Ensayo (dry-run): todos los cambios se revirtieron. Duración medida.' WHERE LoteId = %s""",
                (leidas, sin_cambio, cnt["I"], cnt["U"], cnt["D"], cnt["A"], conc[0], conc[1], lote))
    return lote


def ejecutar(cfg, paso, modo, desde=None, hasta=None, confirmar_sin_preguntar=False):
    conn = bd.conectar(cfg, autocommit=True)
    try:
        ev = evidencia_entorno(cfg, conn)
        params = json.dumps({"desde": desde, "hasta": hasta}) if (desde or hasta) else None
        # 1. Dry-run: se ejecuta exactamente lo mismo y se revierte
        inicio = _hora_servidor(conn)
        _tx(conn, "BEGIN")
        try:
            _, leidas, sin_cambio, resumen = _correr(conn, cfg, paso, "DRYRUN", desde, hasta)
        finally:
            _tx(conn, "ROLLBACK")
        lote_sim = _registrar_simulacion(conn, cfg, paso, leidas, sin_cambio, resumen, params, inicio)
        lineas = _texto_resumen(paso, "DRY-RUN", lote_sim, leidas, sin_cambio, resumen)
        print("\n".join(lineas))
        if modo == "dry-run":
            reporte(f"dryrun_{paso.nombre}", ["Entorno verificado:"] + [f"  {k}: {v}" for k, v in ev.items()] + [""] + lineas)
            return lote_sim
        # 2. Confirmación
        if not confirmar_sin_preguntar:
            r = input(f"\n¿Aplicar estos cambios en ADN_Unificado (sandbox)? Escriba CONFIRMAR: ").strip()
            if r != "CONFIRMAR":
                print("Cancelado: no se aplicó ningún cambio.")
                return None
        _tx(conn, "BEGIN")
        try:
            lote, leidas, sin_cambio, resumen = _correr(conn, cfg, paso, "CONFIRM", desde, hasta)
            _tx(conn, "COMMIT")
        except Exception as e:
            _tx(conn, "ROLLBACK")
            cur = conn.cursor()
            lf = _iniciar(cur, paso, "CONFIRM", cfg, params)
            cur.execute("EXEC ctl.usp_CerrarLote @LoteId = %s, @Estado = 'Fallido', @Mensaje = %s", (lf, str(e)[:2000]))
            raise
        # 3. Archivo de rollback del lote
        cur = conn.cursor()
        ruta = rollback.escribir(cur, lote)
        cur.execute("UPDATE ctl.Lote SET ArchivoRollback = %s WHERE LoteId = %s", (os.path.relpath(ruta, RAIZ), lote))
        lineas = _texto_resumen(paso, "CONFIRM", lote, leidas, sin_cambio, resumen) + [f"  Archivo de rollback: {os.path.relpath(ruta, RAIZ)}"]
        print("\n".join(lineas))
        reporte(f"confirm_{paso.nombre}_lote{lote}", ["Entorno verificado:"] + [f"  {k}: {v}" for k, v in ev.items()] + [""] + lineas)
        return lote
    finally:
        conn.close()


def revertir(cfg, lote_id, ensayo=False):
    conn = bd.conectar(cfg, autocommit=True)
    try:
        ev = evidencia_entorno(cfg, conn)
        cur = conn.cursor()
        cur.execute("SELECT ArchivoRollback FROM ctl.Lote WHERE LoteId = %s", (lote_id,))
        r = cur.fetchone()
        if not r or not r[0]:
            raise SystemExit(f"El lote {lote_id} no tiene archivo de rollback registrado.")
        ruta = os.path.join(RAIZ, r[0])
        with open(ruta, encoding="utf-8") as f:
            texto = f.read()
        if ensayo:
            texto = texto.replace("DECLARE @Simular bit = 0;", "DECLARE @Simular bit = 1;", 1)
        res = bd.ejecutar_script(conn, texto)
        lineas = [f"Rollback del lote {lote_id} ({'ENSAYO' if ensayo else 'CONFIRMADO'}) con {r[0]}"]
        if res:
            lote, elim, rest, quedan, resultado = res[-1]
            lineas += [f"  Filas eliminadas: {elim}", f"  Filas restauradas: {rest}", f"  Filas del lote que quedan: {quedan}",
                       f"  Resultado: {resultado}"]
        print("\n".join(lineas))
        reporte(f"rollback_lote{lote_id}{'_ensayo' if ensayo else ''}",
                ["Entorno verificado:"] + [f"  {k}: {v}" for k, v in ev.items()] + [""] + lineas)
    finally:
        conn.close()
