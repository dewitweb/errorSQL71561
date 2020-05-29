
-- CREATE PROCEDURE [sub].[uspEmployer_ParentChild_Request_Attachment_Get].
CREATE PROCEDURE [sub].[uspEmployer_ParentChild_Request_Attachment_Get]
@RequestID		int,
@AttachmentID	uniqueidentifier
AS
/*	==========================================================================================
	Purpose:	Get specific Employer_ParentChild_Request_Attachment record.

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
	AND		AttachmentID = @AttachmentID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== uspEmployer_ParentChild_Request_Attachment_Get ========================================	*/
