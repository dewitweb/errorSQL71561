
CREATE PROCEDURE [sub].[uspEmployer_IBAN_Change_Attachment_Get]
@IBANChangeID	int,
@AttachmentID	uniqueidentifier
AS
/*	==========================================================================================
	Purpose:	Get specific Employer_IBAN_Change_Attachment record.

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
	AND		AttachmentID = @AttachmentID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== uspEmployer_IBAN_Change_Attachment_Get ================================================	*/
