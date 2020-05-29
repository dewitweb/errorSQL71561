CREATE TABLE [sub].[tblDeclarationEmail_Attachment] (
    [EmailID]          INT              NOT NULL,
    [AttachmentID]     UNIQUEIDENTIFIER NOT NULL,
    [OriginalFileName] VARCHAR (MAX)    NULL,
    CONSTRAINT [PK_sub_tblEmployerEmail_Attachment] PRIMARY KEY CLUSTERED ([EmailID] ASC, [AttachmentID] ASC),
    CONSTRAINT [FK_sub_tblDeclarationEmail_Attachment_tblDeclaration_Email] FOREIGN KEY ([EmailID]) REFERENCES [sub].[tblDeclaration_Email] ([EmailID])
);

