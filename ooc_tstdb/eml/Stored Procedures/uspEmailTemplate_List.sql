
CREATE PROCEDURE eml.uspEmailTemplate_List
AS
/*	==========================================================================================
	Purpose: 	Get list from eml.tblEmailTemplate.

	06-02-2020	Jaap van Assenbergh	Inital version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		TemplateID,
		Template,
		BodyHeader,
		BodyMessage,
		BodyFooter,
		TemplateSubject,
		ProcedureName
FROM	eml.tblEmailTemplate
ORDER BY Template

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== eml.uspEmailTemplate_List =============================================================	*/
