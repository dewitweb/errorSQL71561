CREATE TABLE [auth].[tblLoginFailed] (
    [RecordID]      INT           IDENTITY (1, 1) NOT NULL,
    [LoginName]     VARCHAR (50)  NOT NULL,
    [LoginDateTime] DATETIME      NOT NULL,
    [FailureReason] VARCHAR (4)   NOT NULL,
    [ExtraInfo]     VARCHAR (MAX) NULL,
    CONSTRAINT [PK_auth_tblLoginFailed] PRIMARY KEY CLUSTERED ([RecordID] ASC)
);

