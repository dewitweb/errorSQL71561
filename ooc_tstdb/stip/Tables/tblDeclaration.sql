CREATE TABLE [stip].[tblDeclaration] (
    [DeclarationID]          INT          NOT NULL,
    [EducationID]            INT          NULL,
    [DiplomaDate]            DATE         NULL,
    [DiplomaCheckedByUserID] INT          NULL,
    [DiplomaCheckedDate]     DATETIME     NULL,
    [TerminationDate]        DATETIME     NULL,
    [TerminationReason]      VARCHAR (20) NULL,
    CONSTRAINT [PK_stip_tblDeclaration] PRIMARY KEY CLUSTERED ([DeclarationID] ASC),
    CONSTRAINT [FK_stip_tblDeclaration_tblDeclaration] FOREIGN KEY ([DeclarationID]) REFERENCES [sub].[tblDeclaration] ([DeclarationID])
);

