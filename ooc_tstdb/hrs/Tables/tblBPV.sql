CREATE TABLE [hrs].[tblBPV] (
    [EmployeeNumber]    VARCHAR (8)   NOT NULL,
    [EmployerNumber]    VARCHAR (6)   NOT NULL,
    [StartDate]         DATE          NOT NULL,
    [EndDate]           DATE          NULL,
    [CourseID]          INT           NOT NULL,
    [CourseName]        VARCHAR (200) NULL,
    [StatusCode]        TINYINT       NULL,
    [StatusDescription] VARCHAR (100) NULL,
    [DSR_ID]            INT           NULL,
    [TypeBPV]           VARCHAR (10)  NULL
);


GO
CREATE CLUSTERED INDEX [CI_hrs_tblBPV]
    ON [hrs].[tblBPV]([EmployeeNumber] ASC, [EmployerNumber] ASC, [StartDate] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_hrs_tblBPV_DSR_ID]
    ON [hrs].[tblBPV]([DSR_ID] ASC)
    INCLUDE([StatusCode]);

