
CREATE PROCEDURE [sub].[uspDeclaration_Partition_Voucher_Delete]
@DeclarationID	int,
@EmployeeNumber varchar(8),
@VoucherNumber	varchar(3),
@CurrentUserID	int = 1,
@PartitionID	int = NULL
AS
/*	==========================================================================================
	Purpose:	Remove link between voucher and declaration.

	10-09-2019	Jaap van Assenbergh		OTIBSUB-1553
										Voucherbedragen actualiseren bij terugboeken en 
										verwijderen van declaraties. 
	03-05-2019	Sander van Houten		OTIBSUB-1046	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE	@RC					int,
		@GrantDate			date,
		@ValidityDate		date,
		@VoucherValue		decimal(19,4),
		@AmountUsed			decimal(19,4),
		@ERT_Code			varchar(3),
		@EventName			varchar(100),
		@EventCity			varchar(100),
		@Active				bit

DECLARE @DeclarationValue	decimal(19,4)

DECLARE cur_Partition CURSOR FOR 
	SELECT 
			PartitionID,
			DeclarationValue
	FROM	sub.tblDeclaration_Partition_Voucher
	WHERE	DeclarationID = @DeclarationID
	  AND	PartitionID = COALESCE(@PartitionID, PartitionID)
		
OPEN cur_Partition

FETCH NEXT FROM cur_Partition INTO @PartitionID, @DeclarationValue

WHILE @@FETCH_STATUS = 0  
BEGIN
	-- First update the voucher.
	SELECT	@DeclarationValue = DeclarationValue
	FROM	sub.tblDeclaration_Partition_Voucher
	WHERE	DeclarationID = @DeclarationID
	  AND	PartitionID = @PartitionID
	  AND	EmployeeNumber = @EmployeeNumber
	  AND	VoucherNumber = @VoucherNumber 

	SELECT	@GrantDate = GrantDate,
			@ValidityDate = ValidityDate,
			@VoucherValue = VoucherValue,
			@AmountUsed = AmountUsed - @DeclarationValue,
			@ERT_Code = ERT_Code,
			@EventName = EventName,
			@EventCity = EventCity,
			@Active = 0
	FROM	sub.tblEmployee_Voucher
	WHERE	EmployeeNumber = @EmployeeNumber
	  AND	VoucherNumber = @VoucherNumber 

	EXECUTE @RC = [sub].[uspEmployee_Voucher_Upd] 
	   @EmployeeNumber
	  ,@VoucherNumber
	  ,@GrantDate
	  ,@ValidityDate
	  ,@VoucherValue
	  ,@AmountUsed
	  ,@ERT_Code
	  ,@EventName
	  ,@EventCity
	  ,@Active
	  ,@CurrentUserID

	-- Then delete the link itself.
	EXECUTE @RC = [sub].[uspDeclaration_Partition_Voucher_Del] 
		@DeclarationID,
		@PartitionID,
		@EmployeeNumber,
		@VoucherNumber,
		@CurrentUserID

	/* OTIBSUB-1553 Voucherbedragen actualiseren bij terugboeken en verwijderen van declaraties */
	UPDATE	hrs.tblVoucher
	SET		AmountUsed = AmountUsed - @DeclarationValue,
			AmountBalance = AmountBalance + @DeclarationValue
	WHERE	EmployeeNumber = @EmployeeNumber
	AND		VoucherNumber = @VoucherNumber	

	-- Update Horus. Voor synchroniseren Horus. 
	INSERT INTO hrs.tblVoucher_Used 
		(
			EmployeeNumber,
			EmployerNumber,
			ERT_Code,
			GrantDate,
			DeclarationID,
			VoucherNumber,
			AmountUsed,
			VoucherStatus
		)
	SELECT
			@EmployeeNumber,
			EmployerNumber,
			@ERT_Code,
			@GrantDate,
			@DeclarationID,
			@VoucherNumber,
			@DeclarationValue,
			'0000'
	FROM	sub.tblDeclaration
	WHERE	DeclarationID = @DeclarationID

	FETCH NEXT FROM cur_Partition INTO @PartitionID, @DeclarationValue
END

CLOSE cur_Partition
DEALLOCATE cur_Partition

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID
	
/*	== sub.uspDeclaration_Partition_Voucher_Del ==============================================	*/
