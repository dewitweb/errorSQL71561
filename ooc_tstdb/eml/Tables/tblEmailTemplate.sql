CREATE TABLE [eml].[tblEmailTemplate] (
    [TemplateID]      INT            NOT NULL,
    [Template]        NVARCHAR (100) NOT NULL,
    [BodyHeader]      NVARCHAR (MAX) NULL,
    [BodyMessage]     NVARCHAR (MAX) NULL,
    [BodyFooter]      NVARCHAR (MAX) NULL,
    [TemplateSubject] NVARCHAR (250) NULL,
    [ProcedureName]   NVARCHAR (250) NULL,
    CONSTRAINT [PK_eml_tblEmailTemplate] PRIMARY KEY CLUSTERED ([TemplateID] ASC)
);

