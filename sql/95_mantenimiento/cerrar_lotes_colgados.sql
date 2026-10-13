/* Marca como Fallido los lotes que quedaron 'EnCurso' porque el contenedor se cayó a mitad de la corrida.
   SQL Server deshace la transacción abierta al cortarse la conexión, así que esos lotes no dejaron datos;
   solo falta cerrar su registro. Correr SOLO cuando no haya ninguna corrida del ETL en marcha. SOLO sandbox. */
SET NOCOUNT ON; SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON;
USE ADN_Unificado;
IF NOT EXISTS (SELECT 1 FROM ctl.Entorno WHERE Nombre = 'SANDBOX')
    THROW 50001, 'Este script solo se ejecuta en el sandbox.', 1;

DECLARE @l int;
DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT LoteId FROM ctl.Lote WHERE Estado = 'EnCurso';
OPEN c; FETCH NEXT FROM c INTO @l;
WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC ctl.usp_CerrarLote @LoteId = @l, @Estado = 'Fallido',
         @Mensaje = N'Interrumpido: el contenedor se cayó durante la corrida (la transacción se deshizo). Cerrado a mano.';
    PRINT CONCAT('Lote ', @l, ' marcado como Fallido');
    FETCH NEXT FROM c INTO @l;
END;
CLOSE c; DEALLOCATE c;
