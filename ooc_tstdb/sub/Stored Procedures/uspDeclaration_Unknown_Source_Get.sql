
CREATE PROCEDURE [sub].[uspDeclaration_Unknown_Source_Get]
	@DeclarationID	int
AS
/*	==========================================================================================
	20-07-2018	Jaap van Assenbergh
				Ophalen gegevens uit sub.tblDeclaration_Unknown_Source op basis van DeclarationID
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

	SELECT
			DeclarationID,
			InstituteName,
			CourseName,
			SentToSourceSystemDate,
			ReceivedFromSourceSystemDate
	FROM	sub.tblDeclaration_Unknown_Source
	WHERE	DeclarationID = @DeclarationID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== uspDeclaration_Unknown_Source_Get ======================================================	*/
