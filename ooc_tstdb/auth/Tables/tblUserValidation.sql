CREATE TABLE [auth].[tblUserValidation] (
    [UserID]                  INT          NOT NULL,
    [ContactDetailsCheck]     BIT          CONSTRAINT [DF_tblUserValidation_ContactDetailsCheck] DEFAULT ((0)) NOT NULL,
    [AgreementCheck]          BIT          CONSTRAINT [DF_tblUserValidation_AgreementCheck] DEFAULT ((0)) NOT NULL,
    [EmailCheck]              BIT          CONSTRAINT [DF_tblUserValidation_EmailCheck] DEFAULT ((0)) NOT NULL,
    [EmailValidationToken]    VARCHAR (50) NULL,
    [EmailValidationDateTime] DATETIME     NULL,
    [HorusUpdated]            DATETIME     NULL,
    [HorusResult]             VARCHAR (4)  NULL,
    CONSTRAINT [PK_auth_tblUserValidation] PRIMARY KEY CLUSTERED ([UserID] ASC),
    CONSTRAINT [FK_auth_tblUserValidation_tblUser] FOREIGN KEY ([UserID]) REFERENCES [auth].[tblUser] ([UserID])
);

