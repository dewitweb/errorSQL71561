CREATE PROCEDURE [hrs].[uspHorusBPV_Imp]
AS
/*	==========================================================================================
	Purpose:	Import all BPV data from Horus.

	03-02-2020	Sander van Houten	OTIBSUB-1875	Filtered out the import of payments to employees.
	26-11-2019	Sander van Houten	OTIBSUB-1730	Added field TypeBPV.
	30-09-2019	Sander van Houten	OTIBSUB-1600	Changed import method from full to changes-only
										because of the size of the transaction log.
	20-09-2019	Jaap van Assenbergh	OTIBSUB-1584	Rebuild index on tblBPG and tblBPV_DTG
									    Added as step after this usp. Within the usp it doesn't work.
	05-09-2019	Sander van Houten	OTIBSUB-1535	Added update of declaration amount.
	12-07-2019	Sander van Houten	OTIBSUB-1176	Added payment data. 
	28-06-2019	Sander van Houten	OTIBSUB-1096	Added logging to ait.tblErrorLog. 
	14-05-2019	Sander van Houten	OTIBSUB-1096	Added #tblBPV and removed status filter.
	13-05-2019	Sander van Houten	OTIBSUB-1096	Duplicate key error / Added TRANSACTIONal import.
	27-11-2018	Sander van Houten	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Declare variables.	*/
DECLARE @SQL	varchar(max),
		@Error	bit = 0

DECLARE	@StartTimeStamp	datetime = GETDATE(),
		@TimeStamp		datetime = GETDATE()

CREATE TABLE #tblBPV 
	(
		EmployeeNumber varchar(8) NOT NULL,
		EmployerNumber varchar(6) NOT NULL,
		StartDate date NOT NULL,
		EndDate date NULL,
		CourseID int NOT NULL,
		CourseName varchar(200) NULL,
		StatusCode tinyint NULL,
		StatusDescription varchar(100) NULL,
		DSR_ID int NOT NULL,
        TypeBPV varchar(10) NULL
	)

CREATE TABLE #tblBPV_DTG
	(
		DSR_ID int NOT NULL,
		DTG_ID int NOT NULL,
		ReferenceDate date NOT NULL,
		PaymentStatus varchar(4) NULL,
		DTG_Status varchar(100) NULL,
		PaymentType varchar(3) NOT NULL,
		PaymentNumber tinyint NOT NULL,
		PaymentAmount numeric(18, 2) NULL,
		PaymentDate datetime NULL,
		AmountPaid numeric(18, 2) NULL,
		PaymentDateReversal datetime NULL,
		AmountReversed numeric(10, 2) NULL,
		LastPayment varchar(1) NULL,
		ReasonNotPaidShort varchar(10) NULL,
		ReasonNotPaidLong varchar(100) NULL
	)

