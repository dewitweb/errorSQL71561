
CREATE PROCEDURE [sub].[uspDeclaration_Partition_Voucher_Upd]
@DeclarationID		int,
@PartitionID		int,
@EmployeeNumber		varchar(8),
@VoucherNumber		varchar(3),
@DeclarationValue	decimal(19,4),
@CurrentUserID		int = 1
AS
/*	==========================================================================================
	Purpose:	Add or Update record in sub.tblDeclaration_Partition_Voucher.

	03-05-2019	Sander van Houten		OTIBSUB-1046	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF (SELECT	COUNT(1)
	FROM	sub.tblDeclaration_Partition_Voucher
	WHERE	DeclarationID = @DeclarationID
	  AND	PartitionID = @PartitionID
	  AND	EmployeeNumber = @EmployeeNumber
	  AND	VoucherNumber = @VoucherNumber) = 0
BEGIN
	-- Add new record
	INSERT INTO sub.tblDeclaration_Partition_Voucher
		(
			DeclarationID,
			PartitionID,
			EmployeeNumber,
			VoucherNumber,
			DeclarationValue
		)
	VALUES
		(
			@DeclarationID,
			@PartitionID,
			@EmployeeNumber,
			@VoucherNumber,
			@DeclarationValue
		)

	-- Save new record
	SELECT	@XMLdel = NULL,
			@XMLins = (SELECT	* 
					   FROM		sub.tblDeclaration_Partition_Voucher 
					   WHERE	DeclarationID = @DeclarationID
					     AND	PartitionID = @PartitionID
						 AND	EmployeeNumber = @EmployeeNumber
						 AND	VoucherNumber = @VoucherNumber 
					   FOR XML PATH)
END
ELSE
BEGIN
	-- Save old record
	SELECT	@XMLdel = (SELECT	* 
					   FROM		sub.tblDeclaration_Partition_Voucher 
					   WHERE	DeclarationID = @DeclarationID
					     AND	PartitionID = @PartitionID
						 AND	EmployeeNumber = @EmployeeNumber
						 AND	VoucherNumber = @VoucherNumber 
					   FOR XML PATH)

	-- Update exisiting record
	UPDATE	sub.tblDeclaration_Partition_Voucher
	SET
			DeclarationValue = @DeclarationValue
	WHERE	DeclarationID = @DeclarationID
	  AND	PartitionID = @PartitionID
	  AND	EmployeeNumber = @EmployeeNumber
	  AND	VoucherNumber = @VoucherNumber

	-- Save new record
	SELECT	@XMLins = (SELECT	* 
					   FROM		sub.tblDeclaration_Partition_Voucher 
					   WHERE	DeclarationID = @DeclarationID
					     AND	PartitionID = @PartitionID
						 AND	EmployeeNumber = @EmployeeNumber
						 AND	VoucherNumber = @VoucherNumber 
					   FOR XML PATH)
END

-- Log action in tblHistory
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = CAST(@DeclarationID AS varchar(18)) + '|' + CAST(@PartitionID AS varchar(18)) 
				 + '|' + @EmployeeNumber + '|' + @VoucherNumber

	EXEC his.uspHistory_Add
			'sub.tblDeclaration_Partition_Voucher',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Partition_Voucher_Upd ==============================================	*/
