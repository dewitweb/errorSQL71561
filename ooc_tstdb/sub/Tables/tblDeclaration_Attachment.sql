CREATE TABLE [sub].[tblDeclaration_Attachment] (
    [DeclarationID]    INT              NOT NULL,
    [AttachmentID]     UNIQUEIDENTIFIER CONSTRAINT [DF_sub_tblDeclaration_Attachment_AttachmentID] DEFAULT (newid()) NOT NULL,
    [UploadDateTime]   SMALLDATETIME    CONSTRAINT [DF_sub_tblDeclaration_Attachment_UploadDateTime] DEFAULT (getdate()) NULL,
    [OriginalFileName] VARCHAR (MAX)    NULL,
    [DocumentType]     VARCHAR (20)     NULL,
    [ExtensionID]      INT              NULL,
    CONSTRAINT [PK_sub_tblDeclaration_Attachment] PRIMARY KEY CLUSTERED ([DeclarationID] ASC, [AttachmentID] ASC),
    CONSTRAINT [FK_sub_tblDeclaration_Attachment_tblDeclaration] FOREIGN KEY ([DeclarationID]) REFERENCES [sub].[tblDeclaration] ([DeclarationID]),
    CONSTRAINT [FK_sub_tblDeclaration_Attachment_tblDeclaration_Extension] FOREIGN KEY ([ExtensionID]) REFERENCES [sub].[tblDeclaration_Extension] ([ExtensionID])
);

