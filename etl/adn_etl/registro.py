# -*- coding: utf-8 -*-
"""Registro de todos los pasos de carga, en orden de ejecución."""
from .pasos import ref, cliente, comercial

MODULOS = [ref, cliente, comercial]


def todos():
    pasos = [p for m in MODULOS for p in m.PASOS]
    nombres = [p.nombre for p in pasos]
    dup = {n for n in nombres if nombres.count(n) > 1}
    if dup:
        raise ValueError(f"Pasos con nombre repetido: {dup}")
    pasos.sort(key=lambda p: p.orden)
    vistos = set()
    for p in pasos:
        faltan = [d for d in p.depende if d not in vistos]
        if faltan:
            raise ValueError(f"El paso {p.nombre} depende de {faltan}, que no se ejecutan antes")
        vistos.add(p.nombre)
    return pasos


def por_nombre(nombre):
    for p in todos():
        if p.nombre == nombre:
            return p
    raise KeyError(f"No existe el paso {nombre}. Use 'plan' para ver la lista.")
