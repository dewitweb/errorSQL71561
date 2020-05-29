
CREATE PROCEDURE [hrs].[uspHorusDeclaration2019_Imp]
AS
/*	==========================================================================================
	Purpose:	Import all declaration data from Horus.

	Notes:		The views only select the following declarations:
					- Course startdate >= 01-01-2016 and status PAID
					- Course startdate >= 01-01-2019 (all status).

	02-01-2020	Sander van Houten	OTIBSUB-1801	Corrected the e-mail header 
                                        and only send an e-mail once a day.
	07-11-2019	Sander van Houten	OTIBSUB-1539	DeclarationStatus -> PartitionStatus.
	03-09-2019	Sander van Houten	OTIBSUB-1523	Added initialization of @PreviousEmployee.
	16-08-2019	Jaap van Assenbergh	OTIBSUB-1506	d.drooij@otib.nl vervangen door i.rietveld@otib.nl 
	03-06-2019	Sander van Houten	OTIBSUB-1137	Only e-mail on 12 and 16 o'clock.
	03-05-2019	Sander van Houten	OTIBSUB-1046	Move voucher use to partition level.
	02-04-2019	Sander van Houten	OTIBSUB-874		E-mail design changes.
	22-03-2019	Sander van Houten	OTIBSUB-863		Overzicht declaraties vanuit Horus.
	22-03-2019	Sander van Houten	OTIBSUB-866		Terugmelding naar Horus 
													na inlezen declaraties in DS.
	11-03-2019	Sander van Houten	Jan Odijk Added SUBSIDIE_BEDRAG to HRS_VW_OSR_DECLARATIES.
	04-01-2019	Sander van Houten	Initial version.
	==========================================================================================	*/

SET NOCOUNT ON

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Creation_DateTime  datetime = GETDATE()
DECLARE @TemplateID			int
DECLARE @EmailHeader		varchar(MAX),
		@EmailBody			varchar(MAX),
		@SubjectAddition	varchar(100) = '',
		@Recipients			varchar(MAX)

/* Get all declaration data from Horus.	*/
DECLARE @tblDeclarationID TABLE (DeclarationID int)

DECLARE @SQL	varchar(MAX)

-- First the declarations.
SET @SQL = 'SELECT * FROM OLCOWNER.HRS_VW_OSR_DECLARATIES'

SET @SQL = 'SELECT DECLARATIENR, WGR_NUMMER, DATUM_DECLARATIE, ACT_ID, NAAM, '
			+ 'OPLEIDING_ID, OPLEIDING_NAAM, EIGEN_CSS_OMSCHRIJVING, '
			+ 'STARTDATUM_OPLEIDING, EINDDATUM_OPLEIDING, PLAATSNAAM_LOCATIE, '
			+ 'ELEARNING, DECLARATIE_BEDRAG, SUBSIDIE_BEDRAG, STATUS, '
			+ 'STATUS_OMSCHRIJVING, DEEL_DECLARATIENR, DATUM_UITKERINGSRUN_OSR, '
			+ 'BATCHNUMMERUITGEKEERD, DECLARATIENR_TEGENGEBOEKT, '
			+ 'DATUMUITKERINGTERUGBOEKING, BATCHNUMMERTERUGBOEKING '
			+ 'FROM OPENQUERY(HORUS_P, ''' + REPLACE(@SQL, '''', '''''') + ''')'

IF DB_NAME() = 'OTIBDS'
	SET @SQL = REPLACE(@SQL, 'HORUS_A', 'HORUS_P')
	
-- Empty hrs.tblDeclaration_OSR2019.
DELETE FROM hrs.tblDeclaration_OSR2019

