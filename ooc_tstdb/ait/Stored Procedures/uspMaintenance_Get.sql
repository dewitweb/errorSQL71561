
CREATE PROCEDURE ait.uspMaintenance_Get
@RecordID	int
AS
/*	==========================================================================================
	Purpose: 	Get data from ait.tblMaintenance on basis of RecordID.

	06-05-2019	Sander van Houten	OTIBSUB-964		Inital version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		RecordID,
		StartDate,
		Duration
FROM	ait.tblMaintenance
WHERE	RecordID = @RecordID
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== uspMaintenance_Get ====================================================================	*/
