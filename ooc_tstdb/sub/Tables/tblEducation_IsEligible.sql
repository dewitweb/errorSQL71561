CREATE TABLE [sub].[tblEducation_IsEligible] (
    [EducationID] INT  NOT NULL,
    [FromDate]    DATE NOT NULL,
    [UntilDate]   DATE NULL,
    CONSTRAINT [PK_sub_tblEducation_IsEligible] PRIMARY KEY CLUSTERED ([EducationID] ASC, [FromDate] ASC)
);

