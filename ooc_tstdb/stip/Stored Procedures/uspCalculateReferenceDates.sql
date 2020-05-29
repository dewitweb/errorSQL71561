CREATE PROCEDURE [stip].[uspCalculateReferenceDates]
@DeclarationID			int,
@PartitionStatus		varchar(4),
@EmployerNumber			varchar(6),
@EmployeeNumber			varchar(8),
@EducationID			int,
@StartDate				date,
@EndDate				date,
@tblDeclarationSorted	stip.uttUltimateDiplomaDate READONLY
AS
/*	==========================================================================================
	Purpose:	Calculates the reference dates (partitions) for a STIP declaration.

	17-12-2019	Sander van Houten		OTIBSUB-1729	No longer check if there was a change 
                                            in employment during the period of the education.
	16-12-2019	Jaap van Assenbergh		OTIBSUB-1776	Bij goed keuren op controle lopende BPV 
														wordt er geen Logging weggeschreven van
														de partitie. @PartitionStatus added.
	11-09-2019	Sander van Houten		OTIBSUB-1497	No longer create the diplomadate partition.
	10-09-2019	Sander van Houten		OTIBSUB-1497	Added DiplomaDate bit field to @tblReferenceDate.
	21-08-2019	Sander van Houten		OTIBSUB-1453	Separated calculation of ultimate diplomadate.
	13-08-2019	Sander van Houten		OTIBSUB-1453	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Testdata.
DECLARE	@DeclarationID			int = 408448,
        @PartitionStatus		varchar(4) = '0023',
		@EmployerNumber			varchar(6) = '049073',
		@EmployeeNumber			varchar(8) = '02367050',
		@EducationID			int = 94281,
		@StartDate				date = '2019-08-01',
		@EndDate				date = '2020-07-31',
		@tblDeclarationSorted	stip.uttUltimateDiplomaDate

INSERT INTO @tblDeclarationSorted
	(
		UltimateDiplomaDate,
		RecordID,
		SubsidySchemeID,
		EmployerNumber,
		StartDate,
		EndDate,	
		DeclarationID,		
		ExtensionID,			
		PauseYears,
		PauseMonths,
		PauseDays,
		PauseYearsAll,
		PauseMonthsAll,
		PauseDaysAll
	)
VALUES	('2021-07-31',1,3,'002971','2015-08-01','2016-07-31',0,0,0,0,0,0,0,0),
        ('2021-07-31',2,3,'002971','2017-08-01','2018-07-31',0,0,1,0,0,1,0,0),
        ('2021-07-31',3,3,'002971','2018-08-01','2019-07-31',0,0,1,0,0,1,0,0),
        ('2021-07-31',4,4,'049073','2019-08-01','2020-07-31',408448,0,1,0,0,1,0,0)
    
-- */

DECLARE @NominalDuration		tinyint,
		@Partitions				xml,
		@DiplomaDate			date,
		@UltimateDiplomaDate	date,
		@PartitionAmount		decimal(19,2)
	
DECLARE @tblReferenceDate TABLE
	(
		ReferencePeriod		tinyint,
		ReferenceDate		date,
		SubsidySchemeID		int,
		EmployerNumber		int,
		DeclarationID		int,
		ExtensionID			int,
		CreatePartition		bit,
		PauseYears			tinyint,
		PauseMonths			tinyint,
		PauseDays			tinyint,
		DeclarationRecordID	int,
		DiplomaPartition	bit
	)

/* Get nominal duration of the education.	*/
SELECT	@NominalDuration = NominalDuration
FROM	sub.tblEducation 
WHERE	EducationID = @EducationID

/* Get diplomadate + ultimate diplomadate.	*/
SELECT	TOP 1
		@DiplomaDate = DATEADD(MONTH, -12, UltimateDiplomaDate),
		@UltimateDiplomaDate = UltimateDiplomaDate
FROM	@tblDeclarationSorted

/* Correct the enddate.	*/
IF @EndDate > @UltimateDiplomaDate
BEGIN
	SET @EndDate = @UltimateDiplomaDate
END

