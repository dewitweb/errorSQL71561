
CREATE PROCEDURE [sub].[uspEmployer_IBAN_Change_Attachment_List]
@IBANChangeID	int
AS
/*	==========================================================================================
	Purpose:	Get all attachments from Employer_IBAN_Change_Attachment for specific IBANChangeID.

	19-11-2018	Sander van Houten		Initial version (OTIBSUB-98).
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

	SELECT
			IBANChangeID,
			AttachmentID,
			UploadDateTime,
			OriginalFileName
	FROM	sub.tblEmployer_IBAN_Change_Attachment
	WHERE	IBANChangeID = @IBANChangeID
	ORDER BY UploadDateTime

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployer_IBAN_Change_Attachment_List ===========================================	*/
