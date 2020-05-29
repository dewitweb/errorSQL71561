CREATE TYPE [sub].[uttCourse] AS TABLE (
    [CourseID]             INT             NOT NULL,
    [InstituteID]          INT             NOT NULL,
    [CourseName]           VARCHAR (255)   NULL,
    [FollowedUpByCourseID] INT             NULL,
    [ClusterNumber]        VARCHAR (11)    NULL,
    [CourseCosts]          DECIMAL (19, 4) NULL,
    [IsEligible]           BIT             NULL);

