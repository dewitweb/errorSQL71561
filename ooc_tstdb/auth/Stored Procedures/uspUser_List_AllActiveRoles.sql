
CREATE PROCEDURE [auth].[uspUser_List_AllActiveRoles]
@ActiveUserOnly bit = 1,
@OTIBOnly		bit = 1
AS
/*	==========================================================================================
	Puspose:	List all users with all active roles (abbrevations).

	21-01-2019	Sander van Houten	Initial version
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT	usr.UserID,
		usr.Fullname,
		usr.Loginname,
		ISNULL(STUFF((	SELECT	', '+ rol.Abbreviation
						FROM	auth.tblUser_Role uro 
						INNER JOIN auth.tblRole rol ON rol.RoleID = uro.RoleID
						WHERE	uro.UserID = usr.UserID
						GROUP BY rol.Abbreviation
						ORDER BY rol.Abbreviation
						FOR XML PATH('')), 1, 1, ''), '') AS [Roles]
FROM	auth.tblUser usr
LEFT JOIN auth.tblUser_Role otib ON otib.UserID = usr.UserID AND otib.RoleID = 2	--OTIB
WHERE	( @ActiveUserOnly = 0
   OR	  usr.Active = @ActiveUserOnly )
  AND	( @OTIBOnly = 0
   OR	  otib.RoleID = 2 )
ORDER BY
		usr.UserID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== auth.uspUser_List_AllActiveRoles ======================================================	*/
