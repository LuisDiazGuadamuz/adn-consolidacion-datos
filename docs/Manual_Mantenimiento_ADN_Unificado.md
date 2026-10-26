# Manual de mantenimiento · ADN_Unificado

American Data Networks S.A. · Luis Felipe Díaz Guadamuz · Versión 1.0 (26/10/2026)

Este manual explica cómo volver a ejecutar, verificar, respaldar, revertir y extender la unificación de datos
`ADN_Unificado`. Va dirigido a la persona de ADN que mantenga la base después de la práctica: alguien que conoce
SQL Server y puede usar PowerShell y Docker, pero no participó en el proyecto.

> **Regla de oro.** Todo lo que describe el manual se ejecuta en el **sandbox**: un SQL Server y un MongoDB en
> contenedores Docker, con copias de las bases de origen. El ETL se niega a correr si la base no tiene la marca
> `ctl.Entorno = 'SANDBOX'` o si los servidores no son `sandbox-sql` y `mongo-lab`. Llevar la unificación a
> producción es una decisión aparte que requiere autorización de José Hernández (sección 9).

---

## 1. Qué hay y dónde está

| Pieza | Dónde | Para qué |
|---|---|---|
| Repositorio | `LuisDiazGuadamuz/adn-consolidacion-datos` (privado) | Código del ETL, scripts SQL, documentación |
| Carpeta de trabajo | `C:\Sandbox\adn-consolidacion-datos` | Copia local del repositorio; desde aquí se corre todo |
| Configuración | `config/entorno.env` (no se versiona) | Servidor, usuario y clave del sandbox. Se crea desde `config/entorno.ejemplo.env` |
| SQL Server del sandbox | contenedor `sandbox-sql` | Copias de origen (`ADNApp`, `ADNPayV2`, `Navsat`, `ZBooks_Mirror`, `Zoho_Mirror`, `ZCRM2Trengo`, `History_Tables`) y la base unificada `ADN_Unificado` |
| MongoDB del sandbox | contenedor `mongo-lab` | Copia de `app.data.cr` (llamadas desde 2024) |
| Contenedor del ETL | imagen `adn-etl`, red interna `etl-red` | Ejecuta el ETL; no tiene salida a internet ni a producción |

Esquemas de `ADN_Unificado`:

| Esquema | Contenido |
|---|---|
| `core` | 55 tablas de negocio (clientes, servicios, facturación, telefonía, operación, flota) |
| `ref` | 14 catálogos (provincias, tipo de cambio, impuestos, usuarios, tarifas…) |
| `ctl` | 10 tablas de control: reglas, lotes, bitácora, descartes, anomalías, linaje, reconciliación |
| `stg` | Copias de trabajo de MongoDB (se recargan por período; no son parte del modelo) |
| `etl` | Un procedimiento almacenado por paso de carga (91 pasos: 87 sin período y 4 de tablas grandes que se cargan por período) |
| `rag` | Vistas para ask.data.cr con solo las columnas autorizadas (sección 8) |

Documentos de referencia: diccionario y matriz (`docs/Diccionario_Matriz_ADN_Unificado.xlsx`), catálogo de reglas
(hoja *Reglas*), [runbook técnico](Runbook_ETL.md) y los informes de cierre de cada sprint.

---

## 2. Cómo funciona una carga

Cada **paso** lee una tabla de origen, aplica las reglas aprobadas (catálogo en la hoja *Reglas*) y escribe una
tabla del modelo. Siempre en el mismo orden:

1. Normaliza: fechas con zona horaria, montos con moneda, cédulas y circuitos con su regla, texto recortado.
2. Separa lo que no se carga (duplicados, eliminados en el origen, sin referencia obligatoria) y lo registra en
   `ctl.Descarte` con su regla.
3. Compara con lo que ya está en el modelo por una huella del contenido (`HashContenido`): inserta lo nuevo,
   actualiza lo que cambió y deja igual lo demás. Por eso **repetir una carga no cambia nada** si el origen no cambió.
4. Registra en `ctl.Bitacora` cada fila insertada o actualizada, con sus valores anteriores, y en `ctl.Anomalia`
   los valores que una regla marcó para revisión.

Hay dos modos:

| Modo | Qué hace |
|---|---|
| `dry-run` (ensayo) | Ejecuta todo dentro de una transacción y la deshace. Informa cuánto insertaría, actualizaría y descartaría. No cambia datos |
| `confirm` | Ejecuta el ensayo, pide escribir `CONFIRMAR` (o `--si`) y aplica. Genera el archivo `rollback/lote_NNNNNN_<paso>.sql` |

