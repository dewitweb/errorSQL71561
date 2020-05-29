CREATE TABLE [sub].[tblNewsItem_SubsidyScheme] (
    [NewsItemID]      INT NOT NULL,
    [SubsidySchemeID] INT NOT NULL,
    CONSTRAINT [PK_sub_tblNewsItem_SubsidyScheme] PRIMARY KEY CLUSTERED ([NewsItemID] ASC, [SubsidySchemeID] ASC),
    CONSTRAINT [FK_sub_tblNewsItem_SubsidyScheme_tblNewsItem] FOREIGN KEY ([NewsItemID]) REFERENCES [sub].[tblNewsItem] ([NewsItemID]),
    CONSTRAINT [FK_sub_tblNewsItem_SubsidyScheme_tblSubsidyScheme] FOREIGN KEY ([SubsidySchemeID]) REFERENCES [sub].[tblSubsidyScheme] ([SubsidySchemeID])
);

