/* =====================================================================
   Vistas para ask.data.cr y futuros sistemas RAG (Sprint 5) - GENERADO por herramientas/gen_diccionario.py
   Aplica la decisión D6: cada vista expone solo las columnas clasificadas como 'Disponible' en el diccionario
   (hoja Diccionario, columna 'ask.data.cr / RAG'). Las tablas 'No disponible' no tienen vista.
   El rol rag_lector solo puede leer el esquema rag; no ve core, ref ni ctl.
   Idempotente. SOLO sandbox: en producción requiere autorización de José Hernández.
   ===================================================================== */
SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON;
USE ADN_Unificado;
GO
IF SCHEMA_ID(N'rag') IS NULL EXEC(N'CREATE SCHEMA rag');
GO
CREATE OR ALTER VIEW rag.[Regla] AS
SELECT [ReglaId],
       [Tipo],
       [Descripcion],
       [Criticidad],
       [OpcionAprobada],
       [Version],
       [FechaAprobacion],
       [AprobadoPor]
FROM ctl.[Regla];
GO
CREATE OR ALTER VIEW rag.[Fuente] AS
SELECT [FuenteId],
       [Sistema],
       [Motor],
       [Base],
       [Tabla],
       [Disposicion],
       [MotivoDisposicion],
       [PeriodoDesde],
       [PeriodoHasta]
FROM ctl.[Fuente];
GO
CREATE OR ALTER VIEW rag.[TipoCambio] AS
SELECT [TipoCambioId],
       [Fecha],
       [Compra],
       [Venta],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM ref.[TipoCambio];
GO
CREATE OR ALTER VIEW rag.[Usuario] AS
SELECT [UsuarioId],
       [Rol],
       [Perfil],
       [Division],
       [Estado],
       [FechaCreacionOrigen],
       [FechaModificacionOrigen],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM ref.[Usuario];
GO
CREATE OR ALTER VIEW rag.[Provincia] AS
SELECT [ProvinciaId],
       [Nombre],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM ref.[Provincia];
GO
CREATE OR ALTER VIEW rag.[Canton] AS
SELECT [CantonId],
       [ProvinciaId],
       [Nombre],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM ref.[Canton];
GO
CREATE OR ALTER VIEW rag.[Distrito] AS
SELECT [DistritoId],
       [CantonId],
       [Nombre],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM ref.[Distrito];
GO
CREATE OR ALTER VIEW rag.[Impuesto] AS
SELECT [ImpuestoId],
       [Nombre],
       [Porcentaje],
       [Tipo],
       [EsPredeterminado],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM ref.[Impuesto];
GO
CREATE OR ALTER VIEW rag.[CuentaContable] AS
SELECT [CuentaContableId],
       [CuentaPadreId],
       [Codigo],
       [Nombre],
       [Tipo],
       [Descripcion],
       [EsDeSistema],
       [Activa],
       [FechaCreacionOrigen],
       [FechaModificacionOrigen],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM ref.[CuentaContable];
GO
CREATE OR ALTER VIEW rag.[ProveedorTelefonia] AS
SELECT [ProveedorTelefoniaId],
       [Nombre],
       [FechaActualizacionTarifas],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM ref.[ProveedorTelefonia];
GO
CREATE OR ALTER VIEW rag.[TroncalProveedor] AS
SELECT [TroncalProveedorId],
       [ProveedorTelefoniaId],
       [CodigoTroncal],
       [Estado],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM ref.[TroncalProveedor];
GO
CREATE OR ALTER VIEW rag.[TarifaDestino] AS
SELECT [TarifaDestinoId],
       [ProveedorTelefoniaId],
       [CodigoMarcacion],
       [Nombre],
       [Tarifa],
       [Redondeo],
       [Costo],
       [EsNumeroEspecial],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM ref.[TarifaDestino];
GO
CREATE OR ALTER VIEW rag.[PaqueteMinutos] AS
SELECT [PaqueteMinutosId],
       [Codigo],
       [Descripcion],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM ref.[PaqueteMinutos];
GO
CREATE OR ALTER VIEW rag.[PaqueteMinutosCodigo] AS
SELECT [PaqueteMinutosCodigoId],
       [PaqueteMinutosId],
       [CodigoMarcacion],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM ref.[PaqueteMinutosCodigo];
GO
CREATE OR ALTER VIEW rag.[CodigoPromocion] AS
SELECT [CodigoPromocionId],
       [Codigo],
       [Categoria],
       [Activo],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM ref.[CodigoPromocion];
