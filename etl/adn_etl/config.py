# -*- coding: utf-8 -*-
"""Configuración desde variables de entorno (archivo config/entorno.env, que NO se versiona)."""
import os
from dataclasses import dataclass, field
from urllib.parse import urlparse


def _lista(v, defecto):
    return {x.strip() for x in (v or defecto).split(",") if x.strip()}


@dataclass
class Config:
    entorno: str
    sql_host: str
    sql_port: int
    sql_usuario: str
    sql_clave: str = field(repr=False)
    mongo_uri: str = field(repr=False, default="")
    usuario: str = "etl"
    sql_hosts_permitidos: set = field(default_factory=set)
    mongo_hosts_permitidos: set = field(default_factory=set)

    @property
    def mongo_host(self):
        return urlparse(self.mongo_uri).hostname if self.mongo_uri else ""


def cargar():
    faltan = [v for v in ("ETL_ENTORNO", "ETL_SQL_HOST", "ETL_SQL_USUARIO", "ETL_SQL_CLAVE") if not os.environ.get(v)]
    if faltan:
        raise SystemExit(f"Faltan variables de entorno: {faltan}. Copie config/entorno.ejemplo.env a config/entorno.env.")
    return Config(
        entorno=os.environ["ETL_ENTORNO"].strip().upper(),
        sql_host=os.environ["ETL_SQL_HOST"].strip(),
        sql_port=int(os.environ.get("ETL_SQL_PUERTO", "1433")),
        sql_usuario=os.environ["ETL_SQL_USUARIO"],
        sql_clave=os.environ["ETL_SQL_CLAVE"],
        mongo_uri=os.environ.get("ETL_MONGO_URI", ""),
        usuario=os.environ.get("ETL_USUARIO", "etl"),
        sql_hosts_permitidos=_lista(os.environ.get("ETL_SQL_HOSTS_PERMITIDOS"), "sandbox-sql"),
        mongo_hosts_permitidos=_lista(os.environ.get("ETL_MONGO_HOSTS_PERMITIDOS"), "mongo-lab"),
    )
