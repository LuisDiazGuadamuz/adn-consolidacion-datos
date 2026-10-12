# -*- coding: utf-8 -*-
"""Pasos de usuarios, infraestructura, servicios, clientes, correspondencia y contactos. Orden 200-299.

Reglas de identidad aplicadas (catálogo v1.0 + decisiones D2, D8, D9):
  ID-01 servicio por circuito normalizado · ID-02 cliente por cédula · ID-03 un cliente con varios servicios
  ID-04 llaves de origen en core.ClienteOrigen · ID-05 orden circuito > cédula > sin correspondencia (nunca nombre,
  correo ni teléfono) · ID-06 Books hereda circuito/cédula del contacto · D2 _Extended principal, base completa
  solo ausentes y marcados · D8 clientes sin CRM marcados · D9 CRM manda en comercial/contacto, Books en fiscal,
  ADNPayV2 solo completa vacíos.
"""
from ..paso import Paso, Anomalia
from ..matriz import atributos

FECHA_DT2 = "ctl.fn_FechaCR(CONVERT(nvarchar(30), {c}, 126))"      # columnas datetime2 (hora de Costa Rica, D4)


def _f(col):
    return FECHA_DT2.format(c=col)


# ------------------------------------------------------------------ resolución de identidad (compartida)
# Construye #crm (cuentas), #circ (circuito → cuenta elegida) y #f (todas las fuentes de cliente con su llave de identidad).
IDENTIDAD = """
/* Cuentas del CRM: _Extended (principal) + base completa solo para cuentas ausentes (D2); sin eliminadas */
DROP TABLE IF EXISTS #crm;
SELECT x.* INTO #crm FROM (
    SELECT N'Accounts_Extended' AS Tab, a.id COLLATE DATABASE_DEFAULT AS Llave, a.Cedula_Jurida_Persona AS CedO, ctl.fn_Cedula(a.Cedula_Jurida_Persona) AS Ced,
           a.N_mero_Circuito AS CircO, ctl.fn_Circuito(a.N_mero_Circuito) AS Circ, ctl.fn_Texto(a.Estado) AS Estado,
           ctl.fn_Texto(a.Account_Name) AS Nombre, ctl.fn_Texto(a.Raz_n_Social) AS Razon, ctl.fn_Texto(a.Tipo_Fiscal) AS TipoFis,
           CAST(NULL AS bit) AS Exon, ctl.fn_Texto(a.Segmento_Cuenta) AS Segmento, ctl.fn_Texto(a.Industry) AS Industria,
           ctl.fn_FechaCR(CONVERT(nvarchar(30), a.Created_Time, 126)) AS Creada,
           ctl.fn_FechaCR(CONVERT(nvarchar(30), a.Modified_Time, 126)) AS Modificada,
           ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.Modified_Time DESC) AS rn
    FROM Zoho_Mirror.dbo.Accounts_Extended a
    UNION ALL
    SELECT N'Accounts', b.id COLLATE DATABASE_DEFAULT, b.Cedula_Jurida_Persona, ctl.fn_Cedula(b.Cedula_Jurida_Persona),
           b.N_mero_Circuito, ctl.fn_Circuito(b.N_mero_Circuito), ctl.fn_Texto(b.Estado),
           ctl.fn_Texto(b.Account_Name), ctl.fn_Texto(b.Raz_n_Social), ctl.fn_Texto(b.Tipo_Fiscal),
           ctl.fn_Bit(b.Exonerado), ctl.fn_Texto(b.Segmento_Cuenta), ctl.fn_Texto(b.Industry),
           ctl.fn_FechaCR(b.Created_Time), ctl.fn_FechaCR(b.Modified_Time),
           ROW_NUMBER() OVER (PARTITION BY b.id ORDER BY ctl.fn_FechaCR(b.Modified_Time) DESC)
    FROM Zoho_Mirror.dbo.Accounts b
    WHERE ISNULL(b.deleted, 0) = 0
      AND NOT EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.Accounts_Extended e WHERE e.id = b.id)
) x WHERE x.rn = 1;
CREATE CLUSTERED INDEX ix_crm ON #crm (Llave);

/* Circuito → cuenta: si el circuito está en varias cuentas se elige la activa más reciente (marcado como ambiguo) */
DROP TABLE IF EXISTS #circ;
SELECT Circ, Llave AS Cuenta, Tab, Cuentas INTO #circ FROM (
    SELECT Circ, Llave, Tab, COUNT(*) OVER (PARTITION BY Circ) AS Cuentas,
           ROW_NUMBER() OVER (PARTITION BY Circ ORDER BY CASE WHEN Estado = N'Activo' THEN 0 ELSE 1 END, Modificada DESC, Llave) AS rn
    FROM #crm WHERE Circ IS NOT NULL) z
WHERE rn = 1;
CREATE UNIQUE CLUSTERED INDEX ix_circ ON #circ (Circ);

/* Todas las fuentes de cliente con su llave de identidad (ID-05: circuito > cédula > sin correspondencia) */
DROP TABLE IF EXISTS #f;
CREATE TABLE #f (Sis varchar(20) COLLATE DATABASE_DEFAULT NOT NULL, Base nvarchar(128) COLLATE DATABASE_DEFAULT NOT NULL, Tab nvarchar(128) COLLATE DATABASE_DEFAULT NOT NULL, Llave nvarchar(200) COLLATE DATABASE_DEFAULT NOT NULL,
                 CedO nvarchar(255) COLLATE DATABASE_DEFAULT NULL, Ced varchar(12) COLLATE DATABASE_DEFAULT NULL, CircO nvarchar(255) COLLATE DATABASE_DEFAULT NULL, Circ varchar(12) COLLATE DATABASE_DEFAULT NULL,
                 CuentaCircuito nvarchar(200) COLLATE DATABASE_DEFAULT NULL, CuentasDelCircuito int NULL,
                 Nombre nvarchar(255) COLLATE DATABASE_DEFAULT NULL, Razon nvarchar(255) COLLATE DATABASE_DEFAULT NULL, TipoFis nvarchar(120) COLLATE DATABASE_DEFAULT NULL, Exon bit NULL,
                 Correo nvarchar(255) COLLATE DATABASE_DEFAULT NULL, Tel nvarchar(60) COLLATE DATABASE_DEFAULT NULL, Segmento nvarchar(120) COLLATE DATABASE_DEFAULT NULL, Industria nvarchar(120) COLLATE DATABASE_DEFAULT NULL,
                 Creada datetimeoffset(0) NULL, Modificada datetimeoffset(0) NULL,
                 RankCom tinyint NOT NULL, RankFis tinyint NOT NULL, Clave nvarchar(220) COLLATE DATABASE_DEFAULT NULL, Metodo varchar(20) COLLATE DATABASE_DEFAULT NULL,
                 CedHeredada bit NOT NULL DEFAULT 0,
                 KSis varchar(20) COLLATE DATABASE_DEFAULT NULL, KBase nvarchar(128) COLLATE DATABASE_DEFAULT NULL, KTab nvarchar(128) COLLATE DATABASE_DEFAULT NULL, KLlave nvarchar(200) COLLATE DATABASE_DEFAULT NULL);
INSERT #f (Sis, Base, Tab, Llave, CedO, Ced, CircO, Circ, Nombre, Razon, TipoFis, Exon, Segmento, Industria, Creada, Modificada, RankCom, RankFis, Clave, Metodo)
SELECT 'ZohoCRM', N'Zoho_Mirror', Tab, Llave, CedO, Ced, CircO, Circ, Nombre, Razon, TipoFis, Exon, Segmento, Industria, Creada, Modificada, 1, 2,
       CASE WHEN Ced IS NOT NULL THEN N'C:' + Ced ELSE N'A:' + Tab + N':' + Llave END, 'LLAVE_DIRECTA'
FROM #crm;

/* Books: un registro por contacto cliente (versión más reciente, DD-02) */
INSERT #f (Sis, Base, Tab, Llave, CedO, Ced, CircO, Circ, Nombre, Razon, TipoFis, Exon, Correo, Tel, Segmento, Creada, Modificada, RankCom, RankFis)
SELECT 'ZohoBooks', N'ZBooks_Mirror', N'contacts', c.contact_id, c.cf_identificaci_n_unformatted, ctl.fn_Cedula(c.cf_identificaci_n_unformatted),
       c.cf_circuit_number_unformatted, ctl.fn_Circuito(c.cf_circuit_number_unformatted),
       COALESCE(ctl.fn_Texto(c.customer_name), ctl.fn_Texto(c.contact_name)), ctl.fn_Texto(c.company_name),
       ctl.fn_Texto(c.cf_tipo_fiscal_unformatted), ctl.fn_Bit(c.cf_exonerado_unformatted),
       ctl.fn_Texto(c.email), COALESCE(ctl.fn_Texto(c.phone), ctl.fn_Texto(c.mobile)), ctl.fn_Texto(c.cf_segmento_unformatted),
       ctl.fn_FechaCR(c.created_time), ctl.fn_FechaCR(c.last_modified_time), 2, 1
FROM (SELECT x.*, ROW_NUMBER() OVER (PARTITION BY x.contact_id ORDER BY ctl.fn_FechaCR(x.last_modified_time) DESC, x.contact_name) AS rn
      FROM ZBooks_Mirror.dbo.contacts x WHERE x.contact_type = 'customer' AND NULLIF(LTRIM(x.contact_id), '') IS NOT NULL) c
WHERE c.rn = 1;

/* ADNPayV2: contrataciones aprobadas (solo completan vacíos, D9) */
INSERT #f (Sis, Base, Tab, Llave, CedO, Ced, Nombre, Correo, Tel, Creada, Modificada, RankCom, RankFis)
SELECT 'ADNPayV2', N'ADNPayV2', N'Customer', CAST(p.[index] AS nvarchar(200)), p.id, ctl.fn_Cedula(p.id), ctl.fn_Texto(p.name),
       ctl.fn_Texto(p.email), COALESCE(ctl.fn_Texto(p.mobile), ctl.fn_Texto(p.phone)),
       ctl.fn_FechaCR(CONVERT(nvarchar(30), p.create_time, 126)), ctl.fn_FechaCR(CONVERT(nvarchar(30), p.create_time, 126)), 3, 3
FROM ADNPayV2.dbo.Customer p WHERE p.status = 'approved';

/* Emparejamiento de Books y ADNPayV2 */
UPDATE f SET f.CuentaCircuito = c.Cuenta, f.CuentasDelCircuito = c.Cuentas
FROM #f f JOIN #circ c ON c.Circ = f.Circ WHERE f.Sis <> 'ZohoCRM';
/* Cédula heredada (ID-02 + D9, Books manda en lo fiscal): cuenta del CRM sin cédula válida toma la cédula de los
   registros ligados a ella (Books por circuito, app.data.cr por id de Zoho) solo si todos traen la MISMA cédula.
   El valor original de la cuenta no cambia (core.ClienteOrigen.CedulaOriginal); se marca con anomalía ID-02. */
DROP TABLE IF EXISTS #her;
SELECT Cuenta, MIN(Ced) AS Ced, COUNT(DISTINCT Ced) AS Cedulas INTO #her FROM (
    SELECT f.CuentaCircuito AS Cuenta, f.Ced FROM #f f WHERE f.Sis = 'ZohoBooks' AND f.CuentaCircuito IS NOT NULL AND f.Ced IS NOT NULL
    UNION ALL
    SELECT ctl.fn_Texto(z.ZohoID), ctl.fn_Cedula(z.IDCard) FROM ADNApp.dbo.ZohoEngine_zohocustomer z
    WHERE ctl.fn_Texto(z.ZohoID) IS NOT NULL AND ctl.fn_Cedula(z.IDCard) IS NOT NULL) x
GROUP BY Cuenta;
UPDATE f SET f.Ced = h.Ced, f.CedHeredada = 1, f.Clave = N'C:' + h.Ced
FROM #f f JOIN #her h ON h.Cuenta = f.Llave
WHERE f.Sis = 'ZohoCRM' AND f.Ced IS NULL AND h.Cedulas = 1;
UPDATE f SET f.Clave = k.Clave, f.Metodo = 'CIRCUITO'
FROM #f f JOIN #f k ON k.Sis = 'ZohoCRM' AND k.Llave = f.CuentaCircuito
WHERE f.Sis <> 'ZohoCRM' AND f.CuentaCircuito IS NOT NULL;
UPDATE #f SET Clave = N'C:' + Ced, Metodo = 'CEDULA' WHERE Clave IS NULL AND Ced IS NOT NULL;
UPDATE #f SET Clave = CASE Sis WHEN 'ZohoBooks' THEN N'B:' ELSE N'P:' END + Llave, Metodo = 'SIN_CORRESPONDENCIA' WHERE Clave IS NULL;
/* Una cédula sin cuenta del CRM: si existe, el método CEDULA solo cuenta como correspondencia con otro sistema */
UPDATE f SET f.Metodo = 'SIN_CORRESPONDENCIA'
FROM #f f WHERE f.Metodo = 'CEDULA' AND NOT EXISTS (SELECT 1 FROM #f g WHERE g.Clave = f.Clave AND g.Sis <> f.Sis);
/* Linaje del cliente al que pertenece cada registro (llave del MERGE de core.Cliente) */
UPDATE #f SET KSis = CASE LEFT(Clave, 2) WHEN N'C:' THEN 'Consolidado' WHEN N'A:' THEN 'ZohoCRM' WHEN N'B:' THEN 'ZohoBooks' ELSE 'ADNPayV2' END,
              KBase = CASE LEFT(Clave, 2) WHEN N'C:' THEN N'ADN_Unificado' WHEN N'A:' THEN N'Zoho_Mirror' WHEN N'B:' THEN N'ZBooks_Mirror' ELSE N'ADNPayV2' END,
              KTab = CASE LEFT(Clave, 2) WHEN N'C:' THEN N'Cedula' WHEN N'A:' THEN SUBSTRING(Clave, 3, CHARINDEX(N':', Clave, 3) - 3)
                          WHEN N'B:' THEN N'contacts' ELSE N'Customer' END,
              KLlave = CASE LEFT(Clave, 2) WHEN N'C:' THEN SUBSTRING(Clave, 3, 20) WHEN N'A:' THEN SUBSTRING(Clave, CHARINDEX(N':', Clave, 3) + 1, 200)
                            ELSE SUBSTRING(Clave, 3, 200) END;
CREATE CLUSTERED INDEX ix_f ON #f (Clave, RankCom, RankFis);
CREATE INDEX ix_f_llave ON #f (Sis, Llave) INCLUDE (KSis, KTab, KLlave);
"""


