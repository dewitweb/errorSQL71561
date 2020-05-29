CREATE TABLE [sub].[tblLedgerExtraRights] (
    [RightCode]      VARCHAR (6)     NOT NULL,
    [Description]    VARCHAR (40)    NULL,
    [YearsValid]     NUMERIC (4, 2)  NULL,
    [ValidityType]   VARCHAR (1)     DEFAULT ('F') NULL,
    [OSRType]        VARCHAR (3)     DEFAULT ('COL') NULL,
    [UsabilityType]  VARCHAR (1)     DEFAULT ('S') NULL,
    [Amount]         DECIMAL (19, 4) DEFAULT ((0.00)) NULL,
    [LedgerNumber]   VARCHAR (10)    NULL,
    [RightType]      VARCHAR (3)     DEFAULT ('WNR') NULL,
    [EmployerAmount] DECIMAL (19, 4) DEFAULT (NULL) NULL
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Fixed = toekenningsdatum + geldigheidsduur; Soft = Fixed + rest van het kalenderjaar', @level0type = N'SCHEMA', @level0name = N'sub', @level1type = N'TABLE', @level1name = N'tblLedgerExtraRights', @level2type = N'COLUMN', @level2name = N'ValidityType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Extra recht is individueel of voor de werkgever', @level0type = N'SCHEMA', @level0name = N'sub', @level1type = N'TABLE', @level1name = N'tblLedgerExtraRights', @level2type = N'COLUMN', @level2name = N'OSRType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Specifiek of algemeen inzetbaar', @level0type = N'SCHEMA', @level0name = N'sub', @level1type = N'TABLE', @level1name = N'tblLedgerExtraRights', @level2type = N'COLUMN', @level2name = N'UsabilityType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Betreft het een recht voor de werkgever of de werknemer', @level0type = N'SCHEMA', @level0name = N'sub', @level1type = N'TABLE', @level1name = N'tblLedgerExtraRights', @level2type = N'COLUMN', @level2name = N'RightType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Het bedrag wat door de werkgever besteed mag worden', @level0type = N'SCHEMA', @level0name = N'sub', @level1type = N'TABLE', @level1name = N'tblLedgerExtraRights', @level2type = N'COLUMN', @level2name = N'EmployerAmount';

