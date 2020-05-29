
CREATE PROCEDURE sub.uspEmployer_Subsidy_GracePeriod_Email_List
AS
/*	==========================================================================================
	Purpose: 	Get list from sub.tblEmployer_Subsidy_GracePeriod_Email.

	14-01-2020	Sander van Houten	OTIBSUB-1827    Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		GracePeriodID,
		EmailID,
		Token,
		UserID,
		ValidUntil
FROM	sub.tblEmployer_Subsidy_GracePeriod_Email
ORDER BY 
        GracePeriodID,
		EmailID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployer_Subsidy_GracePeriod_Email_List ========================================	*/
