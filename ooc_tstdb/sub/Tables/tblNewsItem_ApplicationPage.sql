CREATE TABLE [sub].[tblNewsItem_ApplicationPage] (
    [NewsItemID] INT NOT NULL,
    [PageID]     INT NOT NULL,
    CONSTRAINT [PK_sub_tblNewsItem_ApplicationPage] PRIMARY KEY CLUSTERED ([NewsItemID] ASC, [PageID] ASC),
    CONSTRAINT [FK_sub_tblNewsItem_ApplicationPage_tblApplicationPage] FOREIGN KEY ([PageID]) REFERENCES [sub].[tblApplicationPage] ([PageID]),
    CONSTRAINT [FK_sub_tblNewsItem_ApplicationPage_tblNewsItem] FOREIGN KEY ([NewsItemID]) REFERENCES [sub].[tblNewsItem] ([NewsItemID])
);

