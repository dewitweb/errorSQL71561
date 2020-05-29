
CREATE PROCEDURE [sub].[uspEmployer_IBAN_Change_Attachment_Upd]
@IBANChangeID		int,
@AttachmentID		uniqueidentifier,
@UploadDateTime		smalldatetime,
@OriginalFileName	varchar(MAX),
@CurrentUserID		int = 1
AS
/*	==========================================================================================
	Purpose:	Update sub.tblEmployer_IBAN_Change_Attachment on the basis of 
				IBANChangeID and AttachmentID.

	19-11-2018	Sander van Houten		Initial version.
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

	INSERT INTO sub.tblEmployer_IBAN_Change_Attachment
		(
			IBANChangeID,
			AttachmentID,
			UploadDateTime,
			OriginalFileName
		)
	VALUES
		(
			@IBANChangeID,
			@AttachmentID,
			@UploadDateTime,
			@OriginalFileName
		)

	-- Save new record
	SELECT	@XMLdel = NULL,
			@XMLins = (SELECT * 
					   FROM   sub.tblEmployer_IBAN_Change_Attachment 
					   WHERE  IBANChangeID = @IBANChangeID 
						 AND  AttachmentID = @AttachmentID
					   FOR XML PATH)
END
ELSE
BEGIN
	-- Save old record
	SELECT	@XMLdel = (SELECT * 
					   FROM   sub.tblEmployer_IBAN_Change_Attachment 
					   WHERE  IBANChangeID = @IBANChangeID 
						 AND  AttachmentID = @AttachmentID
					   FOR XML PATH)

	-- Update exisiting record
	UPDATE	sub.tblEmployer_IBAN_Change_Attachment
	SET
			UploadDateTime		= @UploadDateTime,
			OriginalFileName	= @OriginalFileName
	WHERE	IBANChangeID = @IBANChangeID
	AND		AttachmentID = @AttachmentID

	-- Save new record
	SELECT	@XMLins = (SELECT * 
					   FROM   sub.tblEmployer_IBAN_Change_Attachment 
					   WHERE  IBANChangeID = @IBANChangeID 
						 AND  AttachmentID = @AttachmentID
					   FOR XML PATH)
END

-- Log action in tblHistory
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = CAST(@IBANChangeID AS varchar(18)) + '|' + CAST(@AttachmentID AS varchar(36))

	EXEC his.uspHistory_Add
			'sub.tblEmployer_IBAN_Change_Attachment',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SELECT	DeclarationID = @IBANChangeID, 
		AttachmentID = @AttachmentID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployer_IBAN_Change_Attachment_Upd ============================================	*/
