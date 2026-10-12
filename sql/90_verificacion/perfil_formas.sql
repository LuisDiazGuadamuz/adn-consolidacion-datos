/* Perfil de FORMAS, catálogos y zona horaria (Sprint 3) - SOLO LECTURA.
   1. Forma de los valores de texto: dígitos → 9, letras → a/A (no muestra datos de clientes).
   2. Valores distintos de campos de catálogo (moneda, tipo, estado...).
   3. Distribución por hora del día de fechas sin zona horaria: si el pico es 8-17 h la hora es de Costa Rica;
      si es 14-23 h está en UTC. */
SET NOCOUNT ON;
DECLARE @d varchar(62) = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',
        @r varchar(62) = '9999999999aaaaaaaaaaaaaaaaaaaaaaaaaaAAAAAAAAAAAAAAAAAAAAAAAAAA';
CREATE TABLE #formas (Base sysname, Tabla sysname, Columna sysname, Forma nvarchar(60), Filas bigint);
DECLARE @c TABLE (Base sysname, Tabla sysname, Columna sysname, Filtro nvarchar(200));
INSERT @c VALUES
 (N'Zoho_Mirror', N'Accounts_Extended', N'Mensualidad', N''),
 (N'Zoho_Mirror', N'Accounts_Extended', N'coordinates', N''),
 (N'Zoho_Mirror', N'Accounts', N'Coordenadas', N''),
 (N'Zoho_Mirror', N'Accounts_Extended', N'Capacidad_MPBS', N''),
 (N'Zoho_Mirror', N'Accounts_Extended', N'Cedula_Jurida_Persona', N''),
 (N'Zoho_Mirror', N'Contacts', N'N_mero_Cedula_Pasaporte', N''),
 (N'Zoho_Mirror', N'Accounts_Extended', N'N_mero_Circuito', N''),
 (N'Zoho_Mirror', N'Products', N'Tax', N''),
 (N'Zoho_Mirror', N'Condominios', N'Capacidad_Maxima', N''),
 (N'Zoho_Mirror', N'Ordenes_de_Trabajo', N'Latitud', N''),
 (N'Zoho_Mirror', N'Ordenes_de_Trabajo', N'Longitud', N''),
 (N'Zoho_Mirror', N'Sales_Orders_Extended', N'Product_Details', N''),
 (N'ZBooks_Mirror', N'invoices_items', N'rate', N''),
 (N'ZBooks_Mirror', N'invoices_items', N'total', N''),
 (N'ZBooks_Mirror', N'invoices_items', N'quantity', N''),
 (N'ZBooks_Mirror', N'contacts', N'cf_circuit_number_unformatted', N''),
 (N'ZBooks_Mirror', N'invoices', N'customer_cf_circuit_number_unformatted', N''),
 (N'ZBooks_Mirror', N'customerpayments', N'invoice_numbers', N''),
 (N'ZBooks_Mirror', N'comments_contacts', N'time', N''),
 (N'ADNApp', N'Telephony_cdr', N'CustomerCircuitNumber', N' WHERE id % 100 = 0'),
 (N'ADNApp', N'ZohoEngine_zohocustomer', N'CircuitNumber', N''),
 (N'ADNPayV2', N'Customer', N'total_price', N''),
 (N'ZCRM2Trengo', N'trengo_data_tickets', N'custom_data', N'');
DECLARE @b sysname, @t sysname, @col sysname, @f nvarchar(200), @sql nvarchar(max);
DECLARE k CURSOR LOCAL FAST_FORWARD FOR SELECT Base, Tabla, Columna, Filtro FROM @c;
OPEN k; FETCH NEXT FROM k INTO @b, @t, @col, @f;
WHILE @@FETCH_STATUS = 0
BEGIN
  SET @sql = N'INSERT #formas SELECT TOP 12 @b, @t, @col, Forma, COUNT_BIG(*) FROM (
       SELECT TRANSLATE(LEFT(CONVERT(nvarchar(4000), ' + QUOTENAME(@col) + N'), 40) COLLATE Latin1_General_BIN, @d, @r) AS Forma
       FROM ' + QUOTENAME(@b) + N'.dbo.' + QUOTENAME(@t) + @f + N') x
     WHERE Forma IS NOT NULL GROUP BY Forma ORDER BY COUNT_BIG(*) DESC;';
  BEGIN TRY EXEC sp_executesql @sql, N'@b sysname, @t sysname, @col sysname, @d varchar(62), @r varchar(62)', @b, @t, @col, @d, @r; END TRY
  BEGIN CATCH INSERT #formas VALUES (@b, @t, @col, N'ERROR: ' + LEFT(ERROR_MESSAGE(), 50), 0); END CATCH
  FETCH NEXT FROM k INTO @b, @t, @col, @f;
END
CLOSE k; DEALLOCATE k;
SELECT N'FORMA' AS Tipo, Base, Tabla, Columna, Forma AS Valor, Filas FROM #formas ORDER BY Base, Tabla, Columna, Filas DESC;