GO
CREATE OR ALTER VIEW rag.[UnidadFlota] AS
SELECT [UnidadFlotaId],
       [Placa],
       [TipoUnidad],
       [Descripcion],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM ref.[UnidadFlota];
GO
CREATE OR ALTER VIEW rag.[Cliente] AS
SELECT [ClienteId],
       [TipoIdentificacion],
       [TipoFiscal],
       [Exonerado],
       [Segmento],
       [Industria],
       [EstadoCorrespondencia],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[Cliente];
GO
CREATE OR ALTER VIEW rag.[Servicio] AS
SELECT [ServicioId],
       [ClienteId],
       [Circuito],
       [TipoCuenta],
       [Estado],
       [Plataforma],
       [CapacidadMbps],
       [TieneIPTV],
       [TieneVoIP],
       [NumeroTroncal],
       [Moneda],
       [TipoCambio],
       [Mensualidad],
       [MensualidadCRC],
       [DistritoId],
       [Provincia],
       [Canton],
       [DistritoTexto],
       [CondominioId],
       [EjecutivoUsuarioId],
       [FechaInstalacion],
       [FechaActivacion],
       [FechaRetiro],
       [EstadoCorrespondencia],
       [FechaCreacionOrigen],
       [FechaModificacionOrigen],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[Servicio];
GO
CREATE OR ALTER VIEW rag.[Contacto] AS
SELECT [ContactoId],
       [ClienteId],
       [ServicioId],
       [TipoContacto],
       [PropietarioUsuarioId],
       [FechaCreacionOrigen],
       [FechaModificacionOrigen],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[Contacto];
GO
CREATE OR ALTER VIEW rag.[Prospecto] AS
SELECT [ProspectoId],
       [ClienteId],
       [Estado],
       [Origen],
       [Segmento],
       [DireccionId],
       [Provincia],
       [Canton],
       [FechaRegistro],
       [FechaConversion],
       [CompraRealizada],
       [PropietarioUsuarioId],
       [FechaCreacionOrigen],
       [FechaModificacionOrigen],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[Prospecto];
GO
CREATE OR ALTER VIEW rag.[Condominio] AS
SELECT [CondominioId],
       [Nombre],
       [Tipo],
       [TipoConstruccion],
       [CantidadCasas],
       [CapacidadMaxima],
       [AplicaFTTH],
       [Provincia],
       [Canton],
       [Distrito],
       [Direccion],
       [Latitud],
       [Longitud],
       [FechaInstalacion],
       [FechaCreacionOrigen],
       [FechaModificacionOrigen],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[Condominio];
GO
CREATE OR ALTER VIEW rag.[Nodo] AS
SELECT [NodoId],
       [Nombre],
       [Nomenclatura],
       [Estado],
       [Capacidad],
       [CantidadClientes],
       [Provincia],
       [Direccion],
       [Latitud],
       [Longitud],
       [FechaCreacionOrigen],
       [FechaModificacionOrigen],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[Nodo];
GO
CREATE OR ALTER VIEW rag.[ClusterFTTH] AS
SELECT [ClusterFTTHId],
       [Nombre],
       [CodigoCluster],
       [NodoId],
       [Fase],
       [CapacidadRed],
       [CantidadClientes],
       [Provincia],
       [Canton],
       [Distrito],
       [FechaInstalacion],
       [FechaCreacionOrigen],
       [FechaModificacionOrigen],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[ClusterFTTH];
GO
CREATE OR ALTER VIEW rag.[Oportunidad] AS
SELECT [OportunidadId],
       [ServicioId],
       [ContactoId],
       [Etapa],
       [Probabilidad],
       [Moneda],
       [TipoCambio],
       [Monto],
       [MontoCRC],
       [FechaCierre],
       [Segmento],
       [PropietarioUsuarioId],
       [FechaCreacionOrigen],
       [FechaModificacionOrigen],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[Oportunidad];
GO
CREATE OR ALTER VIEW rag.[Cotizacion] AS
SELECT [CotizacionId],
       [OportunidadId],
       [ServicioId],
       [ContactoId],
       [Etapa],
       [Tipo],
       [Moneda],
       [TipoCambio],
       [SubTotal],
       [SubTotalCRC],
       [Impuesto],
       [ImpuestoCRC],
       [Descuento],
       [DescuentoCRC],
       [Total],
       [TotalCRC],
       [FechaCotizacion],
       [FechaCreacionOrigen],
       [FechaModificacionOrigen],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[Cotizacion];