-- Refill it.
INSERT INTO hrs.tblDeclaration_OSR2019
	(
		DeclarationNumber,
		EmployerNumber,
		DeclarationDate,
		InstituteID,
		InstituteName,
		CourseNumber,
		CourseName,
	    OwnCourseDescription,
		StartDate,
		EndDate,
		CourseLocation,
		ElearningSubscription,
		DeclarationAmount,
		DeclarationAmountApproved,
		DeclarationStatus,
		StatusDescription,
		ParentDeclarationNumber,
		PaymentRunDate,
		PaymentRunID,
		DeclarationNumber_ReversalPayment,
		PaymentRunDate_ReversalPayment,
		PaymentRunID_ReversalPayment
	)
EXEC(@SQL)

-- Then the declaration rows.
SET @SQL = 'SELECT * FROM OLCOWNER.HRS_VW_OSR_DECLARATIE_REGELS'

SET @SQL = 'SELECT DECLARATIENR, WNR_NUMMER, WNR_NAAM, RAR_CODE, REDENAFWIJZING, '
			+ 'BON_CODE, BON_PROJECT, BON_STARTDATUM, VOUCHERBEDRAG '
			+ 'FROM OPENQUERY(HORUS_P, ''' + REPLACE(@SQL, '''', '''''') + ''')'
	
IF DB_NAME() = 'OTIBDS'
	SET @SQL = REPLACE(@SQL, 'HORUS_A', 'HORUS_P')
	
-- Empty hrs.tblDeclarationRow_OSR2019.
DELETE FROM hrs.tblDeclarationRow_OSR2019

-- Refill it.
INSERT INTO hrs.tblDeclarationRow_OSR2019
	(
		DeclarationNumber,
		EmployeeNumber,
		EmployeeName,
		RAR_Code,
		RejectionReason,
		VoucherNumber,
		ProjectDescription,
		ValidFromDate,
		DeclarationAmount
	)
EXEC(@SQL)

/* Correct the imported data.	*/

-- Correct ParentDeclarationNumber.
UPDATE	hrs.tblDeclaration_OSR2019 
SET		ParentDeclarationNumber = 322507
WHERE	DeclarationNumber IN (322507, 322508, 322509)

UPDATE	hrs.tblDeclaration_OSR2019 
SET		ParentDeclarationNumber = DeclarationNumber
WHERE	ParentDeclarationNumber IS NULL

-- Update OTIB-DS InstituteID.
UPDATE	decl
SET		decl.OTIBDS_InstituteID = iet.EtalageInstituteID
FROM	hrs.tblDeclaration_OSR2019 decl
INNER JOIN hrs.tblInstituteEtalage iet ON iet.HorusInstituteID = decl.InstituteID
WHERE	decl.OTIBDS_InstituteID IS NULL

-- Update OTIB-DS CourseID.
UPDATE	decl
SET		decl.oTIBDS_CourseID = NULL
FROM	hrs.tblDeclaration_OSR2019 decl
WHERE	decl.OTIBDS_CourseID IS NOT NULL

UPDATE	decl
SET		decl.oTIBDS_CourseID = dc.CourseID
FROM	hrs.tblDeclaration_OSR2019 decl
INNER JOIN hrs.tblDeclaration_Course dc ON dc.DeclarationNumber = decl.DeclarationNumber
AND		decl.OTIBDS_CourseID IS NULL

UPDATE	decl
SET		decl.oTIBDS_CourseID = curPrice.OTIBDS_CourseID
FROM	hrs.tblDeclaration_OSR2019 decl
INNER JOIN hrs.tblDeclaration_OSR2019 curPrice 
	ON	curPrice.ParentDeclarationNumber = decl.ParentDeclarationNumber
	AND	curPrice.OTIBDS_CourseID IS NOT NULL
WHERE	decl.OTIBDS_CourseID IS NULL

