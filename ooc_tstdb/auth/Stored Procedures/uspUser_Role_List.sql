
CREATE PROCEDURE [auth].[uspUser_Role_List]
AS
/*	==========================================================================================
	Puspose:	Get all roles connected to all users

	01-05-2018	Sander van Houten	Initial version
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

	SELECT
			uro.UserID,
			rol.RoleID,
			rol.RoleDescription,
			rol.Abbreviation
	FROM	auth.tblUser_Role uro
	INNER JOIN auth.tblRole rol ON rol.RoleID = uro.RoleID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== auth.uspUser_Role_List ================================================================	*/
