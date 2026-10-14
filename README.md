# ADN · Consolidación de datos (ETL)

Scripts reproducibles de limpieza, deduplicación, transformación y carga hacia el modelo unificado
**ADN_Unificado**. Proyecto de Práctica Profesional Supervisada (EIF408, UNA), American Data Networks S.A.

> **Solo copias controladas.** El ETL se niega a ejecutarse si no está dentro del contenedor aislado,
> conectado a la red interna `etl-red`, contra `sandbox-sql` / `mongo-lab` y contra una base marcada
> con `ctl.Entorno = 'SANDBOX'`. Nunca se ejecuta sobre datos productivos.

## Estructura

| Carpeta | Contenido |
|---|---|
| `sql/00_modelo` | DDL del modelo unificado v1.2 y correcciones del Sprint 2 |
| `sql/01_control` | Objetos de control del ETL: bitácora por registro, lote, funciones de normalización |
| `sql/10_pasos` | Un procedimiento por paso de carga (**generados**, no se editan a mano) |
| `sql/90_verificacion` | Verificaciones de solo lectura: pruebas del modelo, pruebas de funciones de limpieza, diagnósticos por grupo |
| `sql/95_mantenimiento` | Mantenimiento del sandbox (p. ej. cerrar lotes colgados tras una caída) |
| `docs` | [Runbook del ETL](docs/Runbook_ETL.md): orden de carga, 24 meses de llamadas, verificaciones del DoD, recuperación |
| `etl/adn_etl` | Runner en Python: especificaciones de los pasos, generador, dry-run/confirm/rollback, verificaciones |
| `etl/adn_etl/datos` | Matriz de correspondencia aprobada (Sprint 2), que los pasos siguen al pie de la letra |
| `docker` | Imagen del ETL y preparación de la red aislada |
| `rollback`, `reportes` | Archivos generados en cada ejecución (no se versionan) |

## Patrón dry-run / confirm / rollback

1. **Dry-run**: el paso se ejecuta completo dentro de una transacción y se revierte. Se informa cuántas
   filas se insertarían, actualizarían, descartarían y cuántas anomalías habría. Queda constancia en `ctl.Lote`
   (estado `Simulado`).
2. **Confirm**: hace primero el dry-run, pide escribir `CONFIRMAR` y aplica el paso en una transacción. Cada
   registro afectado queda en `ctl.Bitacora` (con los valores anteriores si se actualizó).
3. **Rollback**: al confirmar se genera `rollback/lote_NNNNNN_<paso>.sql`, que restaura los valores anteriores,
   elimina lo insertado y marca el lote como `Revertido`. Se puede ensayar con `--ensayo`. Los lotes se revierten
   en orden inverso: el archivo se niega a ejecutar si un lote posterior tocó los mismos registros.

Cada paso es **idempotente**: compara una huella del contenido (`HashContenido`) y solo actualiza lo que cambió,
así que una segunda ejecución sobre la misma copia no cambia nada.

## Puesta en marcha (Windows, PowerShell)

```powershell
# 1. Configuración (no se versiona)
Copy-Item config/entorno.ejemplo.env config/entorno.env   # completar las claves del sandbox

# 2. Red aislada + imagen
./docker/preparar.ps1

# 3. Verificar que solo alcanza el sandbox e instalar los objetos de control y los pasos
./etl.ps1 verificar-entorno
./etl.ps1 instalar

# 4. Ejecutar
./etl.ps1 plan
./etl.ps1 ejecutar --paso ref_Provincia --modo dry-run
./etl.ps1 ejecutar --paso ref_Provincia --modo confirm
./etl.ps1 lotes
./etl.ps1 rollback --lote 3 --ensayo
```

## Verificaciones del DoD

```powershell
./etl.ps1 ejecutar --todos --modo confirm --si
./etl.ps1 instantanea --nombre corrida1
./etl.ps1 ejecutar --todos --modo confirm --si     # segunda ejecución: 0 insertadas / 0 actualizadas
./etl.ps1 instantanea --nombre corrida2
./etl.ps1 comparar --a corrida1 --b corrida2       # IDÉNTICAS
./etl.ps1 muestreo --n 10                          # trazabilidad a fuente y período (reporte .txt y .csv)
```

Cada corrida incluye además la **conciliación** del lote (leídas = válidas + excluidas; toda llave excluida con su
motivo en `ctl.Descarte`), y `sql/90_verificacion/pruebas_funciones.sql` prueba las funciones de limpieza con casos
sintéticos. Detalle en el [runbook](docs/Runbook_ETL.md).

## Agregar o cambiar un paso

Los pasos se definen en `etl/adn_etl/pasos/*.py`. Después de editar:

```powershell
./etl.ps1 generar      # regenera sql/10_pasos
./etl.ps1 instalar     # los instala en el sandbox
```
