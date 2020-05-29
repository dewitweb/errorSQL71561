CREATE TABLE [auth].[tblRole_Permission] (
    [RoleID]       INT NOT NULL,
    [PermissionID] INT NOT NULL,
    CONSTRAINT [PK_auth_tblRole_Permission] PRIMARY KEY CLUSTERED ([RoleID] ASC, [PermissionID] ASC),
    CONSTRAINT [FK_auth_tblRole_Permission_tblPermission] FOREIGN KEY ([PermissionID]) REFERENCES [auth].[tblPermission] ([PermissionID]),
    CONSTRAINT [FK_auth_tblRole_Permission_tblRole] FOREIGN KEY ([RoleID]) REFERENCES [auth].[tblRole] ([RoleID])
);

