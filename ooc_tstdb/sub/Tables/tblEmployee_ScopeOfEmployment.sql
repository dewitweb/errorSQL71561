CREATE TABLE [sub].[tblEmployee_ScopeOfEmployment] (
    [EmployeeNumber]    VARCHAR (8)     NOT NULL,
    [EmployerNumber]    VARCHAR (6)     NOT NULL,
    [StartDate]         DATE            NOT NULL,
    [EndDate]           DATE            NULL,
    [ScopeOfEmployment] DECIMAL (10, 2) NULL,
    CONSTRAINT [PK_sub_tblEmployee_ScopeOfEmployment] PRIMARY KEY CLUSTERED ([EmployeeNumber] ASC, [EmployerNumber] ASC, [StartDate] ASC)
);

