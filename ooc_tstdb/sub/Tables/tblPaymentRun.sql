CREATE TABLE [sub].[tblPaymentRun] (
    [PaymentRunID]    INT      IDENTITY (1, 1) NOT NULL,
    [RunDate]         DATETIME CONSTRAINT [DF_sub_tblPaymentRun_RunDate] DEFAULT (getdate()) NOT NULL,
    [EndDate]         DATETIME NOT NULL,
    [ExportDate]      DATETIME NULL,
    [UserID]          INT      NOT NULL,
    [SubsidySchemeID] INT      NOT NULL,
    [Completed]       DATETIME NULL,
    CONSTRAINT [PK_sub_tblPaymentRun] PRIMARY KEY CLUSTERED ([PaymentRunID] ASC),
    CONSTRAINT [FK_sub_tblPaymentRun_tblSubsidyScheme] FOREIGN KEY ([SubsidySchemeID]) REFERENCES [sub].[tblSubsidyScheme] ([SubsidySchemeID])
);