-- Update OTIB-DS DeclarationStatus.
UPDATE	decl
SET		decl.OTIBDS_StatusCode = 
			CASE 
				WHEN DeclarationStatus = 'AW'	THEN '0017'  
				WHEN DeclarationStatus = 'BGO'	THEN '0017'	
				WHEN DeclarationStatus = 'FT'	THEN '0009'	
				WHEN DeclarationStatus = 'HA'	THEN '0017'	
				WHEN DeclarationStatus = 'IO'	THEN '0002' --'0008'	
				WHEN DeclarationStatus = 'NG'	THEN '0002'	
				WHEN DeclarationStatus = 'TB'	THEN '0012'	
				WHEN DeclarationStatus = 'UB'	THEN '0012'	
				WHEN DeclarationStatus = 'WOB'	THEN '0002'	
				WHEN DeclarationStatus = 'NW'	THEN '0002'	
			END
FROM	hrs.tblDeclaration_OSR2019 decl
WHERE	OTIBDS_StatusCode IS NULL

/*	Update vouchers from Horus.	*/
EXEC hrs.uspHorusVoucher_Imp

/*	Create paymentruns that do not exist in OTIB-DS.	*/
EXEC hrs.uspPaymentRun_OSR2019_Add NULL

/*	Update or insert declaration in OTIB-DS.	*/
DECLARE @RC									int,
		@DeclarationNumber					varchar(6),
		@EmployerNumber						varchar(6),
		@DeclarationDate					datetime,
		@InstituteID						int,
		@CourseID							int,
		@CourseLocation						varchar(100),
		@ElearningSubscription				bit,
		@StartDate							date,
		@EndDate							date,
		@DeclarationAmount					decimal(9,4),
		@DeclarationAmountApproved			decimal(9,4),
		@NewCourse							bit,
		@InstituteName						varchar(100),
		@CourseName							varchar(100),
		@PaymentRunDate						datetime,
		@PaymentRunID						int,
		@DeclarationNumber_ReversalPayment	varchar(6),
		@PaymentRunDate_ReversalPayment		datetime,
		@PaymentID_ReversalPayment			int,
		@Partition							xml,
		@CurrentUserID						int = 1,
		@DeclarationID						int,
		@StatusCode							varchar(4),
		@StatusDescription					varchar(255),
		@NrOfPartitions						tinyint,
		@Result								varchar(8000),
		@DeclarationNumber_HRS				varchar(6),
        @PartitionID                        int,
        @DeclarationStatus                  varchar(4)

-- Select only the DeclarationNumber of the new records.
SELECT	COALESCE(ins.ParentDeclarationNumber, ins.DeclarationNumber)	AS DeclarationNumber,
		COALESCE(ins.ParentDeclarationNumber, ins.DeclarationNumber)	AS DeclarationID,
		SUM(ins.DeclarationAmount)										AS SumOfDeclarationAmount,
		SUM(ins.DeclarationAmountApproved)								AS SumOfDeclarationAmountApproved,
		MIN(ins.StartDate)												AS MinStartDate,
		MAX(ins.EndDate)												AS MaxEndDate
INTO	sub.#tblDeclaration
FROM	hrs.tblDeclaration_OSR2019 ins
LEFT JOIN hrs.tblDeclaration_HorusNr_OTIBDSID ids ON ids.DeclarationNumber = ins.ParentDeclarationNumber
LEFT JOIN sub.tblDeclaration decl ON decl.DeclarationID = ids.DeclarationID
LEFT JOIN osr.tblDeclaration osr ON	osr.DeclarationID = decl.DeclarationID
WHERE	decl.DeclarationID IS NULL --AND ins.ParentDeclarationNumber = 266373
GROUP BY 
		COALESCE(ins.ParentDeclarationNumber, ins.DeclarationNumber),
		ids.DeclarationID

