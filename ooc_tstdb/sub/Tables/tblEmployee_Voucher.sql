CREATE TABLE [sub].[tblEmployee_Voucher] (
    [EmployeeNumber] VARCHAR (8)     NOT NULL,
    [VoucherNumber]  VARCHAR (6)     NOT NULL,
    [GrantDate]      DATE            NOT NULL,
    [ValidityDate]   DATE            NULL,
    [VoucherValue]   DECIMAL (19, 4) NOT NULL,
    [AmountUsed]     DECIMAL (19, 4) DEFAULT ((0.00)) NOT NULL,
    [AmountBalance]  AS              ([VoucherValue]-[AmountUsed]),
    [ERT_Code]       VARCHAR (3)     NOT NULL,
    [EventName]      VARCHAR (100)   NULL,
    [EventCity]      VARCHAR (100)   NULL,
    [Active]         BIT             DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_sub_tblEmployee_Voucher] PRIMARY KEY CLUSTERED ([EmployeeNumber] ASC, [VoucherNumber] ASC),
    CONSTRAINT [FK_sub_tblEmployee_Voucher_tblEmployee] FOREIGN KEY ([EmployeeNumber]) REFERENCES [sub].[tblEmployee] ([EmployeeNumber])
);

