
CREATE PROCEDURE sub.uspDeclaration_Email_Get
	@EmailID	int
AS
/*	==========================================================================================
	27-07-2018	Jaap van Assenbergh
				Ophalen gegevens uit sub.tblDeclaration_Email op basis van EmailID
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
	WHERE	EmailID = @EmailID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== uspDeclaration_Email_Get ===============================================================	*/
