CREATE TABLE [sub].[tblDeclaration_Extension] (
    [ExtensionID]   INT  IDENTITY (1, 1) NOT NULL,
    [DeclarationID] INT  NOT NULL,
    [StartDate]     DATE NOT NULL,
    [EndDate]       DATE NULL,
    [InstituteID]   INT  NULL,
    CONSTRAINT [PK_sub_tblDeclaration_Extension] PRIMARY KEY CLUSTERED ([ExtensionID] ASC),
    CONSTRAINT [FK_sub_tblDeclaration_Extension_tblDeclaration] FOREIGN KEY ([DeclarationID]) REFERENCES [sub].[tblDeclaration] ([DeclarationID])
);

