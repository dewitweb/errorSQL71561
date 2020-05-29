CREATE TYPE [sub].[uttInstitute] AS TABLE (
    [InstituteID]   INT           NOT NULL,
    [InstituteName] VARCHAR (255) NULL,
    [Location]      VARCHAR (24)  NULL,
    [EndDate]       DATE          NULL,
    [HorusID]       VARCHAR (6)   NULL,
    [IsEVC]         BIT           DEFAULT ((0)) NOT NULL,
    [IsEVCWV]       BIT           DEFAULT ((0)) NOT NULL);

