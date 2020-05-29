
CREATE PROCEDURE [auth].[uspUserLoginStatus_History_List]
AS
/*	==========================================================================================
	Purpose:	Get all records from the table tblUserLoginStatus_History

	21-05-2019	Jaap van Assenbergh	OTIBSUB-1098 Bij inloggen gebruiker de user agent loggen
	29-11-2018	Sander van Houten	Initial version (OTIBSUB-476)
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

 SELECT	UserID,
		LastLogin,
		LastLogout,
		UserAgentString
 FROM	auth.tblUserLoginStatus_History

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/* == auth.uspUserLoginStatus_History_List ===================================================	*/
