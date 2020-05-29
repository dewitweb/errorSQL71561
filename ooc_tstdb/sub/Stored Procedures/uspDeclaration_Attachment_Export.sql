CREATE PROCEDURE [sub].[uspDeclaration_Attachment_Export]
@DeclarationID	int,
@AttachmentID	uniqueidentifier,
@CurrentUserID	int
AS
/*	==========================================================================================
	Purpose: 	Get data from sub.tblDeclaration_Attachment on basis of DeclarationID and
				AttachmentID for download purposes.

	01-07-2019	Sander van Houten		OTIBSUB-1295	Added replacement by XML escape characters.
	08-05-2019	Sander van Houten		OTIBSUB-1045	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(100)

DECLARE @UploadDateTime		datetime,
		@OriginalFileName	varchar(max),
		@DocumentType		varchar(20),
		@EmployerNumber		varchar(6)

/*	Get data.	*/
SELECT
		@UploadDateTime = da.UploadDateTime,
		@OriginalFileName = da.OriginalFileName,
		@DocumentType = da.DocumentType,
		@EmployerNumber = decl.EmployerNumber
FROM	sub.tblDeclaration_Attachment da
INNER JOIN sub.tblDeclaration decl ON decl.DeclarationID = da.DeclarationID
WHERE	da.DeclarationID = @DeclarationID
AND		da.AttachmentID = @AttachmentID

/*	Log the download action.	*/
SET @KeyID = CAST(@DeclarationID AS varchar(18)) + '|' + CAST(@AttachmentID AS varchar(36))

SELECT	@XMLdel = CAST('<download>1</download>' AS xml),
		@XMLins = CAST('<row><FileName>' 
					+ REPLACE(REPLACE(REPLACE(@OriginalFileName, '&', '&amp;'), '<', '&lt;'), '>', '&gt;')
					+ '</FileName></row>' AS xml)

EXEC his.uspHistory_Add
		'sub.tblDeclaration_Attachment',
		@KeyID,
		@CurrentUserID,
		@LogDate,
		@XMLdel,
		@XMLins

/*	Give back result.	*/
SELECT	@DeclarationID		AS DeclarationID,
		@AttachmentID		AS AttachmentID,
		@UploadDateTime		AS UploadDateTime,
		@OriginalFileName	AS OriginalFileName,
		@DocumentType		AS DocumentType,
		@EmployerNumber		AS EmployerNumber

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Attachment_Export ==================================================	*/