Cada ejecución es un **lote** (`ctl.Lote`) con su estado: `Simulado`, `Exitoso`, `Fallido` o `Revertido`.

---

## 3. Preparar el entorno (una vez por equipo)

1. Instalar Docker Desktop y Git. Clonar el repositorio en `C:\Sandbox\adn-consolidacion-datos`.
2. Copiar `config/entorno.ejemplo.env` a `config/entorno.env` y completar las claves del sandbox.
   **Las claves no se pegan en chats, tickets ni informes.**
3. Restaurar las copias de las bases de origen en `sandbox-sql` y la copia de MongoDB en `mongo-lab`.
4. `./docker/preparar.ps1` crea la red aislada y la imagen del ETL.
5. Crear el modelo con los scripts de `sql/00_modelo`, **una vez y en orden** (01 a 10; detalle en el runbook,
   sección 1). Cada script es idempotente: si ya se aplicó, no hace nada.
6. Comprobar e instalar:

```powershell
./etl.ps1 verificar-entorno     # debe confirmar SANDBOX, contenedor, hosts permitidos y marca ctl.Entorno
./etl.ps1 instalar              # objetos de control, funciones y los 91 procedimientos de carga
```

---

## 4. Volver a ejecutar la unificación

### 4.1 Cuándo

La empresa no tiene ventanas de mantenimiento definidas (Josué Pérez, 26/10/2026), así que se ejecuta cuando se
necesiten datos al día: por ejemplo, después de traer copias nuevas de las bases de origen. La corrida completa
tarda unos 90 minutos en el sandbox; el límite aprobado es 2 horas, y 15 minutos por cada mes de llamadas.

### 4.2 Actualizar las copias de origen

Restaurar en `sandbox-sql` las copias nuevas de las bases de origen **con los mismos nombres** y, para las
llamadas recientes, copiar el período de MongoDB:

```powershell
./etl.ps1 stage-mongo --coleccion Telephony_cdr --desde 2026-11-01 --hasta 2026-12-01
```

### 4.3 Corrida completa

```powershell
git pull
./etl.ps1 instalar
./etl.ps1 ejecutar --todos --modo dry-run          # ensayo: revisar insertadas / actualizadas / descartadas
./etl.ps1 ejecutar --todos --modo confirm --si     # aplica los pasos que no requieren período
```

Los pasos de tablas grandes se cargan aparte, por período (`--hasta` no incluye ese día):

```powershell
./etl.ps1 ejecutar --paso core_UbicacionFlota --modo confirm --si --desde 2026-01-01 --hasta 2027-01-01
./etl.ps1 ejecutar --paso core_Llamada        --modo confirm --si --desde 2026-11-01 --hasta 2026-12-01
```

Para las llamadas, los tres pasos (`core_Llamada_Historico`, `core_Llamada_SQL`, `core_Llamada`) se pueden correr
con el mismo mes: cada uno toma solo su tramo de fechas. El procedimiento de los 24 meses en línea (decisión D7)
está en el runbook, sección 3.

### 4.4 Solo una parte

```powershell
./etl.ps1 plan                                            # lista los pasos en orden
./etl.ps1 ejecutar --paso core_Factura --modo confirm --si
./etl.ps1 ejecutar --desde-paso core_Servicio --modo confirm --si   # desde un paso hasta el final
```

Si se recarga un paso del que dependen otros (por ejemplo `core_Servicio` o `core_Cliente`), se recargan también
los siguientes: `--desde-paso` lo hace en orden.

---

## 5. Verificar después de cada carga

| Verificación | Comando | Resultado esperado |
|---|---|---|
| Lotes | `./etl.ps1 lotes --ultimos 40` | Todos `Exitoso`; columna `SinMot` en 0 |
| Reconciliación origen-destino | `./etl.ps1 reconciliar` | ≥ 99 % conciliado; 0 sin conciliar; 0 en el modelo sin origen |
| Duplicados | `./etl.ps1 duplicados` | 0 duplicados de la línea base en el modelo |
| Integridad referencial | `./etl.ps1 integridad` | 8 de 8 pruebas aprobadas |
| Rendimiento | `./etl.ps1 rendimiento` | Corrida completa ≤ 120 min; un mes de llamadas ≤ 15 min |
| Reproducibilidad | `instantanea` → repetir la carga → `instantanea` → `comparar` | `IDÉNTICAS` |
| Bitácora técnica | `./etl.ps1 bitacora` | Reporte en `reportes/bitacora_<fecha>/` |
| Estructura vs diccionario | `sql/90_verificacion/diccionario_vs_bd.sql` | Conteos iguales a los del diccionario |

