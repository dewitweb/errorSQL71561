CREATE TABLE [hrs].[tblPaymentExact] (
    [EdeID]            INT             NULL,
    [BatchID]          INT             NULL,
    [RowID]            INT             NULL,
    [PaymentDate]      VARCHAR (10)    NULL,
    [CompensationType] VARCHAR (3)     NULL,
    [JournalType]      VARCHAR (1)     NULL,
    [JournalID]        INT             NULL,
    [CreditorNumber]   VARCHAR (20)    NULL,
    [IBAN]             VARCHAR (34)    NULL,
    [LedgerNumber]     VARCHAR (9)     NULL,
    [EntryNumber]      VARCHAR (10)    NULL,
    [Currency]         VARCHAR (3)     NULL,
    [Amount]           DECIMAL (19, 4) NULL,
    [DeclarationID]    INT             NULL,
    [CostCenter]       VARCHAR (8)     NULL
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Type vergoeding', @level0type = N'SCHEMA', @level0name = N'hrs', @level1type = N'TABLE', @level1name = N'tblPaymentExact', @level2type = N'COLUMN', @level2name = N'CompensationType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Dagboeknummer', @level0type = N'SCHEMA', @level0name = N'hrs', @level1type = N'TABLE', @level1name = N'tblPaymentExact', @level2type = N'COLUMN', @level2name = N'JournalID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Grootboekrekeningnummer', @level0type = N'SCHEMA', @level0name = N'hrs', @level1type = N'TABLE', @level1name = N'tblPaymentExact', @level2type = N'COLUMN', @level2name = N'LedgerNumber';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Boekstuknummer', @level0type = N'SCHEMA', @level0name = N'hrs', @level1type = N'TABLE', @level1name = N'tblPaymentExact', @level2type = N'COLUMN', @level2name = N'EntryNumber';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Kostenplaats', @level0type = N'SCHEMA', @level0name = N'hrs', @level1type = N'TABLE', @level1name = N'tblPaymentExact', @level2type = N'COLUMN', @level2name = N'CostCenter';

