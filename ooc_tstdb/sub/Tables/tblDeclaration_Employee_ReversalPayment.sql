CREATE TABLE [sub].[tblDeclaration_Employee_ReversalPayment] (
    [DeclarationID]     INT         NOT NULL,
    [EmployeeNumber]    VARCHAR (8) NOT NULL,
    [PartitionID]       INT         NOT NULL,
    [ReversalPaymentID] INT         NULL,
    CONSTRAINT [PK_sub_tblDeclaration_Employee_ReversalPayment] PRIMARY KEY CLUSTERED ([DeclarationID] ASC, [EmployeeNumber] ASC, [PartitionID] ASC),
    CONSTRAINT [FK_sub_tblDeclaration_Employee_ReversalPayment_tblDeclaration_Employee] FOREIGN KEY ([DeclarationID], [EmployeeNumber]) REFERENCES [sub].[tblDeclaration_Employee] ([DeclarationID], [EmployeeNumber]),
    CONSTRAINT [FK_sub_tblDeclaration_Employee_ReversalPayment_tblDeclaration_Parition] FOREIGN KEY ([PartitionID]) REFERENCES [sub].[tblDeclaration_Partition] ([PartitionID])
);

