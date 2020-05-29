CREATE TABLE [ait].[tblExactData_XML] (
    [PaymentRunID] INT NOT NULL,
    [XMLData]      XML NULL,
    CONSTRAINT [PK_ait_tblExactData_XML] PRIMARY KEY CLUSTERED ([PaymentRunID] ASC)
);

