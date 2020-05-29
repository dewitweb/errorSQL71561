CREATE TABLE [hrs].[tblContactPerson] (
    [EmployerNumber]      VARCHAR (6)   NOT NULL,
    [EmployerName]        VARCHAR (100) NOT NULL,
    [ContactInitials]     VARCHAR (10)  NOT NULL,
    [ContactAmidst]       VARCHAR (20)  NOT NULL,
    [ContactFirstname]    VARCHAR (100) NOT NULL,
    [ContactSurname]      VARCHAR (100) NOT NULL,
    [Gender]              VARCHAR (1)   NOT NULL,
    [IndicationLetter]    VARCHAR (1)   NOT NULL,
    [Phone]               VARCHAR (50)  NOT NULL,
    [MobilePhone]         VARCHAR (50)  NOT NULL,
    [Email]               VARCHAR (50)  NOT NULL,
    [SubsidySchemeName]   VARCHAR (3)   NOT NULL,
    [StartDate]           DATE          NOT NULL,
    [EndDate]             DATE          NULL,
    [FunctionDescription] VARCHAR (100) NOT NULL,
    [ContactType]         VARCHAR (10)  NOT NULL
);

