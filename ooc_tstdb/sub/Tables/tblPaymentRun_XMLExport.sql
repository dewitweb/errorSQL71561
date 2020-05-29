CREATE TABLE [sub].[tblPaymentRun_XMLExport] (
    [PaymentRunID]          INT             NOT NULL,
    [XMLCreditors]          XML             NULL,
    [XMLPayments]           XML             NULL,
    [NrOfCreditors]         INT             NULL,
    [NrOfDebits]            INT             NULL,
    [NrOfCredits]           INT             NULL,
    [TotalAmountCredit]     DECIMAL (19, 2) NULL,
    [TotalAmountDebit]      DECIMAL (19, 2) NULL,
    [FirstJournalEntryCode] VARCHAR (10)    NULL,
    [LastJournalEntryCode]  VARCHAR (10)    NULL,
    [CreationDate]          DATETIME        NULL,
    [ExportDate]            DATETIME        NULL,
    CONSTRAINT [PK_sub_tblPaymentRun_XMLExport] PRIMARY KEY CLUSTERED ([PaymentRunID] ASC),
    CONSTRAINT [FK_sub_tblPaymentRun_XMLExport_tblPaymentRun] FOREIGN KEY ([PaymentRunID]) REFERENCES [sub].[tblPaymentRun] ([PaymentRunID])
);

