
CREATE PROCEDURE sub.uspEmployer_Subsidy_GracePeriod_List
AS
/*	==========================================================================================
	Purpose: 	Get list from sub.tblEmployer_Subsidy_GracePeriod.

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
ORDER BY 
        EmployerSubsidyID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployer_Subsidy_GracePeriod_List ==============================================	*/
