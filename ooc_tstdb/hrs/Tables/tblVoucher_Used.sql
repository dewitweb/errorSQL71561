CREATE TABLE [hrs].[tblVoucher_Used] (
    [RecordID]        INT             IDENTITY (1, 1) NOT NULL,
    [EmployeeNumber]  VARCHAR (8)     NOT NULL,
    [EmployerNumber]  VARCHAR (6)     NOT NULL,
    [ERT_Code]        VARCHAR (3)     NOT NULL,
    [GrantDate]       DATE            NOT NULL,
    [DeclarationID]   INT             NOT NULL,
    [VoucherNumber]   VARCHAR (6)     NOT NULL,
    [AmountUsed]      DECIMAL (19, 4) NOT NULL,
    [VoucherStatus]   VARCHAR (4)     NOT NULL,
    [ResultFromHorus] VARCHAR (MAX)   NULL,
    [CreationDate]    DATETIME        CONSTRAINT [DF_hrs_tblVoucher_Used_CreationDate] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_hrs_tblVoucher_Used] PRIMARY KEY CLUSTERED ([RecordID] ASC)
);