/* Get all BPV data from Horus.	*/
BEGIN TRY
	/*	Log start of import.	*/
	INSERT INTO sub.tblImportLog
		(
			[Log],
			[TimeStamp],
			Duration
		)
	VALUES
		(
			'De import van BPV data vanuit Horus is gestart.',
			@StartTimeStamp,
			0
		)
	
	-- #tblBPV
	SET @TimeStamp = GETDATE()

	SET @SQL = 'SELECT DISTINCT * FROM OLCOWNER.HRS_VW_BPV '
				+ 'WHERE SUBSTR(WNR_NUMMER, 1, 1) <> ''-'' '
				+ 'AND STATUS NOT IN (3, 4) '

	SET @SQL = 'SELECT WNR_NUMMER, STARTDATUM, EINDDATUM, WGR_NUMMER, CREBO_NUMMER, '
				+ 'NAAM_OPLEIDING, STATUS, STATUSOMSCHRIJVING, DSR_ID, TYPEBPV '
				+ 'FROM OPENQUERY(HORUS_A, ''' + REPLACE(@SQL, '''', '''''') + ''')'

	IF DB_NAME() = 'OTIBDS'
		SET @SQL = REPLACE(@SQL, 'HORUS_A', 'HORUS_P')

	INSERT INTO #tblBPV
		(
			EmployeeNumber, 
			StartDate, 
			EndDate, 
			EmployerNumber, 
			CourseID, 
			CourseName, 
			StatusCode, 
			StatusDescription,
			DSR_ID,
            TypeBPV
		)
	EXEC(@SQL)

	INSERT INTO sub.tblImportLog
		(
			[Log],
			[TimeStamp],
			Duration
		)
	VALUES
		(
			'De import van BPV data naar de tijdelijke tabel is uitgevoerd.',
			GETDATE(),
			DATEDIFF(ss, @TimeStamp, GETDATE())
		)
	
	-- #tblBPV_DTG
	SET @TimeStamp = GETDATE()

	SET @SQL = 'SELECT * FROM OLCOWNER.HRS_VW_BPV_DTG '
				+ 'WHERE TYPE_VERGOEDING <> ''WNR'' '

	SET @SQL = 'SELECT [DSR_ID], [DTG_ID], [PEILDATUM], [UITKERINGSSTATUS], [DTG_STATUS], '
				+ '[TYPE_VERGOEDING], [VERGOEDINGS_NUMMER], [BEDRAG_REGISTRATIE], [DATUM_BPV_RUN], '
				+ '[BEDRAG_VERGOED], [DATUM_TERUGVORDERING], [BEDRAG_TERUGGEVORDERD], '
				+ '[IND_EINDVERGOEDING_JN], [REDEN_NIET_BETAALD], [OMSCHRIJVING_REDEN] '
				+ 'FROM OPENQUERY(HORUS_A, ''' + REPLACE(@SQL, '''', '''''') + ''')'

	IF DB_NAME() = 'OTIBDS'
		SET @SQL = REPLACE(@SQL, 'HORUS_A', 'HORUS_P')

	INSERT INTO #tblBPV_DTG
		(
			DSR_ID,
			DTG_ID,
			ReferenceDate,
			PaymentStatus,
			DTG_Status,
			PaymentType,
			PaymentNumber,
			PaymentAmount,
			PaymentDate,
			AmountPaid,
			PaymentDateReversal,
			AmountReversed,
			LastPayment,
			ReasonNotPaidShort,
			ReasonNotPaidLong
		)
	EXEC(@SQL)

	INSERT INTO sub.tblImportLog
		(
			[Log],
			[TimeStamp],
			Duration
		)
	VALUES
		(
			'De import van BPV_DTG data naar de tijdelijke tabel is uitgevoerd.',
			GETDATE(),
			DATEDIFF(ss, @TimeStamp, GETDATE())
		)
	
	-- Remove data from #tblBPV_DTG for which there is no BPV record (probably because of BPV status 3 or 4).
	SET @TimeStamp = GETDATE()

	DELETE	dtg
	FROM	#tblBPV_DTG dtg
	LEFT JOIN #tblBPV bpv
	ON		bpv.DSR_ID = dtg.DSR_ID
	WHERE	bpv.CourseID IS NULL

	INSERT INTO sub.tblImportLog
		(
			[Log],
			[TimeStamp],
			Duration
		)
	VALUES
		(
			'De overbodige data uit #tblBPV_DTG (BPV status 3 of 4) is verwijderd.',
			GETDATE(),
			DATEDIFF(ss, @TimeStamp, GETDATE())
		)
	
END TRY
BEGIN CATCH
	INSERT INTO [ait].[tblErrorLog]
		(
			ErrorDate,
			ErrorNumber,
			ErrorSeverity,
			ErrorState,
			ErrorProcedure,
			ErrorLine,
			ErrorMessage,
			SendEmail,
			EmailSent
		)
	SELECT  GETDATE()						AS ErrorDate,
			ERROR_NUMBER()					AS ErrorNumber,
			ERROR_SEVERITY()				AS ErrorSeverity,
			ERROR_STATE()					AS ErrorState,
			sch.[name] + '.' + sp.[name]	AS ErrorProcedure,
			ERROR_LINE()					AS ErrorLine,
			ERROR_MESSAGE()					AS ErrorMessage,
			1								AS SendEmail,
			NULL							AS EmailSent
	FROM	sys.procedures sp
	INNER JOIN sys.schemas sch ON sch.schema_id = sp.schema_id
	WHERE	sp.object_id = @@PROCID

	SET @Error = 1
