CREATE TABLE [hrs].[tblDeclarationRow_OSR2019] (
    [DeclarationNumber]  VARCHAR (6)     NOT NULL,
    [EmployeeNumber]     VARCHAR (8)     NOT NULL,
    [EmployeeName]       VARCHAR (255)   NULL,
    [RAR_Code]           VARCHAR (10)    NULL,
    [RejectionReason]    VARCHAR (100)   NULL,
    [VoucherNumber]      VARCHAR (3)     NULL,
    [ProjectDescription] VARCHAR (100)   NULL,
    [ValidFromDate]      DATE            NULL,
    [DeclarationAmount]  DECIMAL (19, 2) NULL,
    [OTIBDS_ReasonCode]  VARCHAR (4)     NULL,
    CONSTRAINT [PK_hrs_tblDeclarationRow_OSR2019] PRIMARY KEY CLUSTERED ([DeclarationNumber] ASC, [EmployeeNumber] ASC)
);

