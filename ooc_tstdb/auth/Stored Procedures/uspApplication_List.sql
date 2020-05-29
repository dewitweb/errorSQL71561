
CREATE PROCEDURE [auth].[uspApplication_List]
AS
/*	==========================================================================================
	Purpose:	Get all records from the table tblApplication

	01-05-2018	Sander van Houten	Initial version
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		ApplicationID,
		ApplicationName
FROM	auth.tblApplication
ORDER BY ApplicationName

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== auth.uspApplication_List ==============================================================	*/
