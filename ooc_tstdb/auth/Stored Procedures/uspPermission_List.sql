
CREATE PROCEDURE [auth].[uspPermission_List]
AS
/*	==========================================================================================
	Purpose:	Get all records from the table tblPermission

	01-05-2018	Sander van Houten	Initial version
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		PermissionID,
		PermissionCode,
		PermissionDescription_NL	AS PermissionDescription,
		ApplicationID
FROM	auth.tblPermission
ORDER BY PermissionDescription

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== auth.uspPermission_List ===============================================================	*/
