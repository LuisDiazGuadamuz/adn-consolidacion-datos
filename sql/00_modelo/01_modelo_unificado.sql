/* =====================================================================
   Modelo de datos unificado ADN_Unificado - Sprint 2
   American Data Networks S.A. · Proyecto de consolidación de datos
   Autor: Luis Felipe Díaz Guadamuz · Generado desde la especificación model.py
   Ejecutar SOLO en el sandbox (SQL Server 2022). No contiene datos de clientes.
   Tablas: 75 · Esquemas: core, ref, ctl
   ===================================================================== */
SET NOCOUNT ON; SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON;
IF DB_ID(N'ADN_Unificado') IS NULL CREATE DATABASE ADN_Unificado COLLATE Modern_Spanish_CI_AS;
GO
USE ADN_Unificado;
GO
/* Protección: si el modelo ya existe, no se ejecuta nada (evita errores al correrlo dos veces). */
IF OBJECT_ID(N'ctl.Regla', N'U') IS NOT NULL
BEGIN
    RAISERROR(N'El modelo ya existe en ADN_Unificado: no se hizo ningún cambio. Para recrearlo, elimine primero la base en el sandbox.', 10, 1) WITH NOWAIT;
    SET NOEXEC ON;
END
GO
IF SCHEMA_ID(N'ctl') IS NULL EXEC(N'CREATE SCHEMA ctl');
IF SCHEMA_ID(N'ref') IS NULL EXEC(N'CREATE SCHEMA ref');
IF SCHEMA_ID(N'core') IS NULL EXEC(N'CREATE SCHEMA core');
GO

/* ctl.Regla: Catálogo de reglas aprobadas (v1.0, 06/10/2026). Grano: Una fila por regla o decisión. */
CREATE TABLE ctl.Regla (
    [ReglaId] varchar(10) NOT NULL,
    [Tipo] varchar(20) NOT NULL,
    [Descripcion] nvarchar(1000) NOT NULL,
    [Criticidad] varchar(10) NOT NULL,
    [OpcionAprobada] varchar(5) NULL,
    [Version] varchar(10) NOT NULL,
    [FechaAprobacion] date NULL,
    [AprobadoPor] nvarchar(100) NULL,
    CONSTRAINT [PK_ctl_Regla] PRIMARY KEY CLUSTERED ([ReglaId])
);
GO

/* ctl.Fuente: Catálogo de tablas y colecciones de origen. Grano: Una fila por tabla de origen. */
CREATE TABLE ctl.Fuente (
    [FuenteId] int IDENTITY(1,1) NOT NULL,
    [Sistema] varchar(20) NOT NULL,
    [Motor] varchar(20) NOT NULL,
    [Base] nvarchar(128) NOT NULL,
    [Tabla] nvarchar(128) NOT NULL,
    [Disposicion] varchar(20) NOT NULL,
    [MotivoDisposicion] nvarchar(400) NULL,
    [PeriodoDesde] date NULL,
    [PeriodoHasta] date NULL,
    CONSTRAINT [PK_ctl_Fuente] PRIMARY KEY CLUSTERED ([FuenteId]),
    CONSTRAINT [UQ_Fuente_Motor_Base_Tabla] UNIQUE ([Motor], [Base], [Tabla])
);
GO

/* ctl.Lote: Ejecución de un proceso de carga. Grano: Una fila por ejecución y fuente. */
CREATE TABLE ctl.Lote (
    [LoteId] int IDENTITY(1,1) NOT NULL,
    [FuenteId] int NOT NULL,
    [FechaInicio] datetimeoffset(0) NOT NULL,
    [FechaFin] datetimeoffset(0) NULL,
    [Estado] varchar(15) NOT NULL,
    [FilasLeidas] bigint NULL,
    [FilasCargadas] bigint NULL,
    [FilasDescartadas] bigint NULL,
    [VersionReglas] varchar(10) NOT NULL,
    [Usuario] nvarchar(100) NOT NULL,
    CONSTRAINT [PK_ctl_Lote] PRIMARY KEY CLUSTERED ([LoteId])
);
GO

/* ctl.Descarte: Registros de origen no cargados, con la regla que los excluyó. Grano: Una fila por registro descartado. */
CREATE TABLE ctl.Descarte (
    [DescarteId] bigint IDENTITY(1,1) NOT NULL,
    [LoteId] int NOT NULL,
    [ReglaId] varchar(10) NOT NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NULL,
    [LlaveConservada] nvarchar(200) NULL,
    [Motivo] nvarchar(400) NOT NULL,
    [ContenidoOrigen] nvarchar(max) NULL,
    [FechaDescarte] datetimeoffset(0) NOT NULL,
    CONSTRAINT [PK_ctl_Descarte] PRIMARY KEY CLUSTERED ([DescarteId])
);
GO

/* ctl.Anomalia: Valores marcados por una regla (fechas ficticias, futuras, huérfanos, cédulas inválidas). Grano: Una fila por valor marcado. */
CREATE TABLE ctl.Anomalia (
    [AnomaliaId] bigint IDENTITY(1,1) NOT NULL,
    [LoteId] int NOT NULL,
    [ReglaId] varchar(10) NOT NULL,
    [TablaModelo] nvarchar(128) NOT NULL,
    [RegistroId] bigint NOT NULL,
    [Columna] nvarchar(128) NULL,
    [ValorOriginal] nvarchar(400) NULL,
    [Detalle] nvarchar(400) NULL,
    CONSTRAINT [PK_ctl_Anomalia] PRIMARY KEY CLUSTERED ([AnomaliaId])
);
GO

/* ctl.LinajeCampo: Origen de cada campo en las tablas que consolidan varios sistemas (Cliente, Servicio, Producto). Grano: Una fila por registro, columna y fuente ganadora. */
CREATE TABLE ctl.LinajeCampo (
    [LinajeCampoId] bigint IDENTITY(1,1) NOT NULL,
    [TablaModelo] nvarchar(128) NOT NULL,
    [RegistroId] bigint NOT NULL,
    [Columna] nvarchar(128) NOT NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [LoteId] int NOT NULL,
    CONSTRAINT [PK_ctl_LinajeCampo] PRIMARY KEY CLUSTERED ([LinajeCampoId]),
    CONSTRAINT [UQ_LinajeCampo_TablaModelo_RegistroId_Columna] UNIQUE ([TablaModelo], [RegistroId], [Columna])
);
GO

