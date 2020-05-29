
CREATE PROCEDURE [auth].[uspRole_Permission_List]
AS
/*	==========================================================================================
	Puspose:	Get all permissions connected to all roles

	01-05-2018	Sander van Houten	Initial version
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

	SELECT
			rop.RoleID,
			prm.PermissionID,
			prm.PermissionDescription_NL	AS PermissionDescription
	FROM	auth.tblRole_Permission rop
	INNER JOIN auth.tblPermission prm ON prm.PermissionID = rop.PermissionID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== auth.uspRole_Permission_List ==========================================================	*/
