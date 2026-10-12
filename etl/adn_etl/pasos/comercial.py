# -*- coding: utf-8 -*-
"""Pasos comerciales y de operación (orden 300-399), generados desde la matriz de correspondencia.

Productos, direcciones, prospectos, oportunidades, cotizaciones, órdenes de venta y sus líneas, órdenes de trabajo,
órdenes de servicio VoIP, casos, notas, tareas, adjuntos y proveedores.

Reglas comunes: ES-01/ES-02 fechas en hora de Costa Rica, ES-04/D5 montos con equivalente en colones, ES-05 textos,
ES-07 sí/no, IN-01 referencias con correspondencia única, IN-05 linaje, DD-02 versión más reciente, DD-06 eliminados.
Las tablas con versión _Extended usan esa como principal y la tabla completa solo para los registros ausentes (D2).
"""
from ..auto import paso_matriz
from ..matriz import atributos
from ..paso import Paso

_CRM = "ZohoCRM"

PASOS = [
    # ------------------------------------------------------------------ productos
    paso_matriz("core_Producto_CRM", 300, "core.Producto", _CRM, "Zoho_Mirror", "Products", "p",
                override={"Sistema": "'ZohoCRM'", "ProductoCrmId": "ctl.fn_Texto(p.id)"},
                depende=["ref_Impuesto"],
                descripcion="Productos del CRM (catálogo principal). El impuesto se vincula por nombre o id de Books."),
    paso_matriz("core_Producto_Books", 301, "core.Producto", "ZohoBooks", "ZBooks_Mirror", "items", "i",
                override={"Sistema": "'ZohoBooks'", "ItemBooksId": "ctl.fn_Texto(i.item_id)", "ProductoCrmId": "CAST(NULL AS nvarchar(30))",
                          "Moneda": "'CRC'"},
                where="NOT EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.Products p WHERE p.id = i.zcrm_product_id)",
                llave="item_id", depende=["core_Producto_CRM"],
                descripcion="Artículos de Books que no están en el CRM. Los ligados a un producto del CRM solo completan su "
                            "id de Books (paso siguiente). Precios en la moneda base de Books (CRC)."),
    Paso(
        nombre="core_Producto_BooksVinculo", orden=302, destino="core.Producto", depende=["core_Producto_Books"],
        fuente=("ZohoCRM", "SQLServer", "Zoho_Mirror", "Products"), llave_origen="id", solo_actualizar=True,
        descripcion="Completa el id de Books en los productos del CRM ligados por zcrm_product_id (ID-04).",
        reglas=["ID-04", "IN-02"], columnas=["ItemBooksId"],
        dedup_orden="s.ItemBooksId",
        select="""
SELECT 'ZohoCRM' AS FuenteSistema, N'Zoho_Mirror' AS FuenteBase, N'Products' AS FuenteTabla, ctl.fn_Texto(i.zcrm_product_id) AS FuenteLlave,
       CAST(NULL AS datetimeoffset(0)) AS FechaDato, ctl.fn_Texto(i.item_id) AS ItemBooksId
FROM ZBooks_Mirror.dbo.items i
WHERE EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.Products p WHERE p.id = i.zcrm_product_id)
"""),
    paso_matriz("core_Producto_ADNPayServicio", 303, "core.Producto", "ADNPayV2", "ADNPayV2", "Service", "v",
                override={"Sistema": "'ADNPayV2'"}, moneda="'CRC'", llave="index",
                descripcion="Planes de internet de la venta en línea (ADNPayV2.Service), en colones."),
    paso_matriz("core_Producto_ADNPayProducto", 304, "core.Producto", "ADNPayV2", "ADNPayV2", "Product", "v",
                override={"Sistema": "'ADNPayV2'"}, moneda="'CRC'", llave="product_id",
                descripcion="Productos adicionales de la venta en línea (ADNPayV2.Product), en colones."),
    paso_matriz("core_Producto_ADNPayIPTV", 305, "core.Producto", "ADNPayV2", "ADNPayV2", "IPTVService", "v",
                override={"Sistema": "'ADNPayV2'"}, moneda="'CRC'", llave="tier_id",
                descripcion="Paquetes de IPTV de la venta en línea (ADNPayV2.IPTVService), en colones."),
    paso_matriz("core_Producto_Onvo", 306, "core.Producto", "ADNPayV2", "ADNPayV2", "OnvoProduct", "v",
                override={"Sistema": "'ADNPayV2'",
                          "Precio": "op.Precio", "Activo": "op.Activo", "FechaModificacionOrigen": "op.Modificado"},
                extra_from="""OUTER APPLY (SELECT TOP 1 CAST(pr.unit_amount AS decimal(19,4)) AS Precio, pr.is_active AS Activo,
                    ctl.fn_FechaCR(CONVERT(nvarchar(30), pr.updated_at, 126)) AS Modificado
             FROM ADNPayV2.dbo.OnvoPrice pr WHERE pr.onvo_product_id = v.onvo_product_id
             ORDER BY pr.is_active DESC, pr.updated_at DESC, pr.id DESC) op""",
                moneda="'CRC'", llave="id",
                descripcion="Productos de la pasarela Onvo con su precio vigente (OnvoPrice activo más reciente), en colones."),

    # ------------------------------------------------------------------ direcciones y prospectos
    paso_matriz("core_Direccion", 310, "core.Direccion", "ADNPayV2", "ADNPayV2", "AddressMain", "d",
                depende=["ref_Distrito"], descripcion="Direcciones registradas en la venta en línea."),
    paso_matriz("core_Prospecto_CRM", 311, "core.Prospecto", _CRM, "Zoho_Mirror", "Leads", "l",
                override={"ClienteId": "cl.ClienteId"},
                extra_from="LEFT JOIN core.Cliente cl ON cl.FuenteTabla = N'Cedula' AND cl.FuenteLlave = ctl.fn_Cedula(l.Legal_ID)",
                depende=["core_Cliente", "ref_Usuario"],
                descripcion="Prospectos del CRM. Si la cédula ya es de un cliente consolidado, se vincula (ID-02)."),
    paso_matriz("core_Prospecto_ADNPay", 312, "core.Prospecto", "ADNPayV2", "ADNPayV2", "CustomerProspect", "c",
                override={"ClienteId": "cl.ClienteId", "FechaCreacionOrigen": "ctl.fn_FechaCR(CONVERT(nvarchar(30), c.registration_date, 126))"},
                extra_from="LEFT JOIN core.Cliente cl ON cl.FuenteTabla = N'Cedula' AND cl.FuenteLlave = ctl.fn_Cedula(c.id_card)",
                depende=["core_Cliente", "core_Direccion"],
                descripcion="Prospectos de la venta en línea. Si la cédula ya es de un cliente consolidado, se vincula (ID-02)."),

    # ------------------------------------------------------------------ oportunidades, cotizaciones y órdenes de venta
    paso_matriz("core_Oportunidad", 320, "core.Oportunidad", _CRM, "Zoho_Mirror", "Deals", "d",
                depende=["core_Servicio", "core_Contacto", "ref_Usuario", "ref_TipoCambio"],
                fecha_tc="COALESCE(q.FechaModificacionOrigen, q.FechaCreacionOrigen)",
                descripcion="Oportunidades del CRM, con monto en moneda original y en colones (D5)."),
    paso_matriz("core_Cotizacion", 321, "core.Cotizacion", _CRM, "Zoho_Mirror", "Quotes", "c",
                depende=["core_Oportunidad"], fecha_tc="COALESCE(q.FechaCotizacion, q.FechaCreacionOrigen)",
                override={"AtributosExtendidos": "JSON_MODIFY(ISNULL(" + atributos("Zoho_Mirror", "Quotes", "c", excluir=("Product_Details",))
                                                 + ", N'{}'), '$.Product_Details', ctl.fn_Texto(CONVERT(nvarchar(max), c.Product_Details)))"},
                descripcion="Cotizaciones del CRM. Las líneas (Product_Details) se guardan como texto dentro de los atributos extendidos."),
    paso_matriz("core_OrdenVenta", 322, "core.OrdenVenta", _CRM, "Zoho_Mirror", "Sales_Orders_Extended", "o",
                depende=["core_Cotizacion"], fecha_tc="COALESCE(q.FechaFirma, q.FechaCreacionOrigen)",
                excluir_atributos=("Product_Details",),
                descripcion="Órdenes de venta: Sales_Orders_Extended es la fuente principal (D2). El servicio se vincula por "
                            "cuenta y, si falta, por circuito con correspondencia única (ID-01)."),
    paso_matriz("core_OrdenVenta_Complemento", 323, "core.OrdenVenta", _CRM, "Zoho_Mirror", "Sales_Orders", "o",
                where="NOT EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.Sales_Orders_Extended e WHERE e.id = o.id)",
                depende=["core_OrdenVenta"], fecha_tc="COALESCE(q.FechaFirma, q.FechaCreacionOrigen)",
                excluir_atributos=("Product_Details",), reglas_extra=("D2",),
                descripcion="Órdenes de venta presentes solo en la tabla completa Sales_Orders (complemento, D2)."),
    paso_matriz("core_OrdenVentaLinea", 324, "core.OrdenVentaLinea", _CRM, "Zoho_Mirror", "Sales_Orders_Products", "l",
                override={"Moneda": "ov.Moneda"}, fecha_dato="ov.FechaCreacionOrigen",
                extra_from="LEFT JOIN core.OrdenVenta ov ON ov.OrdenVentaCrmId = ctl.fn_Texto(l.sales_order)",
                depende=["core_OrdenVenta_Complemento", "core_Producto_CRM"],
                descripcion="Líneas de las órdenes de venta; heredan moneda y fecha de su orden (D5). Sin orden → descarte IN-01."),

    # ------------------------------------------------------------------ operación
    paso_matriz("core_OrdenTrabajo", 330, "core.OrdenTrabajo", _CRM, "Zoho_Mirror", "Ordenes_de_Trabajo", "t",
                depende=["core_Servicio", "core_Nodo", "ref_Usuario"],
                descripcion="Órdenes de trabajo. El servicio se vincula por circuito con correspondencia única (ID-01)."),
    paso_matriz("core_OrdenServicioVoIP", 331, "core.OrdenServicioVoIP", _CRM, "Zoho_Mirror", "Orden_de_Servicio_Voz_IP", "v",
                depende=["core_Servicio"],
                descripcion="Órdenes de servicio de voz IP. El servicio se vincula por circuito con correspondencia única (ID-01)."),
    paso_matriz("core_Caso", 332, "core.Caso", _CRM, "Zoho_Mirror", "Cases_Extended", "c", llave="CaseId",
                depende=["core_Servicio", "ref_Usuario"],
                descripcion="Casos de soporte: Cases_Extended es la fuente principal (D2)."),
    paso_matriz("core_Caso_Complemento", 333, "core.Caso", _CRM, "Zoho_Mirror", "Cases", "c",
                where="NOT EXISTS (SELECT 1 FROM Zoho_Mirror.dbo.Cases_Extended e WHERE e.CaseId = c.id)",
                depende=["core_Caso"], reglas_extra=("D2",),
                descripcion="Casos presentes solo en la tabla completa Cases (complemento, D2)."),
    paso_matriz("core_Nota_Servicio", 334, "core.Nota", _CRM, "Zoho_Mirror", "Accounts_Notes", "n",
                override={"Entidad": "'SERVICIO'"}, llave="NoteId", depende=["core_Servicio", "ref_Usuario"],
                descripcion="Notas de las cuentas del CRM (Entidad = SERVICIO)."),
    paso_matriz("core_Nota_Caso", 335, "core.Nota", _CRM, "Zoho_Mirror", "Cases_Notes", "n",
                override={"Entidad": "'CASO'"}, llave="NoteId", depende=["core_Caso_Complemento", "ref_Usuario"],
                descripcion="Notas de los casos del CRM (Entidad = CASO)."),
    paso_matriz("core_Nota_Cliente", 336, "core.Nota", "ZohoBooks", "ZBooks_Mirror", "comments_contacts", "n",
                override={"Entidad": "'CLIENTE'", "ClienteId": "co.ClienteId"},
                extra_from="""OUTER APPLY (SELECT CASE WHEN COUNT(DISTINCT o.ClienteId) = 1 THEN MIN(o.ClienteId) END AS ClienteId
             FROM core.ClienteOrigen o WHERE o.Sistema = 'ZohoBooks' AND o.LlaveOrigen = ctl.fn_Texto(n.contact_id)) co""",
                llave="id", depende=["core_ClienteOrigen"],
                descripcion="Comentarios de los contactos de Books (Entidad = CLIENTE), vinculados por la tabla de correspondencia (ID-04)."),
    paso_matriz("core_Tarea", 337, "core.Tarea", _CRM, "Zoho_Mirror", "Tasks", "t",
                depende=["core_Servicio", "core_Contacto", "ref_Usuario"],
                descripcion="Tareas del CRM. El registro relacionado se conserva (RelacionadoCrmId) y se vincula al servicio si es una cuenta."),
    paso_matriz("core_Adjunto", 338, "core.Adjunto", _CRM, "Zoho_Mirror", "Zoho_Attachments", "a", llave="AttachmentId",
                descripcion="Metadatos de los adjuntos del CRM (el archivo queda en la nube; solo se guarda la ruta)."),
    paso_matriz("core_Proveedor", 339, "core.Proveedor", "ZohoBooks", "ZBooks_Mirror", "contacts", "v",
                override={"ContactoBooksId": "ctl.fn_Texto(v.contact_id)", "Nombre": "ctl.fn_Texto(v.contact_name)",
                          "Empresa": "ctl.fn_Texto(v.company_name)", "Cedula": "ctl.fn_Cedula(v.cf_identificaci_n_unformatted)",
                          "Correo": "ctl.fn_Texto(v.email)", "Telefono": "ctl.fn_Texto(v.phone)", "Estado": "ctl.fn_Texto(v.status)"},
                where="v.contact_type = 'vendor'", llave="contact_id",
                descripcion="Proveedores de Books (contacts con contact_type = vendor)."),
]
