CREATE TABLE [sub].[tblEmployer_ParentChild] (
    [EmployerNumberParent] VARCHAR (6) NOT NULL,
    [EmployerNumberChild]  VARCHAR (6) NOT NULL,
    [StartDate]            DATE        NOT NULL,
    [EndDate]              DATE        NULL,
    [RecordID]             INT         IDENTITY (1, 1) NOT NULL,
    CONSTRAINT [PK_sub_tblEmployer_ParentChild] PRIMARY KEY CLUSTERED ([EmployerNumberParent] ASC, [EmployerNumberChild] ASC, [StartDate] ASC)
);

