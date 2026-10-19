/* Pruebas automáticas de las funciones de limpieza y normalización (Sprint 3) - SOLO LECTURA.
   Cada caso usa un valor sintético (ningún dato real de clientes) y su resultado esperado según las reglas
   aprobadas (ES-xx, ID-xx, D4, D10). Resultado: PASA/FALLA por caso y un resumen al final.
   Al cambiar una regla (p. ej. ID-01), se actualizan aquí sus casos en el mismo commit. */
SET NOCOUNT ON; SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_WARNINGS ON;
USE ADN_Unificado;

DECLARE @c TABLE (Id int IDENTITY, Regla varchar(10), Funcion varchar(40), Entrada nvarchar(200), Parte tinyint NULL, Esperado nvarchar(100) NULL);
INSERT @c (Regla, Funcion, Entrada, Parte, Esperado) VALUES
-- ES-05 texto: recorta y vacío → NULL
('ES-05', 'fn_Texto', N'  hola  ', NULL, N'hola'),
('ES-05', 'fn_Texto', N'   ', NULL, NULL),
('ES-05', 'fn_Texto', N'a' + NCHAR(9) + N'b' + NCHAR(10), NULL, N'a b'),
-- ID-02 cédula: solo dígitos, 9 / 10 / 12; cero inicial de 10 dígitos se quita
('ID-02', 'fn_Cedula', N'1-0234-0567', NULL, N'102340567'),
('ID-02', 'fn_Cedula', N'01-0234-0567', NULL, N'102340567'),
('ID-02', 'fn_Cedula', N'3-101-123456', NULL, N'3101123456'),
('ID-02', 'fn_Cedula', N'155812345678', NULL, N'155812345678'),
('ID-02', 'fn_Cedula', N'1.0234.0567', NULL, N'102340567'),
('ID-02', 'fn_Cedula', N'ABC12345', NULL, NULL),
('ID-02', 'fn_Cedula', N'12345', NULL, NULL),
('ID-02', 'fn_Cedula', N'', NULL, NULL),
('ID-02', 'fn_TipoIdentificacion', N'1-0234-0567', NULL, N'FISICA'),
('ID-02', 'fn_TipoIdentificacion', N'3-101-123456', NULL, N'JURIDICA'),
('ID-02', 'fn_TipoIdentificacion', N'155812345678', NULL, N'DIMEX'),
('ID-02', 'fn_TipoIdentificacion', N'xyz', NULL, N'INVALIDA'),
('ID-02', 'fn_TipoIdentificacion', N'', NULL, N'SIN_DATO'),
-- ID-01 v1.1 circuito: mayúsculas, sin espacios, CONSERVANDO guiones; AAA-<1 a 6 dígitos>[-<1 a 3 dígitos>], 2 a 9 dígitos
('ID-01', 'fn_Circuito', N'sjo-1234-567', NULL, N'SJO-1234-567'),
('ID-01', 'fn_Circuito', N' SJO-123456-789 ', NULL, N'SJO-123456-789'),
('ID-01', 'fn_Circuito', N'SJO- 99999-999', NULL, N'SJO-99999-999'),
('ID-01', 'fn_Circuito', N'SJO-1234', NULL, N'SJO-1234'),
('ID-01', 'fn_Circuito', N'SJO-12', NULL, N'SJO-12'),
('ID-01', 'fn_Circuito', N'SJO-1-2', NULL, N'SJO-1-2'),
('ID-01', 'fn_Circuito', N'SJO-9', NULL, NULL),
('ID-01', 'fn_Circuito', N'SJO1234567', NULL, NULL),
('ID-01', 'fn_Circuito', N'SJO 1234', NULL, NULL),
('ID-01', 'fn_Circuito', N'SJOX-1234-567', NULL, NULL),
('ID-01', 'fn_Circuito', N'SJO-1234567-89', NULL, NULL),
('ID-01', 'fn_Circuito', N'SJO-1234-5678', NULL, NULL),
('ID-01', 'fn_Circuito', N'SJO-12-34-5', NULL, NULL),
('ID-01', 'fn_Circuito', N'SJO-', NULL, NULL),
('ID-01', 'fn_Circuito', N'SJO-ABC-123', NULL, NULL),
-- ES-01 / ES-02 / D4 fechas en hora de Costa Rica; antes de 1990 = ficticia
('D4',    'fn_FechaCR', N'2025-04-10T10:22:33-0600', NULL, N'2025-04-10T10:22:33-06:00'),
('D4',    'fn_FechaCR', N'2025-04-10T16:22:33Z', NULL, N'2025-04-10T10:22:33-06:00'),
('D4',    'fn_FechaCR', N'2025-04-10T10:22:33', NULL, N'2025-04-10T10:22:33-06:00'),
('D4',    'fn_FechaCR', N'2025-04-10 10:22:33', NULL, N'2025-04-10T10:22:33-06:00'),
('ES-02', 'fn_FechaCR', N'1900-01-01T00:00:00', NULL, NULL),
('ES-02', 'fn_FechaCR', N'no es fecha', NULL, NULL),
('ES-02', 'fn_FechaDia', N'2025-04-10T23:00:00', NULL, N'2025-04-10'),
('ES-02', 'fn_FechaDia', N'1899-12-31', NULL, NULL),
('ES-02', 'fn_EsFechaFicticia', N'1900-01-01', NULL, N'1'),
('ES-02', 'fn_EsFechaFicticia', N'2025-01-01', NULL, N'0'),
('ES-02', 'fn_EsFechaFicticia', N'', NULL, N'0'),
-- ES-07 booleanos
('ES-07', 'fn_Bit', N'Sí', NULL, N'1'),
('ES-07', 'fn_Bit', N'false', NULL, N'0'),
('ES-07', 'fn_Bit', N'quizá', NULL, NULL),
-- ES-04 montos y moneda
('ES-04', 'fn_Monto', N'CRC 25,000.00', NULL, N'25000.0000'),
('ES-04', 'fn_Monto', N'USD 1,234.50', NULL, N'1234.5000'),
('ES-04', 'fn_Monto', N'₡1500', NULL, N'1500.0000'),
('ES-04', 'fn_Monto', N'abc', NULL, NULL),
('ES-04', 'fn_MontoLibre', N'$45', NULL, N'45.0000'),
('ES-04', 'fn_MontoLibre', N'45.50 dólares', NULL, N'45.5000'),
('ES-04', 'fn_MontoLibre', N'25.000 colones', NULL, NULL),
('ES-04', 'fn_MontoLibre', N'25 000', NULL, NULL),
('ES-04', 'fn_MonedaTexto', N'$45', NULL, N'USD'),
('ES-04', 'fn_MonedaTexto', N'₡25000', NULL, N'CRC'),
('ES-04', 'fn_MonedaTexto', N'45', NULL, NULL),
('ES-04', 'fn_Moneda', N' usd ', NULL, N'USD'),
('ES-04', 'fn_Moneda', N'MXN', NULL, NULL),
-- ES-05 coordenadas dentro de Costa Rica (lat 5 a 12, lon -88 a -82); fuera de rango o sin dígitos → NULL
('ES-05', 'fn_Coordenada', N'9.93,-84.08', 1, N'9.9300000'),
('ES-05', 'fn_Coordenada', N'(9.93, -84.08)', 2, N'-84.0800000'),
('ES-05', 'fn_Coordenada', N'https://maps.google.com/?q=9.93,-84.08&z=15', 1, N'9.9300000'),
('ES-05', 'fn_Coordenada', N'-84.08,9.93', 1, N'9.9300000'),
('ES-05', 'fn_Coordenada', N'9°56''12.3"N 84°4''48"W', 1, N'9.9367500'),
('ES-05', 'fn_Coordenada', N'9°56''12.3"N 84°4''48"W', 2, N'-84.0800000'),
('ES-05', 'fn_Coordenada', N'null,null', 1, NULL),
('ES-05', 'fn_Coordenada', N'0,0', 1, NULL),
('ES-05', 'fn_Coordenada', N'40.7,-74.0', 1, NULL),
('ES-05', 'fn_CoordenadaTexto', N'null,null', NULL, NULL),
('ES-05', 'fn_CoordenadaTexto', N' 9.9,-84 ', NULL, N'9.9,-84'),
('ES-05', 'fn_CoordenadaSola', N'9,93', 1, N'9.9300000'),
('ES-05', 'fn_CoordenadaSola', N'20', 1, NULL),
-- Otros
('ES-04', 'fn_PrimerNumero', N'100/100', NULL, N'100.0000'),
('ES-04', 'fn_PrimerNumero', N'50 Mbps', NULL, N'50.0000'),
('ES-04', 'fn_PrimerNumero', N'sin dato', NULL, NULL),
('D10',   'fn_MonedaLlamada', N'50688887777', NULL, N'CRC'),
('D10',   'fn_MonedaLlamada', N'18005551234', NULL, N'USD');

