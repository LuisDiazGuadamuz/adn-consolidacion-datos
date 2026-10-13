# -*- coding: utf-8 -*-
"""Definición de un paso de carga y generación de su procedimiento T-SQL.

Cada paso lee una o varias tablas de origen (copias en el sandbox), normaliza con las reglas aprobadas
y carga una tabla del modelo con este contrato fijo:

  1. #src: filas de origen ya normalizadas + columnas de linaje (IN-05) + HashContenido.
  2. Descartes: filas sin datos obligatorios (IN-01 / ES-05) y duplicados por la llave del paso
     (DD-01 a DD-04) van a ctl.Descarte con la regla aplicada (DD-06).
  3. Imagen previa (JSON) de las filas que van a cambiar, para poder revertir.
  4. MERGE por la llave: inserta lo nuevo, actualiza solo si cambió el contenido (HashContenido).
     Una segunda ejecución sobre la misma copia no cambia nada (reproducibilidad).
  5. ctl.Bitacora: una fila por registro insertado o actualizado (con valores anteriores).
  6. ctl.Anomalia: valores marcados por las reglas (ES-02, ES-03, IN-01...) de todas las filas válidas;
     las vigentes son las del último lote confirmado de cada paso (ctl.vw_AnomaliaVigente).

El procedimiento no abre ni confirma transacciones: el runner lo ejecuta dentro de una transacción
y decide si confirma (confirm) o revierte (dry-run).
"""
from dataclasses import dataclass, field
from typing import List, Optional, Tuple

from . import modelo

LINAJE_COLS = ["FuenteSistema", "FuenteBase", "FuenteTabla", "FuenteLlave", "FechaDato"]
NO_MAPEABLES = {"FechaCarga", "LoteId", "HashContenido", "PeriodoDato"}


@dataclass
class Anomalia:
    regla: str          # p. ej. "ES-02"
    columna: str        # columna del modelo afectada
    valor: str          # expresión sobre #src (alias s) con el valor original
    condicion: str      # expresión booleana sobre #src (alias s)
    detalle: str


