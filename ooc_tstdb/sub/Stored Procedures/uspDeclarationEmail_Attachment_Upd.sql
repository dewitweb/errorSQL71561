
CREATE PROCEDURE [sub].[uspDeclarationEmail_Attachment_Upd]
@EmailID			int,
@AttachmentID		uniqueidentifier,
@OriginalFileName	varchar(MAX),
@CurrentUserID		int = 1
AS
/*	==========================================================================================
	Purpose:	Update sub.tblDeclarationEmail_Attachment on the basis of 
				EmailID and AttachmentID.

	03-08-2018	Sander van Houten		CurrentUserID added.
	27-07-2018	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF (@AttachmentID IS NULL)
BEGIN
	-- Add new record
	SET @AttachmentID = NEWID()

	INSERT INTO sub.tblDeclarationEmail_Attachment
		(
			EmailID,
			AttachmentID,
			OriginalFileName
		)
	VALUES
		(
			@EmailID,
			@AttachmentID,
			@OriginalFileName
		)

	-- Save new record
	SELECT	@XMLdel = NULL,
			@XMLins = (SELECT * 
					   FROM   sub.tblDeclarationEmail_Attachment 
					   WHERE  EmailID = @EmailID 
						 AND  AttachmentID = @AttachmentID
					   FOR XML PATH)
END
ELSE
BEGIN
	-- Save old record
	SELECT	@XMLdel = (SELECT * 
					   FROM   sub.tblDeclarationEmail_Attachment 
					   WHERE  EmailID = @EmailID 
						 AND  AttachmentID = @AttachmentID
					   FOR XML PATH)

	-- Update exisiting record
	UPDATE	sub.tblDeclarationEmail_Attachment
	SET
			AttachmentID	= @AttachmentID,
			OriginalFileName= @OriginalFileName
	WHERE	EmailID = @EmailID

	-- Save new record
	SELECT	@XMLins = (SELECT * 
					   FROM   sub.tblDeclarationEmail_Attachment 
					   WHERE  EmailID = @EmailID 
						 AND  AttachmentID = @AttachmentID
					   FOR XML PATH)
END

-- Log action in tblHistory
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = CAST(@EmailID AS varchar(18)) + '|' + CAST(@AttachmentID AS varchar(36))

	EXEC his.uspHistory_Add
			'sub.tblDeclarationEmail_Attachment',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SELECT	EmailID = @EmailID, 
		AttachmentID = @AttachmentID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclarationEmail_Attachment_Upd =================================================	*/
