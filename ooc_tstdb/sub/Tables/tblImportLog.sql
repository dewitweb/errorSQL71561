CREATE TABLE [sub].[tblImportLog] (
    [RecordID]  INT            IDENTITY (1, 1) NOT NULL,
    [Log]       VARCHAR (1024) NOT NULL,
    [TimeStamp] DATETIME       NOT NULL,
    [Duration]  INT            NOT NULL,
    CONSTRAINT [PK_sub_tblImportLog] PRIMARY KEY CLUSTERED ([RecordID] ASC)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'In seconds', @level0type = N'SCHEMA', @level0name = N'sub', @level1type = N'TABLE', @level1name = N'tblImportLog', @level2type = N'COLUMN', @level2name = N'Duration';

