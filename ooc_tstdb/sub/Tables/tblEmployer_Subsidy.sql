CREATE TABLE [sub].[tblEmployer_Subsidy] (
    [EmployerSubsidyID]               INT             IDENTITY (1, 1) NOT NULL,
    [EmployerNumber]                  VARCHAR (6)     NOT NULL,
    [SubsidySchemeID]                 INT             NOT NULL,
    [StartDate]                       DATE            NOT NULL,
    [EndDate]                         DATE            NOT NULL,
    [Amount]                          DECIMAL (19, 4) NOT NULL,
    [EndDeclarationPeriod]            DATE            NOT NULL,
    [ChangeReason]                    VARCHAR (MAX)   NULL,
    [SubsidyYear]                     AS              (case when datepart(year,[StartDate])=datepart(year,[EndDate]) then CONVERT([varchar](10),datepart(year,[StartDate])) else (CONVERT([varchar](4),datepart(year,[StartDate]))+'/')+CONVERT([varchar](4),datepart(year,[EndDate])) end) PERSISTED,
    [SubsidyAmountPerEmployer]        DECIMAL (19, 2) NULL,
    [SubsidyAmountPerEmployee]        DECIMAL (19, 2) NULL,
    [NumberOfEmployee]                INT             NULL,
    [NumberOfEmployee_WithoutSubsidy] INT             NULL,
    CONSTRAINT [PK_sub_tblEmployer_Subsidy] PRIMARY KEY CLUSTERED ([EmployerSubsidyID] ASC),
    CONSTRAINT [FK_sub_tblEmployer_Subsidy_tblEmployer] FOREIGN KEY ([EmployerNumber]) REFERENCES [sub].[tblEmployer] ([EmployerNumber]),
    CONSTRAINT [FK_sub_tblEmployer_Subsidy_tblSubsidyScheme] FOREIGN KEY ([SubsidySchemeID]) REFERENCES [sub].[tblSubsidyScheme] ([SubsidySchemeID])
);


GO
CREATE NONCLUSTERED INDEX [IX_sub_tblEmployer_Subsidy_EmployerNumber]
    ON [sub].[tblEmployer_Subsidy]([EmployerNumber] ASC, [SubsidySchemeID] ASC, [StartDate] ASC);


GO
CREATE TRIGGER [sub].[trgEmployer_Subsidy_Ins] ON [sub].[tblEmployer_Subsidy]
AFTER INSERT
AS
/*	==========================================================================================
	Purpose:	Update the EndDeclarationPeriod in sub.tblEmployer_Subsidy.

	13-01-2020	Sander van Houten	OTIBSUB-1827    Initial version.
	==========================================================================================	*/

IF (
		SELECT	EndDeclarationPeriod 
		FROM	inserted
	) IS NULL
BEGIN
	UPDATE	ems
	SET		ems.EndDeclarationPeriod = sub.usfGetEndDeclarationPeriod(ems.EmployerSubsidyID)
	FROM	sub.tblEmployer_Subsidy ems
	INNER JOIN inserted i ON i.EmployerSubsidyID = ems.EmployerSubsidyID
END

/*	== sub.trgEmployer_Subsidy_Ins ===========================================================	*/

