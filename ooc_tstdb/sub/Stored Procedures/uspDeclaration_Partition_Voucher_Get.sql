
CREATE PROCEDURE [sub].[uspDeclaration_Partition_Voucher_Get]
@DeclarationID	int,
@PartitionID	int,
@EmployeeNumber varchar(8),
@VoucherNumber	varchar(3)
AS
/*	==========================================================================================
	Purpose:	Get data from sub.tblDeclaration_Partition_Voucher 
				on the basis of DeclarationID, PartitionID, EmployeeNumber and VoucherNumber.

	03-05-2019	Sander van Houten		OTIBSUB-1046	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		DeclarationID,
		PartitionID,
		EmployeeNumber,
		VoucherNumber,
		DeclarationValue
FROM	sub.tblDeclaration_Partition_Voucher
WHERE	DeclarationID = @DeclarationID
  AND	PartitionID = @PartitionID
  AND	EmployeeNumber = @EmployeeNumber
  AND	VoucherNumber = @VoucherNumber

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== uspDeclaration_Partition_Voucher_Get ==================================================	*/
