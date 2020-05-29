CREATE TABLE [sub].[tblSubsidyScheme] (
    [SubsidySchemeID]   INT          IDENTITY (1, 1) NOT NULL,
    [SubsidySchemeName] VARCHAR (50) NULL,
    [StartMonth]        SMALLINT     NULL,
    [Increment]         SMALLINT     NULL,
    [Interval]          VARCHAR (12) NULL,
    [SubmitIncrement]   SMALLINT     NULL,
    [SubmitInterval]    VARCHAR (12) NULL,
    [SortOrder]         TINYINT      NULL,
    [VisibleFromDate]   DATE         NULL,
    [ActiveFromDate]    DATE         NULL,
    [LinkedInstitutes]  BIT          CONSTRAINT [DF_sub_tblSubsidyScheme_LinkedInstitutes] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_sub_tblSubsidyScheme] PRIMARY KEY CLUSTERED ([SubsidySchemeID] ASC)
);

