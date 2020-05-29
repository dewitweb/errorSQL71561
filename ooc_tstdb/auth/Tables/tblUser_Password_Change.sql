CREATE TABLE [auth].[tblUser_Password_Change] (
    [PasswordChangeID]   INT             IDENTITY (1, 1) NOT NULL,
    [EmployerNumber]     VARCHAR (6)     NOT NULL,
    [Email]              VARCHAR (50)    NOT NULL,
    [PasswordResetToken] VARCHAR (50)    NOT NULL,
    [Creation_DateTime]  DATETIME        CONSTRAINT [DF_tblUser_Password_Change_Creation_DateTime] DEFAULT (getdate()) NOT NULL,
    [ValidUntil]         DATETIME        NOT NULL,
    [UserID]             INT             NOT NULL,
    [Password_New]       VARBINARY (128) NULL,
    [SendToHorus]        DATETIME        NULL,
    [ResultFromHorus]    VARCHAR (MAX)   NULL,
    [ChangeSuccessful]   BIT             NULL,
    CONSTRAINT [PK_sub_tblUser_Password_Change] PRIMARY KEY CLUSTERED ([PasswordChangeID] ASC)
);

