
CREATE PROCEDURE ait.uspMaintenance_List
AS
/*	==========================================================================================
	Purpose: 	Get list from ait.tblMaintenance.

	06-05-2019	Sander van Houten	OTIBSUB-964		Inital version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		RecordID,
		StartDate,
		Duration
FROM	ait.tblMaintenance
ORDER BY StartDate

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== ait.uspMaintenance_List ===============================================================	*/
