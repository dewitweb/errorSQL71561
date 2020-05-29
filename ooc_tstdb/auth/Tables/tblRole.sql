CREATE TABLE [auth].[tblRole] (
    [RoleID]                   INT           IDENTITY (1, 1) NOT NULL,
    [RoleName]                 VARCHAR (50)  NOT NULL,
    [RoleDescription]          VARCHAR (100) NULL,
    [Abbreviation]             VARCHAR (3)   NOT NULL,
    [ApplicationID]            INT           CONSTRAINT [DF_auth_tblRole_ApplicationID] DEFAULT ((-1)) NOT NULL,
    [IsSubsidySchemeDependent] BIT           DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_auth_tblRole] PRIMARY KEY CLUSTERED ([RoleID] ASC),
    CONSTRAINT [FK_auth_tblRole_tblApplication] FOREIGN KEY ([ApplicationID]) REFERENCES [auth].[tblApplication] ([ApplicationID])
);