-- Declaration of the main cursor.
DECLARE cur_Declaration CURSOR FOR
	SELECT	DISTINCT
			decl.DeclarationNumber,
			decl.DeclarationID,
			insdecl.EmployerNumber,
			insdecl.DeclarationDate,
			insdecl.OTIBDS_InstituteID,
			insdecl.OTIBDS_CourseID,
			insdecl.CourseLocation,
			0	AS ElearningSubscription,
			decl.MinStartDate,
			decl.MaxEndDate,
			decl.SumOfDeclarationAmount,
			decl.SumOfDeclarationAmountApproved,
			CASE WHEN ISNULL(OTIBDS_CourseID, 0) = 0 THEN 1 ELSE 0 END NewCourse,
			insdecl.InstituteName,
			ISNULL(insdecl.OwnCourseDescription, insdecl.CourseName),
			insdecl.PaymentRunDate,
			insdecl.PaymentRunID,
			insdecl.DeclarationNumber_ReversalPayment,
			insdecl.PaymentRunDate_ReversalPayment,
			insdecl.PaymentRunID_ReversalPayment,
			(
				SELECT	0							AS [PartitionID],
						YEAR(inspart.StartDate)		AS [PartitionYear],
						inspart.DeclarationAmount	AS [PartitionAmount],
						CASE 
							WHEN inspart.OTIBDS_StatusCode = '0002' THEN
								0.00
							ELSE 
								inspart.DeclarationAmountApproved 
							END						AS [PartitionAmountCorrected],
						inspart.OTIBDS_StatusCode	AS [PartitionStatus],
						ISNULL(inspart.PaymentRunDate, 
								CASE WHEN inspart.DeclarationDate > CAST(YEAR(inspart.StartDate) AS varchar(4)) + '-01-01'
									THEN inspart.DeclarationDate
									ELSE CAST(YEAR(inspart.StartDate) AS varchar(4)) + '-01-01'
								END	
							  )						AS [PaymentDate]
				FROM	hrs.tblDeclaration_OSR2019 inspart
				WHERE	COALESCE(inspart.ParentDeclarationNumber, inspart.DeclarationNumber) = decl.DeclarationNumber
				FOR XML PATH('Partition'), ROOT('Partitions')
			) AS [Partition],
			insdecl.OTIBDS_StatusCode
	FROM	sub.#tblDeclaration decl
	INNER JOIN hrs.tblDeclaration_OSR2019 insdecl 
	ON		insdecl.DeclarationNumber = decl.DeclarationNumber

-- Process all selected records.
OPEN cur_Declaration

FETCH NEXT FROM cur_Declaration INTO @DeclarationNumber, @DeclarationID, @EmployerNumber, @DeclarationDate, 
										@InstituteID, @CourseID, @CourseLocation, @ElearningSubscription,
										@StartDate, @EndDate, @DeclarationAmount, @DeclarationAmountApproved, @NewCourse,  
										@InstituteName, @CourseName, @PaymentRunDate, @PaymentRunID, @DeclarationNumber_ReversalPayment,
										@PaymentRunDate_ReversalPayment, @PaymentID_ReversalPayment, @Partition, @StatusCode

