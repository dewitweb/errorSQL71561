

CREATE PROCEDURE [sub].[uspDeclaration_Employee_ReversalPayment_List]
@DeclarationID	int,
@PartitionID	int
AS
/*	==========================================================================================
	Purpose:	List all data from tblDeclaration_Employee_ReversalPayment 
				for a declaration/partition.

	21-02-2019	Sander van Houten		OTIBSUB-792	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		der.DeclarationID,
		der.partitionID,
		der.EmployeeNumber,
		e.FullName AS EmployeeName,
		der.ReversalPaymentID
FROM	sub.tblDeclaration_Employee_ReversalPayment der
INNER JOIN sub.tblEmployee e ON e.EmployeeNumber = der.EmployeeNumber
WHERE	der.DeclarationID = @DeclarationID
  AND	der.PartitionID = @PartitionID
ORDER BY EmployeeNumber

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Employee_ReversalPayment_List ======================================	*/
