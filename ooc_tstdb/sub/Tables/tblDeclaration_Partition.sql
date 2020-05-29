CREATE TABLE [sub].[tblDeclaration_Partition] (
    [PartitionID]              INT             IDENTITY (1, 1) NOT NULL,
    [DeclarationID]            INT             NOT NULL,
    [PartitionYear]            VARCHAR (20)    NOT NULL,
    [PartitionAmount]          DECIMAL (19, 4) NULL,
    [PartitionAmountCorrected] DECIMAL (19, 4) NULL,
    [PaymentDate]              DATETIME        NULL,
    [PartitionStatus]          VARCHAR (4)     NOT NULL,
    CONSTRAINT [PK_sub_tblDeclaration_Partition] PRIMARY KEY CLUSTERED ([PartitionID] ASC),
    CONSTRAINT [FK_sub_tblDeclaration_Partition_tblDeclaration] FOREIGN KEY ([DeclarationID]) REFERENCES [sub].[tblDeclaration] ([DeclarationID])
);


GO
CREATE NONCLUSTERED INDEX [IX_sub_tblDeclaration_Partition]
    ON [sub].[tblDeclaration_Partition]([DeclarationID] ASC, [PartitionYear] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_sub_tblDeclaration_Partition_PartitionStatus]
    ON [sub].[tblDeclaration_Partition]([PartitionStatus] ASC)
    INCLUDE([DeclarationID], [PaymentDate]);

