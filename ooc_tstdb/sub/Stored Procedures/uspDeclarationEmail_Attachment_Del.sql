
CREATE PROCEDURE [sub].[uspDeclarationEmail_Attachment_Del]
@EmailID		int,
@AttachmentID	uniqueidentifier,
@CurrentUserID	int = 1
AS

/*	==========================================================================================
	Purpose:	Remove tblDeclarationEmail_Attachment record.

	02-08-2018	Sander van Houten		CurrentUserID added.
	27-07-2018	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

-- Save old record
SELECT	@XMLdel = (SELECT	* 
				   FROM		sub.tblDeclarationEmail_Attachment
				   WHERE	EmailID = @EmailID
					 AND	AttachmentID = @AttachmentID
				   FOR XML PATH),
		@XMLins = NULL

-- Delete record
DELETE
FROM	sub.tblDeclarationEmail_Attachment
WHERE	EmailID = @EmailID
AND		AttachmentID = @AttachmentID

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

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclarationEmail_Attachment_Del =================================================	*/
