
CREATE PROCEDURE [auth].[uspUserLoginStatus_List]
AS
/*	==========================================================================================
	Purpose:	Get all records from the table tblUserLoginStatus

	01-05-2018	Sander van Houten	Conversion from uspGebruikerInlogStatus_List for new datamodel
	21-03-2018	Sander van Houten	Ophalen lijst uit auth.tblGebruikerInlogStatus
	========================================================================================== */

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		UserID,
		LastLogin,
		LastLogout,
		LoggedIn
FROM auth.tblUserLoginStatus
ORDER BY UserID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== auth.uspUserLoginStatus_List ========================================================== */
