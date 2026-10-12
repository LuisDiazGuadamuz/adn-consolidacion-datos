# -*- coding: utf-8 -*-
"""Genera el script DDL del modelo unificado a partir de model.py"""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "etl"))
from adn_etl import modelo as model
from adn_etl.modelo import T, LINAJE, TABLAS

REGLAS = [
 ("ID-01","Identidad","El servicio se identifica por el número de circuito normalizado (mayúsculas, sin espacios, guiones ni puntos; 3 letras + 4 a 9 dígitos).","Crítica",None),
 ("ID-02","Identidad","El cliente se identifica por su cédula con solo dígitos: 9 física, 10 jurídica, 12 DIMEX; otra longitud es inválida.","Crítica",None),
 ("ID-03","Identidad","Un cliente puede tener varios servicios.","Crítica",None),
 ("ID-04","Identidad","Los IDs de cada sistema se conservan como llaves de origen en la tabla de correspondencia.","Crítica",None),
 ("ID-05","Identidad","Orden de emparejamiento: circuito, luego cédula, si no sin correspondencia. Nunca por nombre, correo o teléfono.","Crítica",None),
 ("ID-06","Identidad","Facturas y pagos de Books heredan el circuito y la cédula del contacto.","Crítica",None),
 ("ID-07","Identidad","Las llamadas se vinculan por CustomerCircuitNumber.","Crítica",None),
 ("ID-08","Identidad","ZohoID equivale a la cuenta del CRM.","Estándar",None),
 ("ID-09","Identidad","Trengo se vincula vía el contacto del CRM (ID_ZCRM).","Estándar",None),
 ("ID-10","Identidad","customer_status_zbooks se vincula por custome_id (contacto de Books).","Estándar",None),
 ("DD-01","Deduplicación","Llamadas iguales en todo salvo id/_id son duplicadas; se conserva la de menor id.","Crítica",None),
 ("DD-02","Deduplicación","Espejos Zoho con el mismo ID: se conserva la modificación más reciente.","Crítica",None),
 ("DD-03","Deduplicación","Filas idénticas sin llave se cargan una sola vez.","Estándar",None),
 ("DD-04","Deduplicación","Una llave numérica no garantiza unicidad; se mide por contenido.","Estándar",None),
 ("DD-05","Deduplicación","Cada archivo CDR se procesa una sola vez (huella).","Crítica",None),
 ("DD-06","Deduplicación","Todo registro excluido queda en la tabla de descartes.","Crítica",None),
 ("ES-01","Estandarización","Fechas tipadas con zona horaria explícita.","Crítica",None),
 ("ES-02","Estandarización","Fechas anteriores a 1990 o 1900-01-01 pasan a NULL y se marcan.","Crítica",None),
 ("ES-03","Estandarización","Fecha de registro posterior a la carga es anomalía.","Estándar",None),
 ("ES-04","Estandarización","Montos decimal(19,4) con la moneda en columna aparte.","Crítica",None),
 ("ES-05","Estandarización","Texto recortado, vacío a NULL, nvarchar y una sola intercalación.","Estándar",None),
 ("ES-06","Estandarización","Las llaves usan el mismo tipo en todas las tablas.","Estándar",None),
 ("ES-07","Estandarización","Booleanos en texto pasan a bit.","Estándar",None),
 ("ES-08","Estandarización","Se conserva el valor original de los campos normalizados.","Estándar",None),
 ("ES-09","Estandarización","Las unidades de Navsat se clasifican (vehículo empresa, propio, colaborador).","Estándar",None),
 ("IN-01","Integridad","Los registros huérfanos se cargan marcados.","Crítica",None),
 ("IN-02","Integridad","Las relaciones se declaran como llaves foráneas.","Crítica",None),
 ("IN-03","Integridad","Las columnas vacías no se migran.","Estándar",None),
 ("IN-04","Integridad","No se migran credenciales, contraseñas, tokens, fotos de cédula ni firmas.","Crítica",None),
 ("IN-05","Integridad","Cada registro guarda su trazabilidad: sistema, base, tabla, llave de origen, período y lote.","Crítica",None),
 ("D1","Decisión","Llamadas: MongoDB desde 2024 + SQL Server 2022-2023.","Crítica","C"),
 ("D2","Decisión","Tablas _Extended como principal; la base completa aporta los ausentes, marcados.","Crítica","C"),
 ("D3","Decisión","Decisión D3 del catálogo v1.0.","Estándar","A"),
 ("D4","Decisión","Fechas en datetimeoffset con zona -06:00.","Crítica","C"),
 ("D5","Decisión","Moneda original + equivalente en colones con el tipo de cambio del día.","Crítica","C"),
 ("D6","Decisión","Modelo con datos completos y acceso restringido; corpus RAG anonimizado.","Crítica","B"),
 ("D7","Decisión","Llamadas: 24 meses en línea + histórico; PRTG 90 días (sujeto a requisitos legales).","Crítica","B"),
 ("D8","Decisión","Se incluyen clientes sin CRM, marcados con su sistema de origen.","Crítica","B"),
 ("D9","Decisión","CRM manda en datos comerciales y de contacto; Books en fiscales; ADNPayV2 solo completa vacíos.","Crítica","B"),
 ("D10","Decisión","Moneda de tarifas y costos de llamadas según el destino: códigos 506 en colones, el resto en dólares.","Crítica","C"),
 ("D11","Decisión","Minutos_Customer y MinutosLegalId se conservan como histórico en core.MinutosContratadosHistorico.","Estándar","B"),
 ("D12","Decisión","Tickets de Trengo y conexiones/desconexiones se cargan como fuentes históricas; los tickets sin ID del CRM quedan sin correspondencia (ID-05 sin excepción).","Estándar","A"),
]

