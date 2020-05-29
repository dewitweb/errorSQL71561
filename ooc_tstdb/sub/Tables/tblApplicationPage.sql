CREATE TABLE [sub].[tblApplicationPage] (
    [PageID]             INT           IDENTITY (1, 1) NOT NULL,
    [PageCode]           VARCHAR (50)  NOT NULL,
    [PageDescription_EN] VARCHAR (100) NULL,
    [PageDescription_NL] VARCHAR (100) NULL,
    [ApplicationID]      INT           CONSTRAINT [DF_sub_tblApplicationPage_ApplicationID] DEFAULT ((1)) NOT NULL,
    [IncludesNewsItems]  BIT           CONSTRAINT [DF_sub_tblApplicationPage_IncludesNewsItems] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_auth_tblPermission] PRIMARY KEY CLUSTERED ([PageID] ASC)
);

