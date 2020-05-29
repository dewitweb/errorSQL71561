CREATE PROCEDURE [sub].[uspDeclaration_Extension_List]
@DeclarationID	int
AS
/*	==========================================================================================
	Purpose: 	Get list from sub.tblDeclaration_Extension on bases of a declarationID.

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
WHERE	DeclarationID = @DeclarationID
ORDER BY 
		DeclarationID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Extension_List =====================================================	*/
