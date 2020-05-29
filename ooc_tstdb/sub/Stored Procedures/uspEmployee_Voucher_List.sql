
CREATE PROCEDURE [sub].[uspEmployee_Voucher_List]
@EmployeeNumber	varchar(8)
AS
/*	==========================================================================================
	Purpose:	List all vouchers from tblEmployee_Voucher on the basis of EmployeeNumber.

	08-01-2020	Sander van Houten	OTIBSUB-1815    Show all vouchers, the front-end checks
                                        if the voucher is valid.
	28-11-2018	Sander van Houten	OTIBSUB-468     Added sync with Horus.
	13-11-2018	Sander van Houten	Altered tblVoucher_Employee to tblEmployee_Voucher.
	19-07-2018	Jaap van Assenbergh	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*  Testdata.
DECLARE @employeeNumber varchar(8) = '00671248'
--  */

DECLARE @RC int

EXECUTE @RC = [sub].[uspEmployee_SyncHorusVoucher] 
   @EmployeeNumber

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
WHERE 	EmployeeNumber = @EmployeeNumber

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployee_Voucher_List ==========================================================	*/
