CREATE TABLE [his].[tblHistory] (
    [HistoryID] INT          IDENTITY (1, 1) NOT NULL,
    [TableName] VARCHAR (50) NOT NULL,
    [KeyID]     VARCHAR (50) NOT NULL,
    [UserID]    INT          NULL,
    [LogDate]   DATETIME     CONSTRAINT [DF_sub_tblHistory_LogDate] DEFAULT (getdate()) NOT NULL,
    [OldValue]  XML          NULL,
    [NewValue]  XML          NULL,
    CONSTRAINT [PK_tblHistory] PRIMARY KEY NONCLUSTERED ([HistoryID] ASC)
);


GO
CREATE CLUSTERED INDEX [CI_tblHistory_TableName_KeyID]
    ON [his].[tblHistory]([TableName] ASC, [KeyID] ASC);

