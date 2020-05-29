
CREATE PROCEDURE [eml].[uspEmail_Upd_SentDateOnly]
 @EmailID		int,
 @SentDate		datetime
AS
/*	==========================================================================================
	Purpose:	Update sentdate of an e-mail.

	05-10-2018	Sander van Houten	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

UPDATE	eml.tblEmail
SET		SentDate = @SentDate
WHERE	EmailID = @EmailID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/* == eml.uspEmail_Upd_SentDateOnly ==========================================================  */
