CREATE TABLE [sub].[tblEmployer_ParentChild_Request_Attachment] (
    [RequestID]        INT              NOT NULL,
    [AttachmentID]     UNIQUEIDENTIFIER NOT NULL,
    [UploadDateTime]   SMALLDATETIME    NULL,
    [OriginalFileName] VARCHAR (MAX)    NULL,
    CONSTRAINT [PK_sub_tblEmployer_ParentChild_Request_Attachment] PRIMARY KEY CLUSTERED ([RequestID] ASC, [AttachmentID] ASC),
    CONSTRAINT [FK_sub_tblEmployer_ParentChild_Request_Attachment_tblEmployer_ParentChild_Request] FOREIGN KEY ([RequestID]) REFERENCES [sub].[tblEmployer_ParentChild_Request] ([RequestID])
);

