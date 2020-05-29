
CREATE PROCEDURE [auth].[uspApplication_Get]
@ApplicationID int
AS
/*	==========================================================================================
	Purpose:	Get a record from the table tblApplication

	01-05-2018	Sander van Houten	Initial version
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		ApplicationID,
		ApplicationName
FROM	auth.tblApplication
WHERE	ApplicationID = @ApplicationID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== auth.uspApplication_Get ===============================================================	*/