GO
CREATE OR ALTER VIEW rag.[OrdenVenta] AS
SELECT [OrdenVentaId],
       [ServicioId],
       [ContactoId],
       [OportunidadId],
       [CotizacionId],
       [Circuito],
       [Estado],
       [TipoContrato],
       [PlazoMeses],
       [CapacidadDescargaMbps],
       [CapacidadCargaMbps],
       [Moneda],
       [TipoCambio],
       [SubTotal],
       [SubTotalCRC],
       [Impuesto],
       [ImpuestoCRC],
       [Descuento],
       [DescuentoCRC],
       [Total],
       [TotalCRC],
       [Mensualidad],
       [MensualidadCRC],
       [FechaFirma],
       [FechaInactivacion],
       [PropietarioUsuarioId],
       [FechaCreacionOrigen],
       [FechaModificacionOrigen],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[OrdenVenta];
GO
CREATE OR ALTER VIEW rag.[OrdenVentaLinea] AS
SELECT [OrdenVentaLineaId],
       [OrdenVentaId],
       [ProductoId],
       [Descripcion],
       [Cantidad],
       [Moneda],
       [TipoCambio],
       [PrecioUnitario],
       [PrecioUnitarioCRC],
       [Descuento],
       [DescuentoCRC],
       [Impuesto],
       [ImpuestoCRC],
       [Total],
       [TotalCRC],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[OrdenVentaLinea];
GO
CREATE OR ALTER VIEW rag.[Producto] AS
SELECT [ProductoId],
       [Sistema],
       [Nombre],
       [Descripcion],
       [Tipo],
       [Categoria],
       [Unidad],
       [CodigoCabys],
       [ImpuestoId],
       [Moneda],
       [TipoCambio],
       [Precio],
       [PrecioCRC],
       [PrecioSinImpuesto],
       [PrecioSinImpuestoCRC],
       [VelocidadDescargaMbps],
       [VelocidadCargaMbps],
       [IncluyeIPTV],
       [IncluyeTelefonia],
       [IncluyeIPPublica],
       [Activo],
       [FechaCreacionOrigen],
       [FechaModificacionOrigen],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[Producto];
GO
CREATE OR ALTER VIEW rag.[OrdenTrabajo] AS
SELECT [OrdenTrabajoId],
       [ServicioId],
       [NodoId],
       [Tipo],
       [TipoSolicitud],
       [Estado],
       [SubEstado],
       [Tecnologia],
       [CapacidadDescarga],
       [CapacidadCarga],
       [Provincia],
       [Canton],
       [Distrito],
       [FechaCreacionOT],
       [FechaCoordinada],
       [FechaEstimada],
       [FechaFinalizacion],
       [FechaEntregaEnlace],
       [AsignadoUsuarioId],
       [FechaCreacionOrigen],
       [FechaModificacionOrigen],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[OrdenTrabajo];
GO
CREATE OR ALTER VIEW rag.[OrdenServicioVoIP] AS
SELECT [OrdenServicioVoIPId],
       [ServicioId],
       [TipoServicio],
       [TipoSolicitud],
       [Estado],
       [FechaSolicitud],
       [FechaInstalacion],
       [FechaDesinstalacion],
       [FechaCreacionOrigen],
       [FechaModificacionOrigen],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[OrdenServicioVoIP];
GO
CREATE OR ALTER VIEW rag.[Caso] AS
SELECT [CasoId],
       [ServicioId],
       [Circuito],
       [NumeroTicket],
       [Estado],
       [Origen],
       [Segmento],
       [TipoMantenimiento],
       [DepartamentoOrigen],
       [ProveedorExterno],
       [VisitaTecnica],
       [Escalado],
       [PropietarioUsuarioId],
       [FechaSolicitud],
       [FechaAfectacion],
       [FechaEscalamiento],
       [FechaFinMantenimiento],
       [FechaFinalizacion],
       [FechaCreacionOrigen],
       [FechaModificacionOrigen],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[Caso];
GO
CREATE OR ALTER VIEW rag.[Nota] AS
SELECT [NotaId],
       [Entidad],
       [ServicioId],
       [CasoId],
       [ClienteId],
       [CompartidaConCliente],
       [AutorUsuarioId],
       [FechaCreacionOrigen],
       [FechaModificacionOrigen],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[Nota];
GO
CREATE OR ALTER VIEW rag.[Tarea] AS
SELECT [TareaId],
       [ServicioId],
       [ContactoId],
       [Tipo],
       [Estado],
       [Prioridad],
       [FechaVencimiento],
       [FechaCierre],
       [AsignadoUsuarioId],
       [FechaCreacionOrigen],
       [FechaModificacionOrigen],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[Tarea];
