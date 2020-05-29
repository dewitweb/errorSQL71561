CREATE TABLE [sub].[tblInstitute] (
    [InstituteID]   INT           NOT NULL,
    [InstituteName] VARCHAR (255) NULL,
    [Location]      VARCHAR (24)  NULL,
    [EndDate]       DATE          NULL,
    [HorusID]       VARCHAR (6)   NULL,
    [SearchName]    VARCHAR (255) NULL,
    CONSTRAINT [PK_sub_tblInstitute] PRIMARY KEY CLUSTERED ([InstituteID] ASC)
);

