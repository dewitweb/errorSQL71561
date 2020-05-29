
-- CREATE PROCEDURE [sub].[uspEmployer_ParentChild_Request_Attachment_Del].
CREATE PROCEDURE [sub].[uspEmployer_ParentChild_Request_Attachment_Del]
@RequestID		int,
@AttachmentID	uniqueidentifier,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose:	Remove Employer_ParentChild_Request_Attachment record.

	18-09-2019	Sander van Houten		OTIBSUB-100		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Return		int = 1	-- Initial returncode is error

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

-- Save old record
SELECT	@XMLdel = (SELECT	* 
				   FROM		sub.tblEmployer_ParentChild_Request_Attachment
				   WHERE	RequestID = @RequestID
				   AND		AttachmentID = @AttachmentID
				   FOR XML PATH),
		@XMLins = NULL

-- Delete record
DELETE
FROM	sub.tblEmployer_ParentChild_Request_Attachment
WHERE	RequestID = @RequestID
AND		AttachmentID = @AttachmentID

-- Log action in tblHistory
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = CAST(@RequestID AS varchar(18)) + '|' + CAST(@AttachmentID AS varchar(36))

	EXEC his.uspHistory_Add
			'sub.tblEmployer_ParentChild_Request_Attachment',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SET @Return = 0

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

usp_Exit:
RETURN @Return

/*	== sub.uspEmployer_ParentChild_Request_Attachment_Del ====================================	*/
