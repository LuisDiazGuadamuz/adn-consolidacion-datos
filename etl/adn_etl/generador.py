# -*- coding: utf-8 -*-
"""Genera los procedimientos T-SQL de los pasos en sql/10_pasos/ (un archivo por paso)."""
import glob
import os

from . import registro

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
DIR_PASOS = os.path.join(RAIZ, "sql", "10_pasos")


def generar():
    os.makedirs(DIR_PASOS, exist_ok=True)
    pasos = registro.todos()
    errores = [e for p in pasos for e in p.validar()]
    if errores:
        raise SystemExit("Errores en las especificaciones:\n  " + "\n  ".join(errores))
    escritos = set()
    for p in pasos:
        ruta = os.path.join(DIR_PASOS, f"{p.orden:03d}_{p.nombre}.sql")
        with open(ruta, "w", encoding="utf-8", newline="\n") as f:
            f.write("USE ADN_Unificado;\nGO\n")
            f.write(p.generar())
        escritos.add(ruta)
    for viejo in glob.glob(os.path.join(DIR_PASOS, "*.sql")):
        if viejo not in escritos:
            os.remove(viejo)
    return sorted(escritos)


if __name__ == "__main__":
    for r in generar():
        print(os.path.relpath(r, RAIZ))
