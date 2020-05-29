CREATE TABLE [ait].[tblLog] (
    [LogID]         INT           IDENTITY (1, 1) NOT NULL,
    [LogDateTime]   DATETIME      CONSTRAINT [DF_ait_tblLog_LogDateTime] DEFAULT (getdate()) NOT NULL,
    [LogMessage]    VARCHAR (255) NULL,
    [LogURL]        VARCHAR (255) NULL,
    [LogLevel]      INT           NULL,
    [PostBody]      VARCHAR (MAX) NULL,
    [Stacktrace]    VARCHAR (MAX) NULL,
    [CurrentUserID] INT           NULL,
    CONSTRAINT [PK_ait_tblLog] PRIMARY KEY NONCLUSTERED ([LogID] ASC)
);


GO
CREATE CLUSTERED INDEX [CI_ait_tblLog_LogDateTime]
    ON [ait].[tblLog]([LogDateTime] ASC);

