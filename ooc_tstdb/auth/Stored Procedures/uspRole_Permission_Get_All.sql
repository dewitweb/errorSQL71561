
CREATE PROCEDURE [auth].[uspRole_Permission_Get_All]
@RoleID int
AS
/*	==========================================================================================
	Puspose:	List all permissions and a specific role with an indication weither the 
				permission is linked to the role or not.

	12-12-2018	Sander van Houten	Initial version
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		rol.RoleID,
		rol.RoleName,
		rol.Abbreviation,
		prm.PermissionID,
		prm.PermissionCode,
		prm.PermissionDescription_NL								AS PermissionDescription,
		CASE ISNULL(rop.PermissionID, 0) WHEN 0 THEN 0 ELSE 1 END	AS Linked
FROM	auth.tblRole rol
INNER JOIN auth.tblPermission prm ON prm.ApplicationID = rol.ApplicationID
LEFT JOIN auth.tblRole_Permission rop ON rop.RoleID = rol.RoleID AND rop.PermissionID = prm.PermissionID
WHERE	rol.RoleID = @RoleID
ORDER BY 
		prm.PermissionID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== auth.uspRole_Permission_Get_All =======================================================	*/
