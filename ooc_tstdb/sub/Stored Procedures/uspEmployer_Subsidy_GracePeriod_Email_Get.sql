
CREATE PROCEDURE sub.uspEmployer_Subsidy_GracePeriod_Email_Get
@GracePeriodID	int,
@EmailID        int
AS
/*	==========================================================================================
	Purpose: 	Get data from sub.tblEmployer_Subsidy_GracePeriod_Email 
                on basis of GracePeriodID and EmailID.

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
WHERE	GracePeriodID = @GracePeriodID
AND     EmailID = @EmailID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== uspEmployer_Subsidy_GracePeriod_Email_Get =============================================	*/
