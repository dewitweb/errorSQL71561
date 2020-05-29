CREATE TABLE [sub].[tblDeclaration_Rejection] (
    [DeclarationID]     INT           NOT NULL,
    [PartitionID]       INT           CONSTRAINT [DF_sub_tblDeclaration_Rejection_PartitionID] DEFAULT ((0)) NOT NULL,
    [RejectionReason]   VARCHAR (24)  NOT NULL,
    [RejectionDateTime] SMALLDATETIME CONSTRAINT [DF_sub_tblDeclaration_Rejection_ReJectionDateTime] DEFAULT (getdate()) NULL,
    [RejectionXML]      XML           NULL,
    CONSTRAINT [PK_sub_tblDeclaration_Rejection] PRIMARY KEY CLUSTERED ([DeclarationID] ASC, [PartitionID] ASC, [RejectionReason] ASC),
    CONSTRAINT [FK_sub_tblDeclaration_Rejection_tblDeclaration] FOREIGN KEY ([DeclarationID]) REFERENCES [sub].[tblDeclaration] ([DeclarationID])
);

