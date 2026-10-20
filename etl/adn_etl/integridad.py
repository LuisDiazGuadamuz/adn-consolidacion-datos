# -*- coding: utf-8 -*-
"""Integridad referencial del modelo unificado (Sprint 4). Solo lectura; el reporte lleva solo conteos.

Pruebas (todas deben dar 0 para aprobar):
  I-1  Llaves foráneas deshabilitadas o no confiables (sys.foreign_keys)
  I-2  Filas huérfanas por cada llave foránea: valor sin fila en la tabla padre (se recalcula aunque la FK sea confiable)
  I-3  Violaciones de llaves foráneas y restricciones CHECK (DBCC CHECKCONSTRAINTS WITH ALL_CONSTRAINTS)
  I-4  Filas sin linaje (FuenteSistema, FuenteTabla o FuenteLlave vacíos)
  I-5  Filas cuyo lote no es una carga confirmada y exitosa (o cuyo lote no existe)
  I-6  Reglas de la consolidación: cliente sin ningún origen vigente; registro de cliente de CRM/Books/ADNPayV2 sin
       cliente unificado; servicio con más de un registro de correspondencia de CRM
Además informa la cobertura de cada referencia que admite vacío (p. ej. % de facturas con cliente), que no es
un defecto de integridad sino la medida de cuánto se pudo vincular.
"""
import csv
import datetime as dt
import os

from . import bd, modelo, runner


def _fks(cur):
    return bd.filas(cur, """
        SELECT fk.name, SCHEMA_NAME(tp.schema_id) + '.' + tp.name AS Hija, cp.name AS ColHija,
               SCHEMA_NAME(tr.schema_id) + '.' + tr.name AS Padre, cr.name AS ColPadre,
               fk.is_disabled, fk.is_not_trusted, cp.is_nullable,
               (SELECT COUNT(*) FROM sys.foreign_key_columns x WHERE x.constraint_object_id = fk.object_id) AS NCols
        FROM sys.foreign_keys fk
        JOIN sys.foreign_key_columns fc ON fc.constraint_object_id = fk.object_id AND fc.constraint_column_id = 1
        JOIN sys.tables tp ON tp.object_id = fk.parent_object_id
        JOIN sys.columns cp ON cp.object_id = fc.parent_object_id AND cp.column_id = fc.parent_column_id
        JOIN sys.tables tr ON tr.object_id = fk.referenced_object_id
        JOIN sys.columns cr ON cr.object_id = fc.referenced_object_id AND cr.column_id = fc.referenced_column_id
        WHERE SCHEMA_NAME(tp.schema_id) IN ('core', 'ref', 'ctl')
        ORDER BY 2, 3""")


