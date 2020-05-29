CREATE TABLE [hrs].[tblWGR] (
    [EmployerNumber]          VARCHAR (6)   NOT NULL,
    [IBAN]                    VARCHAR (34)  NULL,
    [SignedAgreementRecieved] VARCHAR (1)   NULL,
    [Email]                   VARCHAR (254) NULL,
    [Email_ContactPerson]     VARCHAR (254) NULL,
    [Name_ContactPerson]      VARCHAR (100) NULL,
    [Gender_ContactPerson]    VARCHAR (1)   NULL,
    CONSTRAINT [PK_hrs_tblWGR] PRIMARY KEY CLUSTERED ([EmployerNumber] ASC)
);

