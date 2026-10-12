# -*- coding: utf-8 -*-
"""Lectura de la matriz de correspondencia aprobada (Sprint 2) para que los pasos la sigan al pie de la letra."""
import csv
import os
from functools import lru_cache

RUTA = os.path.join(os.path.dirname(__file__), "datos", "matriz_correspondencia.csv")


@lru_cache(maxsize=1)
def filas():
    with open(RUTA, encoding="utf-8") as f:
        return list(csv.DictReader(f))


def de_tabla(base, tabla):
    return [r for r in filas() if r["Base"] == base and r["TablaOrigen"] == tabla]


def columnas(base, tabla, disposicion):
    return [r["ColumnaOrigen"] for r in de_tabla(base, tabla) if r["Disposicion"] == disposicion]


def atributos(base, tabla, alias="x", excluir=()):
    """Expresión T-SQL que arma AtributosExtendidos (JSON) con las columnas que la matriz marca como
    'Atributo extendido'. Los valores vacíos se omiten (ES-05); si no queda ninguno devuelve NULL."""
    cols = [c for c in columnas(base, tabla, "Atributo extendido") if c not in excluir]
    if not cols:
        return "CAST(NULL AS nvarchar(max))"
    partes = ", ".join(f"ctl.fn_Texto(CONVERT(nvarchar(max), {alias}.[{c}])) AS [{c}]" for c in cols)
    return f"NULLIF((SELECT {partes} FOR JSON PATH, WITHOUT_ARRAY_WRAPPER), N'{{}}')"
