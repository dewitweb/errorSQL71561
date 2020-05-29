
CREATE PROCEDURE sub.uspDeclarationEmail_Attachment_List
	@EmailID		int
AS
/*	==========================================================================================
	27-07-2018	Jaap van Assenbergh
				Ophalen lijst uit sub.tblDeclarationEmail_Attachment
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

	SELECT
			EmailID,
			AttachmentID,
			OriginalFileName
	FROM	sub.tblDeclarationEmail_Attachment
	WHERE	EmailID = @EmailID
	ORDER BY AttachmentID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclarationEmail_Attachment_List ================================================	*/
