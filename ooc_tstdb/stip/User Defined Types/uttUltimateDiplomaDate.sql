CREATE TYPE [stip].[uttUltimateDiplomaDate] AS TABLE (
    [UltimateDiplomaDate] DATE        NULL,
    [RecordID]            INT         NULL,
    [SubsidySchemeID]     INT         NULL,
    [EmployerNumber]      VARCHAR (6) NULL,
    [StartDate]           DATE        NULL,
    [EndDate]             DATE        NULL,
    [DeclarationID]       INT         NULL,
    [ExtensionID]         INT         NULL,
    [PauseYears]          TINYINT     NULL,
    [PauseMonths]         TINYINT     NULL,
    [PauseDays]           TINYINT     NULL,
    [PauseYearsAll]       TINYINT     NULL,
    [PauseMonthsAll]      TINYINT     NULL,
    [PauseDaysAll]        TINYINT     NULL);

