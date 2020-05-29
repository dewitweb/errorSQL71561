CREATE TABLE [auth].[tblUserLoginStatus_History] (
    [RecordID]        INT           IDENTITY (1, 1) NOT NULL,
    [UserID]          INT           NOT NULL,
    [LastLogin]       DATETIME      NULL,
    [LastLogout]      DATETIME      NULL,
    [UserAgentString] VARCHAR (255) NULL,
    CONSTRAINT [PK_auth_tblUserInlogStatus_History] PRIMARY KEY CLUSTERED ([RecordID] ASC),
    CONSTRAINT [FK_auth_tblUserLoginStatus_History_tblUser] FOREIGN KEY ([UserID]) REFERENCES [auth].[tblUser] ([UserID])
);


GO
CREATE NONCLUSTERED INDEX [IX_auth_tblUserLoginStatus_History_UserID]
    ON [auth].[tblUserLoginStatus_History]([UserID] ASC)
    INCLUDE([LastLogin], [LastLogout]);

