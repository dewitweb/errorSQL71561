
-- CREATE PROCEDURE [sub].[uspEmployer_ParentChild_Request_Attachment_Upd].
CREATE PROCEDURE [sub].[uspEmployer_ParentChild_Request_Attachment_Upd]
@RequestID			int,
@AttachmentID		uniqueidentifier,
@UploadDateTime		smalldatetime,
@OriginalFileName	varchar(MAX),
@CurrentUserID		int = 1
AS
/*	==========================================================================================
	Purpose:	Update sub.tblEmployer_ParentChild_Request_Attachment on the basis of 
				RequestID and AttachmentID.

	18-09-2019	Sander van Houten		OTIBSUB-100		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(100)

IF (@AttachmentID IS NULL)
BEGIN
	-- Add new record
	SET @AttachmentID = NEWID()

	INSERT INTO sub.tblEmployer_ParentChild_Request_Attachment
		(
			RequestID,
			AttachmentID,
			UploadDateTime,
			OriginalFileName
		)
	VALUES
		(
			@RequestID,
			@AttachmentID,
			@UploadDateTime,
			@OriginalFileName
		)

	-- Save new record
	SELECT	@XMLdel = NULL,
			@XMLins = (SELECT * 
					   FROM   sub.tblEmployer_ParentChild_Request_Attachment 
					   WHERE  RequestID = @RequestID 
						 AND  AttachmentID = @AttachmentID
					   FOR XML PATH)
END
ELSE
BEGIN
	-- Save old record
	SELECT	@XMLdel = (SELECT * 
					   FROM   sub.tblEmployer_ParentChild_Request_Attachment 
					   WHERE  RequestID = @RequestID 
						 AND  AttachmentID = @AttachmentID
					   FOR XML PATH)

	-- Update exisiting record
	UPDATE	sub.tblEmployer_ParentChild_Request_Attachment
	SET
			UploadDateTime		= @UploadDateTime,
			OriginalFileName	= @OriginalFileName
	WHERE	RequestID = @RequestID
	AND		AttachmentID = @AttachmentID

	-- Save new record
	SELECT	@XMLins = (SELECT * 
					   FROM   sub.tblEmployer_ParentChild_Request_Attachment 
					   WHERE  RequestID = @RequestID 
						 AND  AttachmentID = @AttachmentID
					   FOR XML PATH)
END

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

SELECT	DeclarationID = @RequestID, 
		AttachmentID = @AttachmentID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployer_ParentChild_Request_Attachment_Upd ====================================	*/
