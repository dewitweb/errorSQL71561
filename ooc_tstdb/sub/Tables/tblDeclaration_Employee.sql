CREATE TABLE [sub].[tblDeclaration_Employee] (
    [DeclarationID]  INT         NOT NULL,
    [EmployeeNumber] VARCHAR (8) NOT NULL,
    CONSTRAINT [PK_sub_tblDeclaration_Employee] PRIMARY KEY CLUSTERED ([DeclarationID] ASC, [EmployeeNumber] ASC),
    CONSTRAINT [FK_sub_tblDeclaration_Employee_tblDeclaration] FOREIGN KEY ([DeclarationID]) REFERENCES [sub].[tblDeclaration] ([DeclarationID]),
    CONSTRAINT [FK_sub_tblDeclaration_Employee_tblEmployee] FOREIGN KEY ([EmployeeNumber]) REFERENCES [sub].[tblEmployee] ([EmployeeNumber])
);


GO
CREATE NONCLUSTERED INDEX [IX_sub_tblDeclaration_Employee_EmployeeNumber]
    ON [sub].[tblDeclaration_Employee]([EmployeeNumber] ASC);

