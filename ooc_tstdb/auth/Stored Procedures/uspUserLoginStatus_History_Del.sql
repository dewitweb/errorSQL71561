
CREATE PROCEDURE [auth].[uspUserLoginStatus_History_Del]
@UserID int
AS
/* 	==========================================================================================
	Purpose:	Delete all records from one user from the table tblUserLoginStatus_History.

	29-11-2018	Sander van Houten	Initial version (OTIBSUB-476)
	========================================================================================== */

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID
	
DELETE
FROM	auth.tblUserLoginStatus_History
WHERE	UserID = @UserID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/* == auth.uspUserLoginStatus_History_Del ==================================================== */
