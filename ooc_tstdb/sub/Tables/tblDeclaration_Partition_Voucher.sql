CREATE TABLE [sub].[tblDeclaration_Partition_Voucher] (
    [DeclarationID]    INT             NOT NULL,
    [PartitionID]      INT             NOT NULL,
    [EmployeeNumber]   VARCHAR (8)     NOT NULL,
    [VoucherNumber]    VARCHAR (6)     NOT NULL,
    [DeclarationValue] DECIMAL (19, 4) NULL,
    CONSTRAINT [PK_sub_tblDeclaration_Partition_Voucher] PRIMARY KEY CLUSTERED ([DeclarationID] ASC, [PartitionID] ASC, [EmployeeNumber] ASC, [VoucherNumber] ASC),
    CONSTRAINT [FK_sub_tblDeclaration_Partition_Voucher_tblDeclaration] FOREIGN KEY ([DeclarationID]) REFERENCES [sub].[tblDeclaration] ([DeclarationID]),
    CONSTRAINT [FK_sub_tblDeclaration_Partition_Voucher_tblDeclaration_Partition] FOREIGN KEY ([PartitionID]) REFERENCES [sub].[tblDeclaration_Partition] ([PartitionID]),
    CONSTRAINT [FK_sub_tblDeclaration_Partition_Voucher_tblEmployee] FOREIGN KEY ([EmployeeNumber]) REFERENCES [sub].[tblEmployee] ([EmployeeNumber])
);

