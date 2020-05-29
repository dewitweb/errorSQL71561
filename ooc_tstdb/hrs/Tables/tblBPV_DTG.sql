CREATE TABLE [hrs].[tblBPV_DTG] (
    [DSR_ID]              INT             NOT NULL,
    [DTG_ID]              INT             NOT NULL,
    [ReferenceDate]       DATE            NOT NULL,
    [PaymentStatus]       VARCHAR (4)     NULL,
    [DTG_Status]          VARCHAR (100)   NULL,
    [PaymentType]         VARCHAR (3)     NOT NULL,
    [PaymentNumber]       TINYINT         NOT NULL,
    [PaymentAmount]       NUMERIC (18, 2) NULL,
    [PaymentDate]         DATETIME        NULL,
    [AmountPaid]          NUMERIC (18, 2) NULL,
    [PaymentDateReversal] DATETIME        NULL,
    [AmountReversed]      NUMERIC (10, 2) NULL,
    [LastPayment]         VARCHAR (1)     NULL,
    [ReasonNotPaidShort]  VARCHAR (10)    NULL,
    [ReasonNotPaidLong]   VARCHAR (100)   NULL,
    CONSTRAINT [PK_tblBPV_DTG] PRIMARY KEY NONCLUSTERED ([DSR_ID] ASC, [DTG_ID] ASC)
);

