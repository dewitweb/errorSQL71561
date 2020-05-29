CREATE PROCEDURE [sub].[uspDeclaration_Partition_Voucher_Update]
@DeclarationID		int,
@EmployeeNumber		varchar(8),
@VoucherNumber		varchar(3),
@DeclarationValue	decimal(19,4),
@CurrentUserID		int = 1,
@PartitionID		int = NULL
AS
/*	==========================================================================================
	Purpose:	Add or Update record in sub.tblDeclaration_Partition_Voucher 
				on the basis of DeclarationID, Employeenumber and VoucherID.
				(Optionally PartitionID)

	13-06-2019	Sander van Houten		OTIBSUB-1199	Round DeclarationValue to two decimals.
	16-05-2019	Sander van Houten		OTIBSUB-1090	Update hrs.tblVoucher (for ONT and TST).
	03-05-2019	Sander van Houten		OTIBSUB-1046	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @RC							int,
		@PreviousDeclarationValue	decimal(19,4),
		@DeclarationStatus			varchar(4),
		@EmployerNumber				varchar(6)

-- Round the DeclarationValue to 2 decimals.
SET @DeclarationValue = CAST(@DeclarationValue AS decimal(19,2))

-- First get the declaration status at this moment plus the employernumber.
SELECT	@DeclarationStatus = decl.DeclarationStatus,
		@EmployerNumber = EmployerNumber
FROM	sub.tblDeclaration decl
WHERE	decl.DeclarationID = @DeclarationID

DECLARE cur_Partition CURSOR FOR 
	SELECT 
			dep.PartitionID,
			ISNULL(dpv.DeclarationValue, 0.00)
	FROM	sub.tblDeclaration_Partition dep
	LEFT JOIN sub.tblDeclaration_Partition_Voucher dpv 
	ON		dpv.DeclarationID = dep.DeclarationID
	AND		dpv.PartitionID = dep.PartitionID
	AND		dpv.EmployeeNumber = @EmployeeNumber
	AND		dpv.VoucherNumber = @VoucherNumber 
	WHERE	dep.DeclarationID = @DeclarationID
	  AND	dep.PartitionID = @PartitionID

	UNION
	
	SELECT 
			dfp.FirstPartition	AS PartitionID,
			ISNULL(dpv.DeclarationValue, 0.00)
	FROM	sub.viewDeclaration_FirstPartition dfp
	LEFT JOIN sub.tblDeclaration_Partition_Voucher dpv
	ON		dpv.DeclarationID = dfp.DeclarationID
	AND		dpv.PartitionID = dfp.FirstPartition
	AND		dpv.EmployeeNumber = @EmployeeNumber
	AND		dpv.VoucherNumber = @VoucherNumber 
	WHERE	dfp.DeclarationID = @DeclarationID
	  AND	(@PartitionID IS NULL OR dfp.FirstPartition = @PartitionID)
		
OPEN cur_Partition

FETCH NEXT FROM cur_Partition INTO @PartitionID, @PreviousDeclarationValue

WHILE @@FETCH_STATUS = 0  
BEGIN
	-- Add or update the declaration-voucher link.
	EXECUTE @RC = [sub].[uspDeclaration_Partition_Voucher_Upd] 
		@DeclarationID,
		@PartitionID,
		@EmployeeNumber,
		@VoucherNumber,
		@DeclarationValue,
		@CurrentUserID

	-- Update the voucher used amount.
	DECLARE @GrantDate date,
			@ValidityDate date,
			@VoucherValue decimal(19,4),
			@AmountUsed decimal(19,4),
			@ERT_Code varchar(3),
			@EventName varchar(100),
			@EventCity varchar(100),
			@Active bit

	SELECT	@GrantDate = GrantDate,
			@ValidityDate = ValidityDate,
			@VoucherValue = VoucherValue,
			@AmountUsed = CASE @DeclarationStatus
							WHEN '0001' THEN AmountUsed + (@DeclarationValue - @PreviousDeclarationValue)
							WHEN '0002' THEN AmountUsed + (@DeclarationValue - @PreviousDeclarationValue)
							ELSE AmountUsed - @DeclarationValue
						  END,
			@ERT_Code = ERT_Code,
			@EventName = EventName,
			@EventCity = EventCity,
			@Active = 1
	FROM	sub.tblEmployee_Voucher
	WHERE	EmployeeNumber = @EmployeeNumber
	AND		VoucherNumber = @VoucherNumber

	IF @@ROWCOUNT = 0
	BEGIN
		SELECT	@GrantDate = ValidFromDate,
				@ValidityDate = ValidUntilDate,
				@VoucherValue = AmountTotal,
				@AmountUsed = AmountUsed,
				@ERT_Code = ERT_Code,
				@EventName = ProjectDescription,
				@EventCity = City,
				@Active = 1
		FROM	hrs.tblVoucher
		WHERE	EmployeeNumber = @EmployeeNumber
		AND		VoucherNumber = @VoucherNumber	
	END

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

	/*	Update Horus.	*/
	-- Add correction record if necessary
	IF @PreviousDeclarationValue <> 0
	BEGIN
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
		VALUES 
			(
				@EmployeeNumber,
				@EmployerNumber,
				@ERT_Code,
				@GrantDate,
				@DeclarationID,
				@VoucherNumber,
				@DeclarationValue,
				'0000'
			)
	END

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
	VALUES 
		(
			@EmployeeNumber,
			@EmployerNumber,
			@ERT_Code,
			@GrantDate,
			@DeclarationID,
			@VoucherNumber,
			@DeclarationValue,
			'0002'
		)

	-- Update hrs.tblVoucher (OTIBSUB-1090).
	UPDATE	hrs.tblVoucher
	SET		AmountUsed = @AmountUsed,
			AmountBalance = AmountTotal - @AmountUsed,
			Active = 'J'
	WHERE	EmployeeNumber = @EmployeeNumber
	AND		VoucherNumber = @VoucherNumber	


	FETCH NEXT FROM cur_Partition INTO @PartitionID, @DeclarationValue
END

CLOSE cur_Partition
DEALLOCATE cur_Partition

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Partition_Voucher_Update ===========================================	*/