Los reportes quedan en `reportes/` (no se versionan) y solo llevan conteos y nombres técnicos.

Las anomalías vigentes (valores que una regla marcó, como cédulas inválidas o circuitos que no cumplen el patrón)
se consultan en `ctl.vw_AnomaliaVigente`. No son errores de la carga: son datos del origen que conviene corregir
en el sistema de origen.

---

## 6. Respaldo y reversión

Hay tres niveles, de lo más fino a lo más amplio:

| Nivel | Cuándo usarlo | Cómo |
|---|---|---|
| Ensayo | Antes de cualquier carga | `--modo dry-run`: no cambia datos |
| Reversión de un lote | Una carga confirmada salió mal | `./etl.ps1 rollback --lote N` |
| Respaldo completo | Antes de un cambio grande del modelo o de una recarga total | `sql/95_mantenimiento/respaldo_adn_unificado.sql` |

### 6.1 Revertir un lote

Cada `confirm` genera `rollback/lote_NNNNNN_<paso>.sql` desde `ctl.Bitacora`. Ese archivo restaura los valores
anteriores de las filas actualizadas, elimina las insertadas, vuelve a insertar las retiradas, borra los descartes
y anomalías del lote y lo marca `Revertido`.

```powershell
./etl.ps1 lotes --ultimos 20               # identificar el lote
./etl.ps1 rollback --lote 6324 --ensayo    # ejecuta todo y lo deshace: muestra qué haría
./etl.ps1 rollback --lote 6324             # revierte
```

- Los lotes se revierten **en orden inverso**: si un lote posterior tocó los mismos registros, el archivo se niega
  a ejecutar y hay que revertir primero el posterior.
- Solo se revierten lotes `Exitoso`. Los ensayos (`Simulado`) no cambiaron nada.
- El resultado queda en `reportes/<fecha>_rollback_loteN.txt`.
- Después de revertir, se corrige la causa y se vuelve a cargar el paso.

### 6.2 Respaldo completo

```powershell
docker cp sql\95_mantenimiento\respaldo_adn_unificado.sql sandbox-sql:/tmp/r.sql
docker exec -it sandbox-sql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -C -I -i /tmp/r.sql | Tee-Object reportes\respaldo_<fecha>.txt
docker cp sandbox-sql:/var/opt/mssql/data/ADN_Unificado_respaldo.bak C:\Sandbox\respaldos\
```

El script hace un respaldo `COPY_ONLY` con sumas de verificación y lo comprueba con `RESTORE VERIFYONLY`. Si la
instancia tiene otra carpeta de respaldos, la ruta aparece en la salida.

> **El respaldo contiene datos de clientes.** Se guarda solo en el equipo del sandbox; no se sube al repositorio
> ni a servicios externos.

### 6.3 Restaurar

Para comprobar un respaldo sin tocar la base, `sql/95_mantenimiento/prueba_restauracion.sql` lo restaura como
`ADN_Unificado_Prueba`, compara las filas de cada tabla y borra la copia (necesita espacio libre igual al tamaño
de la base).

Para volver la base al estado del respaldo (por ejemplo, después de un cambio de modelo fallido), en SSMS:

```sql
USE master;
ALTER DATABASE ADN_Unificado SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
RESTORE DATABASE ADN_Unificado FROM DISK = N'/var/opt/mssql/data/ADN_Unificado_respaldo.bak' WITH REPLACE, CHECKSUM;
ALTER DATABASE ADN_Unificado SET MULTI_USER;
```

Después: `./etl.ps1 verificar-entorno` y `./etl.ps1 lotes` para confirmar que la base quedó en el estado esperado.

### 6.4 Prueba registrada

La prueba del procedimiento (respaldo, restauración en base aparte y reversión del lote 6324 con su recarga) se
registra en el informe final del proyecto, con sus reportes.

---

## 7. Extender la unificación

Toda extensión sigue el mismo ciclo: **cambiar la especificación → generar → aplicar en el sandbox → ensayar →
confirmar → verificar → documentar.** Las especificaciones son código Python; los SQL de `sql/10_pasos` y
`sql/20_validacion` se generan y **no se editan a mano**.

