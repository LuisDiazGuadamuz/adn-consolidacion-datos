# -*- coding: utf-8 -*-
"""Protección contra producción (regresión del Sprint 3).

El ETL solo se ejecuta si se cumplen TODAS estas condiciones:
  1. ETL_ENTORNO = SANDBOX.
  2. Corre dentro de un contenedor Docker (existe /.dockerenv).
  3. Los hosts de SQL Server y MongoDB están en la lista permitida (por defecto sandbox-sql y mongo-lab)
     y resuelven a la misma red Docker que el contenedor del ETL.
  4. La base ADN_Unificado tiene la marca ctl.Entorno = 'SANDBOX' (nunca se crea en producción).
La evidencia de cada verificación se guarda en reportes/ para el DoD.
"""
import ipaddress
import os
import socket


class EntornoNoPermitido(RuntimeError):
    pass


def _red(ip):
    return ipaddress.ip_network(f"{ip}/16", strict=False)


def verificar_configuracion(cfg):
    ev = {}
    if cfg.entorno != "SANDBOX":
        raise EntornoNoPermitido(f"ETL_ENTORNO debe ser SANDBOX (es '{cfg.entorno}').")
    ev["ETL_ENTORNO"] = cfg.entorno
    if not os.path.exists("/.dockerenv"):
        raise EntornoNoPermitido("El ETL solo corre dentro del contenedor aislado (docker/README).")
    ev["Contenedor"] = socket.gethostname()
    propia = socket.gethostbyname(socket.gethostname())
    ev["IP del contenedor ETL"] = propia
    for nombre, host, permitidos in (("SQL Server", cfg.sql_host, cfg.sql_hosts_permitidos),
                                     ("MongoDB", cfg.mongo_host, cfg.mongo_hosts_permitidos)):
        if not host:
            continue
        if host not in permitidos:
            raise EntornoNoPermitido(f"{nombre}: el host '{host}' no está en la lista permitida {sorted(permitidos)}.")
        try:
            ip = socket.gethostbyname(host)
        except OSError as e:
            raise EntornoNoPermitido(f"{nombre}: no se pudo resolver '{host}' ({e}). ¿Está conectado a la red etl-red?")
        if ipaddress.ip_address(ip) not in _red(propia):
            raise EntornoNoPermitido(f"{nombre}: '{host}' resuelve a {ip}, fuera de la red del contenedor ({_red(propia)}).")
        ev[f"{nombre} host"] = f"{host} → {ip} (misma red Docker)"
    return ev


def verificar_base(cur):
    cur.execute("""
        SELECT DB_NAME() AS Base, @@SERVERNAME AS Servidor, CAST(SERVERPROPERTY('MachineName') AS nvarchar(128)) AS Maquina,
               CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(40)) AS Version,
               (SELECT COUNT(*) FROM ctl.Entorno WHERE Nombre = 'SANDBOX') AS Marca
    """)
    base, servidor, maquina, version, marca = cur.fetchone()
    if base != "ADN_Unificado":
        raise EntornoNoPermitido(f"Conectado a la base '{base}', no a ADN_Unificado.")
    if marca != 1:
        raise EntornoNoPermitido("La base no tiene la marca ctl.Entorno = 'SANDBOX'. Instale sql/01_control en el sandbox.")
    return {"Base": base, "Servidor SQL": servidor, "Máquina SQL": maquina, "Versión SQL": version,
            "Marca ctl.Entorno": "SANDBOX"}
