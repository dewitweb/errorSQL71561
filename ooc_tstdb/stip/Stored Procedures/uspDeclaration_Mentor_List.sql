
CREATE PROCEDURE stip.uspDeclaration_Mentor_List
AS
/*	==========================================================================================
	Purpose: 	Get list from stip.tblDeclaration_Mentor.

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
ORDER BY MentorID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== stip.uspDeclaration_Mentor_List =======================================================	*/
