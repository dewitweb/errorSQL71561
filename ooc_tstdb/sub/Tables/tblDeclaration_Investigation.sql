CREATE TABLE [sub].[tblDeclaration_Investigation] (
    [DeclarationID]     INT           NOT NULL,
    [InvestigationDate] DATETIME      NOT NULL,
    [InvestigationMemo] VARCHAR (MAX) NOT NULL,
    CONSTRAINT [PK_sub_tblDeclaration_Investigation] PRIMARY KEY CLUSTERED ([DeclarationID] ASC, [InvestigationDate] ASC),
    CONSTRAINT [FK_sub_tblDeclaration_Investigation_tblDeclaration] FOREIGN KEY ([DeclarationID]) REFERENCES [sub].[tblDeclaration] ([DeclarationID])
);

