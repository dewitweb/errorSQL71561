
CREATE PROCEDURE [sub].[uspDeclaration_Employee_ReversalPayment_Get]
@DeclarationID	int,
@EmployeeNumber	varchar(8),
@PartitionID	int
AS
/*	==========================================================================================
	Purpose:	Get specific data from tblDeclaration_Employee_ReversalPayment.

	21-02-2019	Sander van Houten		OTIBSUB-792	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

	SELECT
			DeclarationID,
			EmployeeNumber,
			PartitionID,
			ReversalPaymentID
	FROM	sub.tblDeclaration_Employee_ReversalPayment
	WHERE	DeclarationID = @DeclarationID
	  AND	EmployeeNumber = @EmployeeNumber
	  AND	PartitionID = @PartitionID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== uspDeclaration_Employee_ReversalPayment_Get ===========================================	*/
