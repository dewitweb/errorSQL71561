
CREATE PROCEDURE [sub].[uspDeclaration_Partition_Voucher_List]
@DeclarationID	int,
@PartitionID	int = NULL
AS
/*	==========================================================================================
	Purpose:	List all voucher data from sub.tblDeclaration_Partition_Voucher 
				on the basis of DeclarationID (optionally PartitionID).

	03-05-2019	Sander van Houten		OTIBSUB-1046	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		DeclarationID,
		EmployeeNumber,
		VoucherNumber,
		DeclarationValue
FROM	sub.tblDeclaration_Partition_Voucher
WHERE	DeclarationID = @DeclarationID
  AND	PartitionID = COALESCE(@PartitionID, PartitionID)
ORDER BY 
		EmployeeNumber,
		VoucherNumber

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Partition_Partition_Voucher_List ===================================	*/
