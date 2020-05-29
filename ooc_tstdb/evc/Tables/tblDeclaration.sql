CREATE TABLE [evc].[tblDeclaration] (
    [DeclarationID]      INT         NOT NULL,
    [QualificationLevel] VARCHAR (4) NULL,
    [MentorCode]         VARCHAR (4) NULL,
    CONSTRAINT [PK_evc_tblDeclaration] PRIMARY KEY CLUSTERED ([DeclarationID] ASC)
);

