
CREATE PROCEDURE [sub].[uspCheckOnIBANChanges]
AS
/*	==========================================================================================
	Purpose:	Implement IBAN change in sub.tblEmployer and pass it through to Horus.

	Notes:		This procedure is executed once a day by a SQL Server Agent Job.

	05-03-2019	Sander van Houten		Initial version (OTIBSUB-817).
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @EmployerNumber	varchar(6),
		@IBAN_New		varchar(34),
		@IBANChangeID	int

DECLARE @SQL			varchar(max),
		@Result			varchar(8000)

DECLARE cur_Changes CURSOR FOR 
	SELECT	EmployerNumber,
			IBAN_New,
			IBANChangeID
	FROM sub.tblEmployer_IBAN_Change
	WHERE ChangeStatus = '0004'
	  AND StartDate <= CAST(GETDATE() AS date)
	  AND ChangeExecutedOn IS NULL
		
OPEN cur_Changes

FETCH NEXT FROM cur_Changes INTO @EmployerNumber, @IBAN_New, @IBANChangeID

WHILE @@FETCH_STATUS = 0  
BEGIN
	-- Update IBAN in OTIB-DS.
	UPDATE	sub.tblEmployer
	SET		IBAN = @IBAN_New
	WHERE	EmployerNumber = @EmployerNumber

	IF EXISTS(SELECT 1 FROM sys.servers WHERE NAME = N'HORUS_P')
	BEGIN	
		-- Update IBAN in Horus.
		SET	@SQL = 'BEGIN ? :=OLCOWNER.HRS_PCK_OTIBDS.WGR_WIJZIG_IBAN('
					+ '''' + @EmployerNumber + ''', '
					+ '''' + @IBAN_New + ''''
					+ '); END;'

		IF DB_NAME() = 'OTIBDS'
			EXEC(@SQL, @Result OUTPUT) AT HORUS_P
		ELSE
			EXEC(@SQL, @Result OUTPUT) AT HORUS_A

		UPDATE	sub.tblEmployer_IBAN_Change
		SET		HorusUpdateStatus = @Result
		WHERE	IBANChangeID = @IBANChangeID
	END

	UPDATE	sub.tblEmployer_IBAN_Change
	SET		ChangeExecutedOn = GETDATE()
	WHERE	IBANChangeID = @IBANChangeID

	FETCH NEXT FROM cur_Changes INTO @EmployerNumber, @IBAN_New, @IBANChangeID
END

CLOSE cur_Changes
DEALLOCATE cur_Changes

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspCheckOnIBANChanges =============================================================	*/