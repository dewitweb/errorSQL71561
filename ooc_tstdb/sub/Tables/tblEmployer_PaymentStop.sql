CREATE TABLE [sub].[tblEmployer_PaymentStop] (
    [PaymentStopID]   INT           IDENTITY (1, 1) NOT NULL,
    [EmployerNumber]  VARCHAR (6)   NOT NULL,
    [StartDate]       DATE          NOT NULL,
    [StartReason]     VARCHAR (MAX) NULL,
    [EndDate]         DATE          NULL,
    [EndReason]       VARCHAR (MAX) NULL,
    [PaymentstopType] VARCHAR (4)   CONSTRAINT [DF_sub_tblEmployer_PaymentStop_PaymentstopType] DEFAULT ('0001') NOT NULL,
    CONSTRAINT [PK_sub_tblEmployer_PaymentStop] PRIMARY KEY CLUSTERED ([PaymentStopID] ASC),
    CONSTRAINT [FK_sub_tblEmployer_PaymentStop_tblEmployer] FOREIGN KEY ([EmployerNumber]) REFERENCES [sub].[tblEmployer] ([EmployerNumber])
);


GO
CREATE NONCLUSTERED INDEX [IX_sub_tblEmployer_PaymentStop_EmployerNumber]
    ON [sub].[tblEmployer_PaymentStop]([EmployerNumber] ASC) WITH (FILLFACTOR = 90);

