
CREATE PROCEDURE sub.uspDeclaration_Email_List
AS
/*	==========================================================================================
	27-07-2018	Jaap van Assenbergh
				Ophalen lijst uit sub.tblDeclaration_Email
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

	SELECT
			EmailID,
			DeclarationID,
			EmailDate,
			EmailSubject,
			EmailBody,
			Direction,
			HandledDate
	FROM	sub.tblDeclaration_Email
	ORDER BY DeclarationID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Email_List ==========================================================	*/
