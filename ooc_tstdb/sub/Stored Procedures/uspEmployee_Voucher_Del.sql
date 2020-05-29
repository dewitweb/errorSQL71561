
CREATE PROCEDURE [sub].[uspEmployee_Voucher_Del]
@EmployeeNumber	varchar(8),
@VoucherNumber	varchar(3),
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose:	Remove tblEmployee_Voucher record.

	13-11-2018	Sander van Houten		Altered tblVoucher_Employee to tblEmployee_Voucher.
	02-08-2018	Sander van Houten		CurrentUserID added.
	19-07-2018	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

-- Save old record
SELECT	@XMLdel = (SELECT	* 
					FROM	sub.tblEmployee_Voucher
					WHERE	EmployeeNumber = @EmployeeNumber
					  AND	VoucherNumber = @VoucherNumber 
					FOR XML PATH)

-- Delete record
DELETE
FROM	sub.tblEmployee_Voucher
WHERE	EmployeeNumber = @EmployeeNumber
  AND	VoucherNumber = @VoucherNumber 

-- Log action in tblHistory
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @EmployeeNumber + '|' + @VoucherNumber

	EXEC his.uspHistory_Add
			'sub.tblEmployee_Voucher',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			NULL
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployee_Voucher_Del ============================================================	*/
