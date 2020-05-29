CREATE TABLE [sub].[tblEmployee] (
    [EmployeeNumber] VARCHAR (8)   NOT NULL,
    [Initials]       VARCHAR (10)  NULL,
    [Amidst]         VARCHAR (20)  NULL,
    [Surname]        VARCHAR (100) NULL,
    [Gender]         VARCHAR (1)   NULL,
    [AmidstSpous]    VARCHAR (10)  NULL,
    [SurnameSpous]   VARCHAR (100) NULL,
    [Email]          VARCHAR (254) NULL,
    [IBAN]           VARCHAR (34)  NULL,
    [DateOfBirth]    DATE          NULL,
    [SearchName]     VARCHAR (255) NULL,
    [FullName]       AS            (rtrim(((([Surname]+', ')+[Initials])+' ')+[Amidst])) PERSISTED NOT NULL,
    CONSTRAINT [PK_sub_tblEmployee] PRIMARY KEY CLUSTERED ([EmployeeNumber] ASC)
);

