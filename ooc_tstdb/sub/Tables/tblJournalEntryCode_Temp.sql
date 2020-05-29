CREATE TABLE [sub].[tblJournalEntryCode_Temp] (
    [JournalEntryCode] INT           NOT NULL,
    [EmployerNumber]   VARCHAR (8)   NOT NULL,
    [PaymentRunID]     INT           NOT NULL,
    [IBAN]             VARCHAR (35)  NULL,
    [Ascription]       VARCHAR (100) NULL,
    [Specification]    XML           NULL,
    CONSTRAINT [PK_sub_tblJournalEntryCode_Temp] PRIMARY KEY CLUSTERED ([JournalEntryCode] ASC)
);

