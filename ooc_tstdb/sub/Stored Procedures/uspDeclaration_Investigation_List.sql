
CREATE PROCEDURE sub.uspDeclaration_Investigation_List
AS
/*	==========================================================================================
	23-07-2018	Jaap van Assenbergh
				Ophalen lijst uit sub.tblDeclaration_Investigation
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

	SELECT
			DeclarationID,
			InvestigationDate,
			InvestigationMemo
	FROM	sub.tblDeclaration_Investigation
	ORDER BY InvestigationDate

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Investigation_List ==================================================	*/
