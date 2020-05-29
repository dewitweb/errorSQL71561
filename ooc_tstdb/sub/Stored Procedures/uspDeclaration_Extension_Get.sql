CREATE PROCEDURE [sub].[uspDeclaration_Extension_Get]
@ExtensionID	int
AS
/*	==========================================================================================
	Purpose: 	Get data from sub.tblDeclaration_Extension on basis of ExtensionID.

	01-05-2019	Sander van Houten	OTIBSUB-1007	Inital version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		ExtensionID,
		DeclarationID,
		StartDate,
		EndDate,
		InstituteID
FROM	sub.tblDeclaration_Extension
WHERE	ExtensionID = @ExtensionID
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== uspDeclaration_Extension_Get ==========================================================	*/
