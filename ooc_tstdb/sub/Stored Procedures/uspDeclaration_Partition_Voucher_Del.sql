
CREATE PROCEDURE [sub].[uspDeclaration_Partition_Voucher_Del]
@DeclarationID	int,
@PartitionID	int,
@EmployeeNumber varchar(8),
@VoucherNumber	varchar(3),
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose:	Remove link between voucher and declaration_partition.

	03-05-2019	Sander van Houten		OTIBSUB-1046	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

-- Save old record.
SELECT	@XMLdel = (SELECT	* 
				   FROM		sub.tblDeclaration_Partition_Voucher
				   WHERE	DeclarationID = @DeclarationID
					 AND	PartitionID = @PartitionID
				     AND	EmployeeNumber = @EmployeeNumber
					 AND	VoucherNumber = @VoucherNumber 
				   FOR XML PATH),
		@XMLins = NULL

-- Delete record.
DELETE
FROM	sub.tblDeclaration_Partition_Voucher
WHERE	DeclarationID = @DeclarationID
  AND	PartitionID = @PartitionID
  AND	EmployeeNumber = @EmployeeNumber
  AND	VoucherNumber = @VoucherNumber

-- Log action in tblHistory.
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = CAST(@DeclarationID AS varchar(18)) + '|' + CAST(@PartitionID AS varchar(18)) + '|' + @EmployeeNumber + '|' + @VoucherNumber

	EXEC his.uspHistory_Add
			'sub.tblDeclaration_Partition_Voucher',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Partition_Voucher_Del ==============================================	*/
