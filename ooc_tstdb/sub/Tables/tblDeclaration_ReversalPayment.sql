CREATE TABLE [sub].[tblDeclaration_ReversalPayment] (
    [ReversalPaymentID]       INT           IDENTITY (1, 1) NOT NULL,
    [DeclarationID]           INT           NOT NULL,
    [ReversalPaymentReason]   VARCHAR (MAX) NOT NULL,
    [ReversalPaymentDateTime] SMALLDATETIME CONSTRAINT [DF_sub_tblDeclaration_ReversalPayment_DateTime] DEFAULT (getdate()) NULL,
    [PaymentRunID]            INT           NULL,
    CONSTRAINT [PK_sub_tblDeclaration_ReversalPayment] PRIMARY KEY NONCLUSTERED ([ReversalPaymentID] ASC),
    CONSTRAINT [FK_sub_tblDeclaration_ReversalPayment_tblDeclaration] FOREIGN KEY ([DeclarationID]) REFERENCES [sub].[tblDeclaration] ([DeclarationID]),
    CONSTRAINT [FK_sub_tblDeclaration_ReversalPayment_tblPaymentRun] FOREIGN KEY ([PaymentRunID]) REFERENCES [sub].[tblPaymentRun] ([PaymentRunID])
);

