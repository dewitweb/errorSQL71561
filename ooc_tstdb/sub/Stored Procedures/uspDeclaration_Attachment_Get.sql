
CREATE PROCEDURE [sub].[uspDeclaration_Attachment_Get]
	@DeclarationID	int,
	@AttachmentID	uniqueidentifier
AS
/*	==========================================================================================
	19-07-2018	Jaap van Assenbergh
				Ophalen gegevens uit sub.tblDeclaration_Attachment op basis van AttachmentID
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

	SELECT
			da.AttachmentID,
			da.DeclarationID,
			da.UploadDateTime,
			da.OriginalFileName,
			da.DocumentType,
			decl.EmployerNumber
	FROM	sub.tblDeclaration_Attachment da
	INNER JOIN sub.tblDeclaration decl ON decl.DeclarationID = da.DeclarationID
	WHERE	da.DeclarationID = @DeclarationID
	AND		da.AttachmentID = @AttachmentID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Attachment_Get =====================================================	*/
