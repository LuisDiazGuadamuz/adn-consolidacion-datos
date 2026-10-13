# -*- coding: utf-8 -*-
"""Copia colecciones de la copia MongoDB (mongo-lab) a tablas stg.* del sandbox.

Solo lectura sobre MongoDB (find). La recarga es reproducible: borra en stg el período pedido y lo vuelve a
copiar completo, así dos ejecuciones sobre la misma copia dejan exactamente las mismas filas.
"""
import datetime as dt
import os

from pymongo import MongoClient

from . import bd, runner, seguridad

COLECCIONES = {
    "Telephony_cdr": {
        "tabla": "stg.mongo_Telephony_cdr", "fecha": "StartDateTime",
        "campos": ["id", "CDRTypeCode", "CDRTypeReason", "StartDateTime", "AnswerTimeOfDate", "DisconnectDateTime",
                   "IngressTrunk", "EgressTrunk", "DialedNumber", "usd_exchange", "Destination", "DestinationCode",
                   "DestinationRate", "DestinationRateNoProfit", "DestinationRound", "DurationInSeconds",
                   "DurationInRoundedSeconds", "DurationInMinutes", "CallCost", "CallCostNoProfit", "CallingNumber",
                   "BillingNumber", "VoipDevice", "CustomerName", "CustomerIncrement", "CustomerPorcentage",
                   "CustomerCircuitNumber", "IngressTrunkAlias", "EgressTrunkAlias", "OriginationSourceIP",
                   "OriginationDestinationIP", "Rpid_PAI", "RoutingDigits"]},
    "Telephony_insertedcdrfiles": {
        "tabla": "stg.mongo_Telephony_insertedcdrfiles", "fecha": "InsertionDate",
        "campos": ["id", "FileName", "VoipDevice", "InsertionDate"]},
    "Telephony_usdexchange": {
        "tabla": "stg.mongo_Telephony_usdexchange", "fecha": "ExchangeDate",
        "campos": ["id", "Purchase", "Sale", "ExchangeDate"]},
}
FECHAS_SIN_HORA = {"InsertionDate", "ExchangeDate"}


def _valor(campo, v):
    if v is None:
        return None
    if hasattr(v, "to_decimal"):          # Decimal128
        v = float(v.to_decimal())
    # La copia masiva (BCP) solo acepta datetime; SQL Server lo convierte a date en las columnas sin hora
    if isinstance(v, dt.datetime):
        v = v.replace(tzinfo=None)
        return dt.datetime(v.year, v.month, v.day) if campo in FECHAS_SIN_HORA else v
    if isinstance(v, dt.date):
        return dt.datetime(v.year, v.month, v.day)
    if isinstance(v, (dict, list)):
        return str(v)
    return v


def copiar(cfg, coleccion, desde=None, hasta=None, lote_tamano=5000):
    if coleccion not in COLECCIONES:
        raise SystemExit(f"Colección no soportada: {coleccion}. Opciones: {sorted(COLECCIONES)}")
    spec = COLECCIONES[coleccion]
    seguridad.verificar_configuracion(cfg)
    conn = bd.conectar(cfg, autocommit=True)
    cli = MongoClient(cfg.mongo_uri, serverSelectionTimeoutMS=10000, readPreference="secondaryPreferred")
    try:
        ev = runner.evidencia_entorno(cfg, conn)
        bdm = cli[os.environ.get("ETL_MONGO_BD", "developer_adn_app_db")]
        filtro = {}
        if desde or hasta:
            rango = {}
            if desde:
                rango["$gte"] = dt.datetime.fromisoformat(desde)
            if hasta:
                rango["$lt"] = dt.datetime.fromisoformat(hasta)
            filtro[spec["fecha"]] = rango
        print(f"Contando documentos de {coleccion} en MongoDB (puede tardar un par de minutos)...", flush=True)
        total_origen = bdm[coleccion].count_documents(filtro)
        print(f"  {total_origen:,} documentos a copiar", flush=True)
        cur = conn.cursor()
        cur.execute("""SET NOCOUNT ON; DECLARE @L int;
                       EXEC ctl.usp_IniciarLote @Paso = %s, @Sistema = 'AppDataCR', @Motor = 'MongoDB',
                            @Base = %s, @Tabla = %s, @Modo = 'STAGE', @Usuario = %s, @Parametros = %s, @LoteId = @L OUTPUT;
                       SELECT @L;""", (f"stg_{coleccion}", bdm.name, coleccion, cfg.usuario, f'{{"desde":"{desde}","hasta":"{hasta}"}}'))
        lote = int(cur.fetchone()[0])
        # borra el período en stg (recarga reproducible)
        if desde or hasta:
            cond, params = [], []
            if desde:
                cond.append(f"{spec['fecha']} >= %s"); params.append(desde)
            if hasta:
                cond.append(f"{spec['fecha']} < %s"); params.append(hasta)
            cur.execute(f"DELETE FROM {spec['tabla']} WHERE " + " AND ".join(cond), tuple(params))
        else:
            cur.execute(f"TRUNCATE TABLE {spec['tabla']}")
        cols = ["_id"] + spec["campos"] + ["StgLoteId"]
        sql = f"INSERT INTO {spec['tabla']} ({', '.join('[' + c + ']' for c in cols)}) VALUES ({', '.join(['%s'] * len(cols))})"
        proy = {c: 1 for c in spec["campos"]}
        buf, n = [], 0
        usar_bcp = hasattr(conn, "bulk_copy")

        def volcar(filas):
            nonlocal usar_bcp
            if usar_bcp:
                try:
                    conn.bulk_copy(spec["tabla"], filas, column_ids=list(range(1, len(cols) + 1)), batch_size=len(filas))
                    return
                except Exception as e:  # FreeTDS sin BCP o tipos no soportados: se usa INSERT por lotes
                    print(f"  (copia masiva no disponible: {e}; se usa INSERT por lotes)", flush=True)
                    usar_bcp = False
            cur.execute("BEGIN TRANSACTION")
            cur.executemany(sql, filas)
            cur.execute("COMMIT TRANSACTION")

        cursor_m = bdm[coleccion].find(filtro, proy, no_cursor_timeout=False).sort("_id", 1).batch_size(lote_tamano)
        for doc in cursor_m:
            buf.append(tuple([str(doc["_id"])] + [_valor(c, doc.get(c)) for c in spec["campos"]] + [lote]))
            if len(buf) >= lote_tamano:
                volcar(buf); n += len(buf); buf = []
                if n % 100000 < lote_tamano:
                    print(f"  {coleccion}: {n:,} / {total_origen:,}", flush=True)
        if buf:
            volcar(buf); n += len(buf)
        cur.execute("""UPDATE ctl.Lote SET Estado = 'Exitoso', FechaFin = SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00'),
                       FilasLeidas = %s, FilasCargadas = %s, Mensaje = N'Copia de MongoDB a staging (sin cambios en el modelo)'
                       WHERE LoteId = %s""", (total_origen, n, lote))
        lineas = [f"Staging {coleccion} → {spec['tabla']} · lote {lote}",
                  f"  Documentos en MongoDB (filtro): {total_origen:,}", f"  Filas copiadas: {n:,}",
                  "  Resultado: " + ("COMPLETO" if n == total_origen else "DIFERENCIA: revisar")]
        print("\n" + "\n".join(lineas))
        runner.reporte(f"stage_{coleccion}", ["Entorno verificado:"] + [f"  {k}: {v}" for k, v in ev.items()] + [""] + lineas)
        return lote
    finally:
        cli.close()
        conn.close()
