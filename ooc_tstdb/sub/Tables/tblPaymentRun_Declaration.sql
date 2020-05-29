CREATE TABLE [sub].[tblPaymentRun_Declaration] (
    [PaymentRunID]      INT             NOT NULL,
    [DeclarationID]     INT             NOT NULL,
    [PartitionID]       INT             NOT NULL,
    [ReversalPaymentID] INT             CONSTRAINT [DF_sub_tblPaymentRun_Declaration] DEFAULT ((0)) NOT NULL,
    [IBAN]              VARCHAR (35)    NULL,
    [Ascription]        VARCHAR (100)   NULL,
    [JournalEntryCode]  INT             NULL,
    [PartitionAmount]   DECIMAL (19, 4) NULL,
    [VoucherAmount]     DECIMAL (19, 4) NULL,
    CONSTRAINT [PK_sub_tblPaymentRun_Declaration] PRIMARY KEY CLUSTERED ([PaymentRunID] ASC, [DeclarationID] ASC, [PartitionID] ASC),
    CONSTRAINT [FK_sub_tblPaymentRun_Declaration_tblDeclaration] FOREIGN KEY ([DeclarationID]) REFERENCES [sub].[tblDeclaration] ([DeclarationID]),
    CONSTRAINT [FK_sub_tblPaymentRun_Declaration_tblDeclaration_Partition] FOREIGN KEY ([PartitionID]) REFERENCES [sub].[tblDeclaration_Partition] ([PartitionID]),
    CONSTRAINT [FK_sub_tblPaymentRun_Declaration_tblPaymentRun] FOREIGN KEY ([PaymentRunID]) REFERENCES [sub].[tblPaymentRun] ([PaymentRunID])
);


GO
CREATE NONCLUSTERED INDEX [IX_sub_tblPaymentRun_Declaration_DeclarationID]
    ON [sub].[tblPaymentRun_Declaration]([DeclarationID] ASC, [PartitionID] ASC)
    INCLUDE([PartitionAmount], [VoucherAmount]);


GO
CREATE NONCLUSTERED INDEX [IX_sub_tblPaymentRun_Declaration_JournalEntryCode]
    ON [sub].[tblPaymentRun_Declaration]([JournalEntryCode] ASC);

