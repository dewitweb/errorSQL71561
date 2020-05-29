CREATE TABLE [sub].[tblEducation_NominalDuration_History] (
    [EducationID]         INT      NOT NULL,
    [NominalDuration_Old] INT      NULL,
    [NominalDuration_New] INT      NULL,
    [DateCreated]         DATETIME NULL,
    [DateProcessed]       DATETIME NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_sub_tblEducation_NominalDuration_History_EductionID]
    ON [sub].[tblEducation_NominalDuration_History]([EducationID] ASC);

