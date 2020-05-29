
CREATE PROCEDURE [sub].[uspDeclaration_Employee_Get]
	@DeclarationID	int,
	@EmployeeNumber	varchar(8)
AS
/*	==========================================================================================
	19-07-2018	Jaap van Assenbergh
				Ophalen gegevens uit sub.tblDeclaration_Employee op basis van DeclarationID
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

	SELECT
			DeclarationID,
			EmployeeNumber,
			ReversalPaymentID
	FROM	sub.tblDeclaration_Employee
	WHERE	DeclarationID = @DeclarationID
	AND		EmployeeNumber = @EmployeeNumber

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== uspDeclaration_Employee_Get ============================================================	*/