GO
CREATE OR ALTER VIEW rag.[TicketAtencion] AS
SELECT [TicketAtencionId],
       [ContactoId],
       [ServicioId],
       [Canal],
       [Departamento],
       [DuracionMinutos],
       [FechaCreacion],
       [FechaAsignacion],
       [FechaCierre],
       [FechaActualizacion],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[TicketAtencion];
GO
CREATE OR ALTER VIEW rag.[Adjunto] AS
SELECT [AdjuntoId],
       [Modulo],
       [TamanoBytes],
       [TipoArchivo],
       [FechaCreacionOrigen],
       [FechaModificacionOrigen],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[Adjunto];
GO
CREATE OR ALTER VIEW rag.[Proveedor] AS
SELECT [ProveedorId],
       [Nombre],
       [Empresa],
       [Estado],
       [FechaCreacionOrigen],
       [FechaModificacionOrigen],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[Proveedor];
GO
CREATE OR ALTER VIEW rag.[Factura] AS
SELECT [FacturaId],
       [ClienteId],
       [ServicioId],
       [Numero],
       [Estado],
       [Fecha],
       [FechaVencimiento],
       [Moneda],
       [TipoCambio],
       [Total],
       [TotalCRC],
       [Saldo],
       [SaldoCRC],
       [Ajuste],
       [AjusteCRC],
       [CargoEnvio],
       [CargoEnvioCRC],
       [MontoCancelado],
       [MontoCanceladoCRC],
       [Sucursal],
       [FechaUltimoPago],
       [FechaCreacionOrigen],
       [FechaModificacionOrigen],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[Factura];
GO
CREATE OR ALTER VIEW rag.[FacturaLinea] AS
SELECT [FacturaLineaId],
       [FacturaId],
       [ProductoId],
       [Nombre],
       [Descripcion],
       [Cantidad],
       [Moneda],
       [TipoCambio],
       [PrecioUnitario],
       [PrecioUnitarioCRC],
       [Total],
       [TotalCRC],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[FacturaLinea];
GO
CREATE OR ALTER VIEW rag.[FacturaRecurrente] AS
SELECT [FacturaRecurrenteId],
       [ClienteId],
       [ServicioId],
       [Estado],
       [Frecuencia],
       [RepetirCada],
       [Moneda],
       [TipoCambio],
       [Total],
       [TotalCRC],
       [FechaInicio],
       [FechaFin],
       [FechaUltimoEnvio],
       [FechaProximaFactura],
       [MedioPago],
       [FechaCreacionOrigen],
       [FechaModificacionOrigen],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[FacturaRecurrente];
GO
CREATE OR ALTER VIEW rag.[Pago] AS
SELECT [PagoId],
       [ClienteId],
       [ServicioId],
       [Numero],
       [Fecha],
       [MedioPago],
       [CuentaBancariaId],
       [Moneda],
       [TipoCambio],
       [Monto],
       [MontoCRC],
       [MontoNoAplicado],
       [MontoNoAplicadoCRC],
       [MontoReembolsado],
       [MontoReembolsadoCRC],
       [ImpuestoRetenido],
       [ImpuestoRetenidoCRC],
       [Sucursal],
       [FechaCreacionOrigen],
       [FechaModificacionOrigen],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[Pago];
GO
CREATE OR ALTER VIEW rag.[PagoFactura] AS
SELECT [PagoFacturaId],
       [PagoId],
       [FacturaId],
       [NumeroFactura],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[PagoFactura];
GO
CREATE OR ALTER VIEW rag.[CuentaBancaria] AS
SELECT [CuentaBancariaId],
       [Nombre],
       [Codigo],
       [Banco],
       [Tipo],
       [Activa],
       [Moneda],
       [TipoCambio],
       [Saldo],
       [SaldoCRC],
       [SaldoBanco],
       [SaldoBancoCRC],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[CuentaBancaria];
GO
CREATE OR ALTER VIEW rag.[MovimientoBancario] AS
SELECT [MovimientoBancarioId],
       [CuentaBancariaId],
       [ClienteId],
       [Fecha],
       [Tipo],
       [DebitoCredito],
       [Estado],
       [Origen],
       [EstadoConciliacion],
       [Moneda],
       [TipoCambio],
       [Monto],
       [MontoCRC],
       [Sucursal],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[MovimientoBancario];