| Archivo | Qué define |
|---|---|
| `etl/adn_etl/modelo.py` | Tablas y columnas del modelo (fuente de verdad del DDL y del diccionario) |
| `etl/adn_etl/datos/matriz_correspondencia.csv` | Qué columna de origen va a qué columna del modelo, con su regla |
| `etl/adn_etl/pasos/*.py` | Los pasos de carga (uno por tabla de origen) |
| `etl/adn_etl/descripciones.py` | Descripciones del diccionario que no están en `modelo.py` |
| `etl/adn_etl/rag.py` | Qué columnas puede ver ask.data.cr |
| `sql/00_modelo/NN_*.sql` | Cambios del modelo en una base existente (uno por cambio, idempotente) |

### 7.1 Promover un atributo extendido a columna propia

Muchas columnas de Zoho se guardan en `AtributosExtendidos` (JSON) porque nadie las usaba en reportes
(decisión del 12/10). Si una empieza a usarse:

1. `modelo.py`: agregar la columna a la tabla, con tipo, descripción y regla.
2. Matriz: cambiar la fila de `Atributo extendido` a `Mapeada`, con su columna destino.
3. Nuevo `sql/00_modelo/NN_<cambio>.sql` con `IF COL_LENGTH(...) IS NULL ALTER TABLE ... ADD ...`.
4. `python herramientas/gen_ddl.py` para que el DDL completo (`01_modelo_unificado.sql`) también la incluya.
5. `./etl.ps1 generar`, aplicar el script NN, `./etl.ps1 instalar`.
6. Recargar el paso: `./etl.ps1 ejecutar --paso <paso> --modo dry-run` y luego `confirm`. Como el contenido cambia,
   se actualizan todas las filas del paso una vez.

### 7.2 Agregar una tabla de origen a una tabla existente del modelo

1. Copiar la tabla de origen al sandbox (en su base de origen).
2. Agregar sus columnas a la matriz con su disposición: una fila por columna; ninguna sin disposición.
3. En el módulo de `pasos/` del área, agregar un paso. La mayoría se arma con `paso_matriz(...)`, que lee la matriz:

```python
paso_matriz("core_Gasto", 430, "core.Gasto", _B, "ZBooks_Mirror", "expenses", "e", llave="expense_id",
            fecha_tc="q.Fecha", depende=["core_Proveedor", "core_ClienteOrigen"],
            descripcion="Gastos de Books con sus etiquetas en JSON.")
```

   - `orden` define cuándo corre (después de sus dependencias).
   - `llave` es la columna de origen que identifica el registro (queda en `FuenteLlave`).
   - `override={...}` reemplaza la expresión de una columna; `filtros_extra` excluye filas con regla y motivo.
   - Si es una tabla grande, `requiere_periodo=True` y `periodo_origen="<columna de fecha>"`.
4. `./etl.ps1 generar` (crea el procedimiento y actualiza las consultas de reconciliación), `./etl.ps1 instalar`.
5. Ensayo, confirmación y las verificaciones de la sección 5 (en especial `reconciliar --paso <paso>`).

### 7.3 Agregar una tabla nueva al modelo

Igual que 7.2, pero antes se define la tabla en `modelo.py` con `tabla(...)` (área, descripción, grano, columnas;
el linaje se agrega solo) y se crea con un script `sql/00_modelo/NN_*.sql`, como hizo la corrección 04 con
`core.MinutosContratadosHistorico`. Las llaves foráneas se declaran con `fk(...)`.

### 7.4 Agregar un sistema de origen nuevo

1. Inventario y perfilado de sus tablas (como en el Sprint 1): qué contiene, llaves, vacíos, duplicados.
2. Copia al sandbox; nunca se lee desde producción.
3. Filas en la matriz para todas sus columnas (la tabla se registra sola en `ctl.Fuente` en su primer lote).
4. Decidir cómo se empareja con los clientes existentes. Las reglas ID-01 a ID-10 lo resuelven por circuito o por
   cédula; nunca por nombre, correo o teléfono (ID-05). Si hace falta una regla nueva, se aprueba antes y se
   agrega al catálogo (`ctl.Regla`).
5. Pasos (7.2), verificaciones (sección 5) y diccionario (7.6).

### 7.5 Cambiar una regla aprobada