/* 2. Catálogos: valores distintos */
CREATE TABLE #cat (Base sysname, Tabla sysname, Columna sysname, Valor nvarchar(100), Filas bigint);
DECLARE @k TABLE (Base sysname, Tabla sysname, Columna sysname);
INSERT @k VALUES
 (N'Zoho_Mirror', N'Accounts_Extended', N'Currency'), (N'Zoho_Mirror', N'Accounts', N'Currency'),
 (N'Zoho_Mirror', N'Accounts_Extended', N'Account_Type'), (N'Zoho_Mirror', N'Accounts_Extended', N'Estado'),
 (N'Zoho_Mirror', N'Accounts_Extended', N'Tipo_Fiscal'), (N'Zoho_Mirror', N'Accounts_Extended', N'Segmento_Cuenta'),
 (N'Zoho_Mirror', N'Accounts_Extended', N'Tipo'), (N'Zoho_Mirror', N'Deals', N'Currency'),
 (N'Zoho_Mirror', N'Sales_Orders_Extended', N'Currency'), (N'Zoho_Mirror', N'Contacts', N'Tipo_de_Contacto'),
 (N'ZBooks_Mirror', N'contacts', N'contact_type'), (N'ZBooks_Mirror', N'contacts', N'currency_code'),
 (N'ZBooks_Mirror', N'contacts', N'cf_tipo_fiscal_unformatted'), (N'ZBooks_Mirror', N'contacts', N'status'),
 (N'ZBooks_Mirror', N'invoices', N'currency_code'), (N'ZBooks_Mirror', N'invoices', N'status'),
 (N'ZBooks_Mirror', N'customerpayments', N'payment_mode'), (N'ZBooks_Mirror', N'banktransactions', N'debit_or_credit'),
 (N'ADNPayV2', N'Customer', N'id_type'), (N'ADNPayV2', N'Customer', N'type'), (N'ADNPayV2', N'Customer', N'status'),
 (N'ADNPayV2', N'OnvoCheckoutSession', N'currency');
DECLARE k2 CURSOR LOCAL FAST_FORWARD FOR SELECT Base, Tabla, Columna FROM @k;
OPEN k2; FETCH NEXT FROM k2 INTO @b, @t, @col;
WHILE @@FETCH_STATUS = 0
BEGIN
  SET @sql = N'INSERT #cat SELECT TOP 25 @b, @t, @col, LEFT(CONVERT(nvarchar(4000), ' + QUOTENAME(@col) + N'), 100), COUNT_BIG(*)
     FROM ' + QUOTENAME(@b) + N'.dbo.' + QUOTENAME(@t) + N' GROUP BY LEFT(CONVERT(nvarchar(4000), ' + QUOTENAME(@col) + N'), 100) ORDER BY COUNT_BIG(*) DESC;';
  BEGIN TRY EXEC sp_executesql @sql, N'@b sysname, @t sysname, @col sysname', @b, @t, @col; END TRY
  BEGIN CATCH INSERT #cat VALUES (@b, @t, @col, N'ERROR: ' + LEFT(ERROR_MESSAGE(), 80), 0); END CATCH
  FETCH NEXT FROM k2 INTO @b, @t, @col;
END
CLOSE k2; DEALLOCATE k2;
SELECT N'CATALOGO' AS Tipo, Base, Tabla, Columna, ISNULL(Valor, N'(nulo)') AS Valor, Filas FROM #cat ORDER BY Base, Tabla, Columna, Filas DESC;

/* 3. Hora del día de fechas sin zona horaria */
;WITH h AS (
  SELECT N'Zoho Accounts.Created_Time' AS Fuente, DATEPART(hour, TRY_CONVERT(datetime2, Created_Time)) AS Hora FROM Zoho_Mirror.dbo.Accounts
  UNION ALL SELECT N'Zoho Cases.Created_Time', DATEPART(hour, TRY_CONVERT(datetime2, Created_Time)) FROM Zoho_Mirror.dbo.Cases
  UNION ALL SELECT N'Zoho Accounts_Extended.Created_Time', DATEPART(hour, Created_Time) FROM Zoho_Mirror.dbo.Accounts_Extended
  UNION ALL SELECT N'Books invoices.created_time', DATEPART(hour, TRY_CONVERT(datetime2, LEFT(created_time, 19))) FROM ZBooks_Mirror.dbo.invoices
  UNION ALL SELECT N'Books customerpayments.created_time', DATEPART(hour, TRY_CONVERT(datetime2, LEFT(created_time, 19))) FROM ZBooks_Mirror.dbo.customerpayments
  UNION ALL SELECT N'CDR SQL StartDateTime (1%)', DATEPART(hour, StartDateTime) FROM ADNApp.dbo.Telephony_cdr WHERE id % 100 = 0
  UNION ALL SELECT N'Navsat Ultima_ubicacion.crDateTime (1%)', DATEPART(hour, TRY_CONVERT(datetime2, crDateTime)) FROM Navsat.dbo.Ultima_ubicacion WHERE CHECKSUM(deviceName, crDateTime) % 100 = 0
)
SELECT N'HORA' AS Tipo, Fuente, Hora, COUNT_BIG(*) AS Filas FROM h WHERE Hora IS NOT NULL GROUP BY Fuente, Hora ORDER BY Fuente, Hora;
