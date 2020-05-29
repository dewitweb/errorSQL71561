CREATE TYPE [sub].[uttEducation] AS TABLE (
    [EducationID]     INT           NOT NULL,
    [EducationName]   VARCHAR (200) NULL,
    [EducationType]   VARCHAR (24)  NOT NULL,
    [EducationLevel]  VARCHAR (24)  NULL,
    [StartDate]       DATE          NULL,
    [LatestStartDate] DATE          NULL,
    [EndDate]         DATE          NULL,
    [Duration]        INT           NULL,
    [SearchName]      VARCHAR (255) NULL,
    [IsEligible]      BIT           NOT NULL,
    [NominalDuration] INT           NULL);