Un cambio de regla lo aprueba José Hernández y se registra en `ctl.Regla` con su versión. Si afecta la identidad
(circuito o cédula), se recarga desde el servicio en adelante, como se hizo con ID-01 v1.1 (runbook, sección 3b).

### 7.6 Después de cualquier extensión

```powershell
./etl.ps1 generar          # también regenera el diccionario y las vistas de ask.data.cr
git add -A; git commit -m "<qué cambió y por qué>"; git push
```

- Revisar en `docs/Diccionario_Matriz_ADN_Unificado.xlsx` (hoja *Diccionario*) la columna **ask.data.cr / RAG**
  de lo nuevo. Si es un dato personal o texto libre que no quedó bien clasificado, se ajusta en `rag.py`.
- Aplicar `sql/30_rag/vistas_rag.sql` si cambiaron las vistas.
- Anotar el cambio en la hoja *Cambios* (lista `CAMBIOS` de `herramientas/gen_diccionario.py`).

---

## 8. Fuente de datos para ask.data.cr

ask.data.cr es el asistente interno de ADN que responde preguntas con documentos de la empresa (RAG). Según la
decisión D6, la base unificada guarda los datos completos con acceso restringido y lo que se entrega a un corpus
RAG va sin datos que identifiquen a personas.

- La clasificación de cada columna está en el diccionario (columna **ask.data.cr / RAG**):
  `Disponible`, `Requiere anonimización`, `No: dato personal` o `No: técnico`.
- `sql/30_rag/vistas_rag.sql` crea el esquema `rag` con una vista por tabla, con **solo** las columnas
  `Disponible`, y el rol `rag_lector`, que puede leer el esquema `rag` y nada más.
- El usuario con el que ask.data.cr se conecte debe ser miembro de `rag_lector` y de ningún otro rol con acceso a
  `core`, `ref` o `ctl`.
- Las columnas `Requiere anonimización` (descripciones de casos, notas, tareas) no están en las vistas. Para
  incluirlas hace falta antes un proceso de anonimización y su aprobación.

---

## 9. Paso a producción (fuera del alcance de la práctica)

El ETL está construido para correr solo en el sandbox: así se aprobó y así se validó. Llevar la base unificada a
un entorno productivo implica, como mínimo: autorización explícita de José Hernández; un servidor y un usuario
de servicio definidos por ADN; revisar las protecciones de `etl/adn_etl/seguridad.py` para ese entorno; un plan de
respaldos de la empresa; y repetir las verificaciones de la sección 5 sobre ese entorno.

---

## 10. Problemas frecuentes

| Síntoma | Causa probable | Qué hacer |
|---|---|---|
| `unexpected EOF` o error 500 de Docker | Docker sin memoria (carga demasiado grande) | `wsl --shutdown`, abrir Docker Desktop, `docker start sandbox-sql mongo-lab`; repetir con un período más corto |
| Lotes en `EnCurso` después de una caída | La conexión se cortó; SQL Server ya deshizo la transacción | `sql/95_mantenimiento/cerrar_lotes_colgados.sql`, solo si no hay corridas en marcha |
| Error 468 (intercalación) | Comparación entre una base de origen y el modelo | `COLLATE DATABASE_DEFAULT` en el paso, `generar`, `instalar` |
| Error 207 "Invalid column name" | Falta aplicar un script de `sql/00_modelo` | Aplicarlo (sección 3, paso 5) |
| Un cambio en el código "no se aplica" | Se editó un paso pero no se regeneró | `./etl.ps1 generar`, commit, `./etl.ps1 instalar` |
| `El lote no está en estado Exitoso` al revertir | El lote ya se revirtió o era un ensayo | Revisar con `./etl.ps1 lotes` |
| `Lotes posteriores modificaron estos registros` | Se intenta revertir fuera de orden | Revertir primero los lotes posteriores del mismo paso |
| Saltos de ~1000 en el número de lote | Caché de IDENTITY tras reiniciar SQL Server | Normal |

---

## 11. Seguridad

- Las claves viven solo en `config/entorno.env`, que no se versiona ni se comparte.
- Los reportes y las verificaciones devuelven conteos y nombres técnicos: sin cédulas, nombres, teléfonos ni IPs.
- Los respaldos y las copias de origen contienen datos de clientes y no salen del equipo del sandbox.
- Las columnas de credenciales y tarjetas del CRM no se copian al modelo (IN-04). Se recomienda revisarlas en el
  origen.
- Cualquier cambio en producción requiere autorización explícita de José Hernández.
