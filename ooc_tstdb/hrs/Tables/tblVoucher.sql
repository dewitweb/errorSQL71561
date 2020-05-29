CREATE TABLE [hrs].[tblVoucher] (
    [EmployeeNumber]     VARCHAR (8)     NOT NULL,
    [VoucherNumber]      VARCHAR (10)    NOT NULL,
    [ValidFromDate]      VARCHAR (10)    NOT NULL,
    [ValidUntilDate]     VARCHAR (10)    NOT NULL,
    [AmountTotal]        DECIMAL (19, 4) NOT NULL,
    [AmountUsed]         DECIMAL (19, 4) NOT NULL,
    [AmountReserved]     DECIMAL (19, 4) NOT NULL,
    [AmountBalance]      DECIMAL (19, 4) NOT NULL,
    [ProjectDescription] VARCHAR (100)   NOT NULL,
    [ERT_Code]           VARCHAR (3)     NOT NULL,
    [City]               VARCHAR (100)   NOT NULL,
    [Active]             VARCHAR (1)     NOT NULL,
    CONSTRAINT [PK_hrs_tblVoucher] PRIMARY KEY CLUSTERED ([EmployeeNumber] ASC, [VoucherNumber] ASC)
);

