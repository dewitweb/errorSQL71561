CREATE TABLE [sub].[tblPaymentArrear] (
    [EmployerNumber] VARCHAR (6) NOT NULL,
    [FeesPaidUntill] DATE        NULL,
    CONSTRAINT [PK_sub_tblPaymentArrear] PRIMARY KEY CLUSTERED ([EmployerNumber] ASC),
    CONSTRAINT [FK_sub_tblPaymentArrear_tblEmployer] FOREIGN KEY ([EmployerNumber]) REFERENCES [sub].[tblEmployer] ([EmployerNumber])
);

