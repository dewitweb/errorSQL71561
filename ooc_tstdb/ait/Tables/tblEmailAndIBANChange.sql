CREATE TABLE [ait].[tblEmailAndIBANChange] (
    [IBANChangeID]      INT      NOT NULL,
    [UserEmailChangeID] INT      NOT NULL,
    [DetectionDate]     DATETIME CONSTRAINT [DF_ait_tblEmailAndIBANChange_DetectionDate] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_ait_tblEmailAndIBANChange] PRIMARY KEY CLUSTERED ([IBANChangeID] ASC, [DetectionDate] ASC)
);

