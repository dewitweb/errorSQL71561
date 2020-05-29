
CREATE PROCEDURE [sub].[uspEmployer_IBAN_Change_Attachment_Export]
@IBANChangeID	int,
@AttachmentID	uniqueidentifier,
@CurrentUserID	int
AS
/*	==========================================================================================
	Purpose:	Get specific Employer_IBAN_Change_Attachment record for download purposes.

	06-05-2019	Sander van Houten		OTIBSUB-1045	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(100)

DECLARE @OriginalFileName	varchar(max),
		@UploadDateTime		datetime

/*	Get data.	*/
SELECT	@OriginalFileName = OriginalFileName,
		@UploadDateTime = UploadDateTime
FROM	sub.tblEmployer_IBAN_Change_Attachment
WHERE	IBANChangeID = @IBANChangeID
AND		AttachmentID = @AttachmentID

/*	Log the download action.	*/
SET @KeyID = CAST(@IBANChangeID AS varchar(18)) + '|' + CAST(@AttachmentID AS varchar(36))

SELECT	@XMLdel = CAST('<download>1</download>' AS xml),
		@XMLins = CAST('<row><FileName>' + @OriginalFileName + '</FileName></row>' AS xml)

EXEC his.uspHistory_Add
		'sub.tblEmployer_IBAN_Change_Attachment',
		@KeyID,
		@CurrentUserID,
		@LogDate,
		@XMLdel,
		@XMLins

/*	Give back result.	*/
SELECT	@IBANChangeID		AS IBANChangeID,
		@AttachmentID		AS AttachmentID,
		@OriginalFileName	AS OriginalFileName,
		@UploadDateTime		AS UploadDateTime

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== uspEmployer_IBAN_Change_Attachment_Export =============================================	*/
