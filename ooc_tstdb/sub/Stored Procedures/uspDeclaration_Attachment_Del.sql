CREATE PROCEDURE [sub].[uspDeclaration_Attachment_Del]
@DeclarationID	int,
@AttachmentID	uniqueidentifier,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose:	Remove Declaration_Attachment record.

	13-09-2019	Sander van Houten		OTIBSUB-1561	Verwijderen checks in usp bij verwijderen.
											Deze worden in sub.uspDeclaration_Del al toegepast.
	13-09-2018	Sander van Houten		OTIBSUB-249		Toevoegen checks in usp bij verwijderen
	02-08-2018	Sander van Houten		CurrentUserID added.
	19-07-2018	Jaap van Assenbergh		Initial version.
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
				   FROM		sub.tblDeclaration_Attachment
				   WHERE	DeclarationID = @DeclarationID
					 AND	AttachmentID = @AttachmentID
				   FOR XML PATH),
		@XMLins = NULL

-- Delete record
DELETE
FROM	sub.tblDeclaration_Attachment
WHERE	DeclarationID = @DeclarationID
AND		AttachmentID = @AttachmentID

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

SET @Return = 0

usp_Exit:
RETURN @Return

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Attachment_Del ======================================================	*/
