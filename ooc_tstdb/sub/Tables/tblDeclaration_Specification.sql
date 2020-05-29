CREATE TABLE [sub].[tblDeclaration_Specification] (
    [DeclarationID]         INT             NOT NULL,
    [SpecificationSequence] INT             NOT NULL,
    [SpecificationDate]     DATETIME        CONSTRAINT [DF_sub_tblDeclaration_Specification_Date] DEFAULT (getdate()) NOT NULL,
    [PaymentRunID]          INT             NOT NULL,
    [Specification]         XML             NULL,
    [SumPartitionAmount]    DECIMAL (19, 4) CONSTRAINT [DF_sub_tblDeclaration_Specification_SumPartition] DEFAULT ((0)) NOT NULL,
    [SumVoucherAmount]      DECIMAL (19, 4) CONSTRAINT [DF_sub_tblDeclaration_Specification_SumVoucher] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_sub_tblDeclaration_Specification] PRIMARY KEY CLUSTERED ([DeclarationID] ASC, [SpecificationSequence] ASC),
    CONSTRAINT [FK_sub_tblDeclaration_Specification_tblDeclaration] FOREIGN KEY ([DeclarationID]) REFERENCES [sub].[tblDeclaration] ([DeclarationID]),
    CONSTRAINT [FK_sub_tblDeclaration_Specification_tblPaymentRun] FOREIGN KEY ([PaymentRunID]) REFERENCES [sub].[tblPaymentRun] ([PaymentRunID])
);


GO
CREATE NONCLUSTERED INDEX [IX_sub_tblDeclaration_Specification_PaymentRunID]
    ON [sub].[tblDeclaration_Specification]([PaymentRunID] ASC) WITH (FILLFACTOR = 90);

