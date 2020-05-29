CREATE TABLE [eml].[tblEmailAttachment] (
    [AttachmentID] INT            IDENTITY (1, 1) NOT NULL,
    [EmailID]      INT            NOT NULL,
    [Attachment]   VARCHAR (1024) NOT NULL,
    [DateAttached] DATETIME       DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_eml_tblEmailAttachment] PRIMARY KEY CLUSTERED ([AttachmentID] ASC),
    CONSTRAINT [FK_eml_tblEmailAttachment_tblEmail] FOREIGN KEY ([EmailID]) REFERENCES [eml].[tblEmail] ([EmailID])
);


GO
CREATE NONCLUSTERED INDEX [IX_eml_tblEmailAttachment_EmailID]
    ON [eml].[tblEmailAttachment]([EmailID] ASC) WITH (FILLFACTOR = 90);

