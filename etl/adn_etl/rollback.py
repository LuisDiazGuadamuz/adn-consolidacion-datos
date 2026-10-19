# -*- coding: utf-8 -*-
"""Genera el archivo de rollback de un lote a partir de la bitácora por registro.

El archivo es un solo lote T-SQL que se puede revisar y ejecutar desde SSMS o con el runner:
  - restaura los valores anteriores de las filas actualizadas (ctl.Bitacora.ValoresAnteriores),
  - elimina las filas insertadas por el lote,
  - vuelve a insertar, con su mismo id, las filas que el lote retiró por no tener origen vigente (Accion 'R'),
  - elimina descartes, anomalías y linaje de campo del lote,
  - marca el lote como Revertido.
Se niega a ejecutar si el lote no está Exitoso o si un lote posterior modificó los mismos registros
(los lotes se revierten en orden inverso). Con @Simular = 1 hace todo y al final revierte (ensayo).
"""
import datetime as dt
import os

from . import modelo

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
DIR_ROLLBACK = os.path.join(RAIZ, "rollback")


def _columnas(tabla):
    t = modelo.TABLAS[tabla]
    d = {c["name"]: c for c in t["cols"]}
    if t["linaje"]:
        d.update({c["name"]: c for c in modelo.LINAJE})
    pk = t.get("pkcol") or next(c["name"] for c in t["cols"] if c.get("pk"))
    return d, pk


