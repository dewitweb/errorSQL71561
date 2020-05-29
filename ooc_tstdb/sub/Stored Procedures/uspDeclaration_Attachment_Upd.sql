
CREATE PROCEDURE [sub].[uspDeclaration_Attachment_Upd]
@DeclarationID		int,
@AttachmentID		uniqueidentifier,
@UploadDateTime		smalldatetime,
@OriginalFileName	varchar(MAX),
@DocumentType		varchar(20),
@CurrentUserID		int = 1,
@ExtensionID		int = NULL
AS
/*	==========================================================================================
	Purpose:	Update sub.tblDeclaration_Attachment on the basis of 
				DeclarationID and AttachmentID.

	01-05-2019	Sander van Houten		OTIBSUB-1007	Option to link attachment to extension.
	02-08-2018	Sander van Houten		CurrentUserID added.
	19-07-2018	Jaap van Assenbergh		Initial version.
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

	INSERT INTO sub.tblDeclaration_Attachment
		(
			DeclarationID,
			AttachmentID,
			UploadDateTime,
			OriginalFileName,
			DocumentType,
			ExtensionID
		)
	VALUES
		(
			@DeclarationID,
			@AttachmentID,
			@UploadDateTime,
			@OriginalFileName,
			@DocumentType,
			@ExtensionID
		)

	-- Save new record
	SELECT	@XMLdel = NULL,
			@XMLins = (SELECT * 
					   FROM   sub.tblDeclaration_Attachment 
					   WHERE  DeclarationID = @DeclarationID 
						 AND  AttachmentID = @AttachmentID
					   FOR XML PATH)
END
ELSE
BEGIN
	-- Save old record
	SELECT	@XMLdel = (SELECT * 
					   FROM   sub.tblDeclaration_Attachment 
					   WHERE  DeclarationID = @DeclarationID 
						 AND  AttachmentID = @AttachmentID
					   FOR XML PATH)

	-- Update exisiting record
	UPDATE	sub.tblDeclaration_Attachment
	SET
			DeclarationID		= @DeclarationID,
			UploadDateTime		= @UploadDateTime,
			OriginalFileName	= @OriginalFileName,
			DocumentType		= @DocumentType,
			ExtensionID			= @ExtensionID
	WHERE	DeclarationID = @DeclarationID
	AND		AttachmentID = @AttachmentID

	-- Save new record
	SELECT	@XMLins = (SELECT * 
					   FROM   sub.tblDeclaration_Attachment 
					   WHERE  DeclarationID = @DeclarationID 
						 AND  AttachmentID = @AttachmentID
					   FOR XML PATH)
END

-- Log action in tblHistory
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = CAST(@DeclarationID AS varchar(18)) + '|' + CAST(@AttachmentID AS varchar(36))

	EXEC his.uspHistory_Add
			'sub.tblDeclaration_Attachment',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SELECT	DeclarationID = @DeclarationID, 
		AttachmentID = @AttachmentID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Attachment_Upd ======================================================	*/
