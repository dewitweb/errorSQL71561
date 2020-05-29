CREATE TABLE [sub].[tblCourse_IsEligible] (
    [CourseID]  INT  NOT NULL,
    [FromDate]  DATE NOT NULL,
    [UntilDate] DATE NULL,
    CONSTRAINT [PK_sub_tblCourse_IsEligible] PRIMARY KEY CLUSTERED ([CourseID] ASC, [FromDate] ASC)
);

