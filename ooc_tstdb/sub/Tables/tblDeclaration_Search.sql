CREATE TABLE [sub].[tblDeclaration_Search] (
    [DeclarationID] INT           NOT NULL,
    [SearchField]   VARCHAR (MAX) NULL,
    [DateChanged]   DATETIME      NULL,
    CONSTRAINT [PK_sub_tblDeclaration_Search] PRIMARY KEY CLUSTERED ([DeclarationID] ASC)
);

