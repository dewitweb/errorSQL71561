CREATE TABLE [stip].[tblEmail_Partition] (
    [EmailID]     INT         NOT NULL,
    [PartitionID] INT         NOT NULL,
    [ReplyDate]   DATETIME    NULL,
    [ReplyCode]   VARCHAR (4) NULL,
    [LetterType]  TINYINT     NULL,
    CONSTRAINT [PK_stip_tblDeclaration_Partition_Email] PRIMARY KEY CLUSTERED ([EmailID] ASC),
    CONSTRAINT [FK_stip_tblEmail_Partition_tblDeclaration_Partition] FOREIGN KEY ([PartitionID]) REFERENCES [sub].[tblDeclaration_Partition] ([PartitionID])
);

