

CREATE PROCEDURE [hrs].[uspHorusVoucher_Imp]
AS
/*	==========================================================================================
	Purpose:	Import all Voucher data from Horus.

	11-02-2020	Jaap van Assenbergh	OTIBSUB-1900	Geldigheidsduur onjuist van Waardebonnen
										50+ en 60+
	05-11-2019	Sander van Houten	OTIBSUB-1673    Do not import vouchers into DS table which 
                                        have a vouchernumber containing more than 6 characters
                                        and the extra field GERESERVEERD is added.
                                        The value of GERESERVEERD is included in the value of BENUT.
	04-11-2019	Sander van Houten	OTIBSUB-1673    Do not import vouchers into DS table which 
                                        have a vouchernumber containing more than 3 characters.
	23-10-2019	Sander van Houten	OTIBSUB-1640    Transfer missing voucher(s) to DS-table.
	13-12-2018	Sander van Houten	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

IF EXISTS ( SELECT TOP (1) 1 FROM sys.servers WHERE [name] = 'HORUS_P' )
BEGIN
	DECLARE @SQL  varchar(max)

	SET @SQL = 'SELECT * FROM OLCOWNER.ods_vw_waardebonnen '
				+ 'WHERE BONCODE IS NOT NULL '
				+ 'AND SUBSTR(WNR_NUMMER, 1, 1) <> ''-'' '
				+ 'AND GELDIG_TM >= ''20190101'' '

	SET @SQL = 'SELECT DISTINCT WNR_NUMMER, BONCODE, GELDIG_VA, GELDIG_TM, BEDRAG, BENUT, '
                + 'GERESERVEERD, SALDO, OMSCHRIJVING, ERT_CODE, ISNULL(PLAATS, '''') AS PLAATS, ACTIEF '
				+ 'FROM OPENQUERY(HORUS_A, ''' + REPLACE(@SQL, '''', '''''') + ''') '
                + 'WHERE ISNUMERIC(WNR_NUMMER) = 1 '
	
	IF DB_NAME() = 'OTIBDS'
		SET @SQL = REPLACE(@SQL, 'HORUS_A', 'HORUS_P')

	-- First empty hrs.tblIBAN.
	DELETE FROM hrs.tblVoucher

	-- Then refill it.
	INSERT INTO hrs.tblVoucher
		(
			EmployeeNumber,
			VoucherNumber,
			ValidFromDate,
			ValidUntilDate,
			AmountTotal,
			AmountUsed,
            AmountReserved,
			AmountBalance,
			ProjectDescription,
			ERT_Code,
			City,
			Active
		)
	EXEC(@SQL)

	/*  DELETE unused vouchers with are not in Horus anymore.	OTIBSUB-1900	*/
	DELETE	ev
	FROM	sub.tblEmployee_Voucher ev
	LEFT JOIN hrs.tblVoucher v
			ON	v.EmployeeNumber = ev.EmployeeNumber
			AND	v.VoucherNumber = ev.VoucherNumber
			AND	v.ValidFromDate = ev.GrantDate
	WHERE	v.EmployeeNumber = NULL
	AND		NOT EXISTS
			(
				SELECT	dpv.DeclarationID 
				FROM	sub.tblDeclaration_Partition_Voucher dpv
				WHERE	dpv.EmployeeNumber = ev.EmployeeNumber
				AND		dpv.VoucherNumber = ev.VoucherNumber
			)

	/*  UPDATE excisting vouchers with an other ValidityDate	OTIBSUB-1900	*/
	UPDATE	ev
	SET		ev.ValidityDate = v.ValidUntilDate
	FROM	sub.tblEmployee_Voucher ev
	INNER JOIN hrs.tblVoucher v
			ON	v.EmployeeNumber = ev.EmployeeNumber
			AND	v.VoucherNumber = ev.VoucherNumber
			AND	v.ValidFromDate = ev.GrantDate
	WHERE	v.ValidUntilDate <> ev.ValidityDate

	-- Then correct the project descriptions (OTIBSUB-587).
	UPDATE	hrs.tblVoucher
	SET		ProjectDescription = CASE ProjectDescription
									WHEN '50+ Workshop' THEN 'Workshop 50+'
									WHEN '50+ Workshops' THEN 'Workshop 50+'
									WHEN '50+ workshop' THEN 'Workshop 50+'
									WHEN 'MasterClass' THEN 'Masterclass'
									WHEN 'Topstarters' THEN 'TopStarters'
									WHEN 'Topvakmanschapsdag' THEN 'TopVakmanschapsdag'
									ELSE ProjectDescription
								 END

    -- If there are new vouchers... transfer them to sub.tblEmployee_Voucher.
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
    FROM	hrs.tblVoucher vou
    INNER JOIN sub.tblEmployee emp
    ON      emp.EmployeeNumber = vou.EmployeeNumber
    LEFT JOIN sub.tblEmployee_Voucher emv
    ON		emv.EmployeeNumber = vou.EmployeeNumber
    AND		emv.VoucherNumber = vou.VoucherNumber
    WHERE	LEN(vou.VoucherNumber) <= 6
    AND     vou.AmountBalance <> 0.00
    AND     vou.ValidFromDate <= GETDATE()
    AND     vou.ValiduntilDate >= GETDATE()
    AND     emv.EmployeeNumber IS NULL
    ORDER BY 
            vou.EmployeeNumber,
            vou.VoucherNumber
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== hrs.uspHorusVoucher_Imp ===============================================================	*/
