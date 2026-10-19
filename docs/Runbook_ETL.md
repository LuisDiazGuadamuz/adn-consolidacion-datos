# Runbook del ETL · ADN_Unificado (Sprint 3)

Procedimiento de operación del ETL: orden de carga, cargas grandes por período, verificaciones del DoD
y recuperación ante fallos. **Todo se ejecuta solo en el sandbox** (`ETL_ENTORNO=SANDBOX`, marca `ctl.Entorno`,
red Docker interna `etl-red`). Nunca sobre producción.

---

## 1. Preparar un sandbox nuevo

1. `config/entorno.env` a partir de `config/entorno.ejemplo.env` (no se versiona; las claves no se comparten).
2. `./docker/preparar.ps1` (red aislada e imagen `adn-etl`).
3. Modelo y correcciones, **una vez y en orden** (el comando `instalar` no los ejecuta):

   | Script | Qué hace |
   |---|---|
   | `sql/00_modelo/01_modelo_unificado.sql` | DDL del modelo v1.2 |
   | `02_correccion_cliente_cedula.sql` | Cliente por cédula |
   | `03_correccion_evento_conexion.sql` | EventoConexion ligado al cliente (customer_name = ID de contacto de Books) |
   | `04_correccion_decisiones.sql` | Decisiones aprobadas |
   | `05_correccion_circuito_no_unico.sql` | Circuito no único |
   | `06_correccion_linaje_por_lote.sql` | Linaje por lote |
   | `07_correccion_regla_circuito.sql` | ID-01 v1.1: circuito con guiones (varchar(14)); se ejecuta antes y después de recargar |

   ```powershell
   docker cp sql\00_modelo\03_correccion_evento_conexion.sql sandbox-sql:/tmp/c.sql
   docker exec -it sandbox-sql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -C -I -i /tmp/c.sql
   ```
4. `./etl.ps1 verificar-entorno` y `./etl.ps1 instalar` (objetos de control + los procedimientos de `sql/10_pasos`).

> `instalar` instala los procedimientos **tal como están versionados**. Si se cambia un paso en
> `etl/adn_etl/pasos/*.py` hay que correr `./etl.ps1 generar` y versionar `sql/10_pasos` en el mismo commit.

---

## 2. Orden de carga completo

```powershell
./etl.ps1 plan                                            # lista los pasos en orden
./etl.ps1 ejecutar --todos --modo confirm --si            # todos los pasos que no exigen período
```

`--todos` y `--desde-paso` **saltan** los pasos marcados "requiere período" (tablas grandes) y lo avisan.
Esos pasos se cargan aparte, por período (`--hasta` no incluye ese día):

| Paso | Volumen aprox. | Período recomendado |
|---|---|---|
| `core_UbicacionFlota` | 2,5 M filas (nov-2023 → sep-2026) | por año |
| `core_Llamada_Historico` | 47,2 M (jun-2022 → dic-2025) | por mes |
| `core_Llamada_SQL` | 10,3 M (2026) | por mes |
| `core_Llamada` (MongoDB) | según la copia | por mes, después de `stage-mongo` |

```powershell
./etl.ps1 ejecutar --paso core_UbicacionFlota --modo confirm --si --desde 2025-01-01 --hasta 2026-01-01
```

Si una carga tumba Docker (memoria), se divide el período a la mitad (semestre, quincena).

---

## 3. Carga de 24 meses de llamadas (decisión D7)

El modelo guarda **24 meses en línea**; lo anterior queda consultable en `ADNApp.Telephony_cdr_historico`.
Las tres fuentes están **encadenadas por fecha, sin solapes** (ajuste a D1):

| Fuente | Paso | Toma las llamadas |
|---|---|---|
| `ADNApp.Telephony_cdr_historico` | `core_Llamada_Historico` | anteriores a la primera fecha de `Telephony_cdr` y de MongoDB |
| `ADNApp.Telephony_cdr` | `core_Llamada_SQL` | anteriores a la primera fecha de la copia de MongoDB |
| MongoDB (copia `stg.mongo_Telephony_cdr`) | `core_Llamada` | desde la primera fecha de la copia |

Cada paso aplica su corte por dentro, así que **se pueden correr los tres pasos con el mismo mes**: los que no
corresponden leen 0 filas. Procedimiento para el ambiente destino:

```powershell
# 1. Copia de MongoDB del período (solo lectura en MongoDB), por mes
./etl.ps1 stage-mongo --coleccion Telephony_cdr --desde 2026-09-01 --hasta 2026-10-01

# 2. Carga mes a mes de los últimos 24 meses
$inicio = Get-Date -Year 2024 -Month 11 -Day 1
for ($i = 0; $i -lt 24; $i++) {
    $d = $inicio.AddMonths($i).ToString("yyyy-MM-dd")
    $h = $inicio.AddMonths($i + 1).ToString("yyyy-MM-dd")
    foreach ($p in "core_Llamada_Historico", "core_Llamada_SQL", "core_Llamada") {
        ./etl.ps1 ejecutar --paso $p --modo confirm --si --desde $d --hasta $h
        if ($LASTEXITCODE -ne 0) { throw "Falló $p $d" }
    }
}
./etl.ps1 lotes --ultimos 80
```

