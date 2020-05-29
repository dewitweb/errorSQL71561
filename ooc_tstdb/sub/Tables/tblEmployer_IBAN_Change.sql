CREATE TABLE [sub].[tblEmployer_IBAN_Change] (
    [IBANChangeID]           INT           IDENTITY (1, 1) NOT NULL,
    [EmployerNumber]         VARCHAR (6)   NOT NULL,
    [IBAN_Old]               VARCHAR (34)  NULL,
    [IBAN_New]               VARCHAR (34)  NOT NULL,
    [Ascription]             VARCHAR (100) NOT NULL,
    [ChangeStatus]           VARCHAR (4)   NOT NULL,
    [Creation_UserID]        INT           NOT NULL,
    [Creation_DateTime]      DATETIME      NOT NULL,
    [FirstCheck_UserID]      INT           NULL,
    [FirstCheck_DateTime]    DATETIME      NULL,
    [SecondCheck_UserID]     INT           NULL,
    [SecondCheck_DateTime]   DATETIME      NULL,
    [HorusUpdateStatus]      VARCHAR (4)   NULL,
    [InternalMemo]           VARCHAR (MAX) NULL,
    [RejectionReason]        VARCHAR (4)   NULL,
    [StartDate]              DATE          NOT NULL,
    [ChangeExecutedOn]       DATETIME      NULL,
    [ReturnToEmployerReason] VARCHAR (MAX) NULL,
    CONSTRAINT [PK_sub_tblEmployer_IBAN_Change] PRIMARY KEY CLUSTERED ([IBANChangeID] ASC),
    CONSTRAINT [FK_sub_tblEmployer_IBAN_Change_tblEmployer] FOREIGN KEY ([EmployerNumber]) REFERENCES [sub].[tblEmployer] ([EmployerNumber])
);