/* Calculate ultimate diplomadate.	*/
DECLARE @InitialStartDate		date,
		@curEmployerNumber		int,
		@curStartDate			date,
		@curEndDate				date,
		@prvStartDate			date,
		@prvEndDate				date,
		@prvRecordID			int,
		@PauseYears				tinyint = 0,
		@PauseMonths			tinyint = 0,
		@PauseDays				tinyint = 0,
		@PauseYearsAll			tinyint = 0,
		@PauseMonthsAll			tinyint = 0,
		@PauseDaysAll			tinyint = 0
		
-- First determine initial startdate
SELECT	@InitialStartDate = MIN(StartDate)
FROM	@tblDeclarationSorted

/* Calculate reference days.	*/
DECLARE @NumberOfReferenceDates					tinyint,
		@NumberOfBaseReferenceDates				tinyint,
		@CurrentReferencePeriod					tinyint,
		@ReferenceDate							date

-- Determine startdate.
SELECT	@InitialStartDate = MIN(StartDate)
FROM	@tblDeclarationSorted

-- Determine number of (base-)reference dates.
SELECT	@NumberOfReferenceDates = @NominalDuration * 2,
		@NumberOfBaseReferenceDates = (@NominalDuration * 2) - 1,
		@CurrentReferencePeriod = 1,
		@ReferenceDate = DATEADD(DAY, -1, DATEADD(MONTH, (6 * @CurrentReferencePeriod), @InitialStartDate))

-- Initialize variables.
SELECT	@PauseYears = 0,
		@PauseMonths = 0,
		@PauseDays = 0,
		@prvStartDate = NULL

WHILE @CurrentReferencePeriod <= @NumberOfBaseReferenceDates
	AND @ReferenceDate <= @EndDate
BEGIN
	-- Fill @tblReferenceDate.
	INSERT INTO @tblReferenceDate
		(
			ReferencePeriod,
			ReferenceDate,
			SubsidySchemeID,
			EmployerNumber,
			DeclarationID,
			ExtensionID,
			CreatePartition,
			PauseYears,
			PauseMonths,
			PauseDays,
			DeclarationRecordID,
			DiplomaPartition
		)
	SELECT	@CurrentReferencePeriod,
			CASE WHEN @EmployerNumber = d.EmployerNumber AND @PauseYears = 0 AND @PauseMonths = 0 AND @PauseDays = 0
				THEN DATEADD(DAY, d.PauseDays, DATEADD(MONTH, d.PauseMonths, DATEADD(YEAR, d.PauseYears, @ReferenceDate)))
				ELSE @ReferenceDate
			END	AS ReferenceDate,
			ISNULL(d.SubsidySchemeID, 4),
			d.EmployerNumber,
			ISNULL(d.DeclarationID, 0),
			ISNULL(d.ExtensionID, 0),
			CASE WHEN @ReferenceDate >= @StartDate
				THEN 1
				ELSE 0
			END	AS CreatePartition,
			d.PauseYears,
			d.PauseMonths,
			d.PauseDays,
			d.RecordID,
			0
	FROM	@tblDeclarationSorted d 
	WHERE	d.StartDate >= @InitialStartDate
	AND		(d.StartDate <= CASE WHEN @EmployerNumber = d.EmployerNumber AND @PauseYears = 0 AND @PauseMonths = 0 AND @PauseDays = 0
							THEN DATEADD(DAY, d.PauseDays, DATEADD(MONTH, d.PauseMonths, DATEADD(YEAR, d.PauseYears, @ReferenceDate)))
							ELSE @ReferenceDate
							END
			)
	AND		d.EndDate >= CASE WHEN @EmployerNumber = d.EmployerNumber AND @PauseYears = 0 AND @PauseMonths = 0 AND @PauseDays = 0
							THEN DATEADD(DAY, d.PauseDays, DATEADD(MONTH, d.PauseMonths, DATEADD(YEAR, d.PauseYears, @ReferenceDate)))
							ELSE @ReferenceDate
							END

	-- Get saved pauseperiod.
	SELECT	@PauseYears = PauseYears,
			@PauseMonths = PauseMonths,
			@PauseDays = PauseDays,
			@prvRecordID = DeclarationRecordID
	FROM	@tblReferenceDate
	WHERE	ReferencePeriod = @CurrentReferencePeriod

	-- Next period.
	SELECT	@CurrentReferencePeriod = @CurrentReferencePeriod + 1

	-- Next referencedate.
	SET @ReferenceDate = DATEADD(MONTH, (6 * @CurrentReferencePeriod), @InitialStartDate)
	SET @ReferenceDate = DATEADD(DAY, -1, @ReferenceDate)
	SET @ReferenceDate = DATEADD(YEAR, @PauseYears, @ReferenceDate)
	SET @ReferenceDate = DATEADD(MONTH, @PauseMonths, @ReferenceDate)
	SET @ReferenceDate = DATEADD(DAY, @PauseDays, @ReferenceDate)
