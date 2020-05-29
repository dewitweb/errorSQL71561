CREATE TABLE [sub].[tblDeclaration_Email] (
    [EmailID]       INT           IDENTITY (1, 1) NOT NULL,
    [DeclarationID] INT           NOT NULL,
    [EmailDate]     DATETIME      CONSTRAINT [DF_sub_tblDeclaration_Email_EmailDate] DEFAULT (getdate()) NULL,
    [EmailSubject]  VARCHAR (50)  NULL,
    [EmailBody]     VARCHAR (MAX) NULL,
    [Direction]     VARCHAR (10)  NULL,
    [HandledDate]   DATETIME      NULL,
    CONSTRAINT [PK_sub_tblDeclaration_Email] PRIMARY KEY CLUSTERED ([EmailID] ASC),
    CONSTRAINT [FK_sub_tblDeclaration_Email_tblDeclaration] FOREIGN KEY ([DeclarationID]) REFERENCES [sub].[tblDeclaration] ([DeclarationID])
);

