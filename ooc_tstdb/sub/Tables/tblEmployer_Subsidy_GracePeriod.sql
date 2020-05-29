CREATE TABLE [sub].[tblEmployer_Subsidy_GracePeriod] (
    [GracePeriodID]     INT           IDENTITY (1, 1) NOT NULL,
    [EmployerSubsidyID] INT           NOT NULL,
    [EndDate]           DATE          NOT NULL,
    [CreationUserID]    INT           NOT NULL,
    [CreationDate]      DATE          CONSTRAINT [DF_sub_tblEmployer_Subsidy_GracePeriod] DEFAULT (getdate()) NOT NULL,
    [GracePeriodReason] VARCHAR (MAX) NOT NULL,
    [HandledByUserID]   INT           NULL,
    [HandledDate]       DATE          NULL,
    [GracePeriodStatus] VARCHAR (20)  NULL,
    CONSTRAINT [PK_sub_tblEmployer_Subsidy_GracePeriod] PRIMARY KEY CLUSTERED ([GracePeriodID] ASC)
);


GO
CREATE TRIGGER [sub].[trgEmployer_Subsidy_GracePeriod_Del] ON [sub].[tblEmployer_Subsidy_GracePeriod]
AFTER DELETE
AS
/*	==========================================================================================
	Purpose:	Update the EndDeclarationPeriod in sub.tblEmployer_Subsidy.

	13-01-2020	Sander van Houten	OTIBSUB-1827    Initial version.
	==========================================================================================	*/

UPDATE	ems
SET		ems.EndDeclarationPeriod = sub.usfGetEndDeclarationPeriod(ems.EmployerSubsidyID)
FROM	sub.tblEmployer_Subsidy ems
INNER JOIN deleted d ON	d.EmployerSubsidyID = ems.EmployerSubsidyID

/*	== sub.trgEmployer_Subsidy_GracePeriod_Del ===============================================	*/


GO
CREATE TRIGGER [sub].[trgEmployer_Subsidy_GracePeriod_Upd_Status] ON [sub].[tblEmployer_Subsidy_GracePeriod]
AFTER INSERT, UPDATE
AS
/*	==========================================================================================
	Purpose:	Update the EndDeclarationPeriod in sub.tblEmployer_Subsidy.

	11-02-2020	Jaap van Assenbergh	"AND i.GracePeriodStatus = '0002'"
	13-01-2020	Sander van Houten	OTIBSUB-1827    Initial version.
	==========================================================================================	*/

IF UPDATE (GracePeriodStatus)
BEGIN
    UPDATE	ems
    SET		ems.EndDeclarationPeriod = sub.usfGetEndDeclarationPeriod(ems.EmployerSubsidyID)
    FROM	sub.tblEmployer_Subsidy ems
    INNER JOIN inserted i ON i.EmployerSubsidyID = ems.EmployerSubsidyID
	AND		i.GracePeriodStatus = '0002'
END

/*	== sub.trgEmployer_Subsidy_GracePeriod_Upd_Status ========================================	*/

