
CREATE PROCEDURE [auth].[uspUser_Role_Get]
@UserID int
AS
/*	==========================================================================================
	Puspose:	Get all roles connected to a specific user

	01-05-2018	Sander van Houten	Initial version
	21-11-2018	Jaap van Assenbergh OTIBSUB-471
				Indien role 1 en niet alle ggevens zijn gechecked dan role 4
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT	ur.UserID,
		ur.RoleID,	
		rol.RoleName,
		rol.RoleDescription,
		rol.Abbreviation,
		rol.ApplicationID
FROM	(
			SELECT	uro.UserID,
					CASE WHEN uro.RoleID = 1 
							THEN
								CASE WHEN 
										(
											SELECT	COUNT(uv.UserID)
											FROM	auth.tblUserValidation uv
											WHERE	uv.UserID = uro.UserID
											AND		0 NOT IN (ContactDetailsCheck, AgreementCheck, EmailCheck)
										) = 0						
									THEN 4 
									ELSE uro.RoleID 
								END
							ELSE uro.RoleID 
					END RoleID
			FROM	auth.tblUser_Role uro
			WHERE	uro.UserID = @UserID
		) ur
INNER JOIN auth.tblRole rol ON rol.RoleID = ur.RoleID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== auth.uspUser_Role_Get =================================================================	*/
