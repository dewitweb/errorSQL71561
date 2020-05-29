
CREATE PROCEDURE [sub].[usp_RepServ_06_DeclarationsEVC]
	@SubsidyYear int 
AS

/*	==========================================================================================
	Purpose: 	Source for EVC declaration list in SSRS.

	03-07-2019	Jaap van Assenbergh	Inital version (OTIBSUB-1312).
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Select the resultset. */
SELECT	decl.DeclarationID,
		decl.QualificationLevel,
		decl.QualificationLevelLevelName,
		decl.DeclarationAmount,
		decl.PartitionAmount
FROM	evc.viewDeclaration decl
WHERE	decl.DeclarationStatus IN ('0012', '0013', '0014', '0015')
AND		YEAR(decl.PaymentDate) = @SubsidyYear
ORDER BY QualificationLevelLevelName

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.usp_RepServ_06_DeclarationsEVC ================================================	*/
