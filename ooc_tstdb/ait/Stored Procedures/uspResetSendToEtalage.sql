
CREATE PROCEDURE [ait].[uspResetSendToEtalage]
@DeclarationID int
AS

UPDATE	sub.tblDeclaration_Unknown_Source 
SET		SentToSourceSystemDate = NULL
WHERE	DeclarationID = @DeclarationID

UPDATE	sub.tblDeclaration
SET		DeclarationStatus = '0002'
WHERE	DeclarationID = @DeclarationID
