
CREATE PROCEDURE sub.uspDeclarationEmail_Attachment_Get
	@EmailID		int,
	@AttachmentID	uniqueidentifier
AS
/*	==========================================================================================
	27-07-2018	Jaap van Assenbergh
				Ophalen gegevens uit sub.tblDeclarationEmail_Attachment op basis van EmailID
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

	SELECT
			EmailID,
			AttachmentID,
			OriginalFileName
	FROM	sub.tblDeclarationEmail_Attachment
	WHERE	EmailID = @EmailID
	AND		AttachmentID = @AttachmentID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== uspDeclarationEmail_Attachment_Get =====================================================	*/
