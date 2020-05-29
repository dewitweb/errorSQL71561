
CREATE PROCEDURE [auth].[uspRole_List_WithNrOfUsers]
@OTIBOnly	bit = 1
AS
/*	==========================================================================================
	Purpose:	Get all records from the table tblRole

    20-02-2020	Sander van Houten	OTIBSUB-1926    Only count active users.
    09-10-2019	Sander van Houten	OTIBSUB-1446    Added field IsSubsidySchemeDependent.
	20-01-2019	Sander van Houten	Added @OTIBOnly and NrOfUsers.
	01-05-2018	Sander van Houten	Conversion from uspGebruikersGroep_List for new datamodel.
	05-03-2018	Sander van Houten	Ophalen lijst uit auth.tblGebruikersGroep.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		rol.RoleID,
		rol.RoleName,
		rol.RoleDescription,
		rol.Abbreviation,
		SUM(CASE WHEN usr.UserID IS NULL THEN 0 ELSE 1 END)	AS NrOfUsers,
        rol.IsSubsidySchemeDependent
FROM	auth.tblRole rol
LEFT JOIN auth.tblUser_Role uro ON uro.RoleID = rol.RoleID
LEFT JOIN auth.tblUser usr ON usr.UserID = uro.UserID AND usr.Active = 1
LEFT JOIN auth.tblUser_Role otib ON otib.UserID = usr.UserID AND otib.RoleID = 2	--OTIB
WHERE	@OTIBOnly = 0
   OR	otib.RoleID = 2
GROUP BY
		rol.RoleID,
		rol.RoleName,
		rol.RoleDescription,
		rol.Abbreviation,
        rol.IsSubsidySchemeDependent
ORDER BY 
		rol.RoleDescription

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== auth.uspRole_List_WithNrOfUsers =======================================================	*/