GO
CREATE OR ALTER VIEW rag.[Gasto] AS
SELECT [GastoId],
       [ProveedorId],
       [ClienteId],
       [Fecha],
       [Cuenta],
       [PagadoDesde],
       [Estado],
       [Referencia],
       [Moneda],
       [TipoCambio],
       [Total],
       [TotalCRC],
       [TotalSinImpuesto],
       [TotalSinImpuestoCRC],
       [Sucursal],
       [FechaCreacionOrigen],
       [FechaModificacionOrigen],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[Gasto];
GO
CREATE OR ALTER VIEW rag.[OrdenCompra] AS
SELECT [OrdenCompraId],
       [ProveedorId],
       [Numero],
       [Referencia],
       [Estado],
       [EstadoFacturacion],
       [EstadoRecepcion],
       [Fecha],
       [FechaEntrega],
       [Moneda],
       [TipoCambio],
       [Total],
       [TotalCRC],
       [Sucursal],
       [FechaCreacionOrigen],
       [FechaModificacionOrigen],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[OrdenCompra];
GO
CREATE OR ALTER VIEW rag.[HistorialEstadoCliente] AS
SELECT [HistorialEstadoClienteId],
       [ClienteId],
       [Estado],
       [Segmento],
       [FechaCambio],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[HistorialEstadoCliente];
GO
CREATE OR ALTER VIEW rag.[Troncal] AS
SELECT [TroncalId],
       [ServicioId],
       [CodigoTroncal],
       [Tipo],
       [Estado],
       [CodigoEstadoPredeterminado],
       [EstadoSIP],
       [SinRestriccion],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[Troncal];
GO
CREATE OR ALTER VIEW rag.[TroncalPermisoCodigo] AS
SELECT [TroncalPermisoCodigoId],
       [TroncalId],
       [CodigoMarcacion],
       [Minutos],
       [SinRestriccion],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[TroncalPermisoCodigo];
GO
CREATE OR ALTER VIEW rag.[AlertaTroncal] AS
SELECT [AlertaTroncalId],
       [TroncalId],
       [Operacion],
       [FechaBloqueo],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[AlertaTroncal];
GO
CREATE OR ALTER VIEW rag.[LineaGratuita] AS
SELECT [LineaGratuitaId],
       [ServicioId],
       [Estado],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[LineaGratuita];
GO
CREATE OR ALTER VIEW rag.[ServicioPaqueteMinutos] AS
SELECT [ServicioPaqueteMinutosId],
       [ServicioId],
       [PaqueteMinutosId],
       [Minutos],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[ServicioPaqueteMinutos];
GO
CREATE OR ALTER VIEW rag.[MinutosContratadosHistorico] AS
SELECT [MinutosContratadosHistoricoId],
       [ClienteId],
       [ServicioId],
       [Descripcion],
       [Minutos],
       [MinutosFijo],
       [MinutosCelular],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[MinutosContratadosHistorico];
GO
CREATE OR ALTER VIEW rag.[Llamada] AS
SELECT [LlamadaId],
       [ServicioId],
       [TroncalEntradaId],
       [TroncalSalidaId],
       [Circuito],
       [TipoCDR],
       [RazonCDR],
       [FechaInicio],
       [FechaRespuesta],
       [FechaFin],
       [Destino],
       [CodigoDestino],
       [DuracionSegundos],
       [DuracionSegundosRedondeada],
       [DuracionMinutos],
       [RedondeoDestino],
       [IncrementoCliente],
       [PorcentajeCliente],
       [Moneda],
       [TipoCambio],
       [TarifaDestino],
       [TarifaDestinoCRC],
       [TarifaSinMargen],
       [TarifaSinMargenCRC],
       [Costo],
       [CostoCRC],
       [CostoSinMargen],
       [CostoSinMargenCRC],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[Llamada];
GO
CREATE OR ALTER VIEW rag.[CorteVoIP] AS
SELECT [CorteVoIPId],
       [ServicioId],
       [ClienteId],
       [FechaInicio],
       [FechaFin],
       [MinutosMovilDisponibles],
       [MinutosFijoDisponibles],
       [MinutosMovilAplicados],
       [MinutosFijoAplicados],
       [Estado],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[CorteVoIP];
GO
CREATE OR ALTER VIEW rag.[ConsumoVoIP] AS
SELECT [ConsumoVoIPId],
       [CorteVoIPId],
       [ServicioId],
       [ClienteId],
       [TipoServicioVoIP],
       [FechaInicio],
       [FechaFin],
       [Llamadas],
       [Minutos],
       [Moneda],
       [TipoCambio],
       [Costo],
       [CostoCRC],
       [Procesado],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[ConsumoVoIP];
