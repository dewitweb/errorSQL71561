CREATE TABLE [auth].[tblUserLoginStatus] (
    [UserID]     INT      NOT NULL,
    [LastLogin]  DATETIME NULL,
    [LastLogout] DATETIME NULL,
    [LoggedIn]   BIT      CONSTRAINT [DF_auth_tblUserLoginStatus_LoggedIn] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_auth_tblUserInlogStatus] PRIMARY KEY CLUSTERED ([UserID] ASC),
    CONSTRAINT [FK_auth_tblUserLoginStatus_tblUser] FOREIGN KEY ([UserID]) REFERENCES [auth].[tblUser] ([UserID])
);