@dataclass
class Paso:
    nombre: str                              # identificador corto, p. ej. "ref_TipoCambio"
    orden: int                               # orden de ejecución
    destino: str                             # tabla del modelo, p. ej. "ref.TipoCambio"
    fuente: Tuple[str, str, str, str]        # (sistema, motor, base, tabla) principal
    select: str                              # SELECT que produce columnas + linaje (alias de columnas = nombres del modelo)
    columnas: List[str]                      # columnas del modelo que produce el SELECT (sin las de linaje)
    descripcion: str = ""
    reglas: List[str] = field(default_factory=list)
    llave_origen: str = ""                   # columna de la tabla de origen que corresponde a FuenteLlave (muestreo)
    clave: Optional[List[str]] = None        # llave del MERGE; por defecto FuenteSistema + FuenteTabla + FuenteLlave
    dedup_orden: str = ""                    # orden para elegir el registro que se conserva; vacío = por contenido (determinista)
    auxiliares: List[str] = field(default_factory=list)  # columnas extra del SELECT que se conservan en #src (p. ej. valores originales)
    dedup_regla: str = "DD-04"
    dedup_motivo: str = "Registro repetido por la llave del paso; se conserva uno según el orden definido"
    anomalias: List[Anomalia] = field(default_factory=list)
    solo_actualizar: bool = False            # actualiza columnas de filas existentes (no inserta)
    preparacion: str = ""                    # T-SQL que se ejecuta antes del SELECT (tablas temporales intermedias)
    filtros: List[Tuple[str, str, str]] = field(default_factory=list)  # (condición sobre s, regla, motivo) → ctl.Descarte
    linaje_campos: List[str] = field(default_factory=list)
    hash_excluir: List[str] = field(default_factory=list)  # columnas que no cuentan como cambio (p. ej. fecha de emparejamiento)  # columnas con linaje por campo (aux lf_<col>_sis/_tab/_llave/_fecha)
    depende: List[str] = field(default_factory=list)
    requiere_periodo: bool = False           # tabla grande: solo se carga por período (--desde/--hasta)
    # Trazabilidad (muestreo del DoD): cómo recalcular FuenteLlave desde la tabla de origen
    traza_from: str = ""                     # FROM sobre el origen, con alias (vacío = [base].dbo.[tabla] por llave_origen)
    traza_llave: str = ""                    # expresión de FuenteLlave sobre ese FROM
    traza_columna: str = ""                  # columna simple del origen para la búsqueda rápida (índice)
    linaje_tabla: str = ""                   # FuenteTabla que escribe el paso, si no es la tabla de origen (p. ej. 'Dispositivo')

    # ------------------------------------------------------------------ utilidades
    @property
    def tabla(self):
        return modelo.TABLAS[self.destino]

    @property
    def pk(self):
        t = self.tabla
        return t.get("pkcol") or next(c["name"] for c in t["cols"] if c.get("pk"))

    @property
    def proc(self):
        return f"etl.usp_{self.nombre}"

    def cols_modelo(self):
        t = self.tabla
        d = {c["name"]: c for c in t["cols"]}
        if t["linaje"]:
            d.update({c["name"]: c for c in modelo.LINAJE})
        return d

    def llave(self):
        return self.clave or ["FuenteSistema", "FuenteTabla", "FuenteLlave"]

    def validar(self):
        d = self.cols_modelo()
        errores = []
        for c in self.columnas:
            if c not in d:
                errores.append(f"{self.nombre}: la columna {c} no existe en {self.destino}")
            elif c in NO_MAPEABLES or c == self.pk or c in LINAJE_COLS:
                errores.append(f"{self.nombre}: la columna {c} no se debe listar en columnas")
        for c in self.llave():
            if c not in d:
                errores.append(f"{self.nombre}: la llave {c} no existe en {self.destino}")
        if not self.solo_actualizar:
            obligatorias = [n for n, c in d.items() if not c["null"] and n not in NO_MAPEABLES and n != self.pk
                            and n not in LINAJE_COLS and n not in self.columnas]
            if obligatorias:
                errores.append(f"{self.nombre}: faltan columnas obligatorias {obligatorias}")
        return errores

    # ------------------------------------------------------------------ generación
    def _hash(self):
        d = self.cols_modelo()
        partes = []
        for c in [x for x in self.columnas if x not in self.hash_excluir]:
            tipo = d[c]["type"]
            estilo = ", 126" if tipo.startswith(("date", "datetime", "time", "float")) else ""
            partes.append(f"ISNULL(CONVERT(nvarchar(max), q.[{c}]{estilo}), N'~')")
        partes.append("CAST(NULL AS nvarchar(1))")  # CONCAT_WS exige al menos 2 valores; NULL no altera el resultado
        return "HASHBYTES('SHA2_256', CONCAT_WS(N'|', " + ", ".join(partes) + "))"

    def _match(self, a="t", b="s"):
        return " AND ".join(f"{a}.[{c}] = {b}.[{c}]" for c in self.llave())

    def _json_antes(self, cols):
        d = self.cols_modelo()
        sel = []
        for c in cols:
            if d[c]["type"].startswith("binary"):
                sel.append(f"CONVERT(varchar(66), t.[{c}], 1) AS [{c}]")
            else:
                sel.append(f"t.[{c}]")
        return "(SELECT " + ", ".join(sel) + " FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES)"

    def generar(self) -> str:
        errores = self.validar()
        if errores:
            raise ValueError("\n".join(errores))
        d = self.cols_modelo()
        destino, pk = self.destino, self.pk
        linaje = self.tabla["linaje"]
        src_cols = self.columnas + [c for c in LINAJE_COLS if linaje]
        out_cols = self.columnas if self.solo_actualizar else src_cols
        llave_part = ", ".join(f"s.[{c}]" for c in self.llave())
        L = []
        w = L.append
        w(f"/* Paso {self.orden:03d} · {self.nombre} → {destino}")
        w(f"   {self.descripcion}")
        w(f"   Reglas: {', '.join(self.reglas) if self.reglas else '-'}")
        w(f"   GENERADO por adn_etl.generador: no editar a mano. */")
        w(f"CREATE OR ALTER PROCEDURE {self.proc} @LoteId int, @Desde date = NULL, @Hasta date = NULL")
        w("AS")
        w("BEGIN")
        w("    SET NOCOUNT ON; SET XACT_ABORT ON;")
        w("    DECLARE @Ahora datetimeoffset(0) = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00');")
        w("")
        if self.preparacion.strip():
            w("    /* 0. Preparación */")
            for line in self.preparacion.strip("\n").splitlines():
                w("    " + line)
            w("")
        w("    /* 1. Origen normalizado */")
        w("    DROP TABLE IF EXISTS #src;")
        sel = []
        trunc = []
        for c in src_cols:
            tipo = d[c]["type"]
            # Las bases de origen usan otra intercalación (SQL_Latin1_General_CP1_CI_AS); todo texto se lleva a la
            # del modelo (DATABASE_DEFAULT = Modern_Spanish_CI_AS) para comparar con las tablas del modelo sin conflicto
            if tipo.startswith(("nvarchar(", "varchar(", "char(", "nchar(")) and "max" not in tipo:
                n = int(tipo.split("(")[1].rstrip(")"))
                sel.append(f"CAST(q.[{c}] AS {tipo}) COLLATE DATABASE_DEFAULT AS [{c}]")
                if c not in LINAJE_COLS:
                    trunc.append(f"CASE WHEN LEN(q.[{c}]) > {n} THEN N'{c}' END")
            elif tipo.startswith(("nvarchar(", "varchar(")):
                sel.append(f"q.[{c}] COLLATE DATABASE_DEFAULT AS [{c}]")
            else:
                sel.append(f"q.[{c}]")
        if not self.solo_actualizar:
            sel.append(f"{self._hash()} AS HashContenido")
        aux = list(self.auxiliares)
        for c in self.linaje_campos:
            aux += [f"lf_{c}_sis", f"lf_{c}_tab", f"lf_{c}_llave", f"lf_{c}_fecha"]
        sel += [f"q.[{a}]" for a in aux]
        sel.append(("CONCAT_WS(N',', " + ", ".join(trunc + ["CAST(NULL AS nvarchar(1))"]) + ")") if trunc else "CAST(N'' AS nvarchar(1))")
        w("    SELECT " + ",\n           ".join(sel) + " AS _Recortadas")
        w("    INTO #src")
        w("    FROM (")
        for line in self.select.strip("\n").splitlines():
            w("        " + line)
        w("    ) AS q;")
        w("    DECLARE @Leidas bigint = (SELECT COUNT_BIG(*) FROM #src);")
        w("")
        # obligatorias
        oblig = [c for c in src_cols if c in d and not d[c]["null"] and c != pk
                 and c not in ("FuenteSistema", "FuenteBase", "FuenteTabla")
                 and not (self.solo_actualizar and c in LINAJE_COLS)]
        if self.filtros:
            w("    /* 2. Filtros de carga: filas excluidas con la regla que las excluye (DD-06) */")
            for cond, regla, motivo in self.filtros:
                w("    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)")
                w(f"    SELECT @LoteId, '{regla}', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'{motivo}', @Ahora FROM #src s WHERE {cond}")
                w(f"      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'")
                w(f"                      WHERE x.ReglaId = '{regla}' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);")
                w(f"    DELETE s FROM #src s WHERE {cond};")
        w("    /* 2a. Filas sin datos obligatorios (IN-01 si es una referencia, ES-05 si es un dato) */")
        if oblig:
            for c in oblig:
                regla = "IN-01" if d[c].get("fk") else "ES-05"
                w(f"    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, Motivo, FechaDescarte)")
                w(f"    SELECT @LoteId, '{regla}', s.FuenteSistema, s.FuenteTabla, s.FuenteLlave, N'{c} obligatorio vacío o sin correspondencia', @Ahora")
                w(f"    FROM #src s WHERE s.[{c}] IS NULL")
                w(f"      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'")
                w(f"                      WHERE x.ReglaId = '{regla}' AND x.FuenteTabla = s.FuenteTabla AND x.FuenteLlave = s.FuenteLlave);")
            w("    DELETE FROM #src WHERE " + " OR ".join(f"[{c}] IS NULL" for c in oblig) + ";")
        else:
            w("    -- sin columnas obligatorias adicionales")
        w("")
        orden = self.dedup_orden or ("s.FuenteLlave" if self.solo_actualizar else "s.HashContenido, s.FuenteLlave")
        w(f"    /* 2b. Duplicados por la llave del paso ({self.dedup_regla}); el orden es determinista */")
        w("    ;WITH r AS (")
        w(f"        SELECT s.FuenteSistema, s.FuenteTabla, s.FuenteLlave,")
        w(f"               ROW_NUMBER() OVER (PARTITION BY {llave_part} ORDER BY {orden}) AS rn,")
        w(f"               FIRST_VALUE(s.FuenteLlave) OVER (PARTITION BY {llave_part} ORDER BY {orden} ROWS UNBOUNDED PRECEDING) AS Conservada")
        w("        FROM #src s)")
        w("    INSERT ctl.Descarte (LoteId, ReglaId, FuenteSistema, FuenteTabla, FuenteLlave, LlaveConservada, Motivo, FechaDescarte)")
        w(f"    SELECT @LoteId, '{self.dedup_regla}', r.FuenteSistema, r.FuenteTabla, r.FuenteLlave, r.Conservada, N'{self.dedup_motivo}', @Ahora")
        w("    FROM r WHERE r.rn > 1")
        w(f"      AND NOT EXISTS (SELECT 1 FROM ctl.Descarte x JOIN ctl.Lote l ON l.LoteId = x.LoteId AND l.Estado = 'Exitoso'")
        w(f"                      WHERE x.ReglaId = '{self.dedup_regla}' AND x.FuenteTabla = r.FuenteTabla AND x.FuenteLlave = r.FuenteLlave);")
        w("    ;WITH r AS (")
        w(f"        SELECT ROW_NUMBER() OVER (PARTITION BY {llave_part} ORDER BY {orden}) AS rn FROM #src s)")
        w("    DELETE FROM r WHERE rn > 1;")
        w("    DECLARE @Validas bigint = (SELECT COUNT_BIG(*) FROM #src);")
        w("")
        if self.solo_actualizar:
            cols = self.columnas
            diff = "EXISTS (SELECT " + ", ".join(f"s.[{c}]" for c in cols) + " EXCEPT SELECT " + ", ".join(f"t.[{c}]" for c in cols) + ")"
            w("    /* 3. Imagen previa de las filas que cambian (solo las columnas que actualiza este paso) */")
            w("    DROP TABLE IF EXISTS #antes;")
            w(f"    SELECT t.[{pk}] AS RegistroId, t.FuenteLlave, {self._json_antes(cols)} AS Json")
            w(f"    INTO #antes FROM {destino} t JOIN #src s ON {self._match()} WHERE {diff};")
            w("")
            w("    /* 4. Actualización */")
            w("    DROP TABLE IF EXISTS #cambios;")
            w("    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);")
            w(f"    UPDATE t SET " + ", ".join(f"t.[{c}] = s.[{c}]" for c in cols))
            w(f"    OUTPUT N'UPDATE', inserted.[{pk}], inserted.FuenteLlave INTO #cambios")
            w(f"    FROM {destino} t JOIN #src s ON {self._match()} WHERE {diff};")
        else:
            todas = out_cols + ["HashContenido"]
            json_cols = [c for c in d if c not in ("PeriodoDato",) and c != pk and d[c]["type"] != "computed"]
            w("    /* 3. Imagen previa de las filas que van a cambiar (para el rollback) */")
            w("    DROP TABLE IF EXISTS #antes;")
            w(f"    SELECT t.[{pk}] AS RegistroId, t.FuenteLlave, {self._json_antes(json_cols)} AS Json")
            w(f"    INTO #antes FROM {destino} t JOIN #src s ON {self._match()}")
            w("    WHERE t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido;")
            w("")
            w("    /* 4. MERGE: inserta lo nuevo y actualiza solo lo que cambió */")
            w("    DROP TABLE IF EXISTS #cambios;")
            w("    CREATE TABLE #cambios (Accion nvarchar(10) NOT NULL, RegistroId bigint NOT NULL, FuenteLlave nvarchar(200) NULL);")
            w(f"    MERGE {destino} WITH (HOLDLOCK) AS t")
            w("    USING #src AS s")
            w(f"       ON {self._match()}")
            w("    WHEN MATCHED AND (t.HashContenido IS NULL OR t.HashContenido <> s.HashContenido) THEN")
            w("        UPDATE SET " + ", ".join(f"t.[{c}] = s.[{c}]" for c in todas) + ", t.LoteId = @LoteId, t.FechaCarga = @Ahora")
            w("    WHEN NOT MATCHED BY TARGET THEN")
            w("        INSERT (" + ", ".join(f"[{c}]" for c in todas) + ", LoteId, FechaCarga)")
            w("        VALUES (" + ", ".join(f"s.[{c}]" for c in todas) + ", @LoteId, @Ahora)")
            w(f"    OUTPUT $action, inserted.[{pk}], inserted.FuenteLlave INTO #cambios;")
        w("")
        w("    /* 5. Bitácora por registro */")
        w("    INSERT ctl.Bitacora (LoteId, TablaModelo, RegistroId, Accion, FuenteLlave, ValoresAnteriores)")
        w(f"    SELECT @LoteId, N'{destino}', c.RegistroId, CASE c.Accion WHEN N'INSERT' THEN 'I' ELSE 'U' END, c.FuenteLlave, a.Json")
        w("    FROM #cambios c LEFT JOIN #antes a ON a.RegistroId = c.RegistroId AND c.Accion = N'UPDATE';")
        w("")
        if self.linaje_campos:
            w("    /* 5b. Linaje por campo (D9): qué sistema aportó cada valor de las filas afectadas */")
            for c in self.linaje_campos:
                w("    INSERT ctl.LinajeCampo (TablaModelo, RegistroId, Columna, FuenteSistema, FuenteTabla, FuenteLlave, FechaDato, LoteId)")
                w(f"    SELECT N'{destino}', c.RegistroId, N'{c}', s.lf_{c}_sis, s.lf_{c}_tab, s.lf_{c}_llave, s.lf_{c}_fecha, @LoteId")
                w(f"    FROM #cambios c JOIN {destino} t ON t.[{pk}] = c.RegistroId JOIN #src s ON {self._match()}")
                w(f"    WHERE s.lf_{c}_sis IS NOT NULL AND s.lf_{c}_tab IS NOT NULL AND s.lf_{c}_llave IS NOT NULL;")
            w("")
        w("    /* 6. Anomalías vigentes: se evalúan sobre todas las filas válidas del origen (no solo las que cambiaron),")
        w("       así el último lote confirmado de cada paso tiene el estado actual completo (vista ctl.vw_AnomaliaVigente) */")
        w("    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)")
        w(f"    SELECT @LoteId, 'ES-05', N'{destino}', t.[{pk}], LEFT(s._Recortadas, 128), NULL, N'Texto más largo que la columna del modelo: se recortó'")
        w(f"    FROM #src s JOIN {destino} t ON {self._match()}")
        w("    WHERE s._Recortadas <> N'';")
        if self.anomalias:
            for an in self.anomalias:
                w("    INSERT ctl.Anomalia (LoteId, ReglaId, TablaModelo, RegistroId, Columna, ValorOriginal, Detalle)")
                w(f"    SELECT @LoteId, '{an.regla}', N'{destino}', t.[{pk}], N'{an.columna}', LEFT(CONVERT(nvarchar(400), {an.valor}), 400), N'{an.detalle}'")
                w(f"    FROM #src s JOIN {destino} t ON {self._match()}")
                w(f"    WHERE {an.condicion};")
        else:
            w("    -- sin reglas de anomalía en este paso")
        w("")
        w("    SELECT @Leidas AS FilasLeidas, @Validas - (SELECT COUNT_BIG(*) FROM #cambios) AS FilasSinCambio;")
        w("END;")
        return "\n".join(L) + "\nGO\n"
