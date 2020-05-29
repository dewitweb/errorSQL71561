
CREATE PROCEDURE sub.uspDeclaration_Investigation_Get
	@DeclarationID	int
AS
/*	==========================================================================================
	23-07-2018	Jaap van Assenbergh
				Ophalen gegevens uit sub.tblDeclaration_Investigation op basis van DeclarationID
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

	SELECT
			DeclarationID,
			InvestigationDate,
			InvestigationMemo
	FROM	sub.tblDeclaration_Investigation
	WHERE	DeclarationID = @DeclarationID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== uspDeclaration_Investigation_Get =======================================================	*/
