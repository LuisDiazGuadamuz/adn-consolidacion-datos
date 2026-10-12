# -*- coding: utf-8 -*-
"""Pasos de carga del esquema ref (catálogos). Orden 100-199."""
from ..paso import Paso, Anomalia
from ..matriz import atributos

PASOS = [
    Paso(
        nombre="ref_Provincia", orden=100, destino="ref.Provincia",
        fuente=("ADNPayV2", "SQLServer", "ADNPayV2", "AddressProvince"), llave_origen="id",
        descripcion="Provincias del catálogo de direcciones de ADNPayV2. Un nombre repetido se carga una sola vez.",
        reglas=["ES-05", "DD-04", "IN-05"],
        clave=["Nombre"], dedup_orden="TRY_CAST(s.FuenteLlave AS int)",
        dedup_motivo="Provincia con el mismo nombre que otra; se conserva la de menor id",
        columnas=["Nombre"],
        select="""
SELECT 'ADNPayV2' AS FuenteSistema, N'ADNPayV2' AS FuenteBase, N'AddressProvince' AS FuenteTabla,
       CAST(p.id AS nvarchar(200)) AS FuenteLlave, CAST(NULL AS datetimeoffset(0)) AS FechaDato,
       ctl.fn_Texto(p.name) AS Nombre
FROM ADNPayV2.dbo.AddressProvince p
"""),
    Paso(
        nombre="ref_Canton", orden=110, destino="ref.Canton", depende=["ref_Provincia"],
        fuente=("ADNPayV2", "SQLServer", "ADNPayV2", "AddressCanton"), llave_origen="id",
        descripcion="Cantones; la provincia se resuelve por el nombre de la provincia de origen (tolera provincias repetidas).",
        reglas=["ES-05", "IN-01", "IN-05"],
        columnas=["ProvinciaId", "Nombre"],
        select="""
SELECT 'ADNPayV2' AS FuenteSistema, N'ADNPayV2' AS FuenteBase, N'AddressCanton' AS FuenteTabla,
       CAST(c.id AS nvarchar(200)) AS FuenteLlave, CAST(NULL AS datetimeoffset(0)) AS FechaDato,
       p.ProvinciaId, ctl.fn_Texto(c.name) AS Nombre
FROM ADNPayV2.dbo.AddressCanton c
LEFT JOIN ADNPayV2.dbo.AddressProvince ap ON ap.id = c.province_id
LEFT JOIN ref.Provincia p ON p.Nombre = ctl.fn_Texto(ap.name)
"""),
    Paso(
        nombre="ref_Distrito", orden=120, destino="ref.Distrito", depende=["ref_Canton"],
        fuente=("ADNPayV2", "SQLServer", "ADNPayV2", "AddressDistrict"), llave_origen="id",
        descripcion="Distritos; el cantón se resuelve por su llave de origen.",
        reglas=["ES-05", "IN-01", "IN-05"],
        columnas=["CantonId", "Nombre"],
        select="""
SELECT 'ADNPayV2' AS FuenteSistema, N'ADNPayV2' AS FuenteBase, N'AddressDistrict' AS FuenteTabla,
       CAST(d.id AS nvarchar(200)) AS FuenteLlave, CAST(NULL AS datetimeoffset(0)) AS FechaDato,
       c.CantonId, ctl.fn_Texto(d.name) AS Nombre
FROM ADNPayV2.dbo.AddressDistrict d
LEFT JOIN ref.Canton c ON c.FuenteSistema = 'ADNPayV2' AND c.FuenteTabla = N'AddressCanton'
                      AND c.FuenteLlave = CAST(d.canton_id AS nvarchar(200))
"""),
    Paso(
        nombre="ref_TipoCambio", orden=130, destino="ref.TipoCambio",
        fuente=("AppDataCR", "SQLServer", "ADNApp", "Telephony_usdexchange"), llave_origen="id",
        descripcion="Tipo de cambio del dólar por día. Une la copia MongoDB (vigente, requiere stage-mongo) y la copia SQL Server. "
                    "Si un día aparece varias veces se conserva MongoDB y, dentro de la misma fuente, el último registro.",
        reglas=["ES-02", "ES-03", "ES-04", "DD-04", "D1", "D5", "IN-05"],
        clave=["Fecha"],
        dedup_orden="CASE s.FuenteBase WHEN N'developer_adn_app_db' THEN 0 ELSE 1 END, s.o_Orden DESC, s.FuenteLlave",
        dedup_motivo="Varios tipos de cambio para el mismo día; se conserva MongoDB y el último registrado",
        columnas=["Fecha", "Compra", "Venta"],
        auxiliares=["o_Fecha", "o_Orden"],
        anomalias=[Anomalia("ES-03", "Fecha", "s.o_Fecha", "s.Fecha > CAST(SYSDATETIMEOFFSET() AS date)",
                            "Fecha posterior a la carga")],
        select="""
SELECT 'AppDataCR' AS FuenteSistema, N'developer_adn_app_db' AS FuenteBase, N'Telephony_usdexchange' AS FuenteTabla,
       CAST(m._id AS nvarchar(200)) AS FuenteLlave,
       TODATETIMEOFFSET(CAST(ctl.fn_FechaDia(CONVERT(nvarchar(30), m.ExchangeDate, 23)) AS datetime2(0)), '-06:00') AS FechaDato,
       ctl.fn_FechaDia(CONVERT(nvarchar(30), m.ExchangeDate, 23)) AS Fecha,
       CAST(m.Purchase AS decimal(19,6)) AS Compra, CAST(m.Sale AS decimal(19,6)) AS Venta,
       CONVERT(nvarchar(30), m.ExchangeDate, 23) AS o_Fecha, m.id AS o_Orden
FROM stg.mongo_Telephony_usdexchange m
UNION ALL
SELECT 'AppDataCR', N'ADNApp', N'Telephony_usdexchange', CAST(u.id AS nvarchar(200)),
       TODATETIMEOFFSET(CAST(ctl.fn_FechaDia(CONVERT(nvarchar(30), u.ExchangeDate, 23)) AS datetime2(0)), '-06:00'),
       ctl.fn_FechaDia(CONVERT(nvarchar(30), u.ExchangeDate, 23)),
       CAST(u.Purchase AS decimal(19,6)), CAST(u.Sale AS decimal(19,6)),
       CONVERT(nvarchar(30), u.ExchangeDate, 23), u.id
FROM ADNApp.dbo.Telephony_usdexchange u
"""),
    Paso(
        nombre="ref_Impuesto", orden=140, destino="ref.Impuesto",
        fuente=("ZohoBooks", "SQLServer", "ZBooks_Mirror", "taxes"), llave_origen="tax_id",
        descripcion="Impuestos de Zoho Books. El espejo repite filas del mismo tax_id; se carga una por impuesto.",
        reglas=["ES-05", "ES-07", "DD-02", "DD-03", "IN-05"],
        dedup_regla="DD-03", dedup_motivo="Fila repetida del espejo de Books para el mismo tax_id",
        columnas=["ImpuestoBooksId", "Nombre", "Porcentaje", "Tipo", "EsPredeterminado", "AtributosExtendidos"],
        select=f"""
SELECT 'ZohoBooks' AS FuenteSistema, N'ZBooks_Mirror' AS FuenteBase, N'taxes' AS FuenteTabla,
       ctl.fn_Texto(x.tax_id) AS FuenteLlave, CAST(NULL AS datetimeoffset(0)) AS FechaDato,
       ctl.fn_Texto(x.tax_id) AS ImpuestoBooksId,
       ctl.fn_Texto(x.tax_name) AS Nombre,
       TRY_CONVERT(decimal(9,4), ctl.fn_Monto(x.tax_percentage)) AS Porcentaje,
       ctl.fn_Texto(x.tax_type) AS Tipo,
       ctl.fn_Bit(x.is_default_tax) AS EsPredeterminado,
       {atributos("ZBooks_Mirror", "taxes")} AS AtributosExtendidos
FROM ZBooks_Mirror.dbo.taxes x
"""),
    Paso(
        nombre="ref_CuentaContable", orden=150, destino="ref.CuentaContable",
        fuente=("ZohoBooks", "SQLServer", "ZBooks_Mirror", "chartofaccounts"), llave_origen="account_id",
        descripcion="Catálogo contable de Zoho Books. Si el espejo tiene varias versiones de una cuenta se conserva la modificación más reciente (DD-02). La cuenta padre se completa en el paso siguiente.",
        reglas=["ES-01", "ES-02", "ES-05", "ES-07", "DD-02", "IN-05"],
        dedup_regla="DD-02", dedup_orden="s.FechaModificacionOrigen DESC, s.HashContenido",
        dedup_motivo="Versión anterior de la misma cuenta en el espejo de Books; se conserva la modificación más reciente",
        columnas=["CuentaBooksId", "Codigo", "Nombre", "Tipo", "Descripcion", "EsDeSistema", "Activa",
                  "AtributosExtendidos", "FechaCreacionOrigen", "FechaModificacionOrigen"],
        auxiliares=["o_Creada"],
        anomalias=[Anomalia("ES-02", "FechaCreacionOrigen", "s.o_Creada",
                            "s.o_Creada IS NOT NULL AND s.FechaCreacionOrigen IS NULL", "Fecha de creación ficticia o inválida")],
        select=f"""
SELECT 'ZohoBooks' AS FuenteSistema, N'ZBooks_Mirror' AS FuenteBase, N'chartofaccounts' AS FuenteTabla,
       ctl.fn_Texto(x.account_id) AS FuenteLlave,
       ctl.fn_FechaCR(x.created_time) AS FechaDato,
       ctl.fn_Texto(x.account_id) AS CuentaBooksId,
       ctl.fn_Texto(x.account_code) AS Codigo,
       ctl.fn_Texto(x.account_name) AS Nombre,
       ctl.fn_Texto(x.account_type) AS Tipo,
       ctl.fn_Texto(x.description) AS Descripcion,
       ctl.fn_Bit(x.is_system_account) AS EsDeSistema,
       ctl.fn_Bit(x.is_active) AS Activa,
       {atributos("ZBooks_Mirror", "chartofaccounts")} AS AtributosExtendidos,
       ctl.fn_FechaCR(x.created_time) AS FechaCreacionOrigen,
       ctl.fn_FechaCR(x.last_modified_time) AS FechaModificacionOrigen,
       ctl.fn_Texto(x.created_time) AS o_Creada
FROM ZBooks_Mirror.dbo.chartofaccounts x
"""),
    Paso(
        nombre="ref_CuentaContable_Padre", orden=151, destino="ref.CuentaContable", depende=["ref_CuentaContable"],
        fuente=("ZohoBooks", "SQLServer", "ZBooks_Mirror", "chartofaccounts"), llave_origen="account_id",
        descripcion="Completa la cuenta padre de cada cuenta contable (requiere que todas las cuentas ya existan).",
        reglas=["IN-01", "IN-02", "DD-02"],
        solo_actualizar=True, dedup_regla="DD-02",
        dedup_orden="s.o_Modificada DESC, s.CuentaPadreId",
        dedup_motivo="Versión anterior de la misma cuenta en el espejo de Books",
        columnas=["CuentaPadreId"],
        auxiliares=["o_Modificada"],
        select="""
SELECT 'ZohoBooks' AS FuenteSistema, N'ZBooks_Mirror' AS FuenteBase, N'chartofaccounts' AS FuenteTabla,
       ctl.fn_Texto(x.account_id) AS FuenteLlave, CAST(NULL AS datetimeoffset(0)) AS FechaDato,
       p.CuentaContableId AS CuentaPadreId,
       ctl.fn_FechaCR(x.last_modified_time) AS o_Modificada
FROM ZBooks_Mirror.dbo.chartofaccounts x
LEFT JOIN ref.CuentaContable p ON p.CuentaBooksId = ctl.fn_Texto(x.parent_account_id)
"""),
    Paso(
        nombre="ref_CodigoPromocion", orden=160, destino="ref.CodigoPromocion",
        fuente=("ADNPayV2", "SQLServer", "ADNPayV2", "code_promo_condo"), llave_origen="id",
        descripcion="Códigos promocionales de condominios de ADNPayV2 (la tabla Code está vacía y se descartó en la matriz).",
        reglas=["ES-05", "IN-05"],
        columnas=["Codigo", "Categoria", "Activo"],
        select="""
SELECT 'ADNPayV2' AS FuenteSistema, N'ADNPayV2' AS FuenteBase, N'code_promo_condo' AS FuenteTabla,
       CAST(c.id AS nvarchar(200)) AS FuenteLlave, CAST(NULL AS datetimeoffset(0)) AS FechaDato,
       ctl.fn_Texto(c.code) AS Codigo, CAST(N'Condominio' AS varchar(50)) AS Categoria, c.state AS Activo
FROM ADNPayV2.dbo.code_promo_condo c
"""),
]
