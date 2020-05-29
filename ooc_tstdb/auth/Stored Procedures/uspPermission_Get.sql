
CREATE PROCEDURE [auth].[uspPermission_Get]
@PermissionID	int
AS
/*	==========================================================================================
	Purpose:	Get a record from the table tblPermission

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
WHERE	PermissionID = @PermissionID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== auth.uspPermission_Get ===============================================================	*/
