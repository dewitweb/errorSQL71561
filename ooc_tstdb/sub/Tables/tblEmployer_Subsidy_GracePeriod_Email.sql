CREATE TABLE [sub].[tblEmployer_Subsidy_GracePeriod_Email] (
    [GracePeriodID] INT          NOT NULL,
    [EmailID]       INT          NOT NULL,
    [Token]         VARCHAR (50) NOT NULL,
    [UserID]        INT          NOT NULL,
    [ValidUntil]    DATETIME     NOT NULL,
    CONSTRAINT [PK_sub_tblEmployer_Subsidy_GracePeriod_Email] PRIMARY KEY CLUSTERED ([GracePeriodID] ASC, [EmailID] ASC)
);