GO
CREATE OR ALTER VIEW rag.[FacturaElectronicaProveedor] AS
SELECT [FacturaElectronicaProveedorId],
       [Numero],
       [EmisorNombre],
       [FechaEmision],
       [Procesada],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[FacturaElectronicaProveedor];
GO
CREATE OR ALTER VIEW rag.[SolicitudEnLinea] AS
SELECT [SolicitudEnLineaId],
       [ClienteId],
       [ProductoId],
       [Referencia],
       [Estado],
       [TipoCliente],
       [CodigoFTTH],
       [Provincia],
       [Canton],
       [Distrito],
       [IPTVAdicionales],
       [CantidadFirestick],
       [Telefonia],
       [IPPublica],
       [TienePromocion],
       [TipoPromocion],
       [CodigoPromocion],
       [FechaPromocion],
       [TipoPago],
       [Moneda],
       [TipoCambio],
       [Total],
       [TotalCRC],
       [Referido],
       [DatosInvalidos],
       [EnviadoCRM],
       [FechaSolicitud],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[SolicitudEnLinea];
GO
CREATE OR ALTER VIEW rag.[ReservaInstalacion] AS
SELECT [ReservaInstalacionId],
       [SolicitudEnLineaId],
       [FechaReservada],
       [Franja],
       [Estado],
       [FechaRegistro],
       [FechaExpiracion],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[ReservaInstalacion];
GO
CREATE OR ALTER VIEW rag.[OrdenEnLinea] AS
SELECT [OrdenEnLineaId],
       [SolicitudEnLineaId],
       [Tipo],
       [Estado],
       [Bloqueado],
       [Moneda],
       [TipoCambio],
       [Total],
       [TotalCRC],
       [TotalSinImpuesto],
       [TotalSinImpuestoCRC],
       [Fecha],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[OrdenEnLinea];
GO
CREATE OR ALTER VIEW rag.[OrdenEnLineaLinea] AS
SELECT [OrdenEnLineaLineaId],
       [OrdenEnLineaId],
       [ProductoId],
       [Nombre],
       [Descripcion],
       [Cantidad],
       [Moneda],
       [TipoCambio],
       [PrecioUnitario],
       [PrecioUnitarioCRC],
       [PrecioUnitarioSinImpuesto],
       [PrecioUnitarioSinImpuestoCRC],
       [Total],
       [TotalCRC],
       [TotalSinImpuesto],
       [TotalSinImpuestoCRC],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[OrdenEnLineaLinea];
GO
CREATE OR ALTER VIEW rag.[ViajeFlota] AS
SELECT [ViajeFlotaId],
       [UnidadFlotaId],
       [FechaInicio],
       [FechaFin],
       [Kilometros],
       [DuracionMinutos],
       [Estado],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[ViajeFlota];
GO
CREATE OR ALTER VIEW rag.[EventoFlota] AS
SELECT [EventoFlotaId],
       [UnidadFlotaId],
       [FechaHora],
       [Evento],
       [Regla],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[EventoFlota];
GO
CREATE OR ALTER VIEW rag.[IncidenteConduccion] AS
SELECT [IncidenteConduccionId],
       [UnidadFlotaId],
       [TipoEventoCodigo],
       [TipoIncidente],
       [FechaHora],
       [DuracionSegundos],
       [VelocidadMaxima],
       [VecesExcesoVelocidad],
       [Penalidad],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[IncidenteConduccion];
GO
CREATE OR ALTER VIEW rag.[EventoConexion] AS
SELECT [EventoConexionId],
       [ClienteId],
       [Tipo],
       [Fecha],
       [TipoDesconexionReconexion],
       [FechaDesconexionReconexion],
       [FuenteSistema],
       [FechaDato],
       [PeriodoDato]
FROM core.[EventoConexion];
GO
IF DATABASE_PRINCIPAL_ID(N'rag_lector') IS NULL CREATE ROLE rag_lector;
GO
GRANT SELECT ON SCHEMA::rag TO rag_lector;
GO
/* Verificación: vistas creadas y columnas expuestas */
SELECT COUNT(DISTINCT v.object_id) AS Vistas, COUNT(*) AS Columnas
FROM sys.views v JOIN sys.columns c ON c.object_id = v.object_id WHERE SCHEMA_NAME(v.schema_id) = N'rag';
GO
