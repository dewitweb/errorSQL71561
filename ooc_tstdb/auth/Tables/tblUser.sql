CREATE TABLE [auth].[tblUser] (
    [UserID]                 INT           IDENTITY (1, 1) NOT NULL,
    [Initials]               VARCHAR (15)  NULL,
    [Firstname]              VARCHAR (50)  NULL,
    [Infix]                  VARCHAR (15)  NULL,
    [Surname]                VARCHAR (50)  NOT NULL,
    [Email]                  VARCHAR (50)  NULL,
    [Phone]                  VARCHAR (15)  NULL,
    [Loginname]              VARCHAR (50)  NULL,
    [PasswordHash]           NVARCHAR (62) NOT NULL,
    [PasswordChangeCode]     NVARCHAR (62) NULL,
    [PasswordMustChange]     BIT           CONSTRAINT [DF_tblUser_PasswordMustChange] DEFAULT ((0)) NOT NULL,
    [PasswordExpirationDate] DATE          NULL,
    [PasswordFailedAttempts] TINYINT       NULL,
    [IsLockedOut]            DATETIME      NULL,
    [Active]                 BIT           CONSTRAINT [DF_tblUser_Active] DEFAULT ((0)) NOT NULL,
    [Fullname]               AS            ((coalesce([Firstname],[Initials],'')+' ')+ltrim((coalesce([Infix],'')+' ')+[Surname])),
    [FunctionDescription]    VARCHAR (100) NULL,
    [Gender]                 VARCHAR (1)   NULL,
    CONSTRAINT [PK_auth_tblUser] PRIMARY KEY CLUSTERED ([UserID] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_auth_tblUser_LoginName]
    ON [auth].[tblUser]([Loginname] ASC);

