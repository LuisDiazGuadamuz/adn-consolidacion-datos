/* =====================================================================
   Staging de MongoDB (app.data.cr) dentro de ADN_Unificado.
   Las colecciones de la copia mongo-lab se copian a tablas stg.* con los mismos nombres y tipos que la
   copia SQL Server de ADNApp, para que los pasos de carga traten igual ambas fuentes (D1).
   Las tablas stg no son parte del modelo: se recargan por período y no llevan bitácora.
   Idempotente. SOLO sandbox.
   ===================================================================== */
SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON;
USE ADN_Unificado;
GO
IF OBJECT_ID(N'stg.mongo_Telephony_cdr', N'U') IS NULL
CREATE TABLE stg.mongo_Telephony_cdr (
    _id varchar(24) NOT NULL CONSTRAINT PK_stg_mongo_Telephony_cdr PRIMARY KEY,
    id bigint NULL, CDRTypeCode int NULL, CDRTypeReason nvarchar(255) NULL,
    StartDateTime datetime2 NULL, AnswerTimeOfDate datetime2 NULL, DisconnectDateTime datetime2 NULL,
    IngressTrunk int NULL, EgressTrunk int NULL, DialedNumber nvarchar(255) NULL, usd_exchange float NULL,
    Destination nvarchar(255) NULL, DestinationCode nvarchar(255) NULL, DestinationRate float NULL,
    DestinationRateNoProfit float NULL, DestinationRound int NULL, DurationInSeconds float NULL,
    DurationInRoundedSeconds float NULL, DurationInMinutes float NULL, CallCost float NULL, CallCostNoProfit float NULL,
    CallingNumber nvarchar(255) NULL, BillingNumber nvarchar(255) NULL, VoipDevice nvarchar(255) NULL,
    CustomerName nvarchar(255) NULL, CustomerIncrement int NULL, CustomerPorcentage float NULL,
    CustomerCircuitNumber nvarchar(255) NULL, IngressTrunkAlias nvarchar(255) NULL, EgressTrunkAlias nvarchar(255) NULL,
    OriginationSourceIP nvarchar(255) NULL, OriginationDestinationIP nvarchar(255) NULL, Rpid_PAI nvarchar(255) NULL,
    RoutingDigits nvarchar(60) NULL,
    StgLoteId int NULL
);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_stg_cdr_Inicio' AND object_id = OBJECT_ID(N'stg.mongo_Telephony_cdr'))
    CREATE INDEX IX_stg_cdr_Inicio ON stg.mongo_Telephony_cdr (StartDateTime);
GO
IF OBJECT_ID(N'stg.mongo_Telephony_insertedcdrfiles', N'U') IS NULL
CREATE TABLE stg.mongo_Telephony_insertedcdrfiles (
    _id varchar(24) NOT NULL CONSTRAINT PK_stg_mongo_Telephony_insertedcdrfiles PRIMARY KEY,
    id bigint NULL, FileName nvarchar(255) NULL, VoipDevice nvarchar(255) NULL, InsertionDate date NULL,
    StgLoteId int NULL
);
GO
IF OBJECT_ID(N'stg.mongo_Telephony_usdexchange', N'U') IS NULL
CREATE TABLE stg.mongo_Telephony_usdexchange (
    _id varchar(24) NOT NULL CONSTRAINT PK_stg_mongo_Telephony_usdexchange PRIMARY KEY,
    id bigint NULL, Purchase float NULL, Sale float NULL, ExchangeDate date NULL,
    StgLoteId int NULL
);
GO
SELECT s.name + N'.' + t.name AS TablaStaging FROM sys.tables t JOIN sys.schemas s ON s.schema_id = t.schema_id WHERE s.name = N'stg';
GO