def generar(cur, lote_id):
    cur.execute("SELECT Paso, Estado, Modo FROM ctl.Lote WHERE LoteId = %s", (lote_id,))
    r = cur.fetchone()
    if not r:
        raise SystemExit(f"No existe el lote {lote_id}.")
    paso, estado, modo = r
    cur.execute("""SELECT TablaModelo, Accion, COUNT_BIG(*) FROM ctl.Bitacora WHERE LoteId = %s
                   GROUP BY TablaModelo, Accion ORDER BY TablaModelo, Accion""", (lote_id,))
    conteos = cur.fetchall()
    tablas = sorted({t for t, _, _ in conteos})
    L = []
    w = L.append
    w(f"/* ROLLBACK del lote {lote_id} · paso {paso}")
    w(f"   Generado {dt.datetime.now().strftime('%Y-%m-%d %H:%M')} desde ctl.Bitacora por adn_etl.rollback.")
    for t, a, n in conteos:
        w(f"   {t}: {n} filas " + {'I': 'insertadas (se eliminan)', 'U': 'actualizadas (se restauran)', 'R': 'retiradas (se vuelven a insertar)'}.get(a, a))
    w("   Ensayo: cambie @Simular a 1 para ejecutar todo y revertir al final. */")
    w("SET XACT_ABORT ON; SET NOCOUNT ON;")
    w("DECLARE @Simular bit = 0;")
    w(f"DECLARE @LoteId int = {int(lote_id)};")
    w("BEGIN TRANSACTION;")
    w("IF NOT EXISTS (SELECT 1 FROM ctl.Lote WHERE LoteId = @LoteId AND Estado = 'Exitoso')")
    w("    THROW 50001, N'El lote no está en estado Exitoso: no se revierte.', 1;")
    w("IF EXISTS (SELECT 1 FROM ctl.Bitacora b1")
    w("           JOIN ctl.Bitacora b2 ON b2.TablaModelo = b1.TablaModelo AND b2.RegistroId = b1.RegistroId AND b2.LoteId > b1.LoteId")
    w("           JOIN ctl.Lote l2 ON l2.LoteId = b2.LoteId AND l2.Estado = 'Exitoso'")
    w("           WHERE b1.LoteId = @LoteId)")
    w("    THROW 50002, N'Lotes posteriores modificaron estos registros: revierta primero esos lotes (orden inverso).', 1;")
    w("DECLARE @Restauradas bigint = 0, @Eliminadas bigint = 0;")
    for tabla in tablas:
        d, pk = _columnas(tabla)
        cur.execute("""SELECT DISTINCT j.[key] FROM ctl.Bitacora b CROSS APPLY OPENJSON(b.ValoresAnteriores) j
                       WHERE b.LoteId = %s AND b.TablaModelo = %s AND b.Accion = 'U'""", (lote_id, tabla))
        claves = [k for (k,) in cur.fetchall() if k in d and k != pk and d[k]["type"] != "computed"]
        if claves:
            con = []
            sets = []
            for k in sorted(claves):
                tipo = d[k]["type"]
                if tipo.startswith("binary"):
                    con.append(f"[{k}] varchar(66) '$.{k}'")
                    sets.append(f"t.[{k}] = CONVERT({tipo}, j.[{k}], 1)")
                elif tipo == "nvarchar(max)":
                    con.append(f"[{k}] nvarchar(max) '$.{k}'")
                    sets.append(f"t.[{k}] = j.[{k}]")
                else:
                    con.append(f"[{k}] {tipo} '$.{k}'")
                    sets.append(f"t.[{k}] = j.[{k}]")
            w(f"/* {tabla}: restaurar valores anteriores */")
            w(f"UPDATE t SET {', '.join(sets)}")
            w(f"FROM {tabla} t")
            w(f"JOIN ctl.Bitacora b ON b.LoteId = @LoteId AND b.TablaModelo = N'{tabla}' AND b.Accion = 'U' AND b.RegistroId = t.[{pk}]")
            w(f"CROSS APPLY OPENJSON(b.ValoresAnteriores) WITH ({', '.join(con)}) j;")
            w("SET @Restauradas += @@ROWCOUNT;")
        if any(t == tabla and a == "I" for t, a, _ in conteos):
            w(f"/* {tabla}: eliminar filas insertadas por el lote */")
            w(f"DELETE t FROM {tabla} t")
            w(f"JOIN ctl.Bitacora b ON b.LoteId = @LoteId AND b.TablaModelo = N'{tabla}' AND b.Accion = 'I' AND b.RegistroId = t.[{pk}];")
            w("SET @Eliminadas += @@ROWCOUNT;")
    for tabla in tablas:
        if not any(t == tabla and a == "R" for t, a, _ in conteos):
            continue
        d, pk = _columnas(tabla)
        cols = [pk] + [c for c in d if c not in (pk, "HashContenido") and d[c]["type"] != "computed"] + ["HashContenido"]
        con, sel = [], []
        for k in cols:
            tipo = "binary(32)" if k == "HashContenido" else d[k]["type"]
            if tipo.startswith("binary"):
                con.append(f"[{k}] varchar(66) '$.{k}'")
                sel.append(f"CONVERT({tipo}, j.[{k}], 1)")
            else:
                con.append(f"[{k}] {tipo} '$.{k}'")
                sel.append(f"j.[{k}]")
        w(f"/* {tabla}: volver a insertar las filas retiradas por el lote (mismo id) */")
        w(f"SET IDENTITY_INSERT {tabla} ON;")
        w(f"INSERT {tabla} ({', '.join('[' + c + ']' for c in cols)})")
        w(f"SELECT {', '.join(sel)}")
        w(f"FROM ctl.Bitacora b CROSS APPLY OPENJSON(b.ValoresAnteriores) WITH ({', '.join(con)}) j")
        w(f"WHERE b.LoteId = @LoteId AND b.TablaModelo = N'{tabla}' AND b.Accion = 'R';")
        w("SET @Restauradas += @@ROWCOUNT;")
        w(f"SET IDENTITY_INSERT {tabla} OFF;")
    w("DELETE FROM ctl.LinajeCampo WHERE LoteId = @LoteId;")
    w("DELETE FROM ctl.Anomalia WHERE LoteId = @LoteId;")
    w("DELETE FROM ctl.Descarte WHERE LoteId = @LoteId;")
    w("UPDATE ctl.Lote SET Estado = 'Revertido', Mensaje = CONCAT(N'Revertido ', CONVERT(nvarchar(30), SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00'), 126),")
    w("       N': ', @Eliminadas, N' filas eliminadas, ', @Restauradas, N' restauradas') WHERE LoteId = @LoteId;")
    verif = " + ".join(f"(SELECT COUNT_BIG(*) FROM {t} WHERE LoteId = @LoteId)" for t in tablas) or "0"
    w(f"DECLARE @Quedan bigint = {verif};")
    w("SELECT @LoteId AS LoteId, @Eliminadas AS FilasEliminadas, @Restauradas AS FilasRestauradas, @Quedan AS FilasQueQuedanDelLote,")
    w("       CASE WHEN @Simular = 1 THEN 'ENSAYO (revertido)' ELSE 'CONFIRMADO' END AS Resultado;")
    w("IF @Quedan <> 0 THROW 50003, N'Quedaron filas del lote en el modelo: no se confirma.', 1;")
    w("IF @Simular = 1 BEGIN ROLLBACK TRANSACTION; END ELSE BEGIN COMMIT TRANSACTION; END")
    return "\n".join(L) + "\n", paso


def escribir(cur, lote_id):
    texto, paso = generar(cur, lote_id)
    os.makedirs(DIR_ROLLBACK, exist_ok=True)
    ruta = os.path.join(DIR_ROLLBACK, f"lote_{int(lote_id):06d}_{paso}.sql")
    with open(ruta, "w", encoding="utf-8", newline="\n") as f:
        f.write(texto)
    return ruta
