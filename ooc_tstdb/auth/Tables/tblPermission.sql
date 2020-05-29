CREATE TABLE [auth].[tblPermission] (
    [PermissionID]             INT           IDENTITY (1, 1) NOT NULL,
    [PermissionCode]           VARCHAR (50)  NOT NULL,
    [PermissionDescription_EN] VARCHAR (100) NULL,
    [PermissionDescription_NL] VARCHAR (100) NULL,
    [ApplicationID]            INT           CONSTRAINT [DF_auth_tblPermission_ApplicationID] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_auth_tblPermission] PRIMARY KEY CLUSTERED ([PermissionID] ASC),
    CONSTRAINT [FK_auth_tblPermission_tblApplication] FOREIGN KEY ([ApplicationID]) REFERENCES [auth].[tblApplication] ([ApplicationID])
);

