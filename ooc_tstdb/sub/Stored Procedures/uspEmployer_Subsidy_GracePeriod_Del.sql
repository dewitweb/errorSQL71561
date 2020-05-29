
CREATE PROCEDURE [sub].[uspEmployer_Subsidy_GracePeriod_Del]
@GracePeriodID	int,
@CurrentUserID	int = 1
AS

/*	==========================================================================================
	Purpose: 	Delete from sub.tblEmployer_Subsidy_GracePeriod.

    Notes:      If the request is succesfully deleted a trigger will fire, updating the 
                EndDeclarationPeriod field in the table sub.tblEmployer_Subsidy.

	14-01-2020	Sander van Houten	OTIBSUB-1827    Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Return		int = 1

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

-- Save old record.
SELECT	@XMLdel = (	SELECT 	*
					FROM	sub.tblEmployer_Subsidy_GracePeriod
					WHERE	GracePeriodID = @GracePeriodID
					FOR XML PATH ),
		@XMLins = NULL

-- Delete record.
DELETE
FROM	sub.tblEmployer_Subsidy_GracePeriod
WHERE	GracePeriodID = @GracePeriodID

-- Log action in his.tblHistory.
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @GracePeriodID

	EXEC his.uspHistory_Add
        'sub.tblEmployer_Subsidy_GracePeriod',
        @KeyID,
        @CurrentUserID,
        @LogDate,
        @XMLdel,
        @XMLins
END

SET @Return = 0

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployer_Subsidy_GracePeriod_Del ===============================================	*/
