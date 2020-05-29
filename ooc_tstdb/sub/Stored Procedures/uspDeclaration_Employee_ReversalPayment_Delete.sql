CREATE PROCEDURE [sub].[uspDeclaration_Employee_ReversalPayment_Delete]
@DeclarationID	int,
@EmployeeNumber	varchar(8),
@PartitionID	int,
@CurrentUserID	int = 1
AS

/*	==========================================================================================
	Purpose:	Remove Declaration_Employee_ReversalPayment 
				and Declaration_Partition_Voucher record.

	08-05-2019	Sander van Houten		OTIBSUB-1046	Move vouchers to partition level.
	21-02-2019	Sander van Houten		OTIBSUB-792		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @RC int,
		@VoucherNumber varchar(3)

-- First delete record(s) from tblDeclaration_Partition_Voucher.
DECLARE cur_Voucher CURSOR FOR 
	SELECT 
			VoucherNumber
	FROM	sub.tblDeclaration_Partition_Voucher
	WHERE	DeclarationID = @DeclarationID
	  AND	PartitionID = @PartitionID
	  AND	EmployeeNumber = @EmployeeNumber

OPEN cur_Voucher

FETCH NEXT FROM cur_Voucher INTO @VoucherNumber

WHILE @@FETCH_STATUS = 0  
BEGIN
	EXEC @RC = [sub].[uspDeclaration_Partition_Voucher_Delete] 
	   @DeclarationID
	  ,@EmployeeNumber
	  ,@VoucherNumber
	  ,@CurrentUserID
	  ,@PartitionID

	FETCH NEXT FROM cur_Voucher INTO @VoucherNumber
END

CLOSE cur_Voucher
DEALLOCATE cur_Voucher

-- Then delete record from tblDeclaration_Employee.
EXEC @RC = [sub].[uspDeclaration_Employee_ReversalPayment_Del] 
   @DeclarationID
  ,@EmployeeNumber
  ,@PartitionID
  ,@CurrentUserID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Employee_ReversalPayment_Delete ====================================	*/
