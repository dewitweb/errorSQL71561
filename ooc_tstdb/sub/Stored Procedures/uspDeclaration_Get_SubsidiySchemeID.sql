
CREATE PROCEDURE [sub].[uspDeclaration_Get_SubsidiySchemeID]
@DeclarationID	int
AS
/*	==========================================================================================
	Purpose:	Get SubsidyScheme by decleration

	02-11-2018	Jaap van Assenbergh		OTIBSUB-403
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		DeclarationID,
		SubsidySchemeID
FROM	sub.tblDeclaration
WHERE	DeclarationID = @DeclarationID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Get ================================================================	*/
