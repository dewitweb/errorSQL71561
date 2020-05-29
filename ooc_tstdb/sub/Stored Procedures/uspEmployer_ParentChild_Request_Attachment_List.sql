
-- CREATE PROCEDURE [sub].[uspEmployer_ParentChild_Request_Attachment_List].
CREATE PROCEDURE [sub].[uspEmployer_ParentChild_Request_Attachment_List]
@RequestID	int
AS
/*	==========================================================================================
	Purpose:	Get all attachments from Employer_IBAN_Change_Attachment for specific RequestID.

	18-09-2019	Sander van Houten		OTIBSUB-100		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

	SELECT
			RequestID,
			AttachmentID,
			UploadDateTime,
			OriginalFileName
	FROM	sub.tblEmployer_ParentChild_Request_Attachment
	WHERE	RequestID = @RequestID
	ORDER BY 
			UploadDateTime

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployer_ParentChild_Request_Attachment_List ===================================	*/
