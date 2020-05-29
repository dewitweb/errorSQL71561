CREATE TABLE [auth].[tblUser_Role_SubsidyScheme] (
    [UserID]          INT NOT NULL,
    [RoleID]          INT NOT NULL,
    [SubsidySchemeID] INT NOT NULL,
    CONSTRAINT [PK_auth_tblUser_Role_SubsidyScheme] PRIMARY KEY CLUSTERED ([UserID] ASC, [RoleID] ASC, [SubsidySchemeID] ASC),
    CONSTRAINT [FK_auth_tblUser_Role_SubsidyScheme_tblSubsidyScheme] FOREIGN KEY ([SubsidySchemeID]) REFERENCES [sub].[tblSubsidyScheme] ([SubsidySchemeID])
);

