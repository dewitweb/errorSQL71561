
CREATE PROCEDURE [sub].[uspEmployer_IBAN_Change_Attachment_Del]
@IBANChangeID	int,
@AttachmentID	uniqueidentifier,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose:	Remove Employer_IBAN_Change_Attachment record.

	19-11-2018	Sander van Houten		Initial version (OTIBSUB-98).
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
				   FROM		sub.tblEmployer_IBAN_Change_Attachment
				   WHERE	IBANChangeID = @IBANChangeID
					 AND	AttachmentID = @AttachmentID
				   FOR XML PATH),
		@XMLins = NULL

-- Delete record
DELETE
FROM	sub.tblEmployer_IBAN_Change_Attachment
WHERE	IBANChangeID = @IBANChangeID
AND		AttachmentID = @AttachmentID

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

SET @Return = 0

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

usp_Exit:
RETURN @Return

/*	== sub.uspEmployer_IBAN_Change_Attachment_Del ============================================	*/
