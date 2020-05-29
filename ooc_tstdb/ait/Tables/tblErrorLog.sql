CREATE TABLE [ait].[tblErrorLog] (
    [RecordID]       INT           IDENTITY (1, 1) NOT NULL,
    [ErrorDate]      DATETIME      NOT NULL,
    [ErrorNumber]    INT           NULL,
    [ErrorSeverity]  INT           NULL,
    [ErrorState]     INT           NULL,
    [ErrorProcedure] VARCHAR (MAX) NULL,
    [ErrorLine]      INT           NULL,
    [ErrorMessage]   VARCHAR (MAX) NULL,
    [SendEmail]      BIT           NOT NULL,
    [EmailSent]      DATETIME      NULL,
    CONSTRAINT [PK_ait_tblErrorLog] PRIMARY KEY CLUSTERED ([RecordID] ASC)
);

