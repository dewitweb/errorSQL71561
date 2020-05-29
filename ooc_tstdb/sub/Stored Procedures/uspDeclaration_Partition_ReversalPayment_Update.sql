
CREATE PROCEDURE [sub].[uspDeclaration_Partition_ReversalPayment_Update]
@ReversalPaymentID			int,
@DeclarationID				int,
@PartitionID				int,
@tblEmployee 				sub.uttEmployee READONLY,
@ReversalPaymentReason		varchar(max),
@CurrentUserID				int = 1
AS
/*	==========================================================================================
	Purpose:	Update or Add declaration information for reversal payments 
				on bases of a ReversalPaymentID or a DeclarationID+PartitionID.

    Note:       This procedure is NOT being executed by the frontend application.
				
	08-11-2019	Sander van Houten	OTIBSUB-1539	DeclarationStatus 0016-> 0034.
	03-05-2019	Sander van Houten	OTIBSUB-1046	Move voucher use to partition level.
	21-02-2019	Sander van Houten	OTIBSUB-792		Initial version.
	==========================================================================================  */

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

DECLARE @RC							int,
		@EmployeeNumber				varchar(8),
		@VoucherNumber				varchar(3),
		@DeclarationValue			decimal(19,4),
		@Reversal					bit = 1,
		@PreviousReversalPaymentID	int = NULL,
		@EmployeeReversalPaymentID	int,
		@PaymentRunID				int = NULL

DECLARE @GrantDate date,
		@ValidityDate date,
		@VoucherValue decimal(19,4),
		@AmountUsed decimal(19,4),
		@ERT_Code varchar(3),
		@EventName varchar(100),
		@EventCity varchar(100),
		@Active bit

/*	First add a record in sub.tblDeclaration_Partition_ReversalPayment.	*/
IF (SELECT  1
    FROM    sub.tblDeclaration_Partition_ReversalPayment
    WHERE   ReversalPaymentID = @ReversalPaymentID
    AND     PartitionID = @PartitionID
   ) = 0
EXEC @RC = [sub].[uspDeclaration_Partition_ReversalPayment_Add] 
		   @ReversalPaymentID,
		   @PartitionID,
		   @CurrentUserID

/*	Then update all concerning employees and vouchers.	*/
DECLARE cur_Employee CURSOR FOR 
	SELECT 
			rep.EmployeeNumber,
			der.ReversalPaymentID	AS PreviousReversalPaymentID,
			dpv.VoucherNumber,
			dpv.DeclarationValue,
			CASE rep.ReversalPaymentID
				WHEN 0 THEN @ReversalPaymentID
				ELSE NULL
			END						AS NewReversalPaymentID
	FROM	@tblEmployee rep
	LEFT JOIN sub.tblDeclaration_Employee_ReversalPayment der
	ON		der.DeclarationID = @DeclarationID
	AND		der.EmployeeNumber = rep.EmployeeNumber
	AND		der.PartitionID = @PartitionID
	LEFT JOIN sub.tblDeclaration_Partition_Voucher dpv
	ON		dpv.DeclarationID = @DeclarationID
	AND		dpv.PartitionID = @PartitionID
	AND		dpv.EmployeeNumber = rep.EmployeeNumber

OPEN cur_Employee

FETCH NEXT FROM cur_Employee INTO @EmployeeNumber, @PreviousReversalPaymentID, @VoucherNumber, @DeclarationValue, @EmployeeReversalPaymentID

WHILE @@FETCH_STATUS = 0  
BEGIN
	/* Update employee(s).	*/
	-- Delete record ff ReversalPaymentID IS NULL and record exists in tblDeclaration_Employee_ReversalPayment.
	IF @EmployeeReversalPaymentID IS NULL
	BEGIN
		IF EXISTS (	SELECT	1 
					FROM	sub.tblDeclaration_Employee_ReversalPayment 
					WHERE	DeclarationID = @DeclarationID
					AND		EmployeeNumber = @EmployeeNumber
					AND		PartitionID = @PartitionID
				  )
		BEGIN
			EXEC @RC = [sub].[uspDeclaration_Employee_ReversalPayment_Del]
				@DeclarationID,
				@EmployeeNumber,
				@PartitionID,
				@CurrentUserID
		END
	END
	ELSE
	-- Otherwise insert or update the record.
	BEGIN
		EXEC @RC = [sub].[uspDeclaration_Employee_ReversalPayment_Upd]
			@DeclarationID,
			@EmployeeNumber,
			@PartitionID,
			@EmployeeReversalPaymentID,
			@CurrentUserID
	END

	/* Update the voucher used amount.	*/
	IF	(	@VoucherNumber IS NOT NULL
		AND	ISNULL(@PreviousReversalPaymentID, 0) <> ISNULL(@EmployeeReversalPaymentID, 0)
		)
	BEGIN
		SELECT	@GrantDate = GrantDate,
				@ValidityDate = ValidityDate,
				@VoucherValue = VoucherValue,
				@AmountUsed = CASE ISNULL(@EmployeeReversalPaymentID, 0)
								WHEN 0 THEN AmountUsed + @DeclarationValue
								ELSE AmountUsed - @DeclarationValue
							  END,
				@ERT_Code = ERT_Code,
				@EventName = EventName,
				@EventCity = EventCity,
				@Active = Active
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
	END

	FETCH NEXT FROM cur_Employee INTO @EmployeeNumber, @PreviousReversalPaymentID, @VoucherNumber, @DeclarationValue, @EmployeeReversalPaymentID
END

CLOSE cur_Employee
DEALLOCATE cur_Employee

/* Update DeclarationStatus of the declaration.	*/
-- Save old record.
SELECT	@XMLdel = (SELECT	* 
					FROM	sub.tblDeclaration 
					WHERE	DeclarationID = @DeclarationID
					FOR XML PATH)

-- Update exisiting record.
UPDATE	sub.tblDeclaration
SET
		DeclarationStatus = '0034',
		StatusReason = @ReversalPaymentReason
WHERE	DeclarationID	= @DeclarationID
  AND	DeclarationStatus <> '0034'

IF @@ROWCOUNT > 0
BEGIN
	-- Save new record.
	SELECT	@XMLins = (SELECT	* 
						FROM	sub.tblDeclaration 
						WHERE	DeclarationID = @DeclarationID
						FOR XML PATH)

	-- Log action in tblHistory.
	SET @KeyID = @DeclarationID

	EXEC his.uspHistory_Add
			'sub.tblDeclaration',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

/* Update DeclarationStatus of partition.	*/
-- Save old record.
SELECT	@XMLdel = (SELECT	* 
					FROM	sub.tblDeclaration_Partition
					WHERE	PartitionID = @PartitionID
					FOR XML PATH)

-- Update exisiting record.
UPDATE	sub.tblDeclaration_Partition
SET
		PartitionStatus	= '0016'
WHERE	PartitionID = @PartitionID

-- Save new record.
SELECT	@XMLins = (SELECT	* 
					FROM	sub.tblDeclaration_Partition
					WHERE	PartitionID = @PartitionID
					FOR XML PATH)

-- Log action in tblHistory.
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @PartitionID

	EXEC his.uspHistory_Add
			'sub.tblDeclaration_Partition',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Partition_ReversalPayment_Update ===================================	*/