WHILE @@FETCH_STATUS = 0  
BEGIN
	PRINT 'Declaratie ' + @DeclarationNumber
	-- Clear temptable.
	DELETE FROM	@tblDeclarationID

	-- Insert new or update existing declaration.
	INSERT INTO @tblDeclarationID (DeclarationID)
	EXEC hrs.uspDeclaration_upd
		@DeclarationID,
		@EmployerNumber,
		1,					 --@SubsidySchemeID,
		@DeclarationDate,
		@InstituteID,
		@StartDate,
		@EndDate,
		@DeclarationAmount,
		@Partition,
		@CurrentUserID

	-- Save DeclarationID for later use.
	SELECT	@DeclarationID = DeclarationID 
	FROM	@tblDeclarationID

	-- Add record to sub.tblDeclaration_Unkown_Source for further investigation by OTIB user.
	IF @NewCourse = 1
	BEGIN
		EXEC sub.uspDeclaration_Unknown_Source_Upd
				@DeclarationID,
				@InstituteID,
				@InstituteName,
				@CourseID,
				@CourseName,
				NULL,	--SendToSourceSystemDate
				NULL,	--ReceivedFromSourceSystemDate
				@CurrentUserID
	END

	-- Correct the StatusCode
    SET @PartitionID = sub.usfGetActivePartitionByDeclaration(@DeclarationID, GETDATE())
    SET @DeclarationStatus = sub.usfGetDeclarationStatusByPartition(@DeclarationID, @PartitionID, NULL)

    SELECT  @StatusCode = DeclarationStatus
    FROM    sub.tblDeclaration
    WHERE   DeclarationID = @DeclarationID
	
    IF @DeclarationStatus <> @StatusCode
    BEGIN
        EXEC sub.uspDeclaration_Upd_DeclarationStatus
            @DeclarationID,
            @DeclarationStatus,
            @StatusDescription,
            @CurrentUserID
    END

	EXEC osr.uspDeclaration_Upd @DeclarationID, @CourseID, @CourseLocation, @ElearningSubscription

	-- Add new declaration to HORUS/OTIB-DS link table.
	IF NOT EXISTS (	SELECT	1 
					FROM	hrs.tblDeclaration_HorusNr_OTIBDSID 
					WHERE	DeclarationNumber = @DeclarationNumber )
	BEGIN
		INSERT INTO hrs.tblDeclaration_HorusNr_OTIBDSID
			(
				DeclarationNumber,
				DeclarationID
			)
		VALUES
			(
				@DeclarationNumber,
				@DeclarationID
			)
	END

	/* Update or add employees to declaration.	*/
	DECLARE @EmployeeNumber		varchar(8),
			@VoucherNumber		varchar(3),
			@DeclarationValue	decimal(19,2),
			@ValidFromDate		date,
			@ReversalPaymentID	int,
			@PreviousEmployee	varchar(8) = ''

	-- Declaration of cursor.
	DECLARE cur_Employee CURSOR FOR
		SELECT	der.EmployeeNumber,
				der.VoucherNumber,
				der.DeclarationAmount,
				der.ValidFromDate,
				dep.PartitionID
		FROM	hrs.tblDeclaration_OSR2019 decl
		INNER JOIN hrs.tblDeclarationRow_OSR2019 der
		ON		der.DeclarationNumber = decl.DeclarationNumber
		INNER JOIN sub.tblDeclaration_Partition dep
		ON		dep.DeclarationID = decl.ParentDeclarationNumber
		AND		dep.PartitionYear = YEAR(decl.StartDate)
		LEFT JOIN sub.tblDeclaration_Employee dem
		ON		dem.DeclarationID = @DeclarationID
		AND		dem.EmployeeNumber = der.EmployeeNumber
		WHERE	decl.ParentDeclarationNumber = @DeclarationNumber
		--AND		dem.DeclarationID IS NULL
		--AND		COALESCE(der.DeclarationAmount, 0) <> 0

	-- Process all selected records.
	OPEN cur_Employee

	SET @PreviousEmployee = ''

	FETCH NEXT FROM cur_Employee INTO @EmployeeNumber, @VoucherNumber, @DeclarationValue, @ValidFromDate, @PartitionID

	WHILE @@FETCH_STATUS = 0
	BEGIN
		PRINT ' Werknemer ' + @EmployeeNumber

		IF @EmployeeNumber <> @PreviousEmployee
		BEGIN
			-- Update sub.tblDeclaration_Employee.
			EXECUTE @RC = sub.uspDeclaration_Employee_Upd 
				@DeclarationID,
				@EmployeeNumber,
				@ReversalPaymentID,
				@CurrentUserID

			-- Update sub.tblDeclaration_Partition_Voucher.
			-- First check Horus for latest voucher status.
			EXECUTE @RC = sub.uspEmployee_SyncHorusVoucher 
				@EmployeeNumber
		END

		IF ISNULL(@DeclarationValue, 0) <> 0 AND ISNULL(@VoucherNumber, '') <> ''	-- Must have a value and a number.
		BEGIN
			PRINT '  Voucher ' + @VoucherNumber

			EXECUTE @RC = sub.uspDeclaration_Partition_Voucher_Upd
				@DeclarationID,
				@PartitionID,
				@EmployeeNumber,
				@VoucherNumber,
				@DeclarationValue,
				@CurrentUserID

			UPDATE	vu								-- When there is a payed partition then the voucher is payed.
			SET		vu.VoucherStatus = '0010'
			FROM	hrs.tblDeclaration_HorusNr_OTIBDSID dho
			INNER JOIN hrs.tblDeclaration_OSR2019 do
			ON		do.ParentDeclarationNumber = dho.DeclarationNumber
			INNER JOIN hrs.tblDeclarationRow_OSR2019 dro
			ON		dro.DeclarationNumber = do.DeclarationNumber
			INNER JOIN sub.tblDeclaration_Partition dep
			ON		dep.DeclarationID = dho.DeclarationID
			AND		dep.PartitionYear = YEAR(do.StartDate)
			INNER JOIN sub.tblDeclaration_Partition_Voucher dpv
			ON		dpv.DeclarationID = dep.DeclarationID
			AND		dpv.PartitionID = dep.PartitionID
			AND		dpv.EmployeeNumber = dro.EmployeeNumber
			AND		dpv.VoucherNumber = dro.VoucherNumber
			AND		dpv.DeclarationValue = dro.DeclarationAmount
			INNER JOIN hrs.tblVoucher_Used vu 
			ON		vu.DeclarationID = dep.DeclarationID
			AND		vu.VoucherNumber = dpv.VoucherNumber
			AND		vu.AmountUsed = dpv.DeclarationValue
			WHERE	do.DeclarationStatus = 'UB'
			AND		vu.VoucherStatus <> '0010'

		END

		-- Save current employeenumber.
		SET @PreviousEmployee = @EmployeeNumber

		-- Process next employee.
		FETCH NEXT FROM cur_Employee INTO @EmployeeNumber, @VoucherNumber, @DeclarationValue, @ValidFromDate, @PartitionID
	END

	CLOSE cur_Employee
	DEALLOCATE cur_Employee

	/*	Subtract all used vouchers from first partitionamount.	*/
	DECLARE @TotalVoucherAmount	decimal(19,2)

	;WITH cte_Partition AS
	(	
		SELECT	PartitionID,
				SUM(DeclarationValue) TotalVoucherAmount
		FROM	sub.tblDeclaration_Partition_Voucher
		WHERE	DeclarationID = @DeclarationID
		GROUP BY 
				PartitionID
	)
	UPDATE  dep
	SET		dep.PartitionAmount = dep.PartitionAmount - cte.TotalVoucherAmount,
			dep.PartitionAmountCorrected = CASE WHEN dep.PartitionAmountCorrected <> 0.00 
											THEN dep.PartitionAmountCorrected - cte.TotalVoucherAmount
											ELSE dep.PartitionAmountCorrected
										   END
	FROM	sub.tblDeclaration_Partition dep
	INNER JOIN cte_Partition cte ON cte.PartitionID = dep.PartitionID

	/*	Create PaymentRun and Specifications.	*/
	IF @PaymentRunDate IS NOT NULL
	BEGIN
	PRINT ' PaymentRun ' + @DeclarationNumber
		EXECUTE @RC = [hrs].[uspPaymentRun_OSR2019_Add] 
		   @DeclarationNumber

	PRINT ' PaymentRun /' + @DeclarationNumber
	END

	/* Give feedback to Horus.	*/
	IF EXISTS(SELECT 1 FROM sys.servers WHERE NAME = N'HORUS_P')
	BEGIN
		-- Declaration of cursor.
		DECLARE cur_Horus CURSOR FOR
			SELECT	EmployerNumber,
					DeclarationNumber
			FROM	hrs.tblDeclaration_OSR2019
			WHERE	ParentDeclarationNumber = @DeclarationNumber

		-- Process all selected records.
		OPEN cur_Horus

		FETCH NEXT FROM cur_Horus INTO @EmployerNumber, @DeclarationNumber_HRS

		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET	@SQL = 'BEGIN ? :=OLCOWNER.HRS_PCK_OTIBDS.DECLARATIENAAROTIBDS('
						+ '''' + @EmployerNumber + ''', '
						+ '''' + @DeclarationNumber_HRS + ''', '
						+ '''' + @DeclarationNumber
						+ '''); END;'

			IF DB_NAME() = 'OTIBDS'
				EXEC(@SQL, @Result OUTPUT) AT HORUS_P
			ELSE
				EXEC(@SQL, @Result OUTPUT) AT HORUS_A

			FETCH NEXT FROM cur_Horus INTO @EmployerNumber, @DeclarationNumber_HRS
		END

		CLOSE cur_Horus
		DEALLOCATE cur_Horus
	END

	/*	Save processed declaration for feedback to Debra and Sonja.	*/
	INSERT INTO hrs.tblDeclaration_OSR2019_NewInserted (DeclarationNumber) VALUES (@DeclarationNumber)

	-- Process next declaration.
	FETCH NEXT FROM cur_Declaration INTO @DeclarationNumber, @DeclarationID, @EmployerNumber, @DeclarationDate, 
											@InstituteID, @CourseID, @CourseLocation, @ElearningSubscription,
											@StartDate, @EndDate, @DeclarationAmount, @DeclarationAmountApproved, @NewCourse, 
											@InstituteName, @CourseName, @PaymentRunDate, @PaymentRunID, @DeclarationNumber_ReversalPayment,
											@PaymentRunDate_ReversalPayment, @PaymentID_ReversalPayment, @Partition, @StatusCode
