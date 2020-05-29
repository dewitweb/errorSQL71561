CREATE TABLE [auth].[tblUser_Email_Change] (
    [UserEmailChangeID]    INT           IDENTITY (1, 1) NOT NULL,
    [UserID]               INT           NOT NULL,
    [Email_Old]            VARCHAR (50)  NULL,
    [Email_New]            VARCHAR (50)  NOT NULL,
    [Creation_UserID]      INT           NOT NULL,
    [Creation_DateTime]    DATETIME      CONSTRAINT [DF_tblUser_Email_Change_Creation_DateTime] DEFAULT (getdate()) NOT NULL,
    [EmailValidationToken] VARCHAR (50)  NOT NULL,
    [Validation_UserID]    INT           NULL,
    [Validation_DateTime]  DATETIME      NULL,
    [Validation_Result]    VARCHAR (11)  NULL,
    [Validation_Reason]    VARCHAR (MAX) NULL,
    [Horus_Result]         VARCHAR (4)   NULL,
    CONSTRAINT [PK_sub_tblUser_Email_Change] PRIMARY KEY CLUSTERED ([UserID] ASC)
);

