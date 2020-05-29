
CREATE PROCEDURE stip.uspDeclaration_Mentor_Get
@DeclarationID	int
AS
/*	==========================================================================================
	Purpose: 	Get data from stip.tblDeclaration_Mentor on basis of DeclarationID.

	02-05-2019	Jaap van Assenbergh	Inital version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		DeclarationID,
		MentorID,
		StartDate,
		EndDate
FROM	stip.tblDeclaration_Mentor
WHERE	DeclarationID = @DeclarationID
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== uspDeclaration_Mentor_Get =============================================================	*/
