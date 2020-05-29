CREATE TABLE [sub].[tblNewsItem] (
    [NewsItemID]          INT           IDENTITY (1, 1) NOT NULL,
    [NewsItemName]        VARCHAR (200) NOT NULL,
    [NewsItemType]        VARCHAR (4)   NOT NULL,
    [StartDate]           DATE          NOT NULL,
    [EndDate]             DATE          NULL,
    [Title]               VARCHAR (200) NULL,
    [NewsItemMessage]     VARCHAR (MAX) NULL,
    [CalendarDisplayDate] DATE          NULL,
    CONSTRAINT [PK_sub_tblNewsItem] PRIMARY KEY CLUSTERED ([NewsItemID] ASC)
);