/* ref.TipoCambio: Tipo de cambio del dólar por día. Grano: Una fila por fecha. */
CREATE TABLE ref.TipoCambio (
    [TipoCambioId] int IDENTITY(1,1) NOT NULL,
    [Fecha] date NOT NULL,
    [Compra] decimal(19,6) NULL,
    [Venta] decimal(19,6) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_TipoCambio_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_ref_TipoCambio] PRIMARY KEY CLUSTERED ([TipoCambioId]),
    CONSTRAINT [UQ_TipoCambio_Fecha] UNIQUE ([Fecha])
);
CREATE INDEX [IX_TipoCambio_Linaje] ON ref.TipoCambio ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* ref.Usuario: Usuarios de Zoho (ejecutivos, técnicos, agentes). Grano: Una fila por usuario de Zoho. */
CREATE TABLE ref.Usuario (
    [UsuarioId] int IDENTITY(1,1) NOT NULL,
    [ZohoUsuarioId] nvarchar(30) NOT NULL,
    [NombreCompleto] nvarchar(200) NULL,
    [Correo] nvarchar(200) NULL,
    [Telefono] nvarchar(30) NULL,
    [Rol] nvarchar(100) NULL,
    [Perfil] nvarchar(100) NULL,
    [Division] nvarchar(100) NULL,
    [Estado] nvarchar(30) NULL,
    [AtributosExtendidos] nvarchar(max) NULL,
    [FechaCreacionOrigen] datetimeoffset(0) NULL,
    [FechaModificacionOrigen] datetimeoffset(0) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_Usuario_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_ref_Usuario] PRIMARY KEY CLUSTERED ([UsuarioId]),
    CONSTRAINT [UQ_Usuario_ZohoUsuarioId] UNIQUE ([ZohoUsuarioId]),
    CONSTRAINT [CK_Usuario_AtributosJSON] CHECK ([AtributosExtendidos] IS NULL OR ISJSON([AtributosExtendidos]) = 1)
);
CREATE INDEX [IX_Usuario_Linaje] ON ref.Usuario ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* ref.Provincia: Provincias de Costa Rica. Grano: Una fila por provincia. */
CREATE TABLE ref.Provincia (
    [ProvinciaId] int IDENTITY(1,1) NOT NULL,
    [Nombre] nvarchar(60) NOT NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_Provincia_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_ref_Provincia] PRIMARY KEY CLUSTERED ([ProvinciaId]),
    CONSTRAINT [UQ_Provincia_Nombre] UNIQUE ([Nombre])
);
CREATE INDEX [IX_Provincia_Linaje] ON ref.Provincia ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* ref.Canton: Cantones. Grano: Una fila por cantón. */
CREATE TABLE ref.Canton (
    [CantonId] int IDENTITY(1,1) NOT NULL,
    [ProvinciaId] int NOT NULL,
    [Nombre] nvarchar(80) NOT NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_Canton_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_ref_Canton] PRIMARY KEY CLUSTERED ([CantonId])
);
CREATE INDEX [IX_Canton_Linaje] ON ref.Canton ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* ref.Distrito: Distritos. Grano: Una fila por distrito. */
CREATE TABLE ref.Distrito (
    [DistritoId] int IDENTITY(1,1) NOT NULL,
    [CantonId] int NOT NULL,
    [Nombre] nvarchar(80) NOT NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_Distrito_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_ref_Distrito] PRIMARY KEY CLUSTERED ([DistritoId])
);
CREATE INDEX [IX_Distrito_Linaje] ON ref.Distrito ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* ref.Impuesto: Impuestos configurados en Zoho Books. Grano: Una fila por impuesto. */
CREATE TABLE ref.Impuesto (
    [ImpuestoId] int IDENTITY(1,1) NOT NULL,
    [ImpuestoBooksId] nvarchar(30) NOT NULL,
    [Nombre] nvarchar(100) NULL,
    [Porcentaje] decimal(9,4) NULL,
    [Tipo] nvarchar(50) NULL,
    [EsPredeterminado] bit NULL,
    [AtributosExtendidos] nvarchar(max) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_Impuesto_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_ref_Impuesto] PRIMARY KEY CLUSTERED ([ImpuestoId]),
    CONSTRAINT [UQ_Impuesto_ImpuestoBooksId] UNIQUE ([ImpuestoBooksId]),
    CONSTRAINT [CK_Impuesto_AtributosJSON] CHECK ([AtributosExtendidos] IS NULL OR ISJSON([AtributosExtendidos]) = 1)
);
CREATE INDEX [IX_Impuesto_Linaje] ON ref.Impuesto ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* ref.CuentaContable: Catálogo de cuentas contables de Zoho Books. Grano: Una fila por cuenta. */
CREATE TABLE ref.CuentaContable (
    [CuentaContableId] int IDENTITY(1,1) NOT NULL,
    [CuentaBooksId] nvarchar(30) NOT NULL,
    [CuentaPadreId] int NULL,
    [Codigo] nvarchar(50) NULL,
    [Nombre] nvarchar(200) NULL,
    [Tipo] nvarchar(50) NULL,
    [Descripcion] nvarchar(500) NULL,
    [EsDeSistema] bit NULL,
    [Activa] bit NULL,
    [AtributosExtendidos] nvarchar(max) NULL,
    [FechaCreacionOrigen] datetimeoffset(0) NULL,
    [FechaModificacionOrigen] datetimeoffset(0) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_CuentaContable_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_ref_CuentaContable] PRIMARY KEY CLUSTERED ([CuentaContableId]),
    CONSTRAINT [UQ_CuentaContable_CuentaBooksId] UNIQUE ([CuentaBooksId]),
    CONSTRAINT [CK_CuentaContable_AtributosJSON] CHECK ([AtributosExtendidos] IS NULL OR ISJSON([AtributosExtendidos]) = 1)
);
CREATE INDEX [IX_CuentaContable_Linaje] ON ref.CuentaContable ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* ref.ProveedorTelefonia: Proveedores de terminación de llamadas. Grano: Una fila por proveedor. */
CREATE TABLE ref.ProveedorTelefonia (
    [ProveedorTelefoniaId] int IDENTITY(1,1) NOT NULL,
    [Nombre] nvarchar(100) NOT NULL,
    [FechaActualizacionTarifas] datetimeoffset(0) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_ProveedorTelefonia_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_ref_ProveedorTelefonia] PRIMARY KEY CLUSTERED ([ProveedorTelefoniaId])
);
CREATE INDEX [IX_ProveedorTelefonia_Linaje] ON ref.ProveedorTelefonia ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* ref.TroncalProveedor: Troncales de los proveedores de telefonía. Grano: Una fila por troncal de proveedor. */
CREATE TABLE ref.TroncalProveedor (
    [TroncalProveedorId] int IDENTITY(1,1) NOT NULL,
    [ProveedorTelefoniaId] int NOT NULL,
    [CodigoTroncal] nvarchar(50) NOT NULL,
    [Estado] nvarchar(30) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_TroncalProveedor_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_ref_TroncalProveedor] PRIMARY KEY CLUSTERED ([TroncalProveedorId])
);
CREATE INDEX [IX_TroncalProveedor_Linaje] ON ref.TroncalProveedor ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* ref.TarifaDestino: Tarifas por código de marcación (país y números especiales). Grano: Una fila por proveedor y código. */
CREATE TABLE ref.TarifaDestino (
    [TarifaDestinoId] int IDENTITY(1,1) NOT NULL,
    [ProveedorTelefoniaId] int NULL,
    [CodigoMarcacion] varchar(20) NOT NULL,
    [Nombre] nvarchar(150) NULL,
    [Tarifa] decimal(19,4) NULL,
    [Redondeo] decimal(9,2) NULL,
    [Costo] decimal(19,4) NULL,
    [EsNumeroEspecial] bit NOT NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_TarifaDestino_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_ref_TarifaDestino] PRIMARY KEY CLUSTERED ([TarifaDestinoId])
);
CREATE INDEX [IX_TarifaDestino_Linaje] ON ref.TarifaDestino ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* ref.PaqueteMinutos: Paquetes de minutos de telefonía. Grano: Una fila por paquete. */
CREATE TABLE ref.PaqueteMinutos (
    [PaqueteMinutosId] int IDENTITY(1,1) NOT NULL,
    [Codigo] nvarchar(30) NOT NULL,
    [Descripcion] nvarchar(200) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_PaqueteMinutos_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_ref_PaqueteMinutos] PRIMARY KEY CLUSTERED ([PaqueteMinutosId])
);
CREATE INDEX [IX_PaqueteMinutos_Linaje] ON ref.PaqueteMinutos ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* ref.PaqueteMinutosCodigo: Códigos de marcación incluidos en cada paquete. Grano: Una fila por paquete y código. */
CREATE TABLE ref.PaqueteMinutosCodigo (
    [PaqueteMinutosCodigoId] int IDENTITY(1,1) NOT NULL,
    [PaqueteMinutosId] int NOT NULL,
    [CodigoMarcacion] varchar(20) NOT NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_PaqueteMinutosCodigo_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_ref_PaqueteMinutosCodigo] PRIMARY KEY CLUSTERED ([PaqueteMinutosCodigoId])
);
CREATE INDEX [IX_PaqueteMinutosCodigo_Linaje] ON ref.PaqueteMinutosCodigo ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* ref.CodigoPromocion: Códigos promocionales de ADNPayV2. Grano: Una fila por código. */
CREATE TABLE ref.CodigoPromocion (
    [CodigoPromocionId] int IDENTITY(1,1) NOT NULL,
    [Codigo] varchar(50) NOT NULL,
    [Categoria] varchar(50) NULL,
    [Activo] bit NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_CodigoPromocion_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_ref_CodigoPromocion] PRIMARY KEY CLUSTERED ([CodigoPromocionId])
);
CREATE INDEX [IX_CodigoPromocion_Linaje] ON ref.CodigoPromocion ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* ref.UnidadFlota: Vehículos y dispositivos de rastreo de Navsat. Grano: Una fila por dispositivo. */
CREATE TABLE ref.UnidadFlota (
    [UnidadFlotaId] int IDENTITY(1,1) NOT NULL,
    [Dispositivo] nvarchar(100) NOT NULL,
    [Placa] nvarchar(30) NULL,
    [TipoUnidad] varchar(20) NOT NULL,
    [Descripcion] nvarchar(200) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_UnidadFlota_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_ref_UnidadFlota] PRIMARY KEY CLUSTERED ([UnidadFlotaId]),
    CONSTRAINT [UQ_UnidadFlota_Dispositivo] UNIQUE ([Dispositivo])
);
CREATE INDEX [IX_UnidadFlota_Linaje] ON ref.UnidadFlota ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.Cliente: Persona o empresa cliente, identificada por su cédula. Grano: Una fila por cédula válida, o por cliente sin cédula. */
CREATE TABLE core.Cliente (
    [ClienteId] int IDENTITY(1,1) NOT NULL,
    [Cedula] varchar(12) NULL,
    [TipoIdentificacion] varchar(10) NOT NULL,
    [Nombre] nvarchar(200) NULL,
    [RazonSocial] nvarchar(200) NULL,
    [TipoFiscal] nvarchar(50) NULL,
    [Exonerado] bit NULL,
    [Correo] nvarchar(200) NULL,
    [Telefono] nvarchar(30) NULL,
    [Segmento] nvarchar(50) NULL,
    [Industria] nvarchar(100) NULL,
    [EstadoCorrespondencia] varchar(20) NOT NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_Cliente_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_Cliente] PRIMARY KEY CLUSTERED ([ClienteId]),
    CONSTRAINT [CK_Cliente_Cedula] CHECK ([Cedula] IS NULL OR ([Cedula] NOT LIKE '%[^0-9]%' AND LEN([Cedula]) IN (9,10,12)))
);
CREATE UNIQUE INDEX [UX_Cliente_Cedula] ON core.Cliente ([Cedula]) WHERE Cedula IS NOT NULL;
CREATE INDEX [IX_Cliente_Linaje] ON core.Cliente ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.ClienteOrigen: Tabla de correspondencia: cada identificador de origen y el cliente o servicio al que se vinculó. Grano: Una fila por registro de origen. */
CREATE TABLE core.ClienteOrigen (
    [ClienteOrigenId] int IDENTITY(1,1) NOT NULL,
    [ClienteId] int NULL,
    [ServicioId] int NULL,
    [Sistema] varchar(20) NOT NULL,
    [TablaOrigen] nvarchar(128) NOT NULL,
    [LlaveOrigen] nvarchar(200) NOT NULL,
    [CedulaOriginal] nvarchar(50) NULL,
    [CircuitoOriginal] nvarchar(100) NULL,
    [MetodoEmparejamiento] varchar(20) NOT NULL,
    [FechaEmparejamiento] datetimeoffset(0) NOT NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_ClienteOrigen_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_ClienteOrigen] PRIMARY KEY CLUSTERED ([ClienteOrigenId]),
    CONSTRAINT [UQ_ClienteOrigen_Sistema_TablaOrigen_LlaveOrigen] UNIQUE ([Sistema], [TablaOrigen], [LlaveOrigen])
);
CREATE INDEX [IX_ClienteOrigen_Linaje] ON core.ClienteOrigen ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.Servicio: Servicio contratado, identificado por el número de circuito; corresponde a una cuenta del CRM. Grano: Una fila por cuenta del CRM o circuito. */
CREATE TABLE core.Servicio (
    [ServicioId] int IDENTITY(1,1) NOT NULL,
    [ClienteId] int NULL,
    [Circuito] varchar(12) NULL,
    [CuentaCrmId] nvarchar(30) NULL,
    [NombreCuenta] nvarchar(200) NULL,
    [TipoCuenta] nvarchar(50) NULL,
    [Estado] nvarchar(50) NULL,
    [Plataforma] nvarchar(100) NULL,
    [CapacidadMbps] decimal(9,2) NULL,
    [TieneIPTV] bit NULL,
    [TieneVoIP] bit NULL,
    [NumeroTroncal] nvarchar(50) NULL,
    [LineaDID] nvarchar(50) NULL,
    [Moneda] char(3) NULL,
    [TipoCambio] decimal(19,6) NULL,
    [Mensualidad] decimal(19,4) NULL,
    [MensualidadCRC] decimal(19,4) NULL,
    [DistritoId] int NULL,
    [Provincia] nvarchar(60) NULL,
    [Canton] nvarchar(80) NULL,
    [DistritoTexto] nvarchar(80) NULL,
    [DireccionExacta] nvarchar(1000) NULL,
    [Latitud] decimal(10,7) NULL,
    [Longitud] decimal(10,7) NULL,
    [CondominioId] int NULL,
    [EjecutivoUsuarioId] int NULL,
    [FechaInstalacion] date NULL,
    [FechaActivacion] datetimeoffset(0) NULL,
    [FechaRetiro] date NULL,
    [EstadoCorrespondencia] varchar(20) NOT NULL,
    [AtributosExtendidos] nvarchar(max) NULL,
    [FechaCreacionOrigen] datetimeoffset(0) NULL,
    [FechaModificacionOrigen] datetimeoffset(0) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_Servicio_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_Servicio] PRIMARY KEY CLUSTERED ([ServicioId]),
    CONSTRAINT [CK_Servicio_AtributosJSON] CHECK ([AtributosExtendidos] IS NULL OR ISJSON([AtributosExtendidos]) = 1),
    CONSTRAINT [CK_Servicio_Circuito] CHECK ([Circuito] IS NULL OR [Circuito] LIKE '[A-Z][A-Z][A-Z][0-9][0-9][0-9][0-9]%'),
    CONSTRAINT [CK_Servicio_Moneda] CHECK ([Moneda] IS NULL OR [Moneda] IN ('CRC','USD','EUR'))
);
CREATE UNIQUE INDEX [UX_Servicio_CuentaCrmId] ON core.Servicio ([CuentaCrmId]) WHERE CuentaCrmId IS NOT NULL;
CREATE INDEX [IX_Servicio_Circuito] ON core.Servicio ([Circuito]);
CREATE INDEX [IX_Servicio_Linaje] ON core.Servicio ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.Contacto: Personas de contacto del CRM. Grano: Una fila por contacto del CRM. */
CREATE TABLE core.Contacto (
    [ContactoId] int IDENTITY(1,1) NOT NULL,
    [ClienteId] int NULL,
    [ServicioId] int NULL,
    [ContactoCrmId] nvarchar(30) NOT NULL,
    [Nombre] nvarchar(100) NULL,
    [Apellido] nvarchar(100) NULL,
    [NombreCompleto] nvarchar(200) NULL,
    [Cedula] varchar(12) NULL,
    [Correo] nvarchar(200) NULL,
    [Telefono] nvarchar(30) NULL,
    [Movil] nvarchar(30) NULL,
    [TipoContacto] nvarchar(50) NULL,
    [PropietarioUsuarioId] int NULL,
    [AtributosExtendidos] nvarchar(max) NULL,
    [FechaCreacionOrigen] datetimeoffset(0) NULL,
    [FechaModificacionOrigen] datetimeoffset(0) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_Contacto_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_Contacto] PRIMARY KEY CLUSTERED ([ContactoId]),
    CONSTRAINT [UQ_Contacto_ContactoCrmId] UNIQUE ([ContactoCrmId]),
    CONSTRAINT [CK_Contacto_AtributosJSON] CHECK ([AtributosExtendidos] IS NULL OR ISJSON([AtributosExtendidos]) = 1)
);
CREATE INDEX [IX_Contacto_Linaje] ON core.Contacto ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.Prospecto: Prospectos de venta (CRM y registros en línea de ADNPayV2). Grano: Una fila por prospecto de origen. */
CREATE TABLE core.Prospecto (
    [ProspectoId] int IDENTITY(1,1) NOT NULL,
    [ClienteId] int NULL,
    [Cedula] varchar(12) NULL,
    [Nombre] nvarchar(100) NULL,
    [Apellido] nvarchar(100) NULL,
    [Empresa] nvarchar(200) NULL,
    [Correo] nvarchar(200) NULL,
    [Telefono] nvarchar(30) NULL,
    [Movil] nvarchar(30) NULL,
    [Estado] nvarchar(50) NULL,
    [Origen] nvarchar(100) NULL,
    [Segmento] nvarchar(50) NULL,
    [CondominioSolicitado] nvarchar(200) NULL,
    [DireccionId] int NULL,
    [Provincia] nvarchar(60) NULL,
    [Canton] nvarchar(80) NULL,
    [FechaRegistro] datetimeoffset(0) NULL,
    [FechaConversion] datetimeoffset(0) NULL,
    [CompraRealizada] bit NULL,
    [PropietarioUsuarioId] int NULL,
    [AtributosExtendidos] nvarchar(max) NULL,
    [FechaCreacionOrigen] datetimeoffset(0) NULL,
    [FechaModificacionOrigen] datetimeoffset(0) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_Prospecto_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_Prospecto] PRIMARY KEY CLUSTERED ([ProspectoId]),
    CONSTRAINT [CK_Prospecto_AtributosJSON] CHECK ([AtributosExtendidos] IS NULL OR ISJSON([AtributosExtendidos]) = 1)
);
CREATE INDEX [IX_Prospecto_Linaje] ON core.Prospecto ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.Direccion: Direcciones registradas en ADNPayV2. Grano: Una fila por dirección. */
CREATE TABLE core.Direccion (
    [DireccionId] int IDENTITY(1,1) NOT NULL,
    [DistritoId] int NULL,
    [Descripcion] nvarchar(500) NULL,
    [Alias] nvarchar(100) NULL,
    [CodigoPostal] nvarchar(20) NULL,
    [Pais] nvarchar(60) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_Direccion_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_Direccion] PRIMARY KEY CLUSTERED ([DireccionId])
);
CREATE INDEX [IX_Direccion_Linaje] ON core.Direccion ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.Condominio: Condominios con cobertura o en proyecto. Grano: Una fila por condominio. */
CREATE TABLE core.Condominio (
    [CondominioId] int IDENTITY(1,1) NOT NULL,
    [CondominioCrmId] nvarchar(30) NOT NULL,
    [Nombre] nvarchar(200) NULL,
    [Tipo] nvarchar(50) NULL,
    [TipoConstruccion] nvarchar(50) NULL,
    [CantidadCasas] int NULL,
    [CapacidadMaxima] int NULL,
    [AplicaFTTH] bit NULL,
    [Provincia] nvarchar(60) NULL,
    [Canton] nvarchar(80) NULL,
    [Distrito] nvarchar(80) NULL,
    [Direccion] nvarchar(1000) NULL,
    [Latitud] decimal(10,7) NULL,
    [Longitud] decimal(10,7) NULL,
    [FechaInstalacion] date NULL,
    [AtributosExtendidos] nvarchar(max) NULL,
    [FechaCreacionOrigen] datetimeoffset(0) NULL,
    [FechaModificacionOrigen] datetimeoffset(0) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_Condominio_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_Condominio] PRIMARY KEY CLUSTERED ([CondominioId]),
    CONSTRAINT [UQ_Condominio_CondominioCrmId] UNIQUE ([CondominioCrmId]),
    CONSTRAINT [CK_Condominio_AtributosJSON] CHECK ([AtributosExtendidos] IS NULL OR ISJSON([AtributosExtendidos]) = 1)
);
CREATE INDEX [IX_Condominio_Linaje] ON core.Condominio ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.Nodo: Nodos de red. Grano: Una fila por nodo. */
CREATE TABLE core.Nodo (
    [NodoId] int IDENTITY(1,1) NOT NULL,
    [NodoCrmId] nvarchar(30) NOT NULL,
    [Nombre] nvarchar(200) NULL,
    [Nomenclatura] nvarchar(50) NULL,
    [Estado] nvarchar(50) NULL,
    [Capacidad] nvarchar(50) NULL,
    [CantidadClientes] int NULL,
    [Provincia] nvarchar(60) NULL,
    [Direccion] nvarchar(1000) NULL,
    [Latitud] decimal(10,7) NULL,
    [Longitud] decimal(10,7) NULL,
    [AtributosExtendidos] nvarchar(max) NULL,
    [FechaCreacionOrigen] datetimeoffset(0) NULL,
    [FechaModificacionOrigen] datetimeoffset(0) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_Nodo_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_Nodo] PRIMARY KEY CLUSTERED ([NodoId]),
    CONSTRAINT [UQ_Nodo_NodoCrmId] UNIQUE ([NodoCrmId]),
    CONSTRAINT [CK_Nodo_AtributosJSON] CHECK ([AtributosExtendidos] IS NULL OR ISJSON([AtributosExtendidos]) = 1)
);
CREATE INDEX [IX_Nodo_Linaje] ON core.Nodo ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.ClusterFTTH: Clústeres de fibra hasta el hogar. Grano: Una fila por clúster. */
CREATE TABLE core.ClusterFTTH (
    [ClusterFTTHId] int IDENTITY(1,1) NOT NULL,
    [ClusterCrmId] nvarchar(30) NOT NULL,
    [Nombre] nvarchar(200) NULL,
    [CodigoCluster] nvarchar(50) NULL,
    [NodoId] int NULL,
    [Fase] nvarchar(50) NULL,
    [CapacidadRed] int NULL,
    [CantidadClientes] int NULL,
    [Provincia] nvarchar(60) NULL,
    [Canton] nvarchar(80) NULL,
    [Distrito] nvarchar(80) NULL,
    [FechaInstalacion] date NULL,
    [AtributosExtendidos] nvarchar(max) NULL,
    [FechaCreacionOrigen] datetimeoffset(0) NULL,
    [FechaModificacionOrigen] datetimeoffset(0) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_ClusterFTTH_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_ClusterFTTH] PRIMARY KEY CLUSTERED ([ClusterFTTHId]),
    CONSTRAINT [UQ_ClusterFTTH_ClusterCrmId] UNIQUE ([ClusterCrmId]),
    CONSTRAINT [CK_ClusterFTTH_AtributosJSON] CHECK ([AtributosExtendidos] IS NULL OR ISJSON([AtributosExtendidos]) = 1)
);
CREATE INDEX [IX_ClusterFTTH_Linaje] ON core.ClusterFTTH ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.Oportunidad: Oportunidades de venta del CRM. Grano: Una fila por oportunidad. */
CREATE TABLE core.Oportunidad (
    [OportunidadId] int IDENTITY(1,1) NOT NULL,
    [OportunidadCrmId] nvarchar(30) NOT NULL,
    [ServicioId] int NULL,
    [ContactoId] int NULL,
    [Nombre] nvarchar(200) NULL,
    [Etapa] nvarchar(50) NULL,
    [Probabilidad] decimal(5,2) NULL,
    [Moneda] char(3) NULL,
    [TipoCambio] decimal(19,6) NULL,
    [Monto] decimal(19,4) NULL,
    [MontoCRC] decimal(19,4) NULL,
    [FechaCierre] date NULL,
    [Segmento] nvarchar(50) NULL,
    [PropietarioUsuarioId] int NULL,
    [AtributosExtendidos] nvarchar(max) NULL,
    [FechaCreacionOrigen] datetimeoffset(0) NULL,
    [FechaModificacionOrigen] datetimeoffset(0) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_Oportunidad_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_Oportunidad] PRIMARY KEY CLUSTERED ([OportunidadId]),
    CONSTRAINT [UQ_Oportunidad_OportunidadCrmId] UNIQUE ([OportunidadCrmId]),
    CONSTRAINT [CK_Oportunidad_AtributosJSON] CHECK ([AtributosExtendidos] IS NULL OR ISJSON([AtributosExtendidos]) = 1),
    CONSTRAINT [CK_Oportunidad_Moneda] CHECK ([Moneda] IS NULL OR [Moneda] IN ('CRC','USD','EUR'))
);
CREATE INDEX [IX_Oportunidad_Linaje] ON core.Oportunidad ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.Cotizacion: Cotizaciones del CRM. Grano: Una fila por cotización. */
CREATE TABLE core.Cotizacion (
    [CotizacionId] int IDENTITY(1,1) NOT NULL,
    [CotizacionCrmId] nvarchar(30) NOT NULL,
    [OportunidadId] int NULL,
    [ServicioId] int NULL,
    [ContactoId] int NULL,
    [Asunto] nvarchar(300) NULL,
    [Etapa] nvarchar(50) NULL,
    [Tipo] nvarchar(50) NULL,
    [Moneda] char(3) NULL,
    [TipoCambio] decimal(19,6) NULL,
    [SubTotal] decimal(19,4) NULL,
    [SubTotalCRC] decimal(19,4) NULL,
    [Impuesto] decimal(19,4) NULL,
    [ImpuestoCRC] decimal(19,4) NULL,
    [Descuento] decimal(19,4) NULL,
    [DescuentoCRC] decimal(19,4) NULL,
    [Total] decimal(19,4) NULL,
    [TotalCRC] decimal(19,4) NULL,
    [FechaCotizacion] date NULL,
    [AtributosExtendidos] nvarchar(max) NULL,
    [FechaCreacionOrigen] datetimeoffset(0) NULL,
    [FechaModificacionOrigen] datetimeoffset(0) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_Cotizacion_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_Cotizacion] PRIMARY KEY CLUSTERED ([CotizacionId]),
    CONSTRAINT [UQ_Cotizacion_CotizacionCrmId] UNIQUE ([CotizacionCrmId]),
    CONSTRAINT [CK_Cotizacion_AtributosJSON] CHECK ([AtributosExtendidos] IS NULL OR ISJSON([AtributosExtendidos]) = 1),
    CONSTRAINT [CK_Cotizacion_Moneda] CHECK ([Moneda] IS NULL OR [Moneda] IN ('CRC','USD','EUR'))
);
CREATE INDEX [IX_Cotizacion_Linaje] ON core.Cotizacion ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.OrdenVenta: Órdenes de venta y contratos del CRM. Grano: Una fila por orden de venta. */
CREATE TABLE core.OrdenVenta (
    [OrdenVentaId] int IDENTITY(1,1) NOT NULL,
    [OrdenVentaCrmId] nvarchar(30) NOT NULL,
    [ServicioId] int NULL,
    [ContactoId] int NULL,
    [OportunidadId] int NULL,
    [CotizacionId] int NULL,
    [Circuito] varchar(12) NULL,
    [Asunto] nvarchar(300) NULL,
    [Estado] nvarchar(50) NULL,
    [TipoContrato] nvarchar(100) NULL,
    [PlazoMeses] int NULL,
    [CapacidadDescargaMbps] decimal(9,2) NULL,
    [CapacidadCargaMbps] decimal(9,2) NULL,
    [Moneda] char(3) NULL,
    [TipoCambio] decimal(19,6) NULL,
    [SubTotal] decimal(19,4) NULL,
    [SubTotalCRC] decimal(19,4) NULL,
    [Impuesto] decimal(19,4) NULL,
    [ImpuestoCRC] decimal(19,4) NULL,
    [Descuento] decimal(19,4) NULL,
    [DescuentoCRC] decimal(19,4) NULL,
    [Total] decimal(19,4) NULL,
    [TotalCRC] decimal(19,4) NULL,
    [Mensualidad] decimal(19,4) NULL,
    [MensualidadCRC] decimal(19,4) NULL,
    [FechaFirma] date NULL,
    [FechaInactivacion] date NULL,
    [PropietarioUsuarioId] int NULL,
    [AtributosExtendidos] nvarchar(max) NULL,
    [FechaCreacionOrigen] datetimeoffset(0) NULL,
    [FechaModificacionOrigen] datetimeoffset(0) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_OrdenVenta_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_OrdenVenta] PRIMARY KEY CLUSTERED ([OrdenVentaId]),
    CONSTRAINT [UQ_OrdenVenta_OrdenVentaCrmId] UNIQUE ([OrdenVentaCrmId]),
    CONSTRAINT [CK_OrdenVenta_AtributosJSON] CHECK ([AtributosExtendidos] IS NULL OR ISJSON([AtributosExtendidos]) = 1),
    CONSTRAINT [CK_OrdenVenta_Moneda] CHECK ([Moneda] IS NULL OR [Moneda] IN ('CRC','USD','EUR'))
);
CREATE INDEX [IX_OrdenVenta_Linaje] ON core.OrdenVenta ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.OrdenVentaLinea: Productos de cada orden de venta. Grano: Una fila por línea. */
CREATE TABLE core.OrdenVentaLinea (
    [OrdenVentaLineaId] int IDENTITY(1,1) NOT NULL,
    [OrdenVentaId] int NOT NULL,
    [ProductoId] int NULL,
    [Descripcion] nvarchar(1000) NULL,
    [Cantidad] decimal(12,2) NULL,
    [Moneda] char(3) NULL,
    [TipoCambio] decimal(19,6) NULL,
    [PrecioUnitario] decimal(19,4) NULL,
    [PrecioUnitarioCRC] decimal(19,4) NULL,
    [Descuento] decimal(19,4) NULL,
    [DescuentoCRC] decimal(19,4) NULL,
    [Impuesto] decimal(19,4) NULL,
    [ImpuestoCRC] decimal(19,4) NULL,
    [Total] decimal(19,4) NULL,
    [TotalCRC] decimal(19,4) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_OrdenVentaLinea_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_OrdenVentaLinea] PRIMARY KEY CLUSTERED ([OrdenVentaLineaId]),
    CONSTRAINT [CK_OrdenVentaLinea_Moneda] CHECK ([Moneda] IS NULL OR [Moneda] IN ('CRC','USD','EUR'))
);
CREATE INDEX [IX_OrdenVentaLinea_Linaje] ON core.OrdenVentaLinea ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.Producto: Catálogo unificado de productos y planes (CRM, Books y ADNPayV2). Grano: Una fila por producto de origen consolidado. */
CREATE TABLE core.Producto (
    [ProductoId] int IDENTITY(1,1) NOT NULL,
    [Sistema] varchar(20) NOT NULL,
    [ProductoCrmId] nvarchar(30) NULL,
    [ItemBooksId] nvarchar(30) NULL,
    [CodigoOrigen] nvarchar(50) NULL,
    [Nombre] nvarchar(200) NULL,
    [Descripcion] nvarchar(1000) NULL,
    [Tipo] nvarchar(50) NULL,
    [Categoria] nvarchar(100) NULL,
    [Unidad] nvarchar(30) NULL,
    [CodigoCabys] nvarchar(30) NULL,
    [ImpuestoId] int NULL,
    [Moneda] char(3) NULL,
    [TipoCambio] decimal(19,6) NULL,
    [Precio] decimal(19,4) NULL,
    [PrecioCRC] decimal(19,4) NULL,
    [PrecioSinImpuesto] decimal(19,4) NULL,
    [PrecioSinImpuestoCRC] decimal(19,4) NULL,
    [VelocidadDescargaMbps] decimal(9,2) NULL,
    [VelocidadCargaMbps] decimal(9,2) NULL,
    [IncluyeIPTV] bit NULL,
    [IncluyeTelefonia] bit NULL,
    [IncluyeIPPublica] bit NULL,
    [Activo] bit NULL,
    [AtributosExtendidos] nvarchar(max) NULL,
    [FechaCreacionOrigen] datetimeoffset(0) NULL,
    [FechaModificacionOrigen] datetimeoffset(0) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_Producto_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_Producto] PRIMARY KEY CLUSTERED ([ProductoId]),
    CONSTRAINT [CK_Producto_AtributosJSON] CHECK ([AtributosExtendidos] IS NULL OR ISJSON([AtributosExtendidos]) = 1),
    CONSTRAINT [CK_Producto_Moneda] CHECK ([Moneda] IS NULL OR [Moneda] IN ('CRC','USD','EUR'))
);
CREATE INDEX [IX_Producto_Linaje] ON core.Producto ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.OrdenTrabajo: Órdenes de trabajo de instalación y mantenimiento. Grano: Una fila por orden de trabajo. */
CREATE TABLE core.OrdenTrabajo (
    [OrdenTrabajoId] int IDENTITY(1,1) NOT NULL,
    [OrdenTrabajoCrmId] nvarchar(30) NOT NULL,
    [ServicioId] int NULL,
    [NodoId] int NULL,
    [Nombre] nvarchar(200) NULL,
    [Tipo] nvarchar(100) NULL,
    [TipoSolicitud] nvarchar(100) NULL,
    [Estado] nvarchar(50) NULL,
    [SubEstado] nvarchar(50) NULL,
    [Tecnologia] nvarchar(50) NULL,
    [CapacidadDescarga] nvarchar(50) NULL,
    [CapacidadCarga] nvarchar(50) NULL,
    [Provincia] nvarchar(60) NULL,
    [Canton] nvarchar(80) NULL,
    [Distrito] nvarchar(80) NULL,
    [DireccionExacta] nvarchar(1000) NULL,
    [Latitud] decimal(10,7) NULL,
    [Longitud] decimal(10,7) NULL,
    [FechaCreacionOT] datetimeoffset(0) NULL,
    [FechaCoordinada] datetimeoffset(0) NULL,
    [FechaEstimada] datetimeoffset(0) NULL,
    [FechaFinalizacion] datetimeoffset(0) NULL,
    [FechaEntregaEnlace] datetimeoffset(0) NULL,
    [AsignadoUsuarioId] int NULL,
    [AtributosExtendidos] nvarchar(max) NULL,
    [FechaCreacionOrigen] datetimeoffset(0) NULL,
    [FechaModificacionOrigen] datetimeoffset(0) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_OrdenTrabajo_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_OrdenTrabajo] PRIMARY KEY CLUSTERED ([OrdenTrabajoId]),
    CONSTRAINT [UQ_OrdenTrabajo_OrdenTrabajoCrmId] UNIQUE ([OrdenTrabajoCrmId]),
    CONSTRAINT [CK_OrdenTrabajo_AtributosJSON] CHECK ([AtributosExtendidos] IS NULL OR ISJSON([AtributosExtendidos]) = 1)
);
CREATE INDEX [IX_OrdenTrabajo_Linaje] ON core.OrdenTrabajo ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.OrdenServicioVoIP: Órdenes de instalación o retiro de servicios de voz. Grano: Una fila por orden. */
CREATE TABLE core.OrdenServicioVoIP (
    [OrdenServicioVoIPId] int IDENTITY(1,1) NOT NULL,
    [OrdenCrmId] nvarchar(30) NOT NULL,
    [ServicioId] int NULL,
    [Nombre] nvarchar(200) NULL,
    [TipoServicio] nvarchar(100) NULL,
    [TipoSolicitud] nvarchar(100) NULL,
    [Estado] nvarchar(50) NULL,
    [FechaSolicitud] date NULL,
    [FechaInstalacion] date NULL,
    [FechaDesinstalacion] date NULL,
    [AtributosExtendidos] nvarchar(max) NULL,
    [FechaCreacionOrigen] datetimeoffset(0) NULL,
    [FechaModificacionOrigen] datetimeoffset(0) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_OrdenServicioVoIP_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_OrdenServicioVoIP] PRIMARY KEY CLUSTERED ([OrdenServicioVoIPId]),
    CONSTRAINT [UQ_OrdenServicioVoIP_OrdenCrmId] UNIQUE ([OrdenCrmId]),
    CONSTRAINT [CK_OrdenServicioVoIP_AtributosJSON] CHECK ([AtributosExtendidos] IS NULL OR ISJSON([AtributosExtendidos]) = 1)
);
CREATE INDEX [IX_OrdenServicioVoIP_Linaje] ON core.OrdenServicioVoIP ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.Caso: Casos de soporte y mantenimiento. Grano: Una fila por caso. */
CREATE TABLE core.Caso (
    [CasoId] int IDENTITY(1,1) NOT NULL,
    [CasoCrmId] nvarchar(30) NOT NULL,
    [ServicioId] int NULL,
    [Circuito] varchar(12) NULL,
    [NumeroTicket] nvarchar(50) NULL,
    [Asunto] nvarchar(500) NULL,
    [Descripcion] nvarchar(max) NULL,
    [Estado] nvarchar(50) NULL,
    [Origen] nvarchar(50) NULL,
    [Segmento] nvarchar(50) NULL,
    [TipoMantenimiento] nvarchar(100) NULL,
    [DepartamentoOrigen] nvarchar(100) NULL,
    [ProveedorExterno] nvarchar(100) NULL,
    [VisitaTecnica] bit NULL,
    [Escalado] bit NULL,
    [PropietarioUsuarioId] int NULL,
    [FechaSolicitud] datetimeoffset(0) NULL,
    [FechaAfectacion] datetimeoffset(0) NULL,
    [FechaEscalamiento] datetimeoffset(0) NULL,
    [FechaFinMantenimiento] datetimeoffset(0) NULL,
    [FechaFinalizacion] datetimeoffset(0) NULL,
    [AtributosExtendidos] nvarchar(max) NULL,
    [FechaCreacionOrigen] datetimeoffset(0) NULL,
    [FechaModificacionOrigen] datetimeoffset(0) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_Caso_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_Caso] PRIMARY KEY CLUSTERED ([CasoId]),
    CONSTRAINT [UQ_Caso_CasoCrmId] UNIQUE ([CasoCrmId]),
    CONSTRAINT [CK_Caso_AtributosJSON] CHECK ([AtributosExtendidos] IS NULL OR ISJSON([AtributosExtendidos]) = 1)
);
CREATE INDEX [IX_Caso_Linaje] ON core.Caso ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.Nota: Notas de cuentas, casos y contactos de facturación; principal fuente de texto para el RAG. Grano: Una fila por nota. */
CREATE TABLE core.Nota (
    [NotaId] int IDENTITY(1,1) NOT NULL,
    [NotaOrigenId] nvarchar(40) NOT NULL,
    [Entidad] varchar(15) NOT NULL,
    [ServicioId] int NULL,
    [CasoId] int NULL,
    [ClienteId] int NULL,
    [Titulo] nvarchar(500) NULL,
    [Contenido] nvarchar(max) NULL,
    [CompartidaConCliente] bit NULL,
    [AutorUsuarioId] int NULL,
    [Autor] nvarchar(200) NULL,
    [FechaCreacionOrigen] datetimeoffset(0) NULL,
    [FechaModificacionOrigen] datetimeoffset(0) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_Nota_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_Nota] PRIMARY KEY CLUSTERED ([NotaId])
);
CREATE INDEX [IX_Nota_Linaje] ON core.Nota ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.Tarea: Tareas y seguimientos del CRM. Grano: Una fila por tarea. */
CREATE TABLE core.Tarea (
    [TareaId] int IDENTITY(1,1) NOT NULL,
    [TareaCrmId] nvarchar(30) NOT NULL,
    [RelacionadoCrmId] nvarchar(30) NULL,
    [ServicioId] int NULL,
    [ContactoId] int NULL,
    [Asunto] nvarchar(500) NULL,
    [Tipo] nvarchar(50) NULL,
    [Estado] nvarchar(50) NULL,
    [Prioridad] nvarchar(20) NULL,
    [Descripcion] nvarchar(max) NULL,
    [FechaVencimiento] date NULL,
    [FechaCierre] datetimeoffset(0) NULL,
    [AsignadoUsuarioId] int NULL,
    [AtributosExtendidos] nvarchar(max) NULL,
    [FechaCreacionOrigen] datetimeoffset(0) NULL,
    [FechaModificacionOrigen] datetimeoffset(0) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_Tarea_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_Tarea] PRIMARY KEY CLUSTERED ([TareaId]),
    CONSTRAINT [UQ_Tarea_TareaCrmId] UNIQUE ([TareaCrmId]),
    CONSTRAINT [CK_Tarea_AtributosJSON] CHECK ([AtributosExtendidos] IS NULL OR ISJSON([AtributosExtendidos]) = 1)
);
CREATE INDEX [IX_Tarea_Linaje] ON core.Tarea ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.TicketAtencion: Conversaciones de atención al cliente en Trengo. Grano: Una fila por ticket. */
CREATE TABLE core.TicketAtencion (
    [TicketAtencionId] int IDENTITY(1,1) NOT NULL,
    [TicketTrengoId] nvarchar(50) NOT NULL,
    [ContactoId] int NULL,
    [ServicioId] int NULL,
    [Canal] nvarchar(50) NULL,
    [Departamento] nvarchar(100) NULL,
    [Responsable] nvarchar(100) NULL,
    [Telefono] nvarchar(30) NULL,
    [Etiquetas] nvarchar(max) NULL,
    [DatosAdicionales] nvarchar(max) NULL,
    [DuracionMinutos] decimal(12,2) NULL,
    [FechaCreacion] datetimeoffset(0) NULL,
    [FechaAsignacion] datetimeoffset(0) NULL,
    [FechaCierre] datetimeoffset(0) NULL,
    [FechaActualizacion] datetimeoffset(0) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_TicketAtencion_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_TicketAtencion] PRIMARY KEY CLUSTERED ([TicketAtencionId]),
    CONSTRAINT [UQ_TicketAtencion_TicketTrengoId] UNIQUE ([TicketTrengoId])
);
CREATE INDEX [IX_TicketAtencion_Linaje] ON core.TicketAtencion ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.Adjunto: Metadatos de archivos adjuntos del CRM. Grano: Una fila por adjunto. */
CREATE TABLE core.Adjunto (
    [AdjuntoId] int IDENTITY(1,1) NOT NULL,
    [AdjuntoCrmId] nvarchar(30) NOT NULL,
    [Modulo] nvarchar(50) NULL,
    [RegistroCrmId] nvarchar(30) NULL,
    [NombreArchivo] nvarchar(500) NULL,
    [TamanoBytes] bigint NULL,
    [TipoArchivo] nvarchar(50) NULL,
    [RutaNube] nvarchar(1000) NULL,
    [FechaCreacionOrigen] datetimeoffset(0) NULL,
    [FechaModificacionOrigen] datetimeoffset(0) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_Adjunto_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_Adjunto] PRIMARY KEY CLUSTERED ([AdjuntoId]),
    CONSTRAINT [UQ_Adjunto_AdjuntoCrmId] UNIQUE ([AdjuntoCrmId])
);
CREATE INDEX [IX_Adjunto_Linaje] ON core.Adjunto ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.Proveedor: Proveedores registrados en Zoho Books. Grano: Una fila por contacto proveedor. */
CREATE TABLE core.Proveedor (
    [ProveedorId] int IDENTITY(1,1) NOT NULL,
    [ContactoBooksId] nvarchar(30) NOT NULL,
    [Nombre] nvarchar(200) NULL,
    [Empresa] nvarchar(200) NULL,
    [Cedula] varchar(12) NULL,
    [Correo] nvarchar(200) NULL,
    [Telefono] nvarchar(30) NULL,
    [Estado] nvarchar(30) NULL,
    [AtributosExtendidos] nvarchar(max) NULL,
    [FechaCreacionOrigen] datetimeoffset(0) NULL,
    [FechaModificacionOrigen] datetimeoffset(0) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_Proveedor_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_Proveedor] PRIMARY KEY CLUSTERED ([ProveedorId]),
    CONSTRAINT [UQ_Proveedor_ContactoBooksId] UNIQUE ([ContactoBooksId]),
    CONSTRAINT [CK_Proveedor_AtributosJSON] CHECK ([AtributosExtendidos] IS NULL OR ISJSON([AtributosExtendidos]) = 1)
);
CREATE INDEX [IX_Proveedor_Linaje] ON core.Proveedor ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.Factura: Facturas de venta de Zoho Books. Grano: Una fila por factura (sin versiones duplicadas). */
CREATE TABLE core.Factura (
    [FacturaId] int IDENTITY(1,1) NOT NULL,
    [FacturaBooksId] nvarchar(30) NOT NULL,
    [ClienteId] int NULL,
    [ServicioId] int NULL,
    [ContactoBooksId] nvarchar(30) NOT NULL,
    [Numero] nvarchar(50) NULL,
    [Referencia] nvarchar(200) NULL,
    [Estado] nvarchar(30) NULL,
    [Fecha] date NOT NULL,
    [FechaVencimiento] date NULL,
    [Moneda] char(3) NULL,
    [TipoCambio] decimal(19,6) NULL,
    [Total] decimal(19,4) NULL,
    [TotalCRC] decimal(19,4) NULL,
    [Saldo] decimal(19,4) NULL,
    [SaldoCRC] decimal(19,4) NULL,
    [Ajuste] decimal(19,4) NULL,
    [AjusteCRC] decimal(19,4) NULL,
    [CargoEnvio] decimal(19,4) NULL,
    [CargoEnvioCRC] decimal(19,4) NULL,
    [MontoCancelado] decimal(19,4) NULL,
    [MontoCanceladoCRC] decimal(19,4) NULL,
    [Sucursal] nvarchar(100) NULL,
    [Vendedor] nvarchar(200) NULL,
    [FechaUltimoPago] date NULL,
    [AtributosExtendidos] nvarchar(max) NULL,
    [FechaCreacionOrigen] datetimeoffset(0) NULL,
    [FechaModificacionOrigen] datetimeoffset(0) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_Factura_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_Factura] PRIMARY KEY CLUSTERED ([FacturaId]),
    CONSTRAINT [UQ_Factura_FacturaBooksId] UNIQUE ([FacturaBooksId]),
    CONSTRAINT [CK_Factura_AtributosJSON] CHECK ([AtributosExtendidos] IS NULL OR ISJSON([AtributosExtendidos]) = 1),
    CONSTRAINT [CK_Factura_Moneda] CHECK ([Moneda] IS NULL OR [Moneda] IN ('CRC','USD','EUR'))
);
CREATE INDEX [IX_Factura_Linaje] ON core.Factura ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.FacturaLinea: Líneas de las facturas. Grano: Una fila por línea. */
CREATE TABLE core.FacturaLinea (
    [FacturaLineaId] int IDENTITY(1,1) NOT NULL,
    [LineaBooksId] nvarchar(30) NOT NULL,
    [FacturaId] int NOT NULL,
    [ProductoId] int NULL,
    [Nombre] nvarchar(300) NULL,
    [Descripcion] nvarchar(max) NULL,
    [Cantidad] decimal(12,2) NULL,
    [Moneda] char(3) NULL,
    [TipoCambio] decimal(19,6) NULL,
    [PrecioUnitario] decimal(19,4) NULL,
    [PrecioUnitarioCRC] decimal(19,4) NULL,
    [Total] decimal(19,4) NULL,
    [TotalCRC] decimal(19,4) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_FacturaLinea_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_FacturaLinea] PRIMARY KEY CLUSTERED ([FacturaLineaId]),
    CONSTRAINT [UQ_FacturaLinea_LineaBooksId] UNIQUE ([LineaBooksId]),
    CONSTRAINT [CK_FacturaLinea_Moneda] CHECK ([Moneda] IS NULL OR [Moneda] IN ('CRC','USD','EUR'))
);
CREATE INDEX [IX_FacturaLinea_Linaje] ON core.FacturaLinea ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.FacturaRecurrente: Perfiles de facturación recurrente. Grano: Una fila por perfil. */
CREATE TABLE core.FacturaRecurrente (
    [FacturaRecurrenteId] int IDENTITY(1,1) NOT NULL,
    [RecurrenteBooksId] nvarchar(30) NOT NULL,
    [ClienteId] int NULL,
    [ServicioId] int NULL,
    [ContactoBooksId] nvarchar(30) NOT NULL,
    [Nombre] nvarchar(200) NULL,
    [Estado] nvarchar(30) NULL,
    [Frecuencia] nvarchar(30) NULL,
    [RepetirCada] int NULL,
    [Moneda] char(3) NULL,
    [TipoCambio] decimal(19,6) NULL,
    [Total] decimal(19,4) NULL,
    [TotalCRC] decimal(19,4) NULL,
    [FechaInicio] date NULL,
    [FechaFin] date NULL,
    [FechaUltimoEnvio] date NULL,
    [FechaProximaFactura] date NULL,
    [MedioPago] nvarchar(50) NULL,
    [Vendedor] nvarchar(200) NULL,
    [AtributosExtendidos] nvarchar(max) NULL,
    [FechaCreacionOrigen] datetimeoffset(0) NULL,
    [FechaModificacionOrigen] datetimeoffset(0) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_FacturaRecurrente_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_FacturaRecurrente] PRIMARY KEY CLUSTERED ([FacturaRecurrenteId]),
    CONSTRAINT [UQ_FacturaRecurrente_RecurrenteBooksId] UNIQUE ([RecurrenteBooksId]),
    CONSTRAINT [CK_FacturaRecurrente_AtributosJSON] CHECK ([AtributosExtendidos] IS NULL OR ISJSON([AtributosExtendidos]) = 1),
    CONSTRAINT [CK_FacturaRecurrente_Moneda] CHECK ([Moneda] IS NULL OR [Moneda] IN ('CRC','USD','EUR'))
);
CREATE INDEX [IX_FacturaRecurrente_Linaje] ON core.FacturaRecurrente ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.Pago: Pagos de clientes. Grano: Una fila por pago. */
CREATE TABLE core.Pago (
    [PagoId] int IDENTITY(1,1) NOT NULL,
    [PagoBooksId] nvarchar(30) NOT NULL,
    [ClienteId] int NULL,
    [ServicioId] int NULL,
    [ContactoBooksId] nvarchar(30) NOT NULL,
    [Numero] nvarchar(50) NULL,
    [Fecha] date NOT NULL,
    [MedioPago] nvarchar(50) NULL,
    [CuentaBancariaId] int NULL,
    [Referencia] nvarchar(200) NULL,
    [Descripcion] nvarchar(1000) NULL,
    [Moneda] char(3) NULL,
    [TipoCambio] decimal(19,6) NULL,
    [Monto] decimal(19,4) NULL,
    [MontoCRC] decimal(19,4) NULL,
    [MontoNoAplicado] decimal(19,4) NULL,
    [MontoNoAplicadoCRC] decimal(19,4) NULL,
    [MontoReembolsado] decimal(19,4) NULL,
    [MontoReembolsadoCRC] decimal(19,4) NULL,
    [ImpuestoRetenido] decimal(19,4) NULL,
    [ImpuestoRetenidoCRC] decimal(19,4) NULL,
    [Sucursal] nvarchar(100) NULL,
    [AtributosExtendidos] nvarchar(max) NULL,
    [FechaCreacionOrigen] datetimeoffset(0) NULL,
    [FechaModificacionOrigen] datetimeoffset(0) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_Pago_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_Pago] PRIMARY KEY CLUSTERED ([PagoId]),
    CONSTRAINT [UQ_Pago_PagoBooksId] UNIQUE ([PagoBooksId]),
    CONSTRAINT [CK_Pago_AtributosJSON] CHECK ([AtributosExtendidos] IS NULL OR ISJSON([AtributosExtendidos]) = 1),
    CONSTRAINT [CK_Pago_Moneda] CHECK ([Moneda] IS NULL OR [Moneda] IN ('CRC','USD','EUR'))
);
CREATE INDEX [IX_Pago_Linaje] ON core.Pago ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.PagoFactura: Facturas cubiertas por cada pago. Grano: Una fila por pago y factura. */
CREATE TABLE core.PagoFactura (
    [PagoFacturaId] int IDENTITY(1,1) NOT NULL,
    [PagoId] int NOT NULL,
    [FacturaId] int NULL,
    [NumeroFactura] nvarchar(50) NOT NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_PagoFactura_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_PagoFactura] PRIMARY KEY CLUSTERED ([PagoFacturaId])
);
CREATE INDEX [IX_PagoFactura_Linaje] ON core.PagoFactura ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.CuentaBancaria: Cuentas bancarias registradas en Books. Grano: Una fila por cuenta. */
CREATE TABLE core.CuentaBancaria (
    [CuentaBancariaId] int IDENTITY(1,1) NOT NULL,
    [CuentaBooksId] nvarchar(30) NOT NULL,
    [Nombre] nvarchar(200) NULL,
    [Codigo] nvarchar(50) NULL,
    [Banco] nvarchar(100) NULL,
    [Tipo] nvarchar(50) NULL,
    [Activa] bit NULL,
    [Moneda] char(3) NULL,
    [TipoCambio] decimal(19,6) NULL,
    [Saldo] decimal(19,4) NULL,
    [SaldoCRC] decimal(19,4) NULL,
    [SaldoBanco] decimal(19,4) NULL,
    [SaldoBancoCRC] decimal(19,4) NULL,
    [AtributosExtendidos] nvarchar(max) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_CuentaBancaria_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_CuentaBancaria] PRIMARY KEY CLUSTERED ([CuentaBancariaId]),
    CONSTRAINT [UQ_CuentaBancaria_CuentaBooksId] UNIQUE ([CuentaBooksId]),
    CONSTRAINT [CK_CuentaBancaria_AtributosJSON] CHECK ([AtributosExtendidos] IS NULL OR ISJSON([AtributosExtendidos]) = 1),
    CONSTRAINT [CK_CuentaBancaria_Moneda] CHECK ([Moneda] IS NULL OR [Moneda] IN ('CRC','USD','EUR'))
);
CREATE INDEX [IX_CuentaBancaria_Linaje] ON core.CuentaBancaria ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.MovimientoBancario: Movimientos bancarios. Grano: Una fila por movimiento. */
CREATE TABLE core.MovimientoBancario (
    [MovimientoBancarioId] int IDENTITY(1,1) NOT NULL,
    [MovimientoBooksId] nvarchar(30) NOT NULL,
    [CuentaBancariaId] int NULL,
    [ClienteId] int NULL,
    [Fecha] date NOT NULL,
    [Tipo] nvarchar(50) NULL,
    [DebitoCredito] varchar(10) NULL,
    [Estado] nvarchar(30) NULL,
    [Origen] nvarchar(50) NULL,
    [Beneficiario] nvarchar(200) NULL,
    [Descripcion] nvarchar(1000) NULL,
    [Referencia] nvarchar(200) NULL,
    [EstadoConciliacion] nvarchar(30) NULL,
    [Moneda] char(3) NULL,
    [TipoCambio] decimal(19,6) NULL,
    [Monto] decimal(19,4) NULL,
    [MontoCRC] decimal(19,4) NULL,
    [Sucursal] nvarchar(100) NULL,
    [AtributosExtendidos] nvarchar(max) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_MovimientoBancario_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_MovimientoBancario] PRIMARY KEY CLUSTERED ([MovimientoBancarioId]),
    CONSTRAINT [UQ_MovimientoBancario_MovimientoBooksId] UNIQUE ([MovimientoBooksId]),
    CONSTRAINT [CK_MovimientoBancario_AtributosJSON] CHECK ([AtributosExtendidos] IS NULL OR ISJSON([AtributosExtendidos]) = 1),
    CONSTRAINT [CK_MovimientoBancario_Moneda] CHECK ([Moneda] IS NULL OR [Moneda] IN ('CRC','USD','EUR'))
);
CREATE INDEX [IX_MovimientoBancario_Linaje] ON core.MovimientoBancario ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.Gasto: Gastos registrados en Books. Grano: Una fila por gasto. */
CREATE TABLE core.Gasto (
    [GastoId] int IDENTITY(1,1) NOT NULL,
    [GastoBooksId] nvarchar(30) NOT NULL,
    [ProveedorId] int NULL,
    [ClienteId] int NULL,
    [Fecha] date NOT NULL,
    [Cuenta] nvarchar(200) NULL,
    [PagadoDesde] nvarchar(200) NULL,
    [Descripcion] nvarchar(1000) NULL,
    [Estado] nvarchar(30) NULL,
    [Referencia] nvarchar(200) NULL,
    [Moneda] char(3) NULL,
    [TipoCambio] decimal(19,6) NULL,
    [Total] decimal(19,4) NULL,
    [TotalCRC] decimal(19,4) NULL,
    [TotalSinImpuesto] decimal(19,4) NULL,
    [TotalSinImpuestoCRC] decimal(19,4) NULL,
    [Etiquetas] nvarchar(max) NULL,
    [Sucursal] nvarchar(100) NULL,
    [AtributosExtendidos] nvarchar(max) NULL,
    [FechaCreacionOrigen] datetimeoffset(0) NULL,
    [FechaModificacionOrigen] datetimeoffset(0) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_Gasto_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_Gasto] PRIMARY KEY CLUSTERED ([GastoId]),
    CONSTRAINT [UQ_Gasto_GastoBooksId] UNIQUE ([GastoBooksId]),
    CONSTRAINT [CK_Gasto_AtributosJSON] CHECK ([AtributosExtendidos] IS NULL OR ISJSON([AtributosExtendidos]) = 1),
    CONSTRAINT [CK_Gasto_Moneda] CHECK ([Moneda] IS NULL OR [Moneda] IN ('CRC','USD','EUR'))
);
CREATE INDEX [IX_Gasto_Linaje] ON core.Gasto ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.OrdenCompra: Órdenes de compra a proveedores. Grano: Una fila por orden. */
CREATE TABLE core.OrdenCompra (
    [OrdenCompraId] int IDENTITY(1,1) NOT NULL,
    [OrdenCompraBooksId] nvarchar(30) NOT NULL,
    [ProveedorId] int NULL,
    [Numero] nvarchar(50) NULL,
    [Referencia] nvarchar(200) NULL,
    [Estado] nvarchar(30) NULL,
    [EstadoFacturacion] nvarchar(30) NULL,
    [EstadoRecepcion] nvarchar(30) NULL,
    [Fecha] date NULL,
    [FechaEntrega] date NULL,
    [Moneda] char(3) NULL,
    [TipoCambio] decimal(19,6) NULL,
    [Total] decimal(19,4) NULL,
    [TotalCRC] decimal(19,4) NULL,
    [Sucursal] nvarchar(100) NULL,
    [AtributosExtendidos] nvarchar(max) NULL,
    [FechaCreacionOrigen] datetimeoffset(0) NULL,
    [FechaModificacionOrigen] datetimeoffset(0) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_OrdenCompra_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_OrdenCompra] PRIMARY KEY CLUSTERED ([OrdenCompraId]),
    CONSTRAINT [UQ_OrdenCompra_OrdenCompraBooksId] UNIQUE ([OrdenCompraBooksId]),
    CONSTRAINT [CK_OrdenCompra_AtributosJSON] CHECK ([AtributosExtendidos] IS NULL OR ISJSON([AtributosExtendidos]) = 1),
    CONSTRAINT [CK_OrdenCompra_Moneda] CHECK ([Moneda] IS NULL OR [Moneda] IN ('CRC','USD','EUR'))
);
CREATE INDEX [IX_OrdenCompra_Linaje] ON core.OrdenCompra ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.HistorialEstadoCliente: Cambios de estado de clientes en Books (activo, suspendido, retirado). Grano: Una fila por cambio. */
CREATE TABLE core.HistorialEstadoCliente (
    [HistorialEstadoClienteId] int IDENTITY(1,1) NOT NULL,
    [ClienteId] int NULL,
    [ContactoBooksId] nvarchar(30) NOT NULL,
    [Estado] nvarchar(50) NULL,
    [Segmento] nvarchar(50) NULL,
    [RealizadoPor] nvarchar(100) NULL,
    [FechaCambio] datetimeoffset(0) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_HistorialEstadoCliente_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_HistorialEstadoCliente] PRIMARY KEY CLUSTERED ([HistorialEstadoClienteId])
);
CREATE INDEX [IX_HistorialEstadoCliente_Linaje] ON core.HistorialEstadoCliente ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.Troncal: Troncales SIP de los clientes. Grano: Una fila por troncal. */
CREATE TABLE core.Troncal (
    [TroncalId] int IDENTITY(1,1) NOT NULL,
    [ServicioId] int NULL,
    [CodigoTroncal] nvarchar(50) NOT NULL,
    [Tipo] nvarchar(30) NULL,
    [TollFreeEntrante] bit NULL,
    [DIDEntrante] bit NULL,
    [Estado] nvarchar(30) NULL,
    [CodigoEstadoPredeterminado] nvarchar(30) NULL,
    [EstadoSIP] nvarchar(30) NULL,
    [SinRestriccion] bit NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_Troncal_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_Troncal] PRIMARY KEY CLUSTERED ([TroncalId]),
    CONSTRAINT [UQ_Troncal_CodigoTroncal] UNIQUE ([CodigoTroncal])
);
CREATE INDEX [IX_Troncal_Linaje] ON core.Troncal ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.TroncalPermisoCodigo: Códigos de marcación permitidos por troncal. Grano: Una fila por troncal y código. */
CREATE TABLE core.TroncalPermisoCodigo (
    [TroncalPermisoCodigoId] int IDENTITY(1,1) NOT NULL,
    [TroncalId] int NOT NULL,
    [CodigoMarcacion] varchar(20) NOT NULL,
    [Minutos] int NULL,
    [SinRestriccion] bit NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_TroncalPermisoCodigo_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_TroncalPermisoCodigo] PRIMARY KEY CLUSTERED ([TroncalPermisoCodigoId])
);
CREATE INDEX [IX_TroncalPermisoCodigo_Linaje] ON core.TroncalPermisoCodigo ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.AlertaTroncal: Bloqueos y alertas de troncales. Grano: Una fila por alerta. */
CREATE TABLE core.AlertaTroncal (
    [AlertaTroncalId] int IDENTITY(1,1) NOT NULL,
    [TroncalId] int NOT NULL,
    [Operacion] nvarchar(50) NULL,
    [Motivo] nvarchar(500) NULL,
    [FechaBloqueo] datetimeoffset(0) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_AlertaTroncal_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_AlertaTroncal] PRIMARY KEY CLUSTERED ([AlertaTroncalId])
);
CREATE INDEX [IX_AlertaTroncal_Linaje] ON core.AlertaTroncal ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.LineaGratuita: Líneas gratuitas y DID de los clientes. Grano: Una fila por línea. */
CREATE TABLE core.LineaGratuita (
    [LineaGratuitaId] int IDENTITY(1,1) NOT NULL,
    [ServicioId] int NULL,
    [Linea] nvarchar(50) NOT NULL,
    [TollFreeEntrante] bit NULL,
    [DIDEntrante] bit NULL,
    [Estado] nvarchar(30) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_LineaGratuita_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_LineaGratuita] PRIMARY KEY CLUSTERED ([LineaGratuitaId])
);
CREATE INDEX [IX_LineaGratuita_Linaje] ON core.LineaGratuita ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.ServicioPaqueteMinutos: Paquetes de minutos asignados a cada servicio. Grano: Una fila por servicio y paquete. */
CREATE TABLE core.ServicioPaqueteMinutos (
    [ServicioPaqueteMinutosId] int IDENTITY(1,1) NOT NULL,
    [ServicioId] int NULL,
    [PaqueteMinutosId] int NOT NULL,
    [Minutos] int NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_ServicioPaqueteMinutos_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_ServicioPaqueteMinutos] PRIMARY KEY CLUSTERED ([ServicioPaqueteMinutosId])
);
CREATE INDEX [IX_ServicioPaqueteMinutos_Linaje] ON core.ServicioPaqueteMinutos ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.MinutosContratadosHistorico: Minutos contratados registrados a mano en 2022 (histórico, decisión del 12/10/2026). Grano: Una fila por registro de origen. */
CREATE TABLE core.MinutosContratadosHistorico (
    [MinutosContratadosHistoricoId] int IDENTITY(1,1) NOT NULL,
    [ClienteId] int NULL,
    [ServicioId] int NULL,
    [TablaOrigen] varchar(30) NOT NULL,
    [ClienteVoIPOrigenId] bigint NULL,
    [CedulaOriginal] nvarchar(50) NULL,
    [Descripcion] nvarchar(200) NULL,
    [Minutos] decimal(12,2) NULL,
    [MinutosFijo] decimal(12,2) NULL,
    [MinutosCelular] decimal(12,2) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_MinutosContratadosHistorico_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_MinutosContratadosHistorico] PRIMARY KEY CLUSTERED ([MinutosContratadosHistoricoId])
);
CREATE INDEX [IX_MinutosContratadosHistorico_Linaje] ON core.MinutosContratadosHistorico ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.ArchivoCDR: Archivos de llamadas procesados. Grano: Una fila por archivo (única). */
CREATE TABLE core.ArchivoCDR (
    [ArchivoCDRId] int IDENTITY(1,1) NOT NULL,
    [NombreArchivo] nvarchar(300) NOT NULL,
    [Dispositivo] nvarchar(100) NULL,
    [FechaInsercion] date NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_ArchivoCDR_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_ArchivoCDR] PRIMARY KEY CLUSTERED ([ArchivoCDRId]),
    CONSTRAINT [UQ_ArchivoCDR_NombreArchivo_Dispositivo] UNIQUE ([NombreArchivo], [Dispositivo])
);
CREATE INDEX [IX_ArchivoCDR_Linaje] ON core.ArchivoCDR ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.Llamada: Registros de llamadas (CDR) sin duplicados. Grano: Una fila por llamada única (DD-01). */
CREATE TABLE core.Llamada (
    [LlamadaId] bigint IDENTITY(1,1) NOT NULL,
    [ServicioId] int NULL,
    [TroncalEntradaId] int NULL,
    [TroncalSalidaId] int NULL,
    [Circuito] varchar(12) NULL,
    [TipoCDR] int NULL,
    [RazonCDR] nvarchar(100) NULL,
    [FechaInicio] datetimeoffset(0) NOT NULL,
    [FechaRespuesta] datetimeoffset(0) NULL,
    [FechaFin] datetimeoffset(0) NULL,
    [NumeroOrigen] nvarchar(50) NULL,
    [NumeroMarcado] nvarchar(50) NULL,
    [NumeroFacturacion] nvarchar(50) NULL,
    [DigitosRuteo] nvarchar(50) NULL,
    [Destino] nvarchar(150) NULL,
    [CodigoDestino] varchar(20) NULL,
    [Dispositivo] nvarchar(100) NULL,
    [DuracionSegundos] decimal(12,2) NULL,
    [DuracionSegundosRedondeada] decimal(12,2) NULL,
    [DuracionMinutos] decimal(12,2) NULL,
    [RedondeoDestino] int NULL,
    [IncrementoCliente] int NULL,
    [PorcentajeCliente] decimal(9,4) NULL,
    [Moneda] char(3) NULL,
    [TipoCambio] decimal(19,6) NULL,
    [TarifaDestino] decimal(19,4) NULL,
    [TarifaDestinoCRC] decimal(19,4) NULL,
    [TarifaSinMargen] decimal(19,4) NULL,
    [TarifaSinMargenCRC] decimal(19,4) NULL,
    [Costo] decimal(19,4) NULL,
    [CostoCRC] decimal(19,4) NULL,
    [CostoSinMargen] decimal(19,4) NULL,
    [CostoSinMargenCRC] decimal(19,4) NULL,
    [AtributosExtendidos] nvarchar(max) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_Llamada_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_Llamada] PRIMARY KEY CLUSTERED ([LlamadaId]),
    CONSTRAINT [CK_Llamada_AtributosJSON] CHECK ([AtributosExtendidos] IS NULL OR ISJSON([AtributosExtendidos]) = 1),
    CONSTRAINT [CK_Llamada_Moneda] CHECK ([Moneda] IS NULL OR [Moneda] IN ('CRC','USD','EUR'))
);
CREATE UNIQUE INDEX [UX_Llamada_HashContenido] ON core.Llamada ([HashContenido]) WHERE [HashContenido] IS NOT NULL;
CREATE INDEX [IX_Llamada_Linaje] ON core.Llamada ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.CorteVoIP: Cortes de facturación de telefonía por cliente y período. Grano: Una fila por corte. */
CREATE TABLE core.CorteVoIP (
    [CorteVoIPId] int IDENTITY(1,1) NOT NULL,
    [ServicioId] int NULL,
    [ClienteId] int NULL,
    [NombreCliente] nvarchar(200) NULL,
    [FechaInicio] date NULL,
    [FechaFin] date NULL,
    [MinutosMovilDisponibles] decimal(12,2) NULL,
    [MinutosFijoDisponibles] decimal(12,2) NULL,
    [MinutosMovilAplicados] decimal(12,2) NULL,
    [MinutosFijoAplicados] decimal(12,2) NULL,
    [Reporte] nvarchar(max) NULL,
    [Estado] nvarchar(30) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_CorteVoIP_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_CorteVoIP] PRIMARY KEY CLUSTERED ([CorteVoIPId])
);
CREATE INDEX [IX_CorteVoIP_Linaje] ON core.CorteVoIP ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.ConsumoVoIP: Consumo de telefonía por servicio, período y tipo de destino. Grano: Una fila por corte o período y tipo. */
CREATE TABLE core.ConsumoVoIP (
    [ConsumoVoIPId] int IDENTITY(1,1) NOT NULL,
    [CorteVoIPId] int NULL,
    [ServicioId] int NULL,
    [ClienteId] int NULL,
    [TipoServicioVoIP] nvarchar(50) NULL,
    [FechaInicio] date NULL,
    [FechaFin] date NULL,
    [Llamadas] int NULL,
    [Minutos] decimal(12,2) NULL,
    [Moneda] char(3) NULL,
    [TipoCambio] decimal(19,6) NULL,
    [Costo] decimal(19,4) NULL,
    [CostoCRC] decimal(19,4) NULL,
    [RutaArchivo] nvarchar(1000) NULL,
    [Procesado] bit NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_ConsumoVoIP_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_ConsumoVoIP] PRIMARY KEY CLUSTERED ([ConsumoVoIPId]),
    CONSTRAINT [CK_ConsumoVoIP_Moneda] CHECK ([Moneda] IS NULL OR [Moneda] IN ('CRC','USD','EUR'))
);
CREATE INDEX [IX_ConsumoVoIP_Linaje] ON core.ConsumoVoIP ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.FacturaElectronicaProveedor: Facturas electrónicas (XML) recibidas de proveedores. Grano: Una fila por factura. */
CREATE TABLE core.FacturaElectronicaProveedor (
    [FacturaElectronicaProveedorId] int IDENTITY(1,1) NOT NULL,
    [Numero] nvarchar(60) NOT NULL,
    [EmisorNombre] nvarchar(200) NULL,
    [EmisorCedula] varchar(12) NULL,
    [FechaEmision] datetimeoffset(0) NULL,
    [NombreArchivo] nvarchar(300) NULL,
    [Ruta] nvarchar(1000) NULL,
    [TextoPlano] nvarchar(max) NULL,
    [Procesada] bit NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_FacturaElectronicaProveedor_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_FacturaElectronicaProveedor] PRIMARY KEY CLUSTERED ([FacturaElectronicaProveedorId]),
    CONSTRAINT [UQ_FacturaElectronicaProveedor_Numero] UNIQUE ([Numero])
);
CREATE INDEX [IX_FacturaElectronicaProveedor_Linaje] ON core.FacturaElectronicaProveedor ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.SolicitudEnLinea: Contrataciones hechas en ADNPayV2. Grano: Una fila por solicitud. */
CREATE TABLE core.SolicitudEnLinea (
    [SolicitudEnLineaId] int IDENTITY(1,1) NOT NULL,
    [ClienteId] int NULL,
    [ProductoId] int NULL,
    [Referencia] varchar(50) NULL,
    [Estado] nvarchar(50) NULL,
    [TipoCliente] nvarchar(30) NULL,
    [Condominio] nvarchar(200) NULL,
    [CodigoFTTH] nvarchar(50) NULL,
    [Provincia] nvarchar(60) NULL,
    [Canton] nvarchar(80) NULL,
    [Distrito] nvarchar(80) NULL,
    [Direccion] nvarchar(1000) NULL,
    [Latitud] decimal(10,7) NULL,
    [Longitud] decimal(10,7) NULL,
    [IPTVAdicionales] int NULL,
    [CantidadFirestick] int NULL,
    [Telefonia] bit NULL,
    [IPPublica] bit NULL,
    [TienePromocion] bit NULL,
    [TipoPromocion] varchar(50) NULL,
    [CodigoPromocion] nvarchar(50) NULL,
    [FechaPromocion] date NULL,
    [TipoPago] varchar(30) NULL,
    [Moneda] char(3) NULL,
    [TipoCambio] decimal(19,6) NULL,
    [Total] decimal(19,4) NULL,
    [TotalCRC] decimal(19,4) NULL,
    [Referido] bit NULL,
    [ReferidoPor] nvarchar(200) NULL,
    [DatosInvalidos] bit NULL,
    [EnviadoCRM] bit NULL,
    [RutaContrato] nvarchar(1000) NULL,
    [IntentoPagoId] varchar(100) NULL,
    [FechaSolicitud] datetimeoffset(0) NULL,
    [AtributosExtendidos] nvarchar(max) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_SolicitudEnLinea_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_SolicitudEnLinea] PRIMARY KEY CLUSTERED ([SolicitudEnLineaId]),
    CONSTRAINT [CK_SolicitudEnLinea_AtributosJSON] CHECK ([AtributosExtendidos] IS NULL OR ISJSON([AtributosExtendidos]) = 1),
    CONSTRAINT [CK_SolicitudEnLinea_Moneda] CHECK ([Moneda] IS NULL OR [Moneda] IN ('CRC','USD','EUR'))
);
CREATE INDEX [IX_SolicitudEnLinea_Linaje] ON core.SolicitudEnLinea ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.PagoEnLinea: Sesiones de pago con tarjeta (pasarela Onvo). Grano: Una fila por sesión. */
CREATE TABLE core.PagoEnLinea (
    [PagoEnLineaId] int IDENTITY(1,1) NOT NULL,
    [SolicitudEnLineaId] int NULL,
    [SesionId] nvarchar(100) NULL,
    [IntentoPagoId] nvarchar(100) NULL,
    [Modo] nvarchar(30) NULL,
    [EstadoPago] nvarchar(30) NULL,
    [Expirada] bit NULL,
    [Moneda] char(3) NULL,
    [TipoCambio] decimal(19,6) NULL,
    [Monto] decimal(19,4) NULL,
    [MontoCRC] decimal(19,4) NULL,
    [PrecioId] nvarchar(100) NULL,
    [FechaCreacion] datetimeoffset(0) NULL,
    [FechaExpiracion] datetimeoffset(0) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_PagoEnLinea_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_PagoEnLinea] PRIMARY KEY CLUSTERED ([PagoEnLineaId]),
    CONSTRAINT [CK_PagoEnLinea_Moneda] CHECK ([Moneda] IS NULL OR [Moneda] IN ('CRC','USD','EUR'))
);
CREATE INDEX [IX_PagoEnLinea_Linaje] ON core.PagoEnLinea ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.ReservaInstalacion: Citas de instalación reservadas. Grano: Una fila por reserva. */
CREATE TABLE core.ReservaInstalacion (
    [ReservaInstalacionId] int IDENTITY(1,1) NOT NULL,
    [SolicitudEnLineaId] int NULL,
    [FechaReservada] date NULL,
    [Franja] time(0) NULL,
    [Estado] varchar(30) NULL,
    [FechaRegistro] datetimeoffset(0) NULL,
    [FechaExpiracion] datetimeoffset(0) NULL,
    [Direccion] nvarchar(1000) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_ReservaInstalacion_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_ReservaInstalacion] PRIMARY KEY CLUSTERED ([ReservaInstalacionId])
);
CREATE INDEX [IX_ReservaInstalacion_Linaje] ON core.ReservaInstalacion ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.OrdenEnLinea: Carritos y órdenes de compra en línea. Grano: Una fila por carrito u orden. */
CREATE TABLE core.OrdenEnLinea (
    [OrdenEnLineaId] int IDENTITY(1,1) NOT NULL,
    [SolicitudEnLineaId] int NULL,
    [ClienteReferencia] nvarchar(50) NULL,
    [Tipo] varchar(10) NOT NULL,
    [Estado] nvarchar(30) NULL,
    [Bloqueado] bit NULL,
    [Moneda] char(3) NULL,
    [TipoCambio] decimal(19,6) NULL,
    [Total] decimal(19,4) NULL,
    [TotalCRC] decimal(19,4) NULL,
    [TotalSinImpuesto] decimal(19,4) NULL,
    [TotalSinImpuestoCRC] decimal(19,4) NULL,
    [Fecha] datetimeoffset(0) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_OrdenEnLinea_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_OrdenEnLinea] PRIMARY KEY CLUSTERED ([OrdenEnLineaId]),
    CONSTRAINT [CK_OrdenEnLinea_Moneda] CHECK ([Moneda] IS NULL OR [Moneda] IN ('CRC','USD','EUR'))
);
CREATE INDEX [IX_OrdenEnLinea_Linaje] ON core.OrdenEnLinea ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.OrdenEnLineaLinea: Productos de cada carrito u orden. Grano: Una fila por línea. */
CREATE TABLE core.OrdenEnLineaLinea (
    [OrdenEnLineaLineaId] int IDENTITY(1,1) NOT NULL,
    [OrdenEnLineaId] int NOT NULL,
    [ProductoId] int NULL,
    [Nombre] nvarchar(200) NULL,
    [Descripcion] nvarchar(1000) NULL,
    [Cantidad] int NULL,
    [Moneda] char(3) NULL,
    [TipoCambio] decimal(19,6) NULL,
    [PrecioUnitario] decimal(19,4) NULL,
    [PrecioUnitarioCRC] decimal(19,4) NULL,
    [PrecioUnitarioSinImpuesto] decimal(19,4) NULL,
    [PrecioUnitarioSinImpuestoCRC] decimal(19,4) NULL,
    [Total] decimal(19,4) NULL,
    [TotalCRC] decimal(19,4) NULL,
    [TotalSinImpuesto] decimal(19,4) NULL,
    [TotalSinImpuestoCRC] decimal(19,4) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_OrdenEnLineaLinea_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_OrdenEnLineaLinea] PRIMARY KEY CLUSTERED ([OrdenEnLineaLineaId]),
    CONSTRAINT [CK_OrdenEnLineaLinea_Moneda] CHECK ([Moneda] IS NULL OR [Moneda] IN ('CRC','USD','EUR'))
);
CREATE INDEX [IX_OrdenEnLineaLinea_Linaje] ON core.OrdenEnLineaLinea ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.AprovisionamientoOdoo: Envío de clientes nuevos a Odoo. Grano: Una fila por intento. */
CREATE TABLE core.AprovisionamientoOdoo (
    [AprovisionamientoOdooId] int IDENTITY(1,1) NOT NULL,
    [SolicitudEnLineaId] int NULL,
    [Estado] nvarchar(30) NULL,
    [OdooLeadId] int NULL,
    [OdooPartnerId] int NULL,
    [OdooSitioId] int NULL,
    [OdooOrdenId] int NULL,
    [OdooContratoId] int NULL,
    [OdooTareaId] int NULL,
    [Circuito] varchar(12) NULL,
    [Intentos] int NULL,
    [UltimoError] nvarchar(2000) NULL,
    [FechaCreacionOrigen] datetimeoffset(0) NULL,
    [FechaModificacionOrigen] datetimeoffset(0) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_AprovisionamientoOdoo_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_AprovisionamientoOdoo] PRIMARY KEY CLUSTERED ([AprovisionamientoOdooId])
);
CREATE INDEX [IX_AprovisionamientoOdoo_Linaje] ON core.AprovisionamientoOdoo ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.UbicacionFlota: Posiciones reportadas por los dispositivos de rastreo. Grano: Una fila por posición única (DD-03). */
CREATE TABLE core.UbicacionFlota (
    [UbicacionFlotaId] bigint IDENTITY(1,1) NOT NULL,
    [UnidadFlotaId] int NOT NULL,
    [FechaHora] datetimeoffset(0) NOT NULL,
    [Latitud] decimal(10,7) NULL,
    [Longitud] decimal(10,7) NULL,
    [Odometro] decimal(12,2) NULL,
    [Velocidad] decimal(7,2) NULL,
    [Lugar] nvarchar(500) NULL,
    [Estado] nvarchar(50) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_UbicacionFlota_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_UbicacionFlota] PRIMARY KEY CLUSTERED ([UbicacionFlotaId])
);
CREATE INDEX [IX_UbicacionFlota_Linaje] ON core.UbicacionFlota ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.ViajeFlota: Viajes finalizados. Grano: Una fila por viaje único (DD-03). */
CREATE TABLE core.ViajeFlota (
    [ViajeFlotaId] bigint IDENTITY(1,1) NOT NULL,
    [UnidadFlotaId] int NOT NULL,
    [FechaInicio] datetimeoffset(0) NOT NULL,
    [FechaFin] datetimeoffset(0) NULL,
    [Kilometros] decimal(10,2) NULL,
    [DuracionMinutos] decimal(12,2) NULL,
    [LugarInicio] nvarchar(500) NULL,
    [LugarFin] nvarchar(500) NULL,
    [Estado] nvarchar(50) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_ViajeFlota_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_ViajeFlota] PRIMARY KEY CLUSTERED ([ViajeFlotaId])
);
CREATE INDEX [IX_ViajeFlota_Linaje] ON core.ViajeFlota ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.EventoFlota: Eventos y alertas de los dispositivos. Grano: Una fila por evento único (DD-03). */
CREATE TABLE core.EventoFlota (
    [EventoFlotaId] bigint IDENTITY(1,1) NOT NULL,
    [UnidadFlotaId] int NOT NULL,
    [FechaHora] datetimeoffset(0) NOT NULL,
    [Evento] nvarchar(100) NULL,
    [Mensaje] nvarchar(500) NULL,
    [Regla] nvarchar(200) NULL,
    [Latitud] decimal(10,7) NULL,
    [Longitud] decimal(10,7) NULL,
    [Lugar] nvarchar(500) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_EventoFlota_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_EventoFlota] PRIMARY KEY CLUSTERED ([EventoFlotaId])
);
CREATE INDEX [IX_EventoFlota_Linaje] ON core.EventoFlota ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.IncidenteConduccion: Incidentes de conducción (eco-driving). Grano: Una fila por incidente único (DD-03). */
CREATE TABLE core.IncidenteConduccion (
    [IncidenteConduccionId] int IDENTITY(1,1) NOT NULL,
    [UnidadFlotaId] int NOT NULL,
    [TipoEventoCodigo] int NULL,
    [TipoIncidente] nvarchar(100) NULL,
    [Conductor] nvarchar(150) NULL,
    [FechaHora] datetimeoffset(0) NOT NULL,
    [Lugar] nvarchar(500) NULL,
    [DuracionSegundos] int NULL,
    [VelocidadMaxima] int NULL,
    [VecesExcesoVelocidad] int NULL,
    [Penalidad] decimal(9,2) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_IncidenteConduccion_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_IncidenteConduccion] PRIMARY KEY CLUSTERED ([IncidenteConduccionId])
);
CREATE INDEX [IX_IncidenteConduccion_Linaje] ON core.IncidenteConduccion ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.CheckInCampo: Registros de llegada del personal de campo. Grano: Una fila por registro. */
CREATE TABLE core.CheckInCampo (
    [CheckInCampoId] int IDENTITY(1,1) NOT NULL,
    [Empleado] nvarchar(150) NULL,
    [FechaHora] datetimeoffset(0) NOT NULL,
    [Direccion] nvarchar(500) NULL,
    [Latitud] decimal(10,7) NULL,
    [Longitud] decimal(10,7) NULL,
    [Comentario] nvarchar(1000) NULL,
    [RutaArchivo] nvarchar(1000) NULL,
    [UrlDescarga] nvarchar(1000) NULL,
    [ArchivoId] int NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_CheckInCampo_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_CheckInCampo] PRIMARY KEY CLUSTERED ([CheckInCampoId])
);
CREATE INDEX [IX_CheckInCampo_Linaje] ON core.CheckInCampo ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* core.EventoConexion: Conexiones y desconexiones de servicio realizadas. Grano: Una fila por operación. */
CREATE TABLE core.EventoConexion (
    [EventoConexionId] int IDENTITY(1,1) NOT NULL,
    [ClienteId] int NULL,
    [ContactoBooksId] nvarchar(30) NULL,
    [Tipo] nvarchar(50) NULL,
    [RealizadoPor] nvarchar(100) NULL,
    [Fecha] datetimeoffset(0) NULL,
    [TipoDesconexionReconexion] nvarchar(50) NULL,
    [FechaDesconexionReconexion] datetimeoffset(0) NULL,
    [DireccionesIP] nvarchar(max) NULL,
    [ErroresIP] nvarchar(max) NULL,
    [FuenteSistema] varchar(20) NOT NULL,
    [FuenteBase] nvarchar(128) NOT NULL,
    [FuenteTabla] nvarchar(128) NOT NULL,
    [FuenteLlave] nvarchar(200) NOT NULL,
    [FechaDato] datetimeoffset(0) NULL,
    [PeriodoDato] AS (CONVERT(char(7), [FechaDato], 126)),
    [LoteId] int NOT NULL,
    [FechaCarga] datetimeoffset(0) NOT NULL CONSTRAINT [DF_EventoConexion_FechaCarga] DEFAULT (SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')),
    [HashContenido] binary(32) NULL,
    CONSTRAINT [PK_core_EventoConexion] PRIMARY KEY CLUSTERED ([EventoConexionId])
);
CREATE INDEX [IX_EventoConexion_Linaje] ON core.EventoConexion ([FuenteSistema], [FuenteTabla], [FuenteLlave]);
GO

/* ---------------- Llaves foráneas (IN-02) ---------------- */
ALTER TABLE ctl.Lote ADD CONSTRAINT [FK_Lote_FuenteId] FOREIGN KEY ([FuenteId]) REFERENCES ctl.Fuente ([FuenteId]);
CREATE INDEX [IX_Lote_FuenteId] ON ctl.Lote ([FuenteId]);
ALTER TABLE ctl.Descarte ADD CONSTRAINT [FK_Descarte_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE ctl.Descarte ADD CONSTRAINT [FK_Descarte_ReglaId] FOREIGN KEY ([ReglaId]) REFERENCES ctl.Regla ([ReglaId]);
CREATE INDEX [IX_Descarte_ReglaId] ON ctl.Descarte ([ReglaId]);
ALTER TABLE ctl.Anomalia ADD CONSTRAINT [FK_Anomalia_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE ctl.Anomalia ADD CONSTRAINT [FK_Anomalia_ReglaId] FOREIGN KEY ([ReglaId]) REFERENCES ctl.Regla ([ReglaId]);
CREATE INDEX [IX_Anomalia_ReglaId] ON ctl.Anomalia ([ReglaId]);
ALTER TABLE ctl.LinajeCampo ADD CONSTRAINT [FK_LinajeCampo_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE ref.TipoCambio ADD CONSTRAINT [FK_TipoCambio_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE ref.Usuario ADD CONSTRAINT [FK_Usuario_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE ref.Provincia ADD CONSTRAINT [FK_Provincia_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE ref.Canton ADD CONSTRAINT [FK_Canton_ProvinciaId] FOREIGN KEY ([ProvinciaId]) REFERENCES ref.Provincia ([ProvinciaId]);
CREATE INDEX [IX_Canton_ProvinciaId] ON ref.Canton ([ProvinciaId]);
ALTER TABLE ref.Canton ADD CONSTRAINT [FK_Canton_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE ref.Distrito ADD CONSTRAINT [FK_Distrito_CantonId] FOREIGN KEY ([CantonId]) REFERENCES ref.Canton ([CantonId]);
CREATE INDEX [IX_Distrito_CantonId] ON ref.Distrito ([CantonId]);
ALTER TABLE ref.Distrito ADD CONSTRAINT [FK_Distrito_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE ref.Impuesto ADD CONSTRAINT [FK_Impuesto_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE ref.CuentaContable ADD CONSTRAINT [FK_CuentaContable_CuentaPadreId] FOREIGN KEY ([CuentaPadreId]) REFERENCES ref.CuentaContable ([CuentaContableId]);
CREATE INDEX [IX_CuentaContable_CuentaPadreId] ON ref.CuentaContable ([CuentaPadreId]);
ALTER TABLE ref.CuentaContable ADD CONSTRAINT [FK_CuentaContable_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE ref.ProveedorTelefonia ADD CONSTRAINT [FK_ProveedorTelefonia_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE ref.TroncalProveedor ADD CONSTRAINT [FK_TroncalProveedor_ProveedorTelefoniaId] FOREIGN KEY ([ProveedorTelefoniaId]) REFERENCES ref.ProveedorTelefonia ([ProveedorTelefoniaId]);
CREATE INDEX [IX_TroncalProveedor_ProveedorTelefoniaId] ON ref.TroncalProveedor ([ProveedorTelefoniaId]);
ALTER TABLE ref.TroncalProveedor ADD CONSTRAINT [FK_TroncalProveedor_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE ref.TarifaDestino ADD CONSTRAINT [FK_TarifaDestino_ProveedorTelefoniaId] FOREIGN KEY ([ProveedorTelefoniaId]) REFERENCES ref.ProveedorTelefonia ([ProveedorTelefoniaId]);
CREATE INDEX [IX_TarifaDestino_ProveedorTelefoniaId] ON ref.TarifaDestino ([ProveedorTelefoniaId]);
ALTER TABLE ref.TarifaDestino ADD CONSTRAINT [FK_TarifaDestino_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE ref.PaqueteMinutos ADD CONSTRAINT [FK_PaqueteMinutos_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE ref.PaqueteMinutosCodigo ADD CONSTRAINT [FK_PaqueteMinutosCodigo_PaqueteMinutosId] FOREIGN KEY ([PaqueteMinutosId]) REFERENCES ref.PaqueteMinutos ([PaqueteMinutosId]);
CREATE INDEX [IX_PaqueteMinutosCodigo_PaqueteMinutosId] ON ref.PaqueteMinutosCodigo ([PaqueteMinutosId]);
ALTER TABLE ref.PaqueteMinutosCodigo ADD CONSTRAINT [FK_PaqueteMinutosCodigo_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE ref.CodigoPromocion ADD CONSTRAINT [FK_CodigoPromocion_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE ref.UnidadFlota ADD CONSTRAINT [FK_UnidadFlota_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.Cliente ADD CONSTRAINT [FK_Cliente_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.ClienteOrigen ADD CONSTRAINT [FK_ClienteOrigen_ClienteId] FOREIGN KEY ([ClienteId]) REFERENCES core.Cliente ([ClienteId]);
CREATE INDEX [IX_ClienteOrigen_ClienteId] ON core.ClienteOrigen ([ClienteId]);
ALTER TABLE core.ClienteOrigen ADD CONSTRAINT [FK_ClienteOrigen_ServicioId] FOREIGN KEY ([ServicioId]) REFERENCES core.Servicio ([ServicioId]);
CREATE INDEX [IX_ClienteOrigen_ServicioId] ON core.ClienteOrigen ([ServicioId]);
ALTER TABLE core.ClienteOrigen ADD CONSTRAINT [FK_ClienteOrigen_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.Servicio ADD CONSTRAINT [FK_Servicio_ClienteId] FOREIGN KEY ([ClienteId]) REFERENCES core.Cliente ([ClienteId]);
CREATE INDEX [IX_Servicio_ClienteId] ON core.Servicio ([ClienteId]);
ALTER TABLE core.Servicio ADD CONSTRAINT [FK_Servicio_DistritoId] FOREIGN KEY ([DistritoId]) REFERENCES ref.Distrito ([DistritoId]);
CREATE INDEX [IX_Servicio_DistritoId] ON core.Servicio ([DistritoId]);
ALTER TABLE core.Servicio ADD CONSTRAINT [FK_Servicio_CondominioId] FOREIGN KEY ([CondominioId]) REFERENCES core.Condominio ([CondominioId]);
CREATE INDEX [IX_Servicio_CondominioId] ON core.Servicio ([CondominioId]);
ALTER TABLE core.Servicio ADD CONSTRAINT [FK_Servicio_EjecutivoUsuarioId] FOREIGN KEY ([EjecutivoUsuarioId]) REFERENCES ref.Usuario ([UsuarioId]);
CREATE INDEX [IX_Servicio_EjecutivoUsuarioId] ON core.Servicio ([EjecutivoUsuarioId]);
ALTER TABLE core.Servicio ADD CONSTRAINT [FK_Servicio_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.Contacto ADD CONSTRAINT [FK_Contacto_ClienteId] FOREIGN KEY ([ClienteId]) REFERENCES core.Cliente ([ClienteId]);
CREATE INDEX [IX_Contacto_ClienteId] ON core.Contacto ([ClienteId]);
ALTER TABLE core.Contacto ADD CONSTRAINT [FK_Contacto_ServicioId] FOREIGN KEY ([ServicioId]) REFERENCES core.Servicio ([ServicioId]);
CREATE INDEX [IX_Contacto_ServicioId] ON core.Contacto ([ServicioId]);
ALTER TABLE core.Contacto ADD CONSTRAINT [FK_Contacto_PropietarioUsuarioId] FOREIGN KEY ([PropietarioUsuarioId]) REFERENCES ref.Usuario ([UsuarioId]);
CREATE INDEX [IX_Contacto_PropietarioUsuarioId] ON core.Contacto ([PropietarioUsuarioId]);
ALTER TABLE core.Contacto ADD CONSTRAINT [FK_Contacto_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.Prospecto ADD CONSTRAINT [FK_Prospecto_ClienteId] FOREIGN KEY ([ClienteId]) REFERENCES core.Cliente ([ClienteId]);
CREATE INDEX [IX_Prospecto_ClienteId] ON core.Prospecto ([ClienteId]);
ALTER TABLE core.Prospecto ADD CONSTRAINT [FK_Prospecto_DireccionId] FOREIGN KEY ([DireccionId]) REFERENCES core.Direccion ([DireccionId]);
CREATE INDEX [IX_Prospecto_DireccionId] ON core.Prospecto ([DireccionId]);
ALTER TABLE core.Prospecto ADD CONSTRAINT [FK_Prospecto_PropietarioUsuarioId] FOREIGN KEY ([PropietarioUsuarioId]) REFERENCES ref.Usuario ([UsuarioId]);
CREATE INDEX [IX_Prospecto_PropietarioUsuarioId] ON core.Prospecto ([PropietarioUsuarioId]);
ALTER TABLE core.Prospecto ADD CONSTRAINT [FK_Prospecto_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.Direccion ADD CONSTRAINT [FK_Direccion_DistritoId] FOREIGN KEY ([DistritoId]) REFERENCES ref.Distrito ([DistritoId]);
CREATE INDEX [IX_Direccion_DistritoId] ON core.Direccion ([DistritoId]);
ALTER TABLE core.Direccion ADD CONSTRAINT [FK_Direccion_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.Condominio ADD CONSTRAINT [FK_Condominio_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.Nodo ADD CONSTRAINT [FK_Nodo_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.ClusterFTTH ADD CONSTRAINT [FK_ClusterFTTH_NodoId] FOREIGN KEY ([NodoId]) REFERENCES core.Nodo ([NodoId]);
CREATE INDEX [IX_ClusterFTTH_NodoId] ON core.ClusterFTTH ([NodoId]);
ALTER TABLE core.ClusterFTTH ADD CONSTRAINT [FK_ClusterFTTH_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.Oportunidad ADD CONSTRAINT [FK_Oportunidad_ServicioId] FOREIGN KEY ([ServicioId]) REFERENCES core.Servicio ([ServicioId]);
CREATE INDEX [IX_Oportunidad_ServicioId] ON core.Oportunidad ([ServicioId]);
ALTER TABLE core.Oportunidad ADD CONSTRAINT [FK_Oportunidad_ContactoId] FOREIGN KEY ([ContactoId]) REFERENCES core.Contacto ([ContactoId]);
CREATE INDEX [IX_Oportunidad_ContactoId] ON core.Oportunidad ([ContactoId]);
ALTER TABLE core.Oportunidad ADD CONSTRAINT [FK_Oportunidad_PropietarioUsuarioId] FOREIGN KEY ([PropietarioUsuarioId]) REFERENCES ref.Usuario ([UsuarioId]);
CREATE INDEX [IX_Oportunidad_PropietarioUsuarioId] ON core.Oportunidad ([PropietarioUsuarioId]);
ALTER TABLE core.Oportunidad ADD CONSTRAINT [FK_Oportunidad_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.Cotizacion ADD CONSTRAINT [FK_Cotizacion_OportunidadId] FOREIGN KEY ([OportunidadId]) REFERENCES core.Oportunidad ([OportunidadId]);
CREATE INDEX [IX_Cotizacion_OportunidadId] ON core.Cotizacion ([OportunidadId]);
ALTER TABLE core.Cotizacion ADD CONSTRAINT [FK_Cotizacion_ServicioId] FOREIGN KEY ([ServicioId]) REFERENCES core.Servicio ([ServicioId]);
CREATE INDEX [IX_Cotizacion_ServicioId] ON core.Cotizacion ([ServicioId]);
ALTER TABLE core.Cotizacion ADD CONSTRAINT [FK_Cotizacion_ContactoId] FOREIGN KEY ([ContactoId]) REFERENCES core.Contacto ([ContactoId]);
CREATE INDEX [IX_Cotizacion_ContactoId] ON core.Cotizacion ([ContactoId]);
ALTER TABLE core.Cotizacion ADD CONSTRAINT [FK_Cotizacion_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.OrdenVenta ADD CONSTRAINT [FK_OrdenVenta_ServicioId] FOREIGN KEY ([ServicioId]) REFERENCES core.Servicio ([ServicioId]);
CREATE INDEX [IX_OrdenVenta_ServicioId] ON core.OrdenVenta ([ServicioId]);
ALTER TABLE core.OrdenVenta ADD CONSTRAINT [FK_OrdenVenta_ContactoId] FOREIGN KEY ([ContactoId]) REFERENCES core.Contacto ([ContactoId]);
CREATE INDEX [IX_OrdenVenta_ContactoId] ON core.OrdenVenta ([ContactoId]);
ALTER TABLE core.OrdenVenta ADD CONSTRAINT [FK_OrdenVenta_OportunidadId] FOREIGN KEY ([OportunidadId]) REFERENCES core.Oportunidad ([OportunidadId]);
CREATE INDEX [IX_OrdenVenta_OportunidadId] ON core.OrdenVenta ([OportunidadId]);
ALTER TABLE core.OrdenVenta ADD CONSTRAINT [FK_OrdenVenta_CotizacionId] FOREIGN KEY ([CotizacionId]) REFERENCES core.Cotizacion ([CotizacionId]);
CREATE INDEX [IX_OrdenVenta_CotizacionId] ON core.OrdenVenta ([CotizacionId]);
ALTER TABLE core.OrdenVenta ADD CONSTRAINT [FK_OrdenVenta_PropietarioUsuarioId] FOREIGN KEY ([PropietarioUsuarioId]) REFERENCES ref.Usuario ([UsuarioId]);
CREATE INDEX [IX_OrdenVenta_PropietarioUsuarioId] ON core.OrdenVenta ([PropietarioUsuarioId]);
ALTER TABLE core.OrdenVenta ADD CONSTRAINT [FK_OrdenVenta_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.OrdenVentaLinea ADD CONSTRAINT [FK_OrdenVentaLinea_OrdenVentaId] FOREIGN KEY ([OrdenVentaId]) REFERENCES core.OrdenVenta ([OrdenVentaId]);
CREATE INDEX [IX_OrdenVentaLinea_OrdenVentaId] ON core.OrdenVentaLinea ([OrdenVentaId]);
ALTER TABLE core.OrdenVentaLinea ADD CONSTRAINT [FK_OrdenVentaLinea_ProductoId] FOREIGN KEY ([ProductoId]) REFERENCES core.Producto ([ProductoId]);
CREATE INDEX [IX_OrdenVentaLinea_ProductoId] ON core.OrdenVentaLinea ([ProductoId]);
ALTER TABLE core.OrdenVentaLinea ADD CONSTRAINT [FK_OrdenVentaLinea_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.Producto ADD CONSTRAINT [FK_Producto_ImpuestoId] FOREIGN KEY ([ImpuestoId]) REFERENCES ref.Impuesto ([ImpuestoId]);
CREATE INDEX [IX_Producto_ImpuestoId] ON core.Producto ([ImpuestoId]);
ALTER TABLE core.Producto ADD CONSTRAINT [FK_Producto_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.OrdenTrabajo ADD CONSTRAINT [FK_OrdenTrabajo_ServicioId] FOREIGN KEY ([ServicioId]) REFERENCES core.Servicio ([ServicioId]);
CREATE INDEX [IX_OrdenTrabajo_ServicioId] ON core.OrdenTrabajo ([ServicioId]);
ALTER TABLE core.OrdenTrabajo ADD CONSTRAINT [FK_OrdenTrabajo_NodoId] FOREIGN KEY ([NodoId]) REFERENCES core.Nodo ([NodoId]);
CREATE INDEX [IX_OrdenTrabajo_NodoId] ON core.OrdenTrabajo ([NodoId]);
ALTER TABLE core.OrdenTrabajo ADD CONSTRAINT [FK_OrdenTrabajo_AsignadoUsuarioId] FOREIGN KEY ([AsignadoUsuarioId]) REFERENCES ref.Usuario ([UsuarioId]);
CREATE INDEX [IX_OrdenTrabajo_AsignadoUsuarioId] ON core.OrdenTrabajo ([AsignadoUsuarioId]);
ALTER TABLE core.OrdenTrabajo ADD CONSTRAINT [FK_OrdenTrabajo_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.OrdenServicioVoIP ADD CONSTRAINT [FK_OrdenServicioVoIP_ServicioId] FOREIGN KEY ([ServicioId]) REFERENCES core.Servicio ([ServicioId]);
CREATE INDEX [IX_OrdenServicioVoIP_ServicioId] ON core.OrdenServicioVoIP ([ServicioId]);
ALTER TABLE core.OrdenServicioVoIP ADD CONSTRAINT [FK_OrdenServicioVoIP_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.Caso ADD CONSTRAINT [FK_Caso_ServicioId] FOREIGN KEY ([ServicioId]) REFERENCES core.Servicio ([ServicioId]);
CREATE INDEX [IX_Caso_ServicioId] ON core.Caso ([ServicioId]);
ALTER TABLE core.Caso ADD CONSTRAINT [FK_Caso_PropietarioUsuarioId] FOREIGN KEY ([PropietarioUsuarioId]) REFERENCES ref.Usuario ([UsuarioId]);
CREATE INDEX [IX_Caso_PropietarioUsuarioId] ON core.Caso ([PropietarioUsuarioId]);
ALTER TABLE core.Caso ADD CONSTRAINT [FK_Caso_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.Nota ADD CONSTRAINT [FK_Nota_ServicioId] FOREIGN KEY ([ServicioId]) REFERENCES core.Servicio ([ServicioId]);
CREATE INDEX [IX_Nota_ServicioId] ON core.Nota ([ServicioId]);
ALTER TABLE core.Nota ADD CONSTRAINT [FK_Nota_CasoId] FOREIGN KEY ([CasoId]) REFERENCES core.Caso ([CasoId]);
CREATE INDEX [IX_Nota_CasoId] ON core.Nota ([CasoId]);
ALTER TABLE core.Nota ADD CONSTRAINT [FK_Nota_ClienteId] FOREIGN KEY ([ClienteId]) REFERENCES core.Cliente ([ClienteId]);
CREATE INDEX [IX_Nota_ClienteId] ON core.Nota ([ClienteId]);
ALTER TABLE core.Nota ADD CONSTRAINT [FK_Nota_AutorUsuarioId] FOREIGN KEY ([AutorUsuarioId]) REFERENCES ref.Usuario ([UsuarioId]);
CREATE INDEX [IX_Nota_AutorUsuarioId] ON core.Nota ([AutorUsuarioId]);
ALTER TABLE core.Nota ADD CONSTRAINT [FK_Nota_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.Tarea ADD CONSTRAINT [FK_Tarea_ServicioId] FOREIGN KEY ([ServicioId]) REFERENCES core.Servicio ([ServicioId]);
CREATE INDEX [IX_Tarea_ServicioId] ON core.Tarea ([ServicioId]);
ALTER TABLE core.Tarea ADD CONSTRAINT [FK_Tarea_ContactoId] FOREIGN KEY ([ContactoId]) REFERENCES core.Contacto ([ContactoId]);
CREATE INDEX [IX_Tarea_ContactoId] ON core.Tarea ([ContactoId]);
ALTER TABLE core.Tarea ADD CONSTRAINT [FK_Tarea_AsignadoUsuarioId] FOREIGN KEY ([AsignadoUsuarioId]) REFERENCES ref.Usuario ([UsuarioId]);
CREATE INDEX [IX_Tarea_AsignadoUsuarioId] ON core.Tarea ([AsignadoUsuarioId]);
ALTER TABLE core.Tarea ADD CONSTRAINT [FK_Tarea_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.TicketAtencion ADD CONSTRAINT [FK_TicketAtencion_ContactoId] FOREIGN KEY ([ContactoId]) REFERENCES core.Contacto ([ContactoId]);
CREATE INDEX [IX_TicketAtencion_ContactoId] ON core.TicketAtencion ([ContactoId]);
ALTER TABLE core.TicketAtencion ADD CONSTRAINT [FK_TicketAtencion_ServicioId] FOREIGN KEY ([ServicioId]) REFERENCES core.Servicio ([ServicioId]);
CREATE INDEX [IX_TicketAtencion_ServicioId] ON core.TicketAtencion ([ServicioId]);
ALTER TABLE core.TicketAtencion ADD CONSTRAINT [FK_TicketAtencion_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.Adjunto ADD CONSTRAINT [FK_Adjunto_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.Proveedor ADD CONSTRAINT [FK_Proveedor_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.Factura ADD CONSTRAINT [FK_Factura_ClienteId] FOREIGN KEY ([ClienteId]) REFERENCES core.Cliente ([ClienteId]);
CREATE INDEX [IX_Factura_ClienteId] ON core.Factura ([ClienteId]);
ALTER TABLE core.Factura ADD CONSTRAINT [FK_Factura_ServicioId] FOREIGN KEY ([ServicioId]) REFERENCES core.Servicio ([ServicioId]);
CREATE INDEX [IX_Factura_ServicioId] ON core.Factura ([ServicioId]);
ALTER TABLE core.Factura ADD CONSTRAINT [FK_Factura_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.FacturaLinea ADD CONSTRAINT [FK_FacturaLinea_FacturaId] FOREIGN KEY ([FacturaId]) REFERENCES core.Factura ([FacturaId]);
CREATE INDEX [IX_FacturaLinea_FacturaId] ON core.FacturaLinea ([FacturaId]);
ALTER TABLE core.FacturaLinea ADD CONSTRAINT [FK_FacturaLinea_ProductoId] FOREIGN KEY ([ProductoId]) REFERENCES core.Producto ([ProductoId]);
CREATE INDEX [IX_FacturaLinea_ProductoId] ON core.FacturaLinea ([ProductoId]);
ALTER TABLE core.FacturaLinea ADD CONSTRAINT [FK_FacturaLinea_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.FacturaRecurrente ADD CONSTRAINT [FK_FacturaRecurrente_ClienteId] FOREIGN KEY ([ClienteId]) REFERENCES core.Cliente ([ClienteId]);
CREATE INDEX [IX_FacturaRecurrente_ClienteId] ON core.FacturaRecurrente ([ClienteId]);
ALTER TABLE core.FacturaRecurrente ADD CONSTRAINT [FK_FacturaRecurrente_ServicioId] FOREIGN KEY ([ServicioId]) REFERENCES core.Servicio ([ServicioId]);
CREATE INDEX [IX_FacturaRecurrente_ServicioId] ON core.FacturaRecurrente ([ServicioId]);
ALTER TABLE core.FacturaRecurrente ADD CONSTRAINT [FK_FacturaRecurrente_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.Pago ADD CONSTRAINT [FK_Pago_ClienteId] FOREIGN KEY ([ClienteId]) REFERENCES core.Cliente ([ClienteId]);
CREATE INDEX [IX_Pago_ClienteId] ON core.Pago ([ClienteId]);
ALTER TABLE core.Pago ADD CONSTRAINT [FK_Pago_ServicioId] FOREIGN KEY ([ServicioId]) REFERENCES core.Servicio ([ServicioId]);
CREATE INDEX [IX_Pago_ServicioId] ON core.Pago ([ServicioId]);
ALTER TABLE core.Pago ADD CONSTRAINT [FK_Pago_CuentaBancariaId] FOREIGN KEY ([CuentaBancariaId]) REFERENCES core.CuentaBancaria ([CuentaBancariaId]);
CREATE INDEX [IX_Pago_CuentaBancariaId] ON core.Pago ([CuentaBancariaId]);
ALTER TABLE core.Pago ADD CONSTRAINT [FK_Pago_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.PagoFactura ADD CONSTRAINT [FK_PagoFactura_PagoId] FOREIGN KEY ([PagoId]) REFERENCES core.Pago ([PagoId]);
CREATE INDEX [IX_PagoFactura_PagoId] ON core.PagoFactura ([PagoId]);
ALTER TABLE core.PagoFactura ADD CONSTRAINT [FK_PagoFactura_FacturaId] FOREIGN KEY ([FacturaId]) REFERENCES core.Factura ([FacturaId]);
CREATE INDEX [IX_PagoFactura_FacturaId] ON core.PagoFactura ([FacturaId]);
ALTER TABLE core.PagoFactura ADD CONSTRAINT [FK_PagoFactura_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.CuentaBancaria ADD CONSTRAINT [FK_CuentaBancaria_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.MovimientoBancario ADD CONSTRAINT [FK_MovimientoBancario_CuentaBancariaId] FOREIGN KEY ([CuentaBancariaId]) REFERENCES core.CuentaBancaria ([CuentaBancariaId]);
CREATE INDEX [IX_MovimientoBancario_CuentaBancariaId] ON core.MovimientoBancario ([CuentaBancariaId]);
ALTER TABLE core.MovimientoBancario ADD CONSTRAINT [FK_MovimientoBancario_ClienteId] FOREIGN KEY ([ClienteId]) REFERENCES core.Cliente ([ClienteId]);
CREATE INDEX [IX_MovimientoBancario_ClienteId] ON core.MovimientoBancario ([ClienteId]);
ALTER TABLE core.MovimientoBancario ADD CONSTRAINT [FK_MovimientoBancario_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.Gasto ADD CONSTRAINT [FK_Gasto_ProveedorId] FOREIGN KEY ([ProveedorId]) REFERENCES core.Proveedor ([ProveedorId]);
CREATE INDEX [IX_Gasto_ProveedorId] ON core.Gasto ([ProveedorId]);
ALTER TABLE core.Gasto ADD CONSTRAINT [FK_Gasto_ClienteId] FOREIGN KEY ([ClienteId]) REFERENCES core.Cliente ([ClienteId]);
CREATE INDEX [IX_Gasto_ClienteId] ON core.Gasto ([ClienteId]);
ALTER TABLE core.Gasto ADD CONSTRAINT [FK_Gasto_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.OrdenCompra ADD CONSTRAINT [FK_OrdenCompra_ProveedorId] FOREIGN KEY ([ProveedorId]) REFERENCES core.Proveedor ([ProveedorId]);
CREATE INDEX [IX_OrdenCompra_ProveedorId] ON core.OrdenCompra ([ProveedorId]);
ALTER TABLE core.OrdenCompra ADD CONSTRAINT [FK_OrdenCompra_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.HistorialEstadoCliente ADD CONSTRAINT [FK_HistorialEstadoCliente_ClienteId] FOREIGN KEY ([ClienteId]) REFERENCES core.Cliente ([ClienteId]);
CREATE INDEX [IX_HistorialEstadoCliente_ClienteId] ON core.HistorialEstadoCliente ([ClienteId]);
ALTER TABLE core.HistorialEstadoCliente ADD CONSTRAINT [FK_HistorialEstadoCliente_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.Troncal ADD CONSTRAINT [FK_Troncal_ServicioId] FOREIGN KEY ([ServicioId]) REFERENCES core.Servicio ([ServicioId]);
CREATE INDEX [IX_Troncal_ServicioId] ON core.Troncal ([ServicioId]);
ALTER TABLE core.Troncal ADD CONSTRAINT [FK_Troncal_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.TroncalPermisoCodigo ADD CONSTRAINT [FK_TroncalPermisoCodigo_TroncalId] FOREIGN KEY ([TroncalId]) REFERENCES core.Troncal ([TroncalId]);
CREATE INDEX [IX_TroncalPermisoCodigo_TroncalId] ON core.TroncalPermisoCodigo ([TroncalId]);
ALTER TABLE core.TroncalPermisoCodigo ADD CONSTRAINT [FK_TroncalPermisoCodigo_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.AlertaTroncal ADD CONSTRAINT [FK_AlertaTroncal_TroncalId] FOREIGN KEY ([TroncalId]) REFERENCES core.Troncal ([TroncalId]);
CREATE INDEX [IX_AlertaTroncal_TroncalId] ON core.AlertaTroncal ([TroncalId]);
ALTER TABLE core.AlertaTroncal ADD CONSTRAINT [FK_AlertaTroncal_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.LineaGratuita ADD CONSTRAINT [FK_LineaGratuita_ServicioId] FOREIGN KEY ([ServicioId]) REFERENCES core.Servicio ([ServicioId]);
CREATE INDEX [IX_LineaGratuita_ServicioId] ON core.LineaGratuita ([ServicioId]);
ALTER TABLE core.LineaGratuita ADD CONSTRAINT [FK_LineaGratuita_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.ServicioPaqueteMinutos ADD CONSTRAINT [FK_ServicioPaqueteMinutos_ServicioId] FOREIGN KEY ([ServicioId]) REFERENCES core.Servicio ([ServicioId]);
CREATE INDEX [IX_ServicioPaqueteMinutos_ServicioId] ON core.ServicioPaqueteMinutos ([ServicioId]);
ALTER TABLE core.ServicioPaqueteMinutos ADD CONSTRAINT [FK_ServicioPaqueteMinutos_PaqueteMinutosId] FOREIGN KEY ([PaqueteMinutosId]) REFERENCES ref.PaqueteMinutos ([PaqueteMinutosId]);
CREATE INDEX [IX_ServicioPaqueteMinutos_PaqueteMinutosId] ON core.ServicioPaqueteMinutos ([PaqueteMinutosId]);
ALTER TABLE core.ServicioPaqueteMinutos ADD CONSTRAINT [FK_ServicioPaqueteMinutos_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.MinutosContratadosHistorico ADD CONSTRAINT [FK_MinutosContratadosHistorico_ClienteId] FOREIGN KEY ([ClienteId]) REFERENCES core.Cliente ([ClienteId]);
CREATE INDEX [IX_MinutosContratadosHistorico_ClienteId] ON core.MinutosContratadosHistorico ([ClienteId]);
ALTER TABLE core.MinutosContratadosHistorico ADD CONSTRAINT [FK_MinutosContratadosHistorico_ServicioId] FOREIGN KEY ([ServicioId]) REFERENCES core.Servicio ([ServicioId]);
CREATE INDEX [IX_MinutosContratadosHistorico_ServicioId] ON core.MinutosContratadosHistorico ([ServicioId]);
ALTER TABLE core.MinutosContratadosHistorico ADD CONSTRAINT [FK_MinutosContratadosHistorico_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.ArchivoCDR ADD CONSTRAINT [FK_ArchivoCDR_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.Llamada ADD CONSTRAINT [FK_Llamada_ServicioId] FOREIGN KEY ([ServicioId]) REFERENCES core.Servicio ([ServicioId]);
CREATE INDEX [IX_Llamada_ServicioId] ON core.Llamada ([ServicioId]);
ALTER TABLE core.Llamada ADD CONSTRAINT [FK_Llamada_TroncalEntradaId] FOREIGN KEY ([TroncalEntradaId]) REFERENCES core.Troncal ([TroncalId]);
CREATE INDEX [IX_Llamada_TroncalEntradaId] ON core.Llamada ([TroncalEntradaId]);
ALTER TABLE core.Llamada ADD CONSTRAINT [FK_Llamada_TroncalSalidaId] FOREIGN KEY ([TroncalSalidaId]) REFERENCES core.Troncal ([TroncalId]);
CREATE INDEX [IX_Llamada_TroncalSalidaId] ON core.Llamada ([TroncalSalidaId]);
ALTER TABLE core.Llamada ADD CONSTRAINT [FK_Llamada_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.CorteVoIP ADD CONSTRAINT [FK_CorteVoIP_ServicioId] FOREIGN KEY ([ServicioId]) REFERENCES core.Servicio ([ServicioId]);
CREATE INDEX [IX_CorteVoIP_ServicioId] ON core.CorteVoIP ([ServicioId]);
ALTER TABLE core.CorteVoIP ADD CONSTRAINT [FK_CorteVoIP_ClienteId] FOREIGN KEY ([ClienteId]) REFERENCES core.Cliente ([ClienteId]);
CREATE INDEX [IX_CorteVoIP_ClienteId] ON core.CorteVoIP ([ClienteId]);
ALTER TABLE core.CorteVoIP ADD CONSTRAINT [FK_CorteVoIP_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.ConsumoVoIP ADD CONSTRAINT [FK_ConsumoVoIP_CorteVoIPId] FOREIGN KEY ([CorteVoIPId]) REFERENCES core.CorteVoIP ([CorteVoIPId]);
CREATE INDEX [IX_ConsumoVoIP_CorteVoIPId] ON core.ConsumoVoIP ([CorteVoIPId]);
ALTER TABLE core.ConsumoVoIP ADD CONSTRAINT [FK_ConsumoVoIP_ServicioId] FOREIGN KEY ([ServicioId]) REFERENCES core.Servicio ([ServicioId]);
CREATE INDEX [IX_ConsumoVoIP_ServicioId] ON core.ConsumoVoIP ([ServicioId]);
ALTER TABLE core.ConsumoVoIP ADD CONSTRAINT [FK_ConsumoVoIP_ClienteId] FOREIGN KEY ([ClienteId]) REFERENCES core.Cliente ([ClienteId]);
CREATE INDEX [IX_ConsumoVoIP_ClienteId] ON core.ConsumoVoIP ([ClienteId]);
ALTER TABLE core.ConsumoVoIP ADD CONSTRAINT [FK_ConsumoVoIP_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.FacturaElectronicaProveedor ADD CONSTRAINT [FK_FacturaElectronicaProveedor_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.SolicitudEnLinea ADD CONSTRAINT [FK_SolicitudEnLinea_ClienteId] FOREIGN KEY ([ClienteId]) REFERENCES core.Cliente ([ClienteId]);
CREATE INDEX [IX_SolicitudEnLinea_ClienteId] ON core.SolicitudEnLinea ([ClienteId]);
ALTER TABLE core.SolicitudEnLinea ADD CONSTRAINT [FK_SolicitudEnLinea_ProductoId] FOREIGN KEY ([ProductoId]) REFERENCES core.Producto ([ProductoId]);
CREATE INDEX [IX_SolicitudEnLinea_ProductoId] ON core.SolicitudEnLinea ([ProductoId]);
ALTER TABLE core.SolicitudEnLinea ADD CONSTRAINT [FK_SolicitudEnLinea_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.PagoEnLinea ADD CONSTRAINT [FK_PagoEnLinea_SolicitudEnLineaId] FOREIGN KEY ([SolicitudEnLineaId]) REFERENCES core.SolicitudEnLinea ([SolicitudEnLineaId]);
CREATE INDEX [IX_PagoEnLinea_SolicitudEnLineaId] ON core.PagoEnLinea ([SolicitudEnLineaId]);
ALTER TABLE core.PagoEnLinea ADD CONSTRAINT [FK_PagoEnLinea_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.ReservaInstalacion ADD CONSTRAINT [FK_ReservaInstalacion_SolicitudEnLineaId] FOREIGN KEY ([SolicitudEnLineaId]) REFERENCES core.SolicitudEnLinea ([SolicitudEnLineaId]);
CREATE INDEX [IX_ReservaInstalacion_SolicitudEnLineaId] ON core.ReservaInstalacion ([SolicitudEnLineaId]);
ALTER TABLE core.ReservaInstalacion ADD CONSTRAINT [FK_ReservaInstalacion_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.OrdenEnLinea ADD CONSTRAINT [FK_OrdenEnLinea_SolicitudEnLineaId] FOREIGN KEY ([SolicitudEnLineaId]) REFERENCES core.SolicitudEnLinea ([SolicitudEnLineaId]);
CREATE INDEX [IX_OrdenEnLinea_SolicitudEnLineaId] ON core.OrdenEnLinea ([SolicitudEnLineaId]);
ALTER TABLE core.OrdenEnLinea ADD CONSTRAINT [FK_OrdenEnLinea_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.OrdenEnLineaLinea ADD CONSTRAINT [FK_OrdenEnLineaLinea_OrdenEnLineaId] FOREIGN KEY ([OrdenEnLineaId]) REFERENCES core.OrdenEnLinea ([OrdenEnLineaId]);
CREATE INDEX [IX_OrdenEnLineaLinea_OrdenEnLineaId] ON core.OrdenEnLineaLinea ([OrdenEnLineaId]);
ALTER TABLE core.OrdenEnLineaLinea ADD CONSTRAINT [FK_OrdenEnLineaLinea_ProductoId] FOREIGN KEY ([ProductoId]) REFERENCES core.Producto ([ProductoId]);
CREATE INDEX [IX_OrdenEnLineaLinea_ProductoId] ON core.OrdenEnLineaLinea ([ProductoId]);
ALTER TABLE core.OrdenEnLineaLinea ADD CONSTRAINT [FK_OrdenEnLineaLinea_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.AprovisionamientoOdoo ADD CONSTRAINT [FK_AprovisionamientoOdoo_SolicitudEnLineaId] FOREIGN KEY ([SolicitudEnLineaId]) REFERENCES core.SolicitudEnLinea ([SolicitudEnLineaId]);
CREATE INDEX [IX_AprovisionamientoOdoo_SolicitudEnLineaId] ON core.AprovisionamientoOdoo ([SolicitudEnLineaId]);
ALTER TABLE core.AprovisionamientoOdoo ADD CONSTRAINT [FK_AprovisionamientoOdoo_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.UbicacionFlota ADD CONSTRAINT [FK_UbicacionFlota_UnidadFlotaId] FOREIGN KEY ([UnidadFlotaId]) REFERENCES ref.UnidadFlota ([UnidadFlotaId]);
CREATE INDEX [IX_UbicacionFlota_UnidadFlotaId] ON core.UbicacionFlota ([UnidadFlotaId]);
ALTER TABLE core.UbicacionFlota ADD CONSTRAINT [FK_UbicacionFlota_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.ViajeFlota ADD CONSTRAINT [FK_ViajeFlota_UnidadFlotaId] FOREIGN KEY ([UnidadFlotaId]) REFERENCES ref.UnidadFlota ([UnidadFlotaId]);
CREATE INDEX [IX_ViajeFlota_UnidadFlotaId] ON core.ViajeFlota ([UnidadFlotaId]);
ALTER TABLE core.ViajeFlota ADD CONSTRAINT [FK_ViajeFlota_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.EventoFlota ADD CONSTRAINT [FK_EventoFlota_UnidadFlotaId] FOREIGN KEY ([UnidadFlotaId]) REFERENCES ref.UnidadFlota ([UnidadFlotaId]);
CREATE INDEX [IX_EventoFlota_UnidadFlotaId] ON core.EventoFlota ([UnidadFlotaId]);
ALTER TABLE core.EventoFlota ADD CONSTRAINT [FK_EventoFlota_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.IncidenteConduccion ADD CONSTRAINT [FK_IncidenteConduccion_UnidadFlotaId] FOREIGN KEY ([UnidadFlotaId]) REFERENCES ref.UnidadFlota ([UnidadFlotaId]);
CREATE INDEX [IX_IncidenteConduccion_UnidadFlotaId] ON core.IncidenteConduccion ([UnidadFlotaId]);
ALTER TABLE core.IncidenteConduccion ADD CONSTRAINT [FK_IncidenteConduccion_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.CheckInCampo ADD CONSTRAINT [FK_CheckInCampo_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
ALTER TABLE core.EventoConexion ADD CONSTRAINT [FK_EventoConexion_ClienteId] FOREIGN KEY ([ClienteId]) REFERENCES core.Cliente ([ClienteId]);
CREATE INDEX [IX_EventoConexion_ClienteId] ON core.EventoConexion ([ClienteId]);
ALTER TABLE core.EventoConexion ADD CONSTRAINT [FK_EventoConexion_LoteId] FOREIGN KEY ([LoteId]) REFERENCES ctl.Lote ([LoteId]);
GO

/* ---------------- Catálogo de reglas aprobado (v1.0) ---------------- */
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'ID-01', N'Identidad', N'El servicio se identifica por el número de circuito normalizado (mayúsculas, sin espacios, guiones ni puntos; 3 letras + 4 a 9 dígitos).', N'Crítica', NULL, N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'ID-02', N'Identidad', N'El cliente se identifica por su cédula con solo dígitos: 9 física, 10 jurídica, 12 DIMEX; otra longitud es inválida.', N'Crítica', NULL, N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'ID-03', N'Identidad', N'Un cliente puede tener varios servicios.', N'Crítica', NULL, N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'ID-04', N'Identidad', N'Los IDs de cada sistema se conservan como llaves de origen en la tabla de correspondencia.', N'Crítica', NULL, N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'ID-05', N'Identidad', N'Orden de emparejamiento: circuito, luego cédula, si no sin correspondencia. Nunca por nombre, correo o teléfono.', N'Crítica', NULL, N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'ID-06', N'Identidad', N'Facturas y pagos de Books heredan el circuito y la cédula del contacto.', N'Crítica', NULL, N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'ID-07', N'Identidad', N'Las llamadas se vinculan por CustomerCircuitNumber.', N'Crítica', NULL, N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'ID-08', N'Identidad', N'ZohoID equivale a la cuenta del CRM.', N'Estándar', NULL, N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'ID-09', N'Identidad', N'Trengo se vincula vía el contacto del CRM (ID_ZCRM).', N'Estándar', NULL, N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'ID-10', N'Identidad', N'customer_status_zbooks se vincula por custome_id (contacto de Books).', N'Estándar', NULL, N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'DD-01', N'Deduplicación', N'Llamadas iguales en todo salvo id/_id son duplicadas; se conserva la de menor id.', N'Crítica', NULL, N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'DD-02', N'Deduplicación', N'Espejos Zoho con el mismo ID: se conserva la modificación más reciente.', N'Crítica', NULL, N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'DD-03', N'Deduplicación', N'Filas idénticas sin llave se cargan una sola vez.', N'Estándar', NULL, N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'DD-04', N'Deduplicación', N'Una llave numérica no garantiza unicidad; se mide por contenido.', N'Estándar', NULL, N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'DD-05', N'Deduplicación', N'Cada archivo CDR se procesa una sola vez (huella).', N'Crítica', NULL, N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'DD-06', N'Deduplicación', N'Todo registro excluido queda en la tabla de descartes.', N'Crítica', NULL, N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'ES-01', N'Estandarización', N'Fechas tipadas con zona horaria explícita.', N'Crítica', NULL, N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'ES-02', N'Estandarización', N'Fechas anteriores a 1990 o 1900-01-01 pasan a NULL y se marcan.', N'Crítica', NULL, N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'ES-03', N'Estandarización', N'Fecha de registro posterior a la carga es anomalía.', N'Estándar', NULL, N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'ES-04', N'Estandarización', N'Montos decimal(19,4) con la moneda en columna aparte.', N'Crítica', NULL, N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'ES-05', N'Estandarización', N'Texto recortado, vacío a NULL, nvarchar y una sola intercalación.', N'Estándar', NULL, N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'ES-06', N'Estandarización', N'Las llaves usan el mismo tipo en todas las tablas.', N'Estándar', NULL, N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'ES-07', N'Estandarización', N'Booleanos en texto pasan a bit.', N'Estándar', NULL, N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'ES-08', N'Estandarización', N'Se conserva el valor original de los campos normalizados.', N'Estándar', NULL, N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'ES-09', N'Estandarización', N'Las unidades de Navsat se clasifican (vehículo empresa, propio, colaborador).', N'Estándar', NULL, N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'IN-01', N'Integridad', N'Los registros huérfanos se cargan marcados.', N'Crítica', NULL, N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'IN-02', N'Integridad', N'Las relaciones se declaran como llaves foráneas.', N'Crítica', NULL, N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'IN-03', N'Integridad', N'Las columnas vacías no se migran.', N'Estándar', NULL, N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'IN-04', N'Integridad', N'No se migran credenciales, contraseñas, tokens, fotos de cédula ni firmas.', N'Crítica', NULL, N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'IN-05', N'Integridad', N'Cada registro guarda su trazabilidad: sistema, base, tabla, llave de origen, período y lote.', N'Crítica', NULL, N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'D1', N'Decisión', N'Llamadas: MongoDB desde 2024 + SQL Server 2022-2023.', N'Crítica', N'C', N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'D2', N'Decisión', N'Tablas _Extended como principal; la base completa aporta los ausentes, marcados.', N'Crítica', N'C', N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'D3', N'Decisión', N'Decisión D3 del catálogo v1.0.', N'Estándar', N'A', N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'D4', N'Decisión', N'Fechas en datetimeoffset con zona -06:00.', N'Crítica', N'C', N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'D5', N'Decisión', N'Moneda original + equivalente en colones con el tipo de cambio del día.', N'Crítica', N'C', N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'D6', N'Decisión', N'Modelo con datos completos y acceso restringido; corpus RAG anonimizado.', N'Crítica', N'B', N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'D7', N'Decisión', N'Llamadas: 24 meses en línea + histórico; PRTG 90 días (sujeto a requisitos legales).', N'Crítica', N'B', N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'D8', N'Decisión', N'Se incluyen clientes sin CRM, marcados con su sistema de origen.', N'Crítica', N'B', N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'D9', N'Decisión', N'CRM manda en datos comerciales y de contacto; Books en fiscales; ADNPayV2 solo completa vacíos.', N'Crítica', N'B', N'1.0', '2026-10-06', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'D10', N'Decisión', N'Moneda de tarifas y costos de llamadas según el destino: códigos 506 en colones, el resto en dólares.', N'Crítica', N'C', N'1.1', '2026-10-12', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'D11', N'Decisión', N'Minutos_Customer y MinutosLegalId se conservan como histórico en core.MinutosContratadosHistorico.', N'Estándar', N'B', N'1.1', '2026-10-12', N'José Hernández');
INSERT INTO ctl.Regla (ReglaId, Tipo, Descripcion, Criticidad, OpcionAprobada, Version, FechaAprobacion, AprobadoPor) VALUES (N'D12', N'Decisión', N'Tickets de Trengo y conexiones/desconexiones se cargan como fuentes históricas; los tickets sin ID del CRM quedan sin correspondencia (ID-05 sin excepción).', N'Estándar', N'A', N'1.1', '2026-10-12', N'José Hernández');
GO

SET NOEXEC OFF;
GO
/* ---------------- Verificación ---------------- */
SELECT s.name AS Esquema, COUNT(DISTINCT t.object_id) AS Tablas, COUNT(c.column_id) AS Columnas
FROM sys.tables t JOIN sys.schemas s ON s.schema_id = t.schema_id JOIN sys.columns c ON c.object_id = t.object_id
GROUP BY s.name ORDER BY s.name;
SELECT COUNT(*) AS LlavesForaneas FROM sys.foreign_keys;
SELECT COUNT(*) AS Reglas FROM ctl.Regla;
GO