def ejecutar(cfg):
    ahora = dt.datetime.now(dt.timezone(dt.timedelta(hours=-6))).replace(microsecond=0)
    carpeta = os.path.join(runner.DIR_REPORTES, f"integridad_{ahora.strftime('%Y%m%d_%H%M%S')}")
    os.makedirs(carpeta, exist_ok=True)
    conn = bd.conectar(cfg, autocommit=True)
    pruebas, cobertura = [], []
    try:
        ev = runner.evidencia_entorno(cfg, conn)
        cur = conn.cursor()

        def prueba(cod, nombre, valor, detalle=""):
            pruebas.append((cod, nombre, int(valor), "APROBADA" if int(valor) == 0 else "FALLA", detalle))
            print(f"{cod:5s} {nombre:78s} {int(valor):>10}  {'APROBADA' if int(valor) == 0 else 'FALLA'}")

        # I-1
        fks = _fks(cur)
        prueba("I-1", f"Llaves foráneas deshabilitadas o no confiables (de {len(fks)})",
               sum(1 for f in fks if f[5] or f[6]))
        # I-2 + cobertura
        huerf = 0
        for nombre, hija, col, padre, colp, _, _, nullable, ncols in fks:
            if ncols != 1:
                continue
            r = bd.filas(cur, f"""SELECT COUNT_BIG(*), COUNT_BIG(h.[{col}]),
                                         SUM(CASE WHEN h.[{col}] IS NOT NULL AND NOT EXISTS
                                             (SELECT 1 FROM {padre} p WHERE p.[{colp}] = h.[{col}]) THEN 1 ELSE 0 END)
                                  FROM {hija} h""")[0]
            filas, conv, h = int(r[0]), int(r[1]), int(r[2] or 0)
            huerf += h
            pct = None if not filas else round(100.0 * conv / filas, 2)
            cobertura.append((hija, col, padre, filas, conv, pct, h, "sí" if nullable else "no"))
        prueba("I-2", f"Filas huérfanas en {len(cobertura)} llaves foráneas", huerf)
        # I-3
        cur.execute("DBCC CHECKCONSTRAINTS WITH ALL_CONSTRAINTS, NO_INFOMSGS;")
        viol = 0
        while True:
            if cur.description:
                viol += len(cur.fetchall())
            if not cur.nextset():
                break
        prueba("I-3", "Violaciones de FK y CHECK (DBCC CHECKCONSTRAINTS WITH ALL_CONSTRAINTS)", viol)
        # I-4 / I-5 sobre las tablas con linaje
        sin_lin = lote_mal = 0
        for t in modelo.T:
            if not t["linaje"]:
                continue
            full = f"{t['schema']}.{t['name']}"
            r = bd.filas(cur, f"""SELECT SUM(CASE WHEN t.FuenteSistema IS NULL OR t.FuenteTabla IS NULL OR t.FuenteLlave IS NULL THEN 1 ELSE 0 END),
                                         SUM(CASE WHEN l.LoteId IS NULL OR l.Modo <> 'CONFIRM' OR l.Estado <> 'Exitoso' THEN 1 ELSE 0 END)
                                  FROM {full} t LEFT JOIN ctl.Lote l ON l.LoteId = t.LoteId""")[0]
            sin_lin += int(r[0] or 0)
            lote_mal += int(r[1] or 0)
        prueba("I-4", "Filas sin linaje (FuenteSistema, FuenteTabla o FuenteLlave vacíos)", sin_lin)
        prueba("I-5", "Filas cuyo lote no es una carga CONFIRM exitosa", lote_mal)
        # I-6 reglas de consolidación
        r = bd.filas(cur, """SELECT
            (SELECT COUNT_BIG(*) FROM core.Cliente c WHERE NOT EXISTS (SELECT 1 FROM core.ClienteOrigen o WHERE o.ClienteId = c.ClienteId
                    AND o.Sistema IN ('ZohoCRM', 'ZohoBooks', 'ADNPayV2'))),
            (SELECT COUNT_BIG(*) FROM core.ClienteOrigen o WHERE o.Sistema IN ('ZohoCRM', 'ZohoBooks', 'ADNPayV2') AND o.ClienteId IS NULL),
            (SELECT COUNT_BIG(*) FROM (SELECT o.ServicioId FROM core.ClienteOrigen o WHERE o.Sistema = 'ZohoCRM' AND o.ServicioId IS NOT NULL
                    GROUP BY o.ServicioId HAVING COUNT(*) > 1) x)""")[0]
        prueba("I-6a", "Clientes sin ningún origen vigente en CRM, Books o ADNPayV2", r[0])
        prueba("I-6b", "Registros de cliente de CRM, Books o ADNPayV2 sin cliente unificado", r[1])
        prueba("I-6c", "Servicios con más de una cuenta de CRM en la correspondencia", r[2])
    finally:
        conn.close()

    fallas = [p for p in pruebas if p[3] != "APROBADA"]
    print(f"\nPRUEBAS: {len(pruebas) - len(fallas)} de {len(pruebas)} aprobadas")

    with open(os.path.join(carpeta, "pruebas.csv"), "w", encoding="utf-8-sig", newline="") as f:
        w = csv.writer(f, delimiter=";")
        w.writerow(["Prueba", "Descripcion", "Valor", "Resultado", "Detalle"])
        w.writerows(pruebas)
    with open(os.path.join(carpeta, "cobertura_referencias.csv"), "w", encoding="utf-8-sig", newline="") as f:
        w = csv.writer(f, delimiter=";")
        w.writerow(["Tabla", "Columna", "Referencia", "Filas", "ConValor", "PctConValor", "Huerfanas", "AdmiteVacio"])
        w.writerows(cobertura)

    def n(x):
        return "" if x is None else f"{x:,}".replace(",", ".")
    md = ["# Integridad referencial · ADN_Unificado", "",
          f"Ejecución: {ahora.strftime('%d/%m/%Y %H:%M')} (hora de Costa Rica) · entorno {ev.get('Marca ctl.Entorno', '')}", "",
          f"**{len(pruebas) - len(fallas)} de {len(pruebas)} pruebas aprobadas.**", "",
          "| Prueba | Descripción | Resultado esperado 0 | Resultado |", "|---|---|---:|---|"]
    md += [f"| {p[0]} | {p[1]} | {n(p[2])} | {p[3]} |" for p in pruebas]
    md += ["", "## Cobertura de las referencias que admiten vacío", "",
           "Porcentaje de filas que quedaron vinculadas. Un vacío no es un error de integridad: es un registro que no se "
           "pudo vincular con las reglas aprobadas y que queda marcado como anomalía (IN-01, ID-07...). Detalle completo en "
           "`cobertura_referencias.csv`.", "",
           "| Tabla | Columna | Referencia | Filas | Con valor | % |", "|---|---|---|---:|---:|---:|"]
    clave = [c for c in cobertura if c[7] == "sí" and c[3] and c[1] != "LoteId" and c[5] is not None and c[5] < 100]
    clave.sort(key=lambda c: -c[3])
    md += [f"| {c[0]} | {c[1]} | {c[2]} | {n(c[3])} | {n(c[4])} | {c[5]:.2f} |" for c in clave[:40]]
    with open(os.path.join(carpeta, "integridad.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(md) + "\n")
    print("Carpeta:", os.path.relpath(carpeta, runner.RAIZ))
