CREATE TABLE [sub].[tblDeclaration_Partition_ReversalPayment] (
    [ReversalPaymentID] INT NOT NULL,
    [PartitionID]       INT NOT NULL,
    CONSTRAINT [PK_sub_tblDeclaration_Partition_ReversalPayment] PRIMARY KEY NONCLUSTERED ([ReversalPaymentID] ASC, [PartitionID] ASC),
    CONSTRAINT [FK_sub_tblDeclaration_Partition_ReversalPayment_tblDeclaration_Partition] FOREIGN KEY ([PartitionID]) REFERENCES [sub].[tblDeclaration_Partition] ([PartitionID]),
    CONSTRAINT [FK_sub_tblDeclaration_ReversalPayment_tblDeclaration_Partition_ReversalPayment] FOREIGN KEY ([ReversalPaymentID]) REFERENCES [sub].[tblDeclaration_ReversalPayment] ([ReversalPaymentID])
);

