
CREATE PROCEDURE [sub].[uspEmployer_List_ActiveVouchers]
@EmployerNumber varchar(6)
AS
/*	==========================================================================================
	Purpose:	List all acive voucherdata of employee(s) at an employer.

	11-11-2019	Jaap van Assenbergh		OTIBSUB-1678	Waardebonnen worden niet getoond van 
										dochter-werknemers
	28-10-2019	Jaap van Assenbergh		OTIBSUB-1650 Werknemer uit dienst niet tonen in 
										waardebonnenoverzicht
	25-09-2019	Sander van Houten		OTIBSUB-1493		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @GetDate	date = GETDATE()

SELECT	evo.EmployeeNumber,
		evo.VoucherNumber,
		evo.GrantDate,
		evo.EventName,
		emp.FullName + ' (' + CONVERT(varchar(10), emp.DateOfBirth, 105) + ')'	AS Employee,
		evo.ValidityDate,
		CAST(YEAR(evo.ValidityDate) AS char(4))									AS VoucherYear,
		evo.AmountBalance
FROM	sub.tblEmployer_Employee eme
INNER JOIN sub.tblEmployee_Voucher evo ON evo.EmployeeNumber = eme.EmployeeNumber
INNER JOIN sub.tblEmployee emp ON emp.EmployeeNumber = eme.EmployeeNumber
WHERE	eme.EmployerNumber = @EmployerNumber
AND		evo.ValidityDate >= @GetDate
AND		@GetDate BETWEEN eme.StartDate AND ISNULL(eme.EndDate, @GetDate)
AND		evo.AmountBalance <> 0.00

UNION ALL

SELECT	evo.EmployeeNumber,
		evo.VoucherNumber,
		evo.GrantDate,
		evo.EventName,
		emp.FullName + ' (' + CONVERT(varchar(10), emp.DateOfBirth, 105) + ')'	AS Employee,
		evo.ValidityDate,
		CAST(YEAR(evo.ValidityDate) AS char(4))									AS VoucherYear,
		evo.AmountBalance
FROM	sub.tblEmployer_Employee eme
INNER JOIN sub.tblEmployee_Voucher evo ON evo.EmployeeNumber = eme.EmployeeNumber
INNER JOIN sub.tblEmployee emp ON emp.EmployeeNumber = eme.EmployeeNumber
INNER JOIN sub.tblEmployer_ParentChild epc ON epc.EmployerNumberChild = eme.EmployerNumber
WHERE	epc.EmployerNumberParent = @EmployerNumber
AND		evo.ValidityDate >= @GetDate
AND		@GetDate BETWEEN eme.StartDate AND ISNULL(eme.EndDate, @GetDate)
AND		evo.AmountBalance <> 0.00


EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployer_List_ActiveVouchers ===================================================	*/