def q(s): return "N'" + s.replace("'", "''") + "'"

def coldef(t, c):
    n = c["name"]
    if c["type"] == "computed":
        return f"    [{n}] AS (CONVERT(char(7), [FechaDato], 126))"
    s = f"    [{n}] {c['type']}"
    if c.get("identity"): s += " IDENTITY(1,1)"
    s += " NOT NULL" if not c["null"] else " NULL"
    if n == "FechaCarga": s += f" CONSTRAINT [DF_{t['name']}_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00'))"
    return s

def allcols(t):
    return t["cols"] + (LINAJE if t["linaje"] else [])

def pkcol(t):
    if t.get("pkcol"): return t["pkcol"]
    return next(c["name"] for c in t["cols"] if c.get("pk"))

def build():
    out = []
    w = out.append
    w("/* =====================================================================")
    w("   Modelo de datos unificado ADN_Unificado - Sprint 2")
    w("   American Data Networks S.A. · Proyecto de consolidación de datos")
    w("   Autor: Luis Felipe Díaz Guadamuz · Generado desde la especificación model.py")
    w("   Ejecutar SOLO en el sandbox (SQL Server 2022). No contiene datos de clientes.")
    w(f"   Tablas: {len(T)} · Esquemas: core, ref, ctl")
    w("   ===================================================================== */")
    w("SET NOCOUNT ON;")
    w("IF DB_ID(N'ADN_Unificado') IS NULL CREATE DATABASE ADN_Unificado COLLATE Modern_Spanish_CI_AS;")
    w("GO")
    w("USE ADN_Unificado;")
    w("GO")
    w("/* Protección: si el modelo ya existe, no se ejecuta nada (evita errores al correrlo dos veces). */")
    w("IF OBJECT_ID(N'ctl.Regla', N'U') IS NOT NULL")
    w("BEGIN")
    w("    RAISERROR(N'El modelo ya existe en ADN_Unificado: no se hizo ningún cambio. Para recrearlo, elimine primero la base en el sandbox.', 10, 1) WITH NOWAIT;")
    w("    SET NOEXEC ON;")
    w("END")
    w("GO")
    for s in ["ctl", "ref", "core"]:
        w(f"IF SCHEMA_ID(N'{s}') IS NULL EXEC(N'CREATE SCHEMA {s}');")
    w("GO")
    order = [t for t in T if t["schema"] == "ctl"] + [t for t in T if t["schema"] == "ref"] + [t for t in T if t["schema"] == "core"]
    for t in order:
        full = f"{t['schema']}.{t['name']}"
        w("")
        w(f"/* {full}: {t['desc']}. Grano: {t['grano']}. */")
        cols = allcols(t)
        lines = [coldef(t, c) for c in cols]
        lines.append(f"    CONSTRAINT [PK_{t['schema']}_{t['name']}] PRIMARY KEY CLUSTERED ([{pkcol(t)}])")
        for u in t["uniques"]:
            lines.append(f"    CONSTRAINT [UQ_{t['name']}_{'_'.join(u)}] UNIQUE ({', '.join('['+x+']' for x in u)})")
        if any(c["name"] == "AtributosExtendidos" for c in cols):
            lines.append(f"    CONSTRAINT [CK_{t['name']}_AtributosJSON] CHECK ([AtributosExtendidos] IS NULL OR ISJSON([AtributosExtendidos]) = 1)")
        if t["name"] == "Cliente":
            lines.append("    CONSTRAINT [CK_Cliente_Cedula] CHECK ([Cedula] IS NULL OR ([Cedula] NOT LIKE '%[^0-9]%' AND LEN([Cedula]) IN (9,10,12)))")
        if t["name"] == "Servicio":
            lines.append("    CONSTRAINT [CK_Servicio_Circuito] CHECK ([Circuito] IS NULL OR [Circuito] LIKE '[A-Z][A-Z][A-Z][0-9][0-9][0-9][0-9]%')")
        if any(c["name"] == "Moneda" for c in cols):
            lines.append(f"    CONSTRAINT [CK_{t['name']}_Moneda] CHECK ([Moneda] IS NULL OR [Moneda] IN ('CRC','USD','EUR'))")
        w(f"CREATE TABLE {full} (")
        w(",\n".join(lines))
        w(");")
        for col, cond in t.get("filtered_unique", {}).items():
            w(f"CREATE UNIQUE INDEX [UX_{t['name']}_{col}] ON {full} ([{col}]) WHERE {cond};")
        for ix in t.get("indices", []):
            w(f"CREATE INDEX [IX_{t['name']}_{'_'.join(ix)}] ON {full} ({', '.join('['+c+']' for c in ix)});")
        if t.get("unique_hash"):
            w(f"CREATE UNIQUE INDEX [UX_{t['name']}_HashContenido] ON {full} ([HashContenido]) WHERE [HashContenido] IS NOT NULL;")
        if t["linaje"]:
            w(f"CREATE INDEX [IX_{t['name']}_Linaje] ON {full} ([FuenteSistema], [FuenteTabla], [FuenteLlave]);")
        w("GO")
    # llaves foráneas
    w("")
    w("/* ---------------- Llaves foráneas (IN-02) ---------------- */")
    nfk = 0
    for t in order:
        full = f"{t['schema']}.{t['name']}"
        for c in allcols(t):
            ref = c.get("fk")
            if c["name"] == "LoteId" and t["linaje"]: ref = "ctl.Lote"
            if not ref: continue
            rt = TABLAS[ref]
            w(f"ALTER TABLE {full} ADD CONSTRAINT [FK_{t['name']}_{c['name']}] FOREIGN KEY ([{c['name']}]) REFERENCES {ref} ([{pkcol(rt)}]);")
            nfk += 1
            if ref != "ctl.Lote":
                w(f"CREATE INDEX [IX_{t['name']}_{c['name']}] ON {full} ([{c['name']}]);")
    w("GO")
    # reglas
    w("")
    w("/* ---------------- Catálogo de reglas aprobado (v1.0) ---------------- */")
    for r in REGLAS:
        op = "NULL" if r[4] is None else q(r[4])
        w(f"INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) "
          f"VALUES ({q(r[0])}, {q(r[1])}, {q(r[2])}, {q(r[3])}, {op}, N'{'1.1' if r[0] in ('D10','D11','D12') else '1.0'}', '{'2026-10-12' if r[0] in ('D10','D11','D12') else '2026-10-06'}', N'José Hernández');")
    w("GO")
    # vista de verificación
    w("")
    w("SET NOEXEC OFF;")
    w("GO")
    w("/* ---------------- Verificación ---------------- */")
    w("SELECT s.name AS Esquema, COUNT(DISTINCT t.object_id) AS Tablas, COUNT(c.column_id) AS Columnas")
    w("FROM sys.tables t JOIN sys.schemas s ON s.schema_id = t.schema_id JOIN sys.columns c ON c.object_id = t.object_id")
    w("GROUP BY s.name ORDER BY s.name;")
    w("SELECT COUNT(*) AS LlavesForaneas FROM sys.foreign_keys;")
    w("SELECT COUNT(*) AS Reglas FROM ctl.Regla;")
    w("GO")
    return "\n".join(out), nfk

if __name__ == "__main__":
    sql, nfk = build()
    open(os.path.join(os.path.dirname(__file__), "..", "sql", "00_modelo", "01_modelo_unificado.sql"), "w", encoding="utf-8").write(sql)
    print("FKs", nfk, "lines", sql.count("\n"))
