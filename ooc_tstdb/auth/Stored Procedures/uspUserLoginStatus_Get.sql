
CREATE PROCEDURE [auth].[uspUserLoginStatus_Get]
@UserID int
AS
/*	==========================================================================================
	Purpose:	Get a record from the table tblUserLoginStatus by UserID

	01-05-2018	Sander van Houten	Conversion from uspGebruikerInlogStatus_Get for new datamodel
	21-03-2018	Sander van Houten   Ophalen gegevens uit auth.tblGebruikerInlogStatus op basis van GebruikerID
	========================================================================================== */

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		UserID,
		LastLogin,
		LastLogout,
		LoggedIn
FROM	auth.tblUserLoginStatus
WHERE	UserID = @UserID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/* == auth.uspUserLoginStatus_Get =========================================================== */
