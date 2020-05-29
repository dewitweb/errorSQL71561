CREATE TABLE [sub].[tblApplicationPage_Permission] (
    [PageID]       INT NOT NULL,
    [PermissionID] INT NOT NULL,
    CONSTRAINT [PK_sub_tblApplicationPage_Permission] PRIMARY KEY CLUSTERED ([PageID] ASC, [PermissionID] ASC),
    CONSTRAINT [FK_sub_tblApplicationPage_Permission_tblApplicationPage] FOREIGN KEY ([PageID]) REFERENCES [sub].[tblApplicationPage] ([PageID])
);

