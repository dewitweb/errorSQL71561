
CREATE PROCEDURE [hrs].[uspSynchronizeVoucherData]
AS
/*	==========================================================================================
	Purpose:	Synchronize all voucher data to Horus.

	28-11-2018	Sander van Houten		Initial version.
	==========================================================================================	*/

--DECLARE @ExecutedProcedureID int = 0
--EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/* Only if the linked server exists.	*/
IF EXISTS(SELECT 1 FROM sys.servers WHERE NAME = N'HORUS_P')
BEGIN
	DECLARE @SQL	varchar(max),
			@Result	varchar(8000)

	DECLARE @RecordID		int,
			@VoucherStatus	varchar(4)

	DECLARE cur_Voucher CURSOR FOR 
		SELECT	RecordID
		FROM	hrs.tblVoucher_Used
		WHERE   ResultFromHorus IS NULL
		AND		VoucherStatus IN ('0000', '0002', '0010', '0011', '0016', '0017')
		ORDER BY RecordID

	-- Loop through queue table.
	OPEN cur_Voucher

	FETCH NEXT FROM cur_Voucher INTO @RecordID

	WHILE @@FETCH_STATUS = 0  
	BEGIN
		SELECT	@SQL = 'BEGIN ? :=OLCOWNER.HRS_PCK_WAARDEBON.'
						+ CASE VoucherStatus
							WHEN '0000' THEN 'VRIJGEVEN'	--Verwijderd
							WHEN '0002' THEN 'RESERVEER'	--Ingediend
							WHEN '0010' THEN 'BENUT'		--Uitbetaald
							WHEN '0011' THEN 'BENUT'		--Uitbetaald
							WHEN '0016' THEN 'VRIJGEVEN'	--Teruggeboekt
							WHEN '0017' THEN 'VRIJGEVEN'	--Definitief afgekeurd
							END
						+ '(''' + EmployeeNumber + ''', '
						+ '''' + EmployerNumber + ''', '
						+ '''' + ERT_Code + ''', '
						+ 'TO_DATE(''' + REPLACE(CONVERT(varchar(10), GrantDate, 102), '.', '-') + ''', ''YYYY-MM-DD''), '
						+ CAST(DeclarationID AS varchar(18)) + ', '
						+ CAST(CAST(AmountUsed AS decimal(19,2)) AS varchar(20))
						+ '); END;',
				@VoucherStatus = VoucherStatus
		FROM	hrs.tblVoucher_Used
		WHERE	RecordID = @RecordID

		IF DB_NAME() = 'OTIBDS'
			EXEC(@SQL,  @Result OUTPUT) AT HORUS_P
		ELSE
			EXEC(@SQL,  @Result OUTPUT) AT HORUS_A
	
		-- Remove processed record from queue table.
		IF @Result LIKE '%<resultaat>succes</resultaat>%'
		BEGIN
			DELETE FROM hrs.tblVoucher_Used WHERE RecordID = @RecordID
		END
		ELSE
		BEGIN
			UPDATE hrs.tblVoucher_Used SET ResultFromHorus = @Result WHERE RecordID = @RecordID
		END

		FETCH NEXT FROM cur_Voucher INTO @RecordID
	END

	CLOSE cur_Voucher
	DEALLOCATE cur_Voucher
END

--EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== hrs.uspSynchronizeVoucherData =========================================================	*/
