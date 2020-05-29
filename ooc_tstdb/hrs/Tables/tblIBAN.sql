CREATE TABLE [hrs].[tblIBAN] (
    [EmployerNumber] VARCHAR (6)  NOT NULL,
    [IBAN]           VARCHAR (34) NULL,
    CONSTRAINT [PK_hrs_tblIBAN] PRIMARY KEY CLUSTERED ([EmployerNumber] ASC)
);

