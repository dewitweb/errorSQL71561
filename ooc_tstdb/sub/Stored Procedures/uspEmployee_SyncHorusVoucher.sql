
CREATE PROCEDURE [sub].[uspEmployee_SyncHorusVoucher]
@EmployeeNumber		varchar(8)
AS
/*	==========================================================================================
	Purpose:	List all voucherdata from Horus for an employee.

	06-12-2019	Sander van Houten		OTIBSUB-564     Added WHERE clause to Horus query.
	11-12-2018	Jaap van Assenbergh		OTIBSUB-564     Error in sub.uspEmployee_Voucher_List (PRD).
	22-11-2018	Sander van Houten		Initial version (OTIBSUB-149).
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @tblVoucher TABLE (
	EmployeeNumber		varchar(8) NOT NULL,
	VoucherNumber		varchar(4) NOT NULL,
	ValidFromDate		varchar(10) NOT NULL,
	ValidUntilDate		varchar(10) NOT NULL,
	AmountTotal			decimal(19, 4) NOT NULL,
	AmountUsed			decimal(19, 4) NOT NULL,
	AmountBalance		decimal(19, 4) NOT NULL,
	ProjectDescription	varchar(100) NOT NULL,
	ERT_Code			varchar(3) NOT NULL,
	City				varchar(100) NOT NULL,
	Active				varchar(1) NOT NULL )

/*	Check if a linked server to Horus exists.	*/
IF EXISTS(SELECT 1 FROM sys.servers WHERE NAME = N'HORUS_P')
BEGIN
/* Get all vouchers for the employee from Horus.	*/
	DECLARE @SQL	varchar(max)

	DECLARE @tblHorusVoucher TABLE (XMLValue xml)

	SET @SQL = 'SELECT OLCOWNER.HRS_PCK_WAARDEBON.TOON_BONNEN('''+ @EmployeeNumber + ''') FROM DUAL'

	IF DB_NAME() = 'OTIBDS_Acceptatie'
    BEGIN
		SET @SQL = 'SELECT * FROM OPENQUERY(HORUS_A, ''' + REPLACE(@SQL, '''', '''''') + ''')'
    END
	ELSE
    BEGIN
		SET @SQL = 'SELECT * FROM OPENQUERY(HORUS_P, ''' + REPLACE(@SQL, '''', '''''') + ''')'
    END
	
	INSERT INTO @tblHorusVoucher (XMLValue)
	EXEC(@SQL)

	IF (SELECT	CAST(x.r.query('aantal/text()') AS varchar(100)) AS AantalBonnen
		FROM	@tblHorusVoucher
		CROSS APPLY XMLValue.nodes('/waardebon.toon_bonnen') AS x(r)
	   ) <> '0'
    BEGIN
        INSERT INTO @tblVoucher (
                EmployeeNumber,
                VoucherNumber,
                ValidFromDate,
                ValidUntilDate,
                AmountTotal,
                AmountUsed,
                AmountBalance,
                ProjectDescription,
                ERT_Code,
                City,
                Active )
        SELECT	
                @EmployeeNumber,
                CAST(x.r.query('boncode/text()') AS varchar(100))				AS VoucherNumber,
                CAST(x.r.query('geldig_vanaf/text()') AS varchar(100))			AS ValidFromDate,
                CAST(x.r.query('geldig_totenmet/text()') AS varchar(100))		AS ValidUntilDate,
                CAST(x.r.query('waarde/text()') AS varchar(100))				AS AmountTotal,
                CAST(x.r.query('benut/text()') AS varchar(100))					AS AmountUsed,
                CAST(x.r.query('saldo/text()') AS varchar(100))					AS AmountBalance,
                CAST(x.r.query('omschrijvingproject/text()') AS varchar(100))	AS ProjectDescription,
                CAST(x.r.query('ert_code/text()') AS varchar(100))				AS ERT_Code,
                CAST(x.r.query('plaats/text()') AS varchar(100))				AS City,
                CAST(x.r.query('actief/text()') AS varchar(100))				AS Active
        FROM	@tblHorusVoucher
        CROSS APPLY XMLValue.nodes('/waardebon.toon_bonnen/bon') AS x(r)

        /* Remove nonusable vouchers.	*/
        DELETE 
        FROM    @tblVoucher
        WHERE   COALESCE(VoucherNumber, '') = ''
        OR      SUBSTRING(EmployeeNumber, 1, 1) = '-'
        OR      ValidUntilDate < '20190101'
    END
END
ELSE
BEGIN
	INSERT INTO @tblVoucher (
			EmployeeNumber,
			VoucherNumber,
			ValidFromDate,
			ValidUntilDate,
			AmountTotal,
			AmountUsed,
			AmountBalance,
			ProjectDescription,
			ERT_Code,
			City,
			Active )
	SELECT	
			@EmployeeNumber,
			vou.VoucherNumber,
			vou.ValidFromDate,
			vou.ValidUntilDate,
			vou.AmountTotal,
			vou.AmountUsed,
			vou.AmountBalance,
			vou.ProjectDescription,
			vou.ERT_Code,
			vou.City,
			vou.Active
	FROM	hrs.tblVoucher vou
	WHERE	vou.EmployeeNumber = @EmployeeNumber
END

/* Update existing vouchers.	*/
UPDATE	emv
SET		emv.GrantDate = CAST(vou.ValidFromDate AS date),
		emv.ValidityDate = CAST(vou.ValidUntilDate AS date),
		emv.VoucherValue = vou.AmountTotal,
		emv.AmountUsed = vou.AmountUsed,
		emv.ERT_Code = vou.ERT_Code,
		emv.EventName = vou.ProjectDescription,
		emv.EventCity = vou.City,
		emv.Active = CASE WHEN vou.Active = 'J' THEN 1 ELSE 0 END
FROM	@tblVoucher vou
INNER JOIN sub.tblEmployee_Voucher emv
ON		emv.EmployeeNumber = vou.EmployeeNumber
AND		emv.VoucherNumber = vou.VoucherNumber

/* Insert new vouchers.	*/
INSERT INTO [sub].[tblEmployee_Voucher]
		([EmployeeNumber]
		,[VoucherNumber]
		,[GrantDate]
		,[ValidityDate]
		,[VoucherValue]
		,[AmountUsed]
		,[ERT_Code]
		,[EventName]
		,[EventCity]
		,[Active])
SELECT	
		vou.EmployeeNumber,
		vou.VoucherNumber,
		CAST(vou.ValidFromDate AS date),
		CAST(vou.ValidUntilDate AS date),
		vou.AmountTotal,
		vou.AmountUsed,
		vou.ERT_Code,
		vou.ProjectDescription,
		vou.City,
		CASE WHEN vou.Active = 'J' THEN 1 ELSE 0 END
FROM	@tblVoucher vou
LEFT JOIN sub.tblEmployee_Voucher emv
ON		emv.EmployeeNumber = vou.EmployeeNumber
AND		emv.VoucherNumber = vou.VoucherNumber
WHERE	vou.EmployeeNumber = @EmployeeNumber
  AND	emv.EmployeeNumber IS NULL

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployee_SyncHorusVoucher ======================================================	*/
