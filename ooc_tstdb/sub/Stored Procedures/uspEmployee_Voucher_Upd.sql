
CREATE PROCEDURE [sub].[uspEmployee_Voucher_Upd]
@EmployeeNumber	varchar(8),
@VoucherNumber	varchar(3),
@GrantDate		date,
@ValidityDate	date,
@VoucherValue	decimal(19,4),
@AmountUsed		decimal(19,4),
@ERT_Code		varchar(3),
@EventName		varchar(100),
@EventCity		varchar(100),
@Active			bit,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose:	Update sub.tblEmployee_Voucher on the basis of EmployeeNumber and VoucherNumber.

	27-11-2018	Sander van Houten		Added EventName and EventCity (OTIBSUB-182).
	13-11-2018	Sander van Houten		Altered tblVoucher_Employee to tblEmployee_Voucher.
	02-08-2018	Jaap van Assenbergh		CurrentUserID added.
	19-07-2018	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel	xml,
		@XMLins	xml,
		@LogDate datetime = GETDATE(),
		@KeyID		varchar(50)

IF (SELECT	COUNT(VoucherNumber)
	FROM	sub.tblEmployee_Voucher
	WHERE	EmployeeNumber = @EmployeeNumber
	  AND	VoucherNumber = @VoucherNumber) = 0
BEGIN
	-- Add new record
	INSERT INTO sub.tblEmployee_Voucher
		(
			EmployeeNumber,
			VoucherNumber,
			GrantDate,
			ValidityDate,
			VoucherValue,
			AmountUsed,
			ERT_Code,
			EventName,
			EventCity,
			Active
		)
	VALUES
		(
			@EmployeeNumber,
			@VoucherNumber,
			@GrantDate,
			@ValidityDate,
			@VoucherValue,
			@AmountUsed,
			@ERT_Code,
			@EventName,
			@EventCity,
			@Active
		)

	-- Save new record
	SELECT	@XMLdel = NULL,
			@XMLins = (SELECT	* 
					   FROM		sub.tblEmployee_Voucher 
					   WHERE	EmployeeNumber = @EmployeeNumber
					     AND	VoucherNumber = @VoucherNumber 
					   FOR XML PATH)
END
ELSE
BEGIN
	-- Save old record
	SELECT	@XMLdel = (SELECT	* 
					   FROM		sub.tblEmployee_Voucher 
					   WHERE	EmployeeNumber = @EmployeeNumber
					     AND	VoucherNumber = @VoucherNumber 
					   FOR XML PATH)

	-- Update exisiting record
	UPDATE	sub.tblEmployee_Voucher
	SET
			GrantDate		= @GrantDate,
			ValidityDate	= @ValidityDate,
			VoucherValue	= @VoucherValue,
			AmountUsed		= @AmountUsed,
			ERT_Code		= @ERT_Code,
			EventName		= @EventName,
			EventCity		= @EventCity,
			Active			= @Active
	WHERE	EmployeeNumber	= @EmployeeNumber
	  AND	VoucherNumber	= @VoucherNumber 

	-- Save new record
	SELECT	@XMLins = (SELECT	* 
					   FROM		sub.tblEmployee_Voucher 
					   WHERE	EmployeeNumber = @EmployeeNumber
					     AND	VoucherNumber = @VoucherNumber 
					   FOR XML PATH)
END

-- Log action in tblHistory
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @EmployeeNumber + '|' + @VoucherNumber

	EXEC his.uspHistory_Add
			'tblEmployee_Voucher',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployee_Voucher_Upd ============================================================	*/