END

/* Remove referencedates if Horus has created more referencedates then DS did.	*/
DECLARE @HorusReferenceDates	tinyint,
		@HorusReferenceDatesDS	tinyint,
		@LastPaymentInHorus		varchar(1),
		@StartDateSTIP			date

-- Get initial startdate STIP.
SELECT	@StartDateSTIP = MIN(StartDate)
FROM	@tblDeclarationSorted
WHERE	SubsidySchemeID = 4

-- Get number of referencedates created by Horus.
SELECT	@HorusReferenceDates = COUNT(dtg.DTG_ID),
		@LastPaymentInHorus = MIN(dtg.LastPayment)
FROM	hrs.viewBPV bpv
INNER JOIN hrs.viewBPV_DTG dtg
ON		dtg.DSR_ID = bpv.DSR_ID
WHERE	bpv.EmployeeNumber = @EmployeeNumber
AND		bpv.CourseID = @EducationID
AND		(	
			dtg.ReferenceDate < @StartDateSTIP
		OR	(
				COALESCE(dtg.PaymentDate, @StartDateSTIP) < @StartDateSTIP
			AND	COALESCE(dtg.AmountPaid, 0.00) <> 0.00
			)
		)

-- Get number of Horus referencedates created by DS.
SELECT	@HorusReferenceDatesDS = COUNT(1)
FROM	@tblReferenceDate
WHERE	SubsidySchemeID = 3

SET	@HorusReferenceDatesDS = ISNULL(@HorusReferenceDatesDS, 0)

/*  For testpurposes only!	*/
--SELECT	*
--FROM	@tblReferenceDate

--SELECT	@HorusReferenceDatesDS,
--		@HorusReferenceDates
/*	----------------------	*/

-- Remove referencedates if necessary (1).
IF	@HorusReferenceDatesDS > 0
AND	@HorusReferenceDatesDS < @HorusReferenceDates
BEGIN
	DELETE 
	FROM	@tblReferenceDate
	WHERE	ReferencePeriod > ( (@CurrentReferencePeriod - 1) - (@HorusReferenceDates - @HorusReferenceDatesDS) )
END

-- Remove referencedates if necessary (2).
IF	@NumberOfBaseReferenceDates <= @HorusReferenceDates
AND @LastPaymentInHorus = 'N'
BEGIN
	DELETE 
	FROM	@tblReferenceDate
	WHERE	ReferencePeriod = @NumberOfBaseReferenceDates
END

/* For testing purposes!!!	*/
--SELECT * FROM @tblReferenceDate
/* -----------------------	*/

/*	Calculate partitionamount.	*/
SELECT	@PartitionAmount = aex.SettingValue / 2
FROM	sub.tblApplicationSetting aps
INNER JOIN sub.tblApplicationSetting_Extended aex ON aex.ApplicationSettingID = aps.ApplicationSettingID
WHERE	aps.SettingName = 'SubsidyAmountPerType'
AND		aps.SettingCode = 'STIP'
AND		@StartDate BETWEEN aex.StartDate AND aex.EndDate

/* Return the resultset.	*/
SELECT	0											AS PartitionID,
		@DeclarationID								AS DeclarationID,
		CAST(YEAR(ReferenceDate) AS varchar(4)) + '-'
		+ RIGHT('00' + CAST(MONTH(ReferenceDate) AS varchar(2)), 2)		
													AS PartitionYear,
		ISNULL(@PartitionAmount, 0.00)				AS PartitionAmount,
		0.00										AS PartitionAmountCorrected,
		ReferenceDate								AS PaymentDate,
		ISNULL(@PartitionStatus,
		CASE WHEN ReferenceDate > GETDATE()
			THEN '0001'
			ELSE '0002'
		END)										AS PartitionStatus,
		CreatePartition								AS CreatePartition,
		DiplomaPartition							AS DiplomaPartition
FROM	@tblReferenceDate

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== stip.uspCalculateReferenceDates =======================================================	*/
