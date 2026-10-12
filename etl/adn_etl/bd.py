# -*- coding: utf-8 -*-
"""Conexión a SQL Server (sandbox) y ejecución de scripts con separador GO."""
import re

import pymssql

_GO = re.compile(r"^\s*GO\s*;?\s*$", re.IGNORECASE | re.MULTILINE)


def conectar(cfg, autocommit=False):
    return pymssql.connect(server=cfg.sql_host, port=cfg.sql_port, user=cfg.sql_usuario, password=cfg.sql_clave,
                           database="ADN_Unificado", autocommit=autocommit, login_timeout=15, timeout=0,
                           charset="UTF-8", appname="adn_etl")


def lotes_sql(texto):
    return [b for b in _GO.split(texto) if b.strip()]


def ejecutar_script(conn, texto):
    """Ejecuta un script por lotes (GO). Devuelve las filas del último conjunto de resultados."""
    cur = conn.cursor()
    ultimo = []
    for b in lotes_sql(texto):
        cur.execute(b)
        while True:
            if cur.description:
                ultimo = [tuple(r) for r in cur.fetchall()]
            if not cur.nextset():
                break
    return ultimo


def filas(cur, sql, params=None):
    cur.execute(sql, params) if params is not None else cur.execute(sql)
    res = cur.fetchall() if cur.description else []
    while cur.nextset():
        if cur.description:
            res = cur.fetchall()
    return res
