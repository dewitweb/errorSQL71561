CREATE TABLE [auth].[tblUser_Role] (
    [UserID] INT NOT NULL,
    [RoleID] INT NOT NULL,
    CONSTRAINT [PK_auth_tblUserRole] PRIMARY KEY CLUSTERED ([UserID] ASC, [RoleID] ASC),
    CONSTRAINT [FK_auth_tblUser_Role_tblRole] FOREIGN KEY ([RoleID]) REFERENCES [auth].[tblRole] ([RoleID]),
    CONSTRAINT [FK_auth_tblUser_Role_tblUser] FOREIGN KEY ([UserID]) REFERENCES [auth].[tblUser] ([UserID])
);

