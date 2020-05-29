CREATE TABLE [sub].[tblEmployer_ParentChild_Request] (
    [RequestID]            INT           IDENTITY (1, 1) NOT NULL,
    [EmployerNumberParent] VARCHAR (6)   NOT NULL,
    [EmployerNameParent]   VARCHAR (100) NULL,
    [EmployerNumberChild]  VARCHAR (6)   NOT NULL,
    [StartDate]            DATE          NOT NULL,
    [EndDate]              DATE          NULL,
    [Creation_DateTime]    DATETIME      NOT NULL,
    [RequestStatus]        VARCHAR (4)   NOT NULL,
    [RejectionReason]      VARCHAR (200) NULL,
    [RequestProcessedOn]   DATETIME      NULL,
    CONSTRAINT [PK_sub_tblEmployer_ParentChild_Request] PRIMARY KEY CLUSTERED ([RequestID] ASC)
);