def _campo(col, rank):
    """OUTER APPLY que elige, para cada cliente, el primer valor no vacío según la prioridad D9."""
    return (f"OUTER APPLY (SELECT TOP 1 f.{col} AS v, f.Sis, f.Tab, f.Llave, f.Modificada FROM #f f "
            f"WHERE f.Clave = k.Clave AND f.{col} IS NOT NULL ORDER BY f.{rank}, f.Modificada DESC, f.Llave) AS x_{col}")


CAMPOS_CLIENTE = [  # (columna del modelo, columna en #f, prioridad)
    ("Nombre", "Nombre", "RankCom"), ("RazonSocial", "Razon", "RankFis"), ("TipoFiscal", "TipoFis", "RankFis"),
    ("Exonerado", "Exon", "RankFis"), ("Correo", "Correo", "RankCom"), ("Telefono", "Tel", "RankCom"),
    ("Segmento", "Segmento", "RankCom"), ("Industria", "Industria", "RankCom"),
]

SELECT_CLIENTE = (
    "SELECT p.KSis AS FuenteSistema, p.KBase AS FuenteBase, p.KTab AS FuenteTabla, p.KLlave AS FuenteLlave,\n"
    "       k.Desde AS FechaDato,\n"
    "       CASE WHEN LEFT(k.Clave, 2) = N'C:' THEN SUBSTRING(k.Clave, 3, 20) END AS Cedula,\n"
    "       CASE WHEN LEFT(k.Clave, 2) = N'C:' THEN ctl.fn_TipoIdentificacion(SUBSTRING(k.Clave, 3, 20)) ELSE ctl.fn_TipoIdentificacion(p.CedO) END AS TipoIdentificacion,\n"
    + "".join(f"       x_{f}.v AS {m},\n" for m, f, _ in CAMPOS_CLIENTE)
    + "       CASE WHEN k.ConCrm = 1 THEN 'CRM' WHEN k.ConBooks = 1 THEN 'SOLO_BOOKS' ELSE 'SOLO_ADNPAY' END AS EstadoCorrespondencia,\n"
    + ",\n".join(f"       x_{f}.Sis AS lf_{m}_sis, x_{f}.Tab AS lf_{m}_tab, x_{f}.Llave AS lf_{m}_llave, x_{f}.Modificada AS lf_{m}_fecha"
                 for m, f, _ in CAMPOS_CLIENTE)
    + ",\n       p.CedO AS o_Cedula, k.Heredada AS o_Heredada\n"
    "FROM (SELECT Clave, MIN(Creada) AS Desde, MAX(CASE WHEN Sis = 'ZohoCRM' THEN 1 ELSE 0 END) AS ConCrm,\n"
    "             MAX(CASE WHEN Sis = 'ZohoBooks' THEN 1 ELSE 0 END) AS ConBooks, COUNT(DISTINCT Ced) AS Cedulas,\n"
    "             MAX(CAST(CedHeredada AS int)) AS Heredada\n"
    "      FROM #f GROUP BY Clave) k\n"
    "CROSS APPLY (SELECT TOP 1 f.KSis, f.KBase, f.KTab, f.KLlave, f.CedO FROM #f f WHERE f.Clave = k.Clave ORDER BY f.RankCom, f.Modificada DESC, f.Llave) p\n"
    + "\n".join(_campo(f, r) for _, f, r in CAMPOS_CLIENTE)
)

