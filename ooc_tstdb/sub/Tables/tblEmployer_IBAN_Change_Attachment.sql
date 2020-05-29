CREATE TABLE [sub].[tblEmployer_IBAN_Change_Attachment] (
    [IBANChangeID]     INT              NOT NULL,
    [AttachmentID]     UNIQUEIDENTIFIER NOT NULL,
    [UploadDateTime]   SMALLDATETIME    NULL,
    [OriginalFileName] VARCHAR (MAX)    NULL,
    CONSTRAINT [PK_sub_tblEmployer_IBAN_Change_Attachment] PRIMARY KEY CLUSTERED ([IBANChangeID] ASC, [AttachmentID] ASC),
    CONSTRAINT [FK_sub_tblEmployer_IBAN_Change_Attachment_tblEmployer_IBAN_Change] FOREIGN KEY ([IBANChangeID]) REFERENCES [sub].[tblEmployer_IBAN_Change] ([IBANChangeID])
);

