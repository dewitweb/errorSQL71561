
CREATE PROCEDURE [sub].[uspEmployer_Subsidy_GracePeriod_Get]
@GracePeriodID	int
AS
/*	==========================================================================================
	Purpose: 	Get data from sub.tblEmployer_Subsidy_GracePeriod on basis of GracePeriodID.

	14-01-2020	Sander van Houten	OTIBSUB-1827    Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		GracePeriodID,
		EmployerSubsidyID,
		EndDate,
		CreationUserID,
		CreationDate,
		GracePeriodReason,
		HandledByUserID,
		HandledDate,
		GracePeriodStatus
FROM	sub.tblEmployer_Subsidy_GracePeriod
WHERE	GracePeriodID = @GracePeriodID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployer_Subsidy_GracePeriod_Get ===============================================	*/