END

CLOSE cur_Declaration
DEALLOCATE cur_Declaration

SET @Recipients = 'i.rietveld@otib.nl;s.vdwaaij@otib.nl'

/* Give feedback to Debra and Sonja.	*/
IF DB_NAME() = 'OTIBDS'
AND (DATEPART(hour, GETDATE()) = 16)
BEGIN
	IF (SELECT COUNT(1) FROM hrs.tblDeclaration_OSR2019_NewInserted) = 0
	--	Send an e-mail stating there has been no new declarations imported from Horus.
	BEGIN

		SET @TemplateID = 9

		SET @EmailHeader = eml.usfGetEmail_Header (@TemplateID)
		SET @EmailBody = eml.usfGetEmail_Body (@TemplateID)

		--INSERT INTO eml.tblEmail
		--		   (EmailHeaders
		--		   ,EmailBody
		--		   ,CreationDate)
		--SELECT	'<headers>'
		--		+ '<header key="subject" value="OTIB Online: Inlezen declaraties vanuit Horus" />'
		--		+ '<header key="to" value="i.rietveld@otib.nl;s.vdwaaij@otib.nl" />'
		--		+ '</headers>'	AS EmailHeaders,
		--		'Beste Ineke, Sonja, <br>' +
		--		'<br>Er zijn vanuit Horus geen nieuwe declaraties ingelezen.<br>' + 
		--		'<br><br>' +			'Met vriendelijke groet,<br>' +
		--		'Ambition IT<br>' +
		--		'<a href="mailto:support@ambitionit.nl">support@ambitionit.nl</a><br>' +
		--		'T 073-5225100<br>'
		--				AS EmailBody,
		--		GETDATE()		AS CreationDate
	END

	ELSE

	--	Send an e-mail stating with overview of new declarations that have been imported from Horus.
	BEGIN

		SET @TemplateID = 10

		SET @EmailHeader = eml.usfGetEmail_Header (@TemplateID)
		SET @EmailHeader = REPLACE(@EmailHeader, '</headers>',  '<header key="bcc" value="svanhouten@ambitionit.nl" /></headers>')

		SET @EmailBody = eml.usfGetEmail_Body (@TemplateID)

		DECLARE cur_Email CURSOR FOR
			SELECT	decl.DeclarationNumber
			FROM	hrs.tblDeclaration_OSR2019_NewInserted ide
			INNER JOIN hrs.tblDeclaration_OSR2019 decl 
			ON		decl.ParentDeclarationNumber = ide.DeclarationNumber

		SET	@Result = ''

		-- Process all selected records.
		OPEN cur_Email

		FETCH NEXT FROM cur_Email INTO @DeclarationNumber

		WHILE @@FETCH_STATUS = 0
		BEGIN
			SELECT	@Result = @Result + '<tr><td width="200">' + DeclarationNumber + '</td>'
										+ '<td width="200">' + ParentDeclarationNumber + '</td>'
										+ '<td width="150">' + EmployerNumber + '</td>' 
										+ '<td width="150">' + CONVERT(varchar(10), StartDate, 120) + '</td>'
										+ '<td width="150">' + CONVERT(varchar(10), EndDate, 120) + '</td>'
										+ '<td width="100">' + DeclarationStatus + '</td></tr>'
			FROM	hrs.tblDeclaration_OSR2019
			WHERE	DeclarationNumber = @DeclarationNumber

			FETCH NEXT FROM cur_Email INTO @DeclarationNumber
		END

		CLOSE cur_Email
		DEALLOCATE cur_Email
		
		--INSERT INTO eml.tblEmail
		--		   (EmailHeaders
		--		   ,EmailBody
		--		   ,CreationDate)
		--SELECT	'<headers>'
		--		+ '<header key="subject" value="OTIB Online: Inlezen declaraties vanuit Horus" />'
		--		+ '<header key="to" value="i.rietveld@otib.nl;s.vdwaaij@otib.nl" />'
		--		+ '<header key="bcc" value="svanhouten@ambitionit.nl" />'
		--		+ '</headers>'	AS EmailHeaders,
		--		'<style type="text/css">p {font-family: arial;font-size: 14.5px}</style><p>Beste Ineke, Sonja, <br>' +
		--		'<br>Zojuist zijn de volgende declaraties ingelezen vanuit Horus.<br>' + 
		--		'<br>' +
		--		'<table cellspacing="0" cellpadding="0" border="0" width="950">' +
		--		'<tr><td width="200">Declaratienummer_HRS</td><td width="200">Declaratienummer_DS</td>'+
		--		'<td width="150">WGR nummer</td><td width="150">Startdatum</td>' + 
		--		'<td width="150">Einddatum</td><td width="100">Status_HRS</td></tr>' +
		--		@Result +
		--		'</table>' +
		--		'<br><br>' +			'Met vriendelijke groet,<br>' +
		--		'Ambition IT<br>' +
		--		'<a href="mailto:support@ambitionit.nl">support@ambitionit.nl</a><br>' +
		--		'T 073-5225100<br>' +
		--		'</p>'		AS EmailBody,
		--		GETDATE()		AS CreationDate

			SET @EmailBody = REPLACE(@EmailBody, '<%Result%>', ISNULL(@Result, ''))

		-- Initialize hrs.tbltblDeclaration_OSR2019_NewInserted
		DELETE FROM hrs.tblDeclaration_OSR2019_NewInserted
	END

SET @EmailHeader = REPLACE(@EmailHeader, '<%Recipients%>', ISNULL(@Recipients, ''))
SET @EmailHeader = REPLACE(@EmailHeader, '<%SubjectAddition%>', ISNULL(@SubjectAddition, ''))

INSERT INTO eml.tblEmail
    (
        EmailHeaders,
        EmailBody,
        CreationDate
    )
VALUES
    (
		@EmailHeader,
		@EmailBody,
		@Creation_DateTime
	)

END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== hrs.uspHorusDeclaration2019_Imp =======================================================	*/
