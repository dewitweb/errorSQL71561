CREATE TABLE [sub].[tblLedger] (
    [LedgerYear]        SMALLINT      NOT NULL,
    [SubsidySchemeName] VARCHAR (50)  NOT NULL,
    [LedgerNumber]      VARCHAR (10)  NOT NULL,
    [SubsidySchemeType] VARCHAR (50)  NOT NULL,
    [Description]       VARCHAR (100) NULL,
    CONSTRAINT [PK_sub_tblLedger] PRIMARY KEY CLUSTERED ([LedgerYear] ASC, [SubsidySchemeType] ASC)
);

