
CREATE PROCEDURE [eml].[uspEmail_Attachment_List]
@EmailID	int
AS
/*	==========================================================================================
	Purpose:	Get e-mail attachment(s) on basis of EmailID.

	05-10-2018	Sander van Houten		Initial version.
	==========================================================================================	*/

--DECLARE @ExecutedProcedureID int = 0
--EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT	ema.AttachmentID,
		ema.EmailID,
		ema.Attachment,
		ema.DateAttached
FROM	eml.tblEmailAttachment ema
WHERE	ema.EmailID = @EmailID

--EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== eml.uspEmail_Attachment_List ==========================================================	*/
