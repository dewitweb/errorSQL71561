CREATE PROCEDURE [ait].[uspLog_Get]
@LogID	int
AS
/*	==========================================================================================
	Purpose: 	Get data from ait.tblLog on basis of LogID.

	20-06-2019	Jaap van Assenbergh	Inital version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		LogID,
		LogDateTime,
		LogMessage,
		LogURL,
		LogLevel,
		PostBody,
		Stacktrace,
		CurrentUserID
FROM	ait.tblLog
WHERE	LogID = @LogID
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== uspLog_Get ============================================================================	*/
