CREATE TABLE [sub].[tblEmployer_Employee] (
    [EmployerNumber] VARCHAR (6) NOT NULL,
    [EmployeeNumber] VARCHAR (8) NOT NULL,
    [StartDate]      DATE        NOT NULL,
    [EndDate]        DATE        NULL,
    CONSTRAINT [PK_sub_tblEmployer_Employee] PRIMARY KEY CLUSTERED ([EmployerNumber] ASC, [EmployeeNumber] ASC, [StartDate] ASC),
    CONSTRAINT [FK_sub_tblEmployer_Employee_tblEmployee] FOREIGN KEY ([EmployeeNumber]) REFERENCES [sub].[tblEmployee] ([EmployeeNumber]),
    CONSTRAINT [FK_sub_tblEmployer_Employee_tblEmployer] FOREIGN KEY ([EmployerNumber]) REFERENCES [sub].[tblEmployer] ([EmployerNumber])
);

