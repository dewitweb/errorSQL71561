CREATE TABLE [sub].[tblNewsItem_NewsItemPage] (
    [NewsItemID] INT NOT NULL,
    [PageID]     INT NOT NULL,
    CONSTRAINT [PK_sub_tblNewsItem_NewsItemPage] PRIMARY KEY CLUSTERED ([NewsItemID] ASC, [PageID] ASC),
    CONSTRAINT [FK_sub_tblNewsItem_NewsItemPage_tblApplicationPage] FOREIGN KEY ([PageID]) REFERENCES [sub].[tblApplicationPage] ([PageID]),
    CONSTRAINT [FK_sub_tblNewsItem_NewsItemPage_tblNewsItem] FOREIGN KEY ([NewsItemID]) REFERENCES [sub].[tblNewsItem] ([NewsItemID])
);

