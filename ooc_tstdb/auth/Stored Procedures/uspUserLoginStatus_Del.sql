
CREATE PROCEDURE [auth].[uspUserLoginStatus_Del]
@UserID int
AS
/* 	==========================================================================================
	Purpose:	Delete a record from the table tblUserLoginStatus

	01-05-2018	Sander van Houten	Conversion from uspGebruikerInlogStatus_Del for new datamodel
	21-03-2018 	Sander van Houten   Verwijderen uit auth.tblGebruikerInlogStatus
	========================================================================================== */

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID
	
DELETE
FROM	auth.tblUserLoginStatus
WHERE	UserID = @UserID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/* == auth.uspUserLoginStatus_Del ============================================================ */
