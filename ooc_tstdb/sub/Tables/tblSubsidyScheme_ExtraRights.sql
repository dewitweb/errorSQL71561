CREATE TABLE [sub].[tblSubsidyScheme_ExtraRights] (
    [RightCode]        VARCHAR (6)     NOT NULL,
    [RightDescription] VARCHAR (40)    NOT NULL,
    [NrOfYearsValid]   SMALLINT        NOT NULL,
    [TypeOfValidity]   VARCHAR (1)     DEFAULT ('F') NOT NULL,
    [TypeOSR]          VARCHAR (3)     DEFAULT ('COL') NOT NULL,
    [TypeOfUse]        VARCHAR (1)     DEFAULT ('S') NOT NULL,
    [Amount]           NUMERIC (19, 2) DEFAULT ((0.00)) NOT NULL,
    [Ledger]           VARCHAR (10)    NOT NULL,
    [TypeOfRight]      VARCHAR (3)     DEFAULT ('WNR') NOT NULL,
    [AmountWGR]        NUMERIC (19, 2) DEFAULT ((0.00)) NOT NULL,
    CONSTRAINT [PK_sub_tblSubsidyScheme_ExtraRights] PRIMARY KEY CLUSTERED ([RightCode] ASC)
);

