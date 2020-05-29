CREATE PROCEDURE [sub].[uspDeclaration_Attachment_List]
@DeclarationID	int,
@ExtensionID	int = NULL,
@AllAttachments	bit = 0
AS
/*	==========================================================================================
	Purpose:	Get declaration information with possible attachment(s).

	Parameters:	DeclarationID,	Mandatory.
				ExtensionID,	NULL for attachments linked to intial declaration.
								Specific ID for attachments linked to specific extension.
				AllAttachments,	Get all attachments linked to declaration.

	01-05-2019	Sander van Houten		OTIBSUB-1007	Option to link attachment to extension.
	19-07-2018	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		AttachmentID,
		DeclarationID,
		UploadDateTime,
		OriginalFileName,
		DocumentType,
		ExtensionID
FROM	sub.tblDeclaration_Attachment
WHERE	DeclarationID = @DeclarationID
AND		(
			@AllAttachments = 1
OR			(
				@AllAttachments = 0 
			AND COALESCE(ExtensionID, 0) = COALESCE(@ExtensionID, 0)
			)
		)
ORDER BY DeclarationID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Attachment_List =====================================================	*/