END CATCH

/*	If no errors occurred, proceed with transferring the data to the DS tables.	*/
IF @Error = 0
BEGIN
	SET NUMERIC_ROUNDABORT OFF
	SET XACT_ABORT ON
	SET TRANSACTION ISOLATION LEVEL SERIALIZABLE

	BEGIN TRY
		BEGIN TRANSACTION

		-- 1. Delete from tblBPV.
		SET @TimeStamp = GETDATE()

		DELETE	del
		FROM	hrs.tblBPV del
		LEFT JOIN #tblBPV src
		ON		src.EmployerNumber = del.EmployerNumber
		AND		src.EmployeeNumber = del.EmployeeNumber
		AND		src.CourseID = del.CourseID
		AND		src.StartDate = del.StartDate
		WHERE	src.DSR_ID IS NULL

		INSERT INTO sub.tblImportLog
			(
				[Log],
				[TimeStamp],
				Duration
			)
		VALUES
			(
				'Er zijn ' + CAST(@@ROWCOUNT AS varchar(10)) + ' BPV records verwijderd.',
				GETDATE(),
				DATEDIFF(ss, @TimeStamp, GETDATE())
			)
	
		-- 2. Update tblBPV.
		SET @TimeStamp = GETDATE()

		UPDATE	upd
		SET		upd.EndDate = src.EndDate,
				upd.StatusCode = src.StatusCode,
				upd.StatusDescription = src.StatusDescription,
                upd.DSR_ID = src.DSR_ID,
                upd.TypeBPV = src.TypeBPV
		FROM	hrs.tblBPV upd
		INNER JOIN #tblBPV src
		ON		src.EmployerNumber = upd.EmployerNumber
		AND		src.EmployeeNumber = upd.EmployeeNumber
		AND		src.CourseID = upd.CourseID
		AND		src.StartDate = upd.StartDate
		WHERE	COALESCE(upd.EndDate, '19000101') <> COALESCE(src.EndDate, '19000101')
		OR		COALESCE(upd.StatusCode, 0) <> COALESCE(src.StatusCode, 0)
		OR		COALESCE(upd.StatusDescription, '') <> COALESCE(src.StatusDescription, '')
		OR		COALESCE(upd.DSR_ID, 0) <> COALESCE(src.DSR_ID, 0)
		OR		COALESCE(upd.TypeBPV, '') <> COALESCE(src.TypeBPV, '')

		INSERT INTO sub.tblImportLog
			(
				[Log],
				[TimeStamp],
				Duration
			)
		VALUES
			(
				'Er zijn ' + CAST(@@ROWCOUNT AS varchar(10)) + ' BPV records bijgewerkt.',
				GETDATE(),
				DATEDIFF(ss, @TimeStamp, GETDATE())
			)
	
		-- 3. Insert into tblBPV.
		SET @TimeStamp = GETDATE()

		INSERT INTO hrs.tblBPV
			(	
				EmployeeNumber, 
				StartDate, 
				EndDate, 
				EmployerNumber, 
				CourseID, 
				CourseName, 
				StatusCode, 
				StatusDescription,
				DSR_ID,
                TypeBPV
			)
		SELECT 	src.EmployeeNumber, 
				src.StartDate, 
				src.EndDate, 
				src.EmployerNumber, 
				src.CourseID, 
				src.CourseName, 
				src.StatusCode, 
				src.StatusDescription,
				src.DSR_ID,
                src.TypeBPV
		FROM	#tblBPV src
		LEFT JOIN hrs.tblBPV ins
		ON		ins.EmployerNumber = src.EmployerNumber
		AND		ins.EmployeeNumber = src.EmployeeNumber
		AND		ins.CourseID = src.CourseID
		AND		ins.StartDate = src.StartDate
		WHERE	ins.DSR_ID IS NULL

		INSERT INTO sub.tblImportLog
			(
				[Log],
				[TimeStamp],
				Duration
			)
		VALUES
			(
				'Er zijn ' + CAST(@@ROWCOUNT AS varchar(10)) + ' BPV records toegevoegd.',
				GETDATE(),
				DATEDIFF(ss, @TimeStamp, GETDATE())
			)
	
		-- 4. Delete from tblBPV_DTG.
		SET @TimeStamp = GETDATE()

		DELETE	del
		FROM	hrs.tblBPV_DTG del
		LEFT JOIN #tblBPV_DTG src
		ON		src.DTG_ID = del.DTG_ID
		WHERE	src.DSR_ID IS NULL

		INSERT INTO sub.tblImportLog
			(
				[Log],
				[TimeStamp],
				Duration
			)
		VALUES
			(
				'Er zijn ' + CAST(@@ROWCOUNT AS varchar(10)) + ' BPV_DTG records verwijderd.',
				GETDATE(),
				DATEDIFF(ss, @TimeStamp, GETDATE())
			)
	
		-- 5. Update tblBPV_DTG.
		SET @TimeStamp = GETDATE()

		UPDATE	upd
		SET		upd.ReferenceDate = src.ReferenceDate,
				upd.PaymentStatus = src.PaymentStatus,
				upd.DTG_Status = src.DTG_Status,
				upd.PaymentType = src.PaymentType,
				upd.PaymentNumber = src.PaymentNumber,
				upd.PaymentAmount = src.PaymentAmount,
				upd.PaymentDate = src.PaymentDate,
				upd.AmountPaid = src.AmountPaid,
				upd.PaymentDateReversal = src.PaymentDateReversal,
				upd.AmountReversed = src.AmountReversed,
				upd.LastPayment = src.LastPayment,
				upd.ReasonNotPaidShort = src.ReasonNotPaidShort,
				upd.ReasonNotPaidLong = src.ReasonNotPaidLong
		FROM	hrs.tblBPV_DTG upd
		INNER JOIN #tblBPV_DTG src
		ON		src.DTG_ID = upd.DTG_ID
		WHERE	COALESCE(upd.ReferenceDate, '19000101') <> COALESCE(src.ReferenceDate, '19000101')
		OR		COALESCE(upd.PaymentStatus, '') <> COALESCE(src.PaymentStatus, '')
		OR		COALESCE(upd.DTG_Status, '') <> COALESCE(src.DTG_Status, '')
		OR		COALESCE(upd.PaymentType, '') <> COALESCE(src.PaymentType, '')
		OR		COALESCE(upd.PaymentNumber, 0) <> COALESCE(src.PaymentNumber, 0)
		OR		COALESCE(upd.PaymentAmount, 0.00) <> COALESCE(src.PaymentAmount, 0.00)
		OR		COALESCE(upd.PaymentDate, '19000101') <> COALESCE(src.PaymentDate, '19000101')
		OR		COALESCE(upd.AmountPaid, 0.00) <> COALESCE(src.AmountPaid, 0.00)
		OR		COALESCE(upd.PaymentDateReversal, '19000101') <> COALESCE(src.PaymentDateReversal, '19000101')
		OR		COALESCE(upd.AmountReversed, 0.00) <> COALESCE(src.AmountReversed, 0.00)
		OR		COALESCE(upd.LastPayment, '') <> COALESCE(src.LastPayment, '')
		OR		COALESCE(upd.ReasonNotPaidShort, '') <> COALESCE(src.ReasonNotPaidShort, '')
		OR		COALESCE(upd.ReasonNotPaidLong, '') <> COALESCE(src.ReasonNotPaidLong, '')

		INSERT INTO sub.tblImportLog
			(
				[Log],
				[TimeStamp],
				Duration
			)
		VALUES
			(
				'Er zijn ' + CAST(@@ROWCOUNT AS varchar(10)) + ' BPV_DTG records bijgewerkt.',
				GETDATE(),
				DATEDIFF(ss, @TimeStamp, GETDATE())
			)
	
		-- 6. Insert into tblBPV_DTG.
		SET @TimeStamp = GETDATE()

		INSERT INTO hrs.tblBPV_DTG
			(	
				DSR_ID,
				DTG_ID,
				ReferenceDate,
				PaymentStatus,
				DTG_Status,
				PaymentType,
				PaymentNumber,
				PaymentAmount,
				PaymentDate,
				AmountPaid,
				PaymentDateReversal,
				AmountReversed,
				LastPayment,
				ReasonNotPaidShort,
				ReasonNotPaidLong
			)
		SELECT 	src.DSR_ID,
				src.DTG_ID,
				src.ReferenceDate,
				src.PaymentStatus,
				src.DTG_Status,
				src.PaymentType,
				src.PaymentNumber,
				src.PaymentAmount,
				src.PaymentDate,
				src.AmountPaid,
				src.PaymentDateReversal,
				src.AmountReversed,
				src.LastPayment,
				src.ReasonNotPaidShort,
				src.ReasonNotPaidLong
		FROM	#tblBPV_DTG src
		LEFT JOIN hrs.tblBPV_DTG ins
		ON		ins.DTG_ID = src.DTG_ID
		WHERE	ins.DSR_ID IS NULL

		INSERT INTO sub.tblImportLog
			(
				[Log],
				[TimeStamp],
				Duration
			)
		VALUES
			(
				'Er zijn ' + CAST(@@ROWCOUNT AS varchar(10)) + ' BPV_DTG records toegevoegd.',
				GETDATE(),
				DATEDIFF(ss, @TimeStamp, GETDATE())
			)
	
		PRINT 'TRANSACTION COMMITTED'

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		PRINT 'ROLLBACK TRANSACTION'

		ROLLBACK TRANSACTION

		INSERT INTO [ait].[tblErrorLog]
			(
				ErrorDate,
				ErrorNumber,
				ErrorSeverity,
				ErrorState,
				ErrorProcedure,
				ErrorLine,
				ErrorMessage,
				SendEmail,
				EmailSent
			)
		SELECT  GETDATE()						AS ErrorDate,
				ERROR_NUMBER()					AS ErrorNumber,
				ERROR_SEVERITY()				AS ErrorSeverity,
				ERROR_STATE()					AS ErrorState,
				sch.[name] + '.' + sp.[name]	AS ErrorProcedure,
				ERROR_LINE()					AS ErrorLine,
				ERROR_MESSAGE()					AS ErrorMessage,
				1								AS SendEmail,
				NULL							AS EmailSent
		FROM	sys.procedures sp
		INNER JOIN sys.schemas sch ON sch.schema_id = sp.schema_id
		WHERE	sp.object_id = @@PROCID
	END CATCH

	-- 7. Rebuild index
	EXECUTE	[hrs].[uspHorusBPV_Imp_Rebuild_Index]

	-- 8. Update the declarationamount in DS.
	DECLARE @DeclarationID		int,
			@Declarationamount	decimal(19,2)

	DECLARE cur_Declaration CURSOR FOR 
		SELECT 
				d.DeclarationID,
				dda.DeclarationAmount
		FROM	sub.tblDeclaration d
		INNER JOIN stip.viewDeclaration_DynamicAmount dda ON dda.DeclarationID = d.DeclarationID
		WHERE	COALESCE(d.DeclarationAmount, 0.00) <> dda.DeclarationAmount
		
	OPEN cur_Declaration

	FETCH NEXT FROM cur_Declaration INTO @DeclarationID, @Declarationamount

	WHILE @@FETCH_STATUS = 0  
	BEGIN
		EXEC sub.uspDeclaration_Upd_DeclarationAmount
			@DeclarationID,
			@DeclarationAmount,
			1	-- UserID Systeem

		FETCH NEXT FROM cur_Declaration INTO @DeclarationID, @Declarationamount
	END

	CLOSE cur_Declaration
	DEALLOCATE cur_Declaration
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== hrs.uspHorusBPV_Imp ===================================================================	*/