WITH r AS (
    SELECT c.*, CASE c.Funcion
        WHEN 'fn_Texto'              THEN ctl.fn_Texto(c.Entrada)
        WHEN 'fn_Cedula'             THEN CONVERT(nvarchar(100), ctl.fn_Cedula(c.Entrada))
        WHEN 'fn_TipoIdentificacion' THEN CONVERT(nvarchar(100), ctl.fn_TipoIdentificacion(c.Entrada))
        WHEN 'fn_Circuito'           THEN CONVERT(nvarchar(100), ctl.fn_Circuito(c.Entrada))
        WHEN 'fn_FechaCR'            THEN CONVERT(nvarchar(100), ctl.fn_FechaCR(c.Entrada), 126)
        WHEN 'fn_FechaDia'           THEN CONVERT(nvarchar(100), ctl.fn_FechaDia(c.Entrada), 23)
        WHEN 'fn_EsFechaFicticia'    THEN CONVERT(nvarchar(100), ctl.fn_EsFechaFicticia(c.Entrada))
        WHEN 'fn_Bit'                THEN CONVERT(nvarchar(100), ctl.fn_Bit(c.Entrada))
        WHEN 'fn_Monto'              THEN CONVERT(nvarchar(100), ctl.fn_Monto(c.Entrada))
        WHEN 'fn_MontoLibre'         THEN CONVERT(nvarchar(100), ctl.fn_MontoLibre(c.Entrada))
        WHEN 'fn_MonedaTexto'        THEN CONVERT(nvarchar(100), ctl.fn_MonedaTexto(c.Entrada))
        WHEN 'fn_Moneda'             THEN CONVERT(nvarchar(100), ctl.fn_Moneda(c.Entrada))
        WHEN 'fn_Coordenada'         THEN CONVERT(nvarchar(100), ctl.fn_Coordenada(c.Entrada, c.Parte))
        WHEN 'fn_CoordenadaTexto'    THEN ctl.fn_CoordenadaTexto(c.Entrada)
        WHEN 'fn_CoordenadaSola'     THEN CONVERT(nvarchar(100), ctl.fn_CoordenadaSola(c.Entrada, c.Parte))
        WHEN 'fn_PrimerNumero'       THEN CONVERT(nvarchar(100), ctl.fn_PrimerNumero(c.Entrada))
        WHEN 'fn_MonedaLlamada'      THEN CONVERT(nvarchar(100), ctl.fn_MonedaLlamada(c.Entrada))
    END AS Obtenido
    FROM @c c)
SELECT Id, Regla, Funcion, REPLACE(REPLACE(Entrada, NCHAR(9), N'\t'), NCHAR(10), N'\n') AS Entrada, Parte,
       ISNULL(Esperado, N'(NULL)') AS Esperado, ISNULL(Obtenido, N'(NULL)') AS Obtenido,
       CASE WHEN (Esperado IS NULL AND Obtenido IS NULL) OR Esperado = Obtenido COLLATE Latin1_General_BIN THEN 'PASA' ELSE 'FALLA' END AS Resultado
INTO #r FROM r;

PRINT '== Casos';
SELECT Id, Regla, Funcion, Entrada, Parte, Esperado, Obtenido, Resultado FROM #r ORDER BY Id;

PRINT '== Resumen';
SELECT COUNT(*) AS Casos, SUM(CASE WHEN Resultado = 'PASA' THEN 1 ELSE 0 END) AS Pasan,
       SUM(CASE WHEN Resultado = 'FALLA' THEN 1 ELSE 0 END) AS Fallan FROM #r;
SELECT Funcion, Entrada, Esperado, Obtenido FROM #r WHERE Resultado = 'FALLA' ORDER BY Id;
DROP TABLE #r;
