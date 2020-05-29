CREATE TABLE [hrs].[tblEVC] (
    [EmployeeNumber]    VARCHAR (8)   NOT NULL,
    [IntakeDate]        DATE          NULL,
    [CertificationDate] DATE          NULL,
    [CheckDate]         DATE          NULL,
    [DeclarationNumber] VARCHAR (10)  NULL,
    [DeclarationStatus] VARCHAR (5)   NULL,
    [StatusDescription] VARCHAR (100) NULL
);


GO
CREATE CLUSTERED INDEX [CI_hrs_tblEVC]
    ON [hrs].[tblEVC]([EmployeeNumber] ASC);