PASOS = [
    Paso(
        nombre="ref_Usuario", orden=200, destino="ref.Usuario",
        fuente=("ZohoCRM", "SQLServer", "Zoho_Mirror", "Users"), llave_origen="id",
        descripcion="Usuarios de Zoho (ejecutivos, técnicos, agentes). Varias versiones del mismo usuario: se conserva la más reciente (DD-02).",
        reglas=["ES-01", "ES-05", "DD-02", "IN-05"],
        dedup_regla="DD-02", dedup_orden="s.FechaModificacionOrigen DESC, s.HashContenido",
        dedup_motivo="Versión anterior del mismo usuario en el espejo de Zoho",
        columnas=["ZohoUsuarioId", "NombreCompleto", "Correo", "Telefono", "Rol", "Perfil", "Division", "Estado",
                  "AtributosExtendidos", "FechaCreacionOrigen", "FechaModificacionOrigen"],
        select=f"""
SELECT 'ZohoCRM' AS FuenteSistema, N'Zoho_Mirror' AS FuenteBase, N'Users' AS FuenteTabla, ctl.fn_Texto(u.id) AS FuenteLlave,
       ctl.fn_FechaCR(u.Created_Time) AS FechaDato,
       ctl.fn_Texto(u.id) AS ZohoUsuarioId, ctl.fn_Texto(u.full_name) AS NombreCompleto, ctl.fn_Texto(u.email) AS Correo,
       ctl.fn_Texto(u.phone) AS Telefono, ctl.fn_Texto(u.role) AS Rol, ctl.fn_Texto(u.profile) AS Perfil,
       ctl.fn_Texto(u.Division) AS Division, ctl.fn_Texto(u.status) AS Estado,
       {atributos("Zoho_Mirror", "Users", "u")} AS AtributosExtendidos,
       ctl.fn_FechaCR(u.Created_Time) AS FechaCreacionOrigen, ctl.fn_FechaCR(u.Modified_Time) AS FechaModificacionOrigen
FROM Zoho_Mirror.dbo.Users u
"""),
    Paso(
        nombre="ref_Usuario_ADNApp", orden=201, destino="ref.Usuario", depende=["ref_Usuario"],
        fuente=("AppDataCR", "SQLServer", "ADNApp", "ZohoEngine_zohouser"), llave_origen="zoho_id",
        descripcion="Usuarios de Zoho que solo aparecen en la copia de app.data.cr (complemento; los que ya vienen de Zoho no se repiten).",
        reglas=["ES-05", "DD-04", "IN-05"],
        columnas=["ZohoUsuarioId", "NombreCompleto", "Correo", "Telefono", "Rol", "Perfil", "Estado", "FechaCreacionOrigen"],
        select="""
SELECT 'AppDataCR' AS FuenteSistema, N'ADNApp' AS FuenteBase, N'ZohoEngine_zohouser' AS FuenteTabla, ctl.fn_Texto(z.zoho_id) AS FuenteLlave,
       ctl.fn_FechaCR(CONVERT(nvarchar(30), z.created_time, 126)) AS FechaDato,
       ctl.fn_Texto(z.zoho_id) AS ZohoUsuarioId,
       COALESCE(ctl.fn_Texto(z.full_name), ctl.fn_Texto(CONCAT(z.first_name, N' ', z.last_name))) AS NombreCompleto,
       ctl.fn_Texto(z.email) AS Correo, COALESCE(ctl.fn_Texto(z.mobile), ctl.fn_Texto(z.phone)) AS Telefono,
       ctl.fn_Texto(z.role) AS Rol, ctl.fn_Texto(z.profile) AS Perfil, ctl.fn_Texto(z.status) AS Estado,
       ctl.fn_FechaCR(CONVERT(nvarchar(30), z.created_time, 126)) AS FechaCreacionOrigen
FROM ADNApp.dbo.ZohoEngine_zohouser z
WHERE NOT EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.Users u WHERE ctl.fn_Texto(u.id) = ctl.fn_Texto(z.zoho_id))
"""),
    Paso(
        nombre="core_Condominio", orden=210, destino="core.Condominio",
        fuente=("ZohoCRM", "SQLServer", "Zoho_Mirror", "Condominios"), llave_origen="id",
        descripcion="Condominios. Coordenadas validadas dentro de Costa Rica; capacidad máxima en Mbps (1GB = 1000).",
        reglas=["ES-01", "ES-02", "ES-05", "ES-07", "DD-02", "DD-06", "IN-05"],
        dedup_regla="DD-02", dedup_orden="s.FechaModificacionOrigen DESC, s.HashContenido",
        dedup_motivo="Versión anterior del mismo condominio en el espejo de Zoho",
        filtros=[("s.o_Eliminado = 1", "DD-06", "Registro marcado como eliminado en Zoho (deleted = 1)")],
        columnas=["CondominioCrmId", "Nombre", "Tipo", "TipoConstruccion", "CantidadCasas", "CapacidadMaxima", "AplicaFTTH",
                  "Provincia", "Canton", "Distrito", "Direccion", "Latitud", "Longitud", "FechaInstalacion",
                  "AtributosExtendidos", "FechaCreacionOrigen", "FechaModificacionOrigen"],
        auxiliares=["o_Eliminado", "o_Coordenadas"],
        anomalias=[Anomalia("ES-05", "Latitud", "s.o_Coordenadas", "s.o_Coordenadas IS NOT NULL AND s.Latitud IS NULL",
                            "Coordenadas ilegibles o fuera de Costa Rica")],
        select=f"""
SELECT 'ZohoCRM' AS FuenteSistema, N'Zoho_Mirror' AS FuenteBase, N'Condominios' AS FuenteTabla, ctl.fn_Texto(c.id) AS FuenteLlave,
       ctl.fn_FechaCR(c.Created_Time) AS FechaDato,
       ctl.fn_Texto(c.id) AS CondominioCrmId, COALESCE(ctl.fn_Texto(c.Name), ctl.fn_Texto(c.Nombre)) AS Nombre,
       ctl.fn_Texto(c.Tipo_de_Condominio) AS Tipo, ctl.fn_Texto(c.Tipo_de_Construcci_n) AS TipoConstruccion,
       TRY_CONVERT(int, ctl.fn_PrimerNumero(c.Canitdad_de_Casas)) AS CantidadCasas,
       TRY_CONVERT(int, ctl.fn_PrimerNumero(c.Capacidad_Maxima) * CASE WHEN UPPER(c.Capacidad_Maxima) LIKE N'%G%' THEN 1000 ELSE 1 END) AS CapacidadMaxima,
       ctl.fn_Bit(c.Aplica_FTTH) AS AplicaFTTH,
       ctl.fn_Texto(c.Provincia) AS Provincia, ctl.fn_Texto(c.Cant_n) AS Canton, ctl.fn_Texto(c.Distritos) AS Distrito,
       ctl.fn_Texto(CONVERT(nvarchar(max), c.Direcci_n)) AS Direccion,
       ctl.fn_Coordenada(c.Coordenadas, 1) AS Latitud, ctl.fn_Coordenada(c.Coordenadas, 2) AS Longitud,
       ctl.fn_FechaDia(c.Fecha_de_Instalaci_n) AS FechaInstalacion,
       {atributos("Zoho_Mirror", "Condominios", "c")} AS AtributosExtendidos,
       ctl.fn_FechaCR(c.Created_Time) AS FechaCreacionOrigen, ctl.fn_FechaCR(c.Modified_Time) AS FechaModificacionOrigen,
       CAST(ISNULL(c.deleted, 0) AS int) AS o_Eliminado, ctl.fn_CoordenadaTexto(c.Coordenadas) AS o_Coordenadas
FROM Zoho_Mirror.dbo.Condominios c
"""),
    Paso(
        nombre="core_Nodo", orden=211, destino="core.Nodo",
        fuente=("ZohoCRM", "SQLServer", "Zoho_Mirror", "Nodos"), llave_origen="id",
        descripcion="Nodos de red.",
        reglas=["ES-01", "ES-05", "DD-02", "DD-06", "IN-05"],
        dedup_regla="DD-02", dedup_orden="s.FechaModificacionOrigen DESC, s.HashContenido",
        dedup_motivo="Versión anterior del mismo nodo en el espejo de Zoho",
        filtros=[("s.o_Eliminado = 1", "DD-06", "Registro marcado como eliminado en Zoho (deleted = 1)")],
        columnas=["NodoCrmId", "Nombre", "Nomenclatura", "Estado", "Capacidad", "CantidadClientes", "Provincia", "Direccion",
                  "Latitud", "Longitud", "AtributosExtendidos", "FechaCreacionOrigen", "FechaModificacionOrigen"],
        auxiliares=["o_Eliminado"],
        select=f"""
SELECT 'ZohoCRM' AS FuenteSistema, N'Zoho_Mirror' AS FuenteBase, N'Nodos' AS FuenteTabla, ctl.fn_Texto(n.id) AS FuenteLlave,
       ctl.fn_FechaCR(n.Created_Time) AS FechaDato,
       ctl.fn_Texto(n.id) AS NodoCrmId, ctl.fn_Texto(n.Name) AS Nombre, ctl.fn_Texto(n.Nomenclatura) AS Nomenclatura,
       ctl.fn_Texto(n.Estado_de_Nodo) AS Estado, ctl.fn_Texto(n.Capacidad) AS Capacidad,
       TRY_CONVERT(int, ctl.fn_PrimerNumero(n.Cantidad_de_Clientes)) AS CantidadClientes, ctl.fn_Texto(n.Provincia) AS Provincia,
       ctl.fn_Texto(CONVERT(nvarchar(max), n.Direcci_n)) AS Direccion,
       ctl.fn_Coordenada(n.Coordenadas, 1) AS Latitud, ctl.fn_Coordenada(n.Coordenadas, 2) AS Longitud,
       {atributos("Zoho_Mirror", "Nodos", "n")} AS AtributosExtendidos,
       ctl.fn_FechaCR(n.Created_Time) AS FechaCreacionOrigen, ctl.fn_FechaCR(n.Modified_Time) AS FechaModificacionOrigen,
       CAST(ISNULL(n.deleted, 0) AS int) AS o_Eliminado
FROM Zoho_Mirror.dbo.Nodos n
"""),
    Paso(
        nombre="core_ClusterFTTH", orden=212, destino="core.ClusterFTTH", depende=["core_Nodo"],
        fuente=("ZohoCRM", "SQLServer", "Zoho_Mirror", "FTTHs"), llave_origen="id",
        descripcion="Clústeres FTTH. El nodo se vincula por id del CRM o por nombre, solo si corresponde a un único nodo.",
        reglas=["ES-01", "ES-05", "DD-02", "DD-06", "IN-01", "IN-05"],
        dedup_regla="DD-02", dedup_orden="s.FechaModificacionOrigen DESC, s.HashContenido",
        dedup_motivo="Versión anterior del mismo clúster en el espejo de Zoho",
        filtros=[("s.o_Eliminado = 1", "DD-06", "Registro marcado como eliminado en Zoho (deleted = 1)")],
        columnas=["ClusterCrmId", "Nombre", "CodigoCluster", "NodoId", "Fase", "CapacidadRed", "CantidadClientes",
                  "Provincia", "Canton", "Distrito", "FechaInstalacion", "AtributosExtendidos", "FechaCreacionOrigen", "FechaModificacionOrigen"],
        auxiliares=["o_Eliminado", "o_Nodo"],
        anomalias=[Anomalia("IN-01", "NodoId", "s.o_Nodo", "s.o_Nodo IS NOT NULL AND s.NodoId IS NULL", "Nodo sin correspondencia única por nombre")],
        select=f"""
SELECT 'ZohoCRM' AS FuenteSistema, N'Zoho_Mirror' AS FuenteBase, N'FTTHs' AS FuenteTabla, ctl.fn_Texto(f.id) AS FuenteLlave,
       ctl.fn_FechaCR(f.Created_Time) AS FechaDato,
       ctl.fn_Texto(f.id) AS ClusterCrmId, ctl.fn_Texto(f.Name) AS Nombre, ctl.fn_Texto(f.Codigo_Cluster) AS CodigoCluster,
       nd.NodoId, ctl.fn_Texto(f.Fase) AS Fase, TRY_CONVERT(int, ctl.fn_PrimerNumero(f.Capacidad_de_la_Red)) AS CapacidadRed,
       TRY_CONVERT(int, ctl.fn_PrimerNumero(f.Cantidad_de_Clientes)) AS CantidadClientes,
       ctl.fn_Texto(f.Provincia) AS Provincia, ctl.fn_Texto(f.Cant_n) AS Canton, ctl.fn_Texto(f.Distrito) AS Distrito,
       ctl.fn_FechaDia(f.Fecha_de_Instalaci_n) AS FechaInstalacion,
       {atributos("Zoho_Mirror", "FTTHs", "f")} AS AtributosExtendidos,
       ctl.fn_FechaCR(f.Created_Time) AS FechaCreacionOrigen, ctl.fn_FechaCR(f.Modified_Time) AS FechaModificacionOrigen,
       CAST(ISNULL(f.deleted, 0) AS int) AS o_Eliminado, ctl.fn_Texto(f.Nodo) AS o_Nodo
FROM Zoho_Mirror.dbo.FTTHs f
OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(n.NodoId) END AS NodoId FROM core.Nodo n
             WHERE n.NodoCrmId = ctl.fn_Texto(f.Nodo) OR n.Nombre = ctl.fn_Texto(f.Nodo)) nd
"""),
    Paso(
        nombre="core_Servicio", orden=220, destino="core.Servicio",
        depende=["ref_Usuario", "ref_Distrito", "ref_TipoCambio", "core_Condominio"],
        fuente=("ZohoCRM", "SQLServer", "Zoho_Mirror", "Accounts_Extended"), llave_origen="id",
        descripcion="Servicios = cuentas del CRM (D2): Accounts_Extended es la fuente principal; la tabla completa Accounts solo "
                    "aporta cuentas ausentes (marcadas con anomalía D2). El cliente se asigna en el paso core_Servicio_Cliente.",
        reglas=["ID-01", "ID-04", "D2", "D4", "D5", "ES-01", "ES-02", "ES-04", "ES-05", "ES-07", "ES-08", "DD-02", "DD-06", "IN-01", "IN-05"],
        dedup_regla="DD-02", dedup_orden="s.FechaModificacionOrigen DESC, s.HashContenido",
        dedup_motivo="Versión anterior de la misma cuenta en el espejo de Zoho",
        filtros=[("s.o_Eliminado = 1", "DD-06", "Cuenta marcada como eliminada en Zoho (deleted = 1)")],
        preparacion="""
/* Cantidad de cuentas por circuito normalizado (para marcar circuitos compartidos) */
DROP TABLE IF EXISTS #cc;
SELECT Circ, COUNT(*) AS Cuentas INTO #cc FROM (
    SELECT ctl.fn_Circuito(N_mero_Circuito) AS Circ FROM Zoho_Mirror.dbo.Accounts_Extended
    UNION ALL
    SELECT ctl.fn_Circuito(b.N_mero_Circuito) FROM Zoho_Mirror.dbo.Accounts b
    WHERE ISNULL(b.deleted, 0) = 0 AND NOT EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.Accounts_Extended e WHERE e.id = b.id)) x
WHERE Circ IS NOT NULL GROUP BY Circ;
CREATE UNIQUE CLUSTERED INDEX ix_cc ON #cc (Circ);
""",
        columnas=["Circuito", "CuentaCrmId", "NombreCuenta", "TipoCuenta", "Estado", "Plataforma", "CapacidadMbps", "TieneIPTV",
                  "TieneVoIP", "NumeroTroncal", "LineaDID", "Moneda", "TipoCambio", "Mensualidad", "MensualidadCRC",
                  "DistritoId", "Provincia", "Canton", "DistritoTexto", "DireccionExacta", "Latitud", "Longitud", "CondominioId",
                  "EjecutivoUsuarioId", "FechaInstalacion", "FechaActivacion", "FechaRetiro", "EstadoCorrespondencia",
                  "AtributosExtendidos", "FechaCreacionOrigen", "FechaModificacionOrigen"],
        auxiliares=["o_Eliminado", "o_Circuito", "o_Mensualidad", "o_Coordenadas", "o_Condominio", "o_Ejecutivo", "o_CircuitoCuentas"],
        anomalias=[
            Anomalia("ID-01", "Circuito", "s.o_Circuito", "s.o_Circuito IS NOT NULL AND s.Circuito IS NULL", "Circuito que no cumple el patrón aprobado"),
            Anomalia("ID-01", "Circuito", "s.o_Circuito", "s.o_CircuitoCuentas > 1", "El mismo circuito normalizado está en varias cuentas"),
            Anomalia("ES-04", "Mensualidad", "s.o_Mensualidad", "s.o_Mensualidad IS NOT NULL AND s.Mensualidad IS NULL", "Mensualidad escrita de forma ambigua; se conserva el texto original"),
            Anomalia("ES-05", "Latitud", "s.o_Coordenadas", "s.o_Coordenadas IS NOT NULL AND s.Latitud IS NULL", "Coordenadas ilegibles o fuera de Costa Rica"),
            Anomalia("IN-01", "CondominioId", "s.o_Condominio", "s.o_Condominio IS NOT NULL AND s.CondominioId IS NULL", "Condominio sin correspondencia"),
            Anomalia("IN-01", "EjecutivoUsuarioId", "s.o_Ejecutivo", "s.o_Ejecutivo IS NOT NULL AND s.EjecutivoUsuarioId IS NULL", "Ejecutivo sin correspondencia en ref.Usuario"),
            Anomalia("D2", "CuentaCrmId", "s.FuenteLlave", "s.FuenteTabla = N'Accounts'", "Cuenta presente solo en la tabla completa (no está en _Extended)"),
        ],
        select=f"""
SELECT q.*,
       CASE q.Moneda WHEN 'CRC' THEN CAST(1 AS decimal(19,6)) WHEN 'USD' THEN tc.Venta END AS TipoCambio,
       CASE q.Moneda WHEN 'CRC' THEN q.Mensualidad WHEN 'USD' THEN CAST(q.Mensualidad * tc.Venta AS decimal(19,4)) END AS MensualidadCRC,
       d.DistritoId, co.CondominioId, us.UsuarioId AS EjecutivoUsuarioId, cc.Cuentas AS o_CircuitoCuentas
FROM (
    SELECT 'ZohoCRM' AS FuenteSistema, N'Zoho_Mirror' AS FuenteBase, N'Accounts_Extended' AS FuenteTabla, a.id AS FuenteLlave,
           {_f("a.Created_Time")} AS FechaDato,
           ctl.fn_Circuito(a.N_mero_Circuito) AS Circuito, a.id AS CuentaCrmId, ctl.fn_Texto(a.Account_Name) AS NombreCuenta,
           ctl.fn_Texto(a.Account_Type) AS TipoCuenta, ctl.fn_Texto(a.Estado) AS Estado, ctl.fn_Texto(a.Plataforma_de_servicio) AS Plataforma,
           CAST(ctl.fn_PrimerNumero(a.Capacidad_MPBS) AS decimal(9,2)) AS CapacidadMbps, a.IPTV AS TieneIPTV,
           CASE WHEN a.Telefon_a = 1 OR a.VoIP_B2C = 1 THEN CAST(1 AS bit) WHEN a.Telefon_a = 0 OR a.VoIP_B2C = 0 THEN CAST(0 AS bit) END AS TieneVoIP,
           ctl.fn_Texto(a.Numero_Troncal) AS NumeroTroncal, ctl.fn_Texto(a.Line_DID) AS LineaDID,
           COALESCE(ctl.fn_MonedaTexto(a.Mensualidad), ctl.fn_Moneda(a.Currency)) AS Moneda,
           ctl.fn_MontoLibre(a.Mensualidad) AS Mensualidad,
           ctl.fn_Texto(a.Provincia) AS Provincia, ctl.fn_Texto(a.Cant_n) AS Canton, ctl.fn_Texto(a.Distritos) AS DistritoTexto,
           ctl.fn_Texto(a.Direcci_n_Exacta) AS DireccionExacta,
           COALESCE(ctl.fn_CoordenadaSola(CONVERT(nvarchar(60), a.latitude), 1), ctl.fn_Coordenada(a.coordinates, 1)) AS Latitud,
           COALESCE(ctl.fn_CoordenadaSola(CONVERT(nvarchar(60), a.longitude), 2), ctl.fn_Coordenada(a.coordinates, 2)) AS Longitud,
           ctl.fn_Texto(a.Condominio_C) AS o_Condominio, ctl.fn_Texto(a.Ejecutivo_Asignado) AS o_Ejecutivo,
           ctl.fn_FechaDia(CONVERT(nvarchar(30), a.Fecha_de_instalaci_n, 23)) AS FechaInstalacion, {_f("a.Fecha_Confirmacion")} AS FechaActivacion,
           ctl.fn_FechaDia(CONVERT(nvarchar(30), a.Fecha_de_Retiro, 23)) AS FechaRetiro,
           'CRM' AS EstadoCorrespondencia,
           {atributos("Zoho_Mirror", "Accounts_Extended", "a")} AS AtributosExtendidos,
           {_f("a.Created_Time")} AS FechaCreacionOrigen, {_f("a.Modified_Time")} AS FechaModificacionOrigen,
           0 AS o_Eliminado, ctl.fn_Texto(a.N_mero_Circuito) AS o_Circuito, ctl.fn_Texto(a.Mensualidad) AS o_Mensualidad,
           ctl.fn_CoordenadaTexto(a.coordinates) AS o_Coordenadas
    FROM Zoho_Mirror.dbo.Accounts_Extended a
    UNION ALL
    SELECT 'ZohoCRM', N'Zoho_Mirror', N'Accounts', b.id, ctl.fn_FechaCR(b.Created_Time),
           ctl.fn_Circuito(b.N_mero_Circuito), b.id, ctl.fn_Texto(b.Account_Name), ctl.fn_Texto(b.Account_Type), ctl.fn_Texto(b.Estado),
           NULL, NULL, ctl.fn_Bit(b.IPTV),
           CASE WHEN ctl.fn_Bit(b.Telefon_a) = 1 OR ctl.fn_Bit(b.VoIP_B2C) = 1 THEN CAST(1 AS bit)
                WHEN ctl.fn_Bit(b.Telefon_a) = 0 OR ctl.fn_Bit(b.VoIP_B2C) = 0 THEN CAST(0 AS bit) END,
           ctl.fn_Texto(b.Numero_Troncal), ctl.fn_Texto(b.Line_DID), ctl.fn_Moneda(b.Currency), NULL,
           ctl.fn_Texto(b.Provincia), ctl.fn_Texto(b.Cant_n), ctl.fn_Texto(b.Distritos), ctl.fn_Texto(CONVERT(nvarchar(max), b.Direcci_n_Exacta)),
           ctl.fn_Coordenada(b.Coordenadas, 1), ctl.fn_Coordenada(b.Coordenadas, 2),
           ctl.fn_Texto(b.Condominio_C), ctl.fn_Texto(b.Ejecutivo_Asignado),
           NULL, ctl.fn_FechaCR(b.Fecha_Confirmacion), ctl.fn_FechaDia(b.Fecha_de_Retiro), 'CRM',
           {atributos("Zoho_Mirror", "Accounts", "b")},
           ctl.fn_FechaCR(b.Created_Time), ctl.fn_FechaCR(b.Modified_Time),
           CAST(ISNULL(b.deleted, 0) AS int), ctl.fn_Texto(b.N_mero_Circuito), NULL, ctl.fn_CoordenadaTexto(b.Coordenadas)
    FROM Zoho_Mirror.dbo.Accounts b
    WHERE NOT EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.Accounts_Extended e WHERE e.id = b.id)
) q
LEFT JOIN #cc cc ON cc.Circ = q.Circuito
OUTER APPLY (SELECT TOP 1 t.Venta FROM ref.TipoCambio t WHERE t.Fecha <= CAST(COALESCE(q.FechaModificacionOrigen, q.FechaCreacionOrigen) AS date) ORDER BY t.Fecha DESC) tc
OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(d0.DistritoId) END AS DistritoId FROM ref.Distrito d0 JOIN ref.Canton c0 ON c0.CantonId = d0.CantonId
             WHERE d0.Nombre = q.DistritoTexto AND c0.Nombre = q.Canton) d
OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(c1.CondominioId) END AS CondominioId FROM core.Condominio c1
             WHERE c1.CondominioCrmId = q.o_Condominio OR c1.Nombre = q.o_Condominio) co
OUTER APPLY (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(u1.UsuarioId) END AS UsuarioId FROM ref.Usuario u1
             WHERE u1.ZohoUsuarioId = q.o_Ejecutivo OR u1.NombreCompleto = q.o_Ejecutivo) us
"""),
    Paso(
        nombre="core_Cliente", orden=230, destino="core.Cliente", depende=["core_Servicio"],
        fuente=("Consolidado", "SQLServer", "ADN_Unificado", "Cedula"), llave_origen="",
        descripcion="Clientes consolidados de CRM, Books y ADNPayV2. Con cédula válida: un cliente por cédula (FuenteTabla = Cedula). "
                    "Sin cédula: un cliente por registro de origen sin correspondencia (D8). Cada campo toma el valor según D9 "
                    "y su origen queda en ctl.LinajeCampo.",
        reglas=["ID-02", "ID-03", "ID-05", "ID-06", "D8", "D9", "ES-05", "ES-07", "ES-08", "IN-05"],
        preparacion=IDENTIDAD,
        columnas=["Cedula", "TipoIdentificacion"] + [m for m, _, _ in CAMPOS_CLIENTE] + ["EstadoCorrespondencia"],
        linaje_campos=[m for m, _, _ in CAMPOS_CLIENTE],
        auxiliares=["o_Cedula", "o_Heredada"],
        anomalias=[Anomalia("ID-02", "Cedula", "s.o_Cedula", "s.Cedula IS NULL AND s.TipoIdentificacion = 'INVALIDA'",
                            "Identificación con formato inválido; se conserva el valor original en core.ClienteOrigen"),
                   Anomalia("ID-02", "Cedula", "s.o_Cedula", "s.o_Heredada = 1",
                            "Cuenta del CRM sin cédula: se tomó la cédula única de Books o app.data.cr ligados a la cuenta")],
        select=SELECT_CLIENTE,
    ),
    Paso(
        nombre="core_ClienteOrigen", orden=240, destino="core.ClienteOrigen", depende=["core_Cliente"],
        fuente=("Consolidado", "SQLServer", "ADN_Unificado", "Correspondencia"), llave_origen="",
        descripcion="Tabla de correspondencia: cada cuenta del CRM, contacto de Books, contratación de ADNPayV2 y cliente VoIP de "
                    "app.data.cr con el cliente y el servicio al que se vinculó y el método (ID-04, ID-05).",
        reglas=["ID-01", "ID-02", "ID-04", "ID-05", "ID-06", "ID-08", "ES-08", "IN-05"],
        preparacion=IDENTIDAD,
        hash_excluir=["FechaEmparejamiento"],
        columnas=["ClienteId", "ServicioId", "Sistema", "TablaOrigen", "LlaveOrigen", "CedulaOriginal", "CircuitoOriginal",
                  "MetodoEmparejamiento", "FechaEmparejamiento"],
        auxiliares=["o_Cuentas"],
        anomalias=[Anomalia("ID-01", "ServicioId", "s.CircuitoOriginal", "s.o_Cuentas > 1",
                            "Circuito presente en varias cuentas: se vinculó a la cuenta activa más reciente")],
        select="""
SELECT f.Sis AS FuenteSistema, f.Base AS FuenteBase, f.Tab AS FuenteTabla, f.Llave AS FuenteLlave, f.Creada AS FechaDato,
       cl.ClienteId, sv.ServicioId, f.Sis AS Sistema, f.Tab AS TablaOrigen, f.Llave AS LlaveOrigen,
       ctl.fn_Texto(f.CedO) AS CedulaOriginal, ctl.fn_Texto(f.CircO) AS CircuitoOriginal,
       CASE WHEN f.CedHeredada = 1 THEN 'CEDULA_HEREDADA' ELSE f.Metodo END AS MetodoEmparejamiento,
       @Ahora AS FechaEmparejamiento, f.CuentasDelCircuito AS o_Cuentas
FROM #f f
LEFT JOIN core.Cliente cl ON cl.FuenteSistema = f.KSis AND cl.FuenteTabla = f.KTab AND cl.FuenteLlave = f.KLlave
LEFT JOIN core.Servicio sv ON sv.CuentaCrmId = CASE WHEN f.Sis = 'ZohoCRM' THEN f.Llave ELSE f.CuentaCircuito END
UNION ALL
SELECT 'AppDataCR', N'ADNApp', N'ZohoEngine_zohocustomer', CAST(z.id AS nvarchar(200)), CAST(NULL AS datetimeoffset(0)),
       COALESCE(cla.ClienteId, clc.ClienteId), sv.ServicioId, 'AppDataCR', N'ZohoEngine_zohocustomer', CAST(z.id AS nvarchar(200)),
       ctl.fn_Texto(z.IDCard), ctl.fn_Texto(z.CircuitNumber),
       CASE WHEN svz.ServicioId IS NOT NULL THEN 'LLAVE_DIRECTA' WHEN svc.ServicioId IS NOT NULL THEN 'CIRCUITO'
            WHEN clc.ClienteId IS NOT NULL THEN 'CEDULA' ELSE 'SIN_CORRESPONDENCIA' END,
       @Ahora, CASE WHEN svz.ServicioId IS NULL THEN c.Cuentas END
FROM ADNApp.dbo.ZohoEngine_zohocustomer z
LEFT JOIN core.Servicio svz ON svz.CuentaCrmId = ctl.fn_Texto(z.ZohoID)
LEFT JOIN #circ c ON c.Circ = ctl.fn_Circuito(z.CircuitNumber)
LEFT JOIN core.Servicio svc ON svz.ServicioId IS NULL AND svc.CuentaCrmId = c.Cuenta
CROSS APPLY (SELECT COALESCE(svz.ServicioId, svc.ServicioId) AS ServicioId, COALESCE(svz.CuentaCrmId, svc.CuentaCrmId) AS Cuenta) sv
LEFT JOIN #f fa ON fa.Sis = 'ZohoCRM' AND fa.Llave = sv.Cuenta
LEFT JOIN core.Cliente cla ON cla.FuenteSistema = fa.KSis AND cla.FuenteTabla = fa.KTab AND cla.FuenteLlave = fa.KLlave
LEFT JOIN core.Cliente clc ON sv.ServicioId IS NULL AND clc.FuenteTabla = N'Cedula' AND clc.FuenteLlave = ctl.fn_Cedula(z.IDCard)
"""),
    Paso(
        nombre="core_Servicio_Cliente", orden=250, destino="core.Servicio", depende=["core_ClienteOrigen"],
        fuente=("ZohoCRM", "SQLServer", "Zoho_Mirror", "Accounts_Extended"), llave_origen="id",
        descripcion="Asigna a cada servicio su cliente según la tabla de correspondencia (ID-03).",
        reglas=["ID-03", "ID-04", "IN-02"],
        solo_actualizar=True,
        columnas=["ClienteId"],
        select="""
SELECT o.FuenteSistema, o.FuenteBase, o.FuenteTabla, o.FuenteLlave, o.FechaDato, o.ClienteId
FROM core.ClienteOrigen o
WHERE o.Sistema = 'ZohoCRM' AND o.TablaOrigen IN (N'Accounts_Extended', N'Accounts') AND o.ClienteId IS NOT NULL
"""),
    Paso(
        nombre="core_Contacto", orden=260, destino="core.Contacto", depende=["core_Servicio_Cliente", "ref_Usuario"],
        fuente=("ZohoCRM", "SQLServer", "Zoho_Mirror", "Contacts"), llave_origen="id",
        descripcion="Contactos del CRM; heredan el servicio y el cliente de su cuenta.",
        reglas=["ID-02", "ID-04", "ES-01", "ES-05", "ES-08", "DD-02", "DD-06", "IN-01", "IN-05"],
        dedup_regla="DD-02", dedup_orden="s.FechaModificacionOrigen DESC, s.HashContenido",
        dedup_motivo="Versión anterior del mismo contacto en el espejo de Zoho",
        filtros=[("s.o_Eliminado = 1", "DD-06", "Contacto marcado como eliminado en Zoho (deleted = 1)")],
        columnas=["ClienteId", "ServicioId", "ContactoCrmId", "Nombre", "Apellido", "NombreCompleto", "Cedula", "Correo",
                  "Telefono", "Movil", "TipoContacto", "PropietarioUsuarioId", "AtributosExtendidos",
                  "FechaCreacionOrigen", "FechaModificacionOrigen"],
        auxiliares=["o_Eliminado", "o_Cuenta"],
        anomalias=[Anomalia("IN-01", "ServicioId", "s.o_Cuenta", "s.o_Cuenta IS NOT NULL AND s.ServicioId IS NULL", "Cuenta del contacto sin correspondencia")],
        select=f"""
SELECT 'ZohoCRM' AS FuenteSistema, N'Zoho_Mirror' AS FuenteBase, N'Contacts' AS FuenteTabla, ctl.fn_Texto(k.id) AS FuenteLlave,
       ctl.fn_FechaCR(k.Created_Time) AS FechaDato,
       sv.ClienteId, sv.ServicioId, ctl.fn_Texto(k.id) AS ContactoCrmId, ctl.fn_Texto(k.First_Name) AS Nombre,
       ctl.fn_Texto(k.Last_Name) AS Apellido, ctl.fn_Texto(k.Full_Name) AS NombreCompleto,
       COALESCE(ctl.fn_Cedula(k.N_mero_Cedula_Pasaporte), ctl.fn_Cedula(k.Cedula_Juridica)) AS Cedula,
       ctl.fn_Texto(k.Email) AS Correo, ctl.fn_Texto(k.Phone) AS Telefono, ctl.fn_Texto(k.Mobile) AS Movil,
       ctl.fn_Texto(k.Tipo_de_Contacto) AS TipoContacto, us.UsuarioId AS PropietarioUsuarioId,
       {atributos("Zoho_Mirror", "Contacts", "k")} AS AtributosExtendidos,
       ctl.fn_FechaCR(k.Created_Time) AS FechaCreacionOrigen, ctl.fn_FechaCR(k.Modified_Time) AS FechaModificacionOrigen,
       CAST(ISNULL(k.deleted, 0) AS int) AS o_Eliminado, ctl.fn_Texto(k.Account_Name) AS o_Cuenta
FROM Zoho_Mirror.dbo.Contacts k
LEFT JOIN core.Servicio sv ON sv.CuentaCrmId = ctl.fn_Texto(k.Account_Name)
LEFT JOIN ref.Usuario us ON us.ZohoUsuarioId = ctl.fn_Texto(k.Owner)
"""),
]