- Un mes ronda 0,75–0,95 M llamadas (≈ 6–9 % se descarta como idéntica, DD-01).
- Revisar espacio cada 6 meses (`EXEC sp_spaceused` en ADN_Unificado) y que el disco tenga margen.
- Si un mes falla a la mitad, la transacción se deshace: se vuelve a correr ese mes (la carga es idempotente).
- En el sandbox se cargó un mes por fuente (oct-2026 MongoDB, abr-2026 Telephony_cdr, abr-2025 histórico).

---

## 3b. Cambio de una regla de identidad (p. ej. ID-01)

Un cambio en la normalización del circuito o de la cédula cambia qué servicio y qué cliente corresponde a cada
registro, así que se recarga desde el servicio hacia adelante:

```powershell
git pull
./etl.ps1 instalar                                   # nueva ctl.fn_Circuito y pasos regenerados
# corrección del modelo (sqlcmd): sql/00_modelo/07_correccion_regla_circuito.sql  (antes de recargar)
./etl.ps1 ejecutar --desde-paso core_Servicio --modo confirm --si
# llamadas: repetir los meses cargados (el circuito liga cada llamada a su servicio)
./etl.ps1 ejecutar --paso core_Llamada_Historico --modo confirm --si --desde 2025-04-01 --hasta 2025-05-01
./etl.ps1 ejecutar --paso core_Llamada_SQL --modo confirm --si --desde 2026-04-01 --hasta 2026-05-01
./etl.ps1 ejecutar --paso core_Llamada --modo confirm --si --desde 2026-10-01 --hasta 2026-11-01
# corrección del modelo otra vez (valida CK_Servicio_Circuito contra los circuitos nuevos)
```

Después: `pruebas_funciones.sql`, `muestreo`, la comparación de instantáneas y la `bitacora` como evidencia.

## 4. Verificaciones del DoD

| Verificación | Cómo | Resultado esperado |
|---|---|---|
| Funciones de limpieza | `sql/90_verificacion/pruebas_funciones.sql` (sqlcmd) | todos los casos `PASA` |
| Conciliación por lote | automática en cada corrida (línea "Conciliación") y columnas `Excl` / `SinMot` de `./etl.ps1 lotes` | `llaves excluidas sin motivo registrado: 0` |
| Trazabilidad a fuente y período | `./etl.ps1 muestreo --n 10` → `reportes/*_muestreo_trazabilidad.txt/.csv` | origen y lote+bitácora al 100 %; período en toda tabla con fecha |
| Reproducibilidad | `instantanea` → segunda corrida → `instantanea` → `comparar` | `IDÉNTICAS`; la segunda corrida da 0 insertadas / 0 actualizadas |
| Rollback | `./etl.ps1 rollback --lote N --ensayo` y luego sin `--ensayo` | el lote queda `Revertido` y la tabla vuelve a su estado anterior |
| Bitácora técnica de ejecución | `./etl.ps1 bitacora` → `reportes/bitacora_<fecha>/` (`bitacora_ejecucion.md` + CSV) | historial de lotes, estado vigente por paso, descartes, anomalías, rollbacks y fallidos |

```powershell
./etl.ps1 instantanea --nombre corrida1
./etl.ps1 ejecutar --todos --modo confirm --si
./etl.ps1 instantanea --nombre corrida2
./etl.ps1 comparar --a corrida1 --b corrida2
```

Los scripts de `sql/90_verificacion` son de **solo lectura** y solo devuelven conteos (sin datos de clientes).

---

## 5. Recuperación ante fallos

| Síntoma | Causa probable | Qué hacer |
|---|---|---|
| `error waiting for container: unexpected EOF`, error 500 de `docker` | Docker/WSL sin memoria (carga demasiado grande) | `wsl --shutdown`, abrir Docker Desktop, `docker start sandbox-sql mongo-lab`; repetir con un período más corto |
| Lotes en estado `EnCurso` después de una caída | la conexión se cortó; SQL Server ya deshizo la transacción | `sql/95_mantenimiento/cerrar_lotes_colgados.sql` (los marca `Fallido`), solo sin corridas en marcha |
| Error 468 (intercalación) | comparación entre la base de origen (`SQL_Latin1_General_CP1_CI_AS`) y el modelo (`Modern_Spanish_CI_AS`) | agregar `COLLATE DATABASE_DEFAULT` en el paso, `generar`, `instalar` |
| Error 207 "Invalid column name" en un paso nuevo | corrección del modelo no aplicada en el sandbox | aplicar el script de `sql/00_modelo` correspondiente (sección 1) |
| Un cambio en el código "no se aplica" | se editó `pasos/*.py` pero no se regeneró | `./etl.ps1 generar`, commit de `sql/10_pasos`, `git pull`, `./etl.ps1 instalar` |
| `CHECK constraint ... AtributosJSON` | texto suelto donde va JSON | revisar la fila de la matriz que manda la columna a `AtributosExtendidos` |
| Saltos de ~1000 en el número de lote | caché de IDENTITY tras reiniciar SQL Server | normal, no requiere acción |

---

## 6. Seguridad

- Las claves viven solo en `config/entorno.env` (no versionado). No se pegan en chats, tickets ni informes.
- Las salidas para informes llevan solo conteos y códigos técnicos: sin cédulas, nombres, teléfonos ni IPs.
- Cambios en producción: solo con autorización explícita de José Hernández.
