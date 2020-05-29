
CREATE PROCEDURE [sub].[uspEmployee_Voucher_Get]
@EmployeeNumber	varchar(8),
@VoucherNumber	varchar(3)
AS
/*	==========================================================================================
	Purpose:	Get data from tblEmployee_Voucher on the basis of EmployeeNumber and VoucherNumber.

	13-11-2018	Sander van Houten		Altered tblVoucher_Employee to tblEmployee_Voucher.
	19-07-2018	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

	SELECT
			EmployeeNumber,
			VoucherNumber,
			GrantDate,
			ValidityDate,
			VoucherValue,
			AmountUsed,
			AmountBalance,
			ERT_Code,
			EventName,
			EventCity,
			Active
	FROM	sub.tblEmployee_Voucher
	WHERE	EmployeeNumber = @EmployeeNumber
	  AND	VoucherNumber = @VoucherNumber

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== uspEmployee_Voucher_Get ===============================================================	*/
