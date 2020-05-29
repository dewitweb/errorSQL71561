
CREATE PROCEDURE eml.uspEmailTemplate_Get
@TemplateID	int
AS
/*	==========================================================================================
	Purpose: 	Get data from eml.tblEmailTemplate on basis of TemplateID.

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
WHERE	TemplateID = @TemplateID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== uspEmailTemplate_Get ==================================================================	*/
