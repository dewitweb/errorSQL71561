CREATE PROCEDURE [stip].[uspDeclaration_CheckOnRunningEducation]
@EmployeeNumber	varchar(8),
@StartDate		date,
@EndDate		date,
@EmployerNumber	varchar(6),
@EducationID	int
AS
/*	==========================================================================================
	Purpose:	Checks if an employee already has a running eduction in the given time period.
				This can be a STIP or BPV.

	Note:		Multiple running are allowed if both the conditions below are true:
				1. The new CREBO is different from the one(s) that is/are already running.
				2. The employer is different from the one(s) that is/are already running.

	22-10-2019	Sander van Houten		OTIBSUB-1634	Removed the check on ended declarations
                                            in the first select statement.
	26-09-2019	Sander van Houten		OTIBSUB-1567	Altered determining method for 
											result field CanExtend.
	16-09-2019	Sander van Houten		OTIBSUB-1567	Added result field CanExtend.
	03-09-2019	Sander van Houten		OTIBSUB-1527	Added GROUP BY for BPV records.
	21-08-2019	Sander van Houten		OTIBSUB-1499	Added parameter @EducationID and
											result fields UltimateEndDate and ExtendOnly.
	05-08-2019	Sander van Houten		OTIBSUB-1436	Only give feedback on current employer or
											employers with a mother-daughter relationship with
											the current employer.
	01-08-2019	Sander van Houten		OTIBSUB-1428	Added ModifyOnly to resultset.
	12-07-2019	Sander van Houten		OTIBSUB-1368	Expanded checks on running BPV/STIP.
	01-07-2019	Sander van Houten		OTIBSUB-1264	Removed check on running EVC.
	08-06-2019	Sander van Houten		OTIBSUB-1114	Added check on running EVC.
	28-05-2019	Sander van Houten		OTIBSUB-1114	Removed parameter @EducationID again.
	24-05-2019	Sander van Houten		OTIBSUB-1114	Multiple running STIP/BPVs are allowed 
											in some situations.
	09-05-2019	Sander van Houten		OTIBSUB-997		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Testdata.
DECLARE @EmployeeNumber varchar(8) = '000022', 
		@StartDate date = '20190801',
		@EndDate date = '20200731',
		@EmployerNumber varchar(6) = '063721',
		@EducationID int = NULL
--	*/

/* Declare variables.	*/
DECLARE @GetDate			datetime = GETDATE(),
		@UltimateEnddate	date = NULL

DECLARE @tblResult TABLE 
	(
		DeclarationID		int,
		EducationID			int,
		EducationName		varchar(200),
		StartDate			date,
		EndDate				date,
		SubsidySchemeID		int,
		SubsidySchemeName	varchar(50),
		ModifyOnly			bit,
		ExtendOnly			bit,
		UltimateEndDate		date,
		CanExtend			bit
	)

/*	Fill result table.	*/
--	Actual STIP declaration for the same EmployerNumber/Employee.
INSERT INTO @tblResult
	(
		DeclarationID,
		EducationID,
		EducationName,
		StartDate,
		EndDate,
		SubsidySchemeID,
		SubsidySchemeName,
		ModifyOnly,
		ExtendOnly,
		UltimateEndDate,
		CanExtend
	)

SELECT	d.DeclarationID,
		d.EducationID,
		d.EducationName 		AS EducationName,
		d.StartDate				AS StartDate,
		d.EndDate				AS EndDate,
		ssc.SubsidySchemeID,
		ssc.SubsidySchemeName,
		CAST(CASE WHEN d.LastExtensionID IS NULL 
				THEN CASE WHEN pad.PartitionID IS NULL
						THEN 1
						ELSE 0
					 END
				ELSE CASE WHEN d.LastExtensionID IS NOT NULL 
						  AND EXISTS (	SELECT	1
										FROM	sub.tblDeclaration_Extension dex
										INNER JOIN sub.tblPaymentRun_Declaration pad
										ON		pad.DeclarationID = dex.DeclarationID
										INNER JOIN sub.tblDeclaration_Partition dep
										ON		dep.PartitionID = pad.PartitionID
										WHERE	dex.ExtensionID = d.LastExtensionID
										AND		dep.PaymentDate >= dex.StartDate
									 )
						THEN 1 
						ELSE 0
					END
				END
			AS bit)			AS ModifyOnly,
		CAST(0 AS bit)		AS ExtendOnly,
		NULL				AS UltimateEndDate,
		CAST(CASE WHEN d.EndDate <= CAST(DATEADD(MONTH, 6, GETDATE()) AS date)
				THEN 1
				ELSE 0
			 END AS bit)	AS CanExtend
FROM	sub.tblDeclaration_Employee dem
INNER JOIN stip.viewDeclaration d ON d.DeclarationID = dem.DeclarationID
INNER JOIN sub.tblSubsidyScheme ssc ON ssc.SubsidySchemeID = d.SubsidySchemeID
LEFT JOIN sub.tblPaymentRun_Declaration pad ON	pad.DeclarationID = d.DeclarationID
WHERE	dem.EmployeeNumber = @EmployeeNumber
AND		d.EmployerNumber = @EmployerNumber
AND		(
			@StartDate BETWEEN d.StartDate AND d.EndDate
	OR		@EndDate BETWEEN d.StartDate AND d.EndDate
	OR		@StartDate < d.StartDate AND @EndDate > d.EndDate
		)

UNION

--	Actual Horus declaration for the same EmployerNumber/Employee with overlap.
SELECT	NULL				AS DeclarationID,
		bpv.CourseID		AS EducationID,
		bpv.CourseName + ' (' + CAST(bpv.CourseID AS varchar(10)) + ')'	AS EducationName,
		MIN(bpv.StartDate)	AS StartDate,
		MAX(bpv.EndDate)	AS EndDate,
		ssc.SubsidySchemeID,
		ssc.SubsidySchemeName,
		CAST(0 AS bit)		AS ModifyOnly,
		CAST(0 AS bit)		AS ExtendOnly,
		NULL				AS UltimateEndDate,
		CAST(CASE WHEN MAX(bpv.EndDate) <= CAST(DATEADD(MONTH, 6, GETDATE()) AS date)
				THEN 1
				ELSE 0
			 END AS bit)	AS CanExtend
FROM	hrs.viewBPV bpv
LEFT JOIN sub.tblEmployer_ParentChild epc1 ON epc1.EmployerNumberParent = bpv.EmployerNumber
LEFT JOIN sub.tblEmployer_ParentChild epc2 ON epc2.EmployerNumberChild = bpv.EmployerNumber
CROSS JOIN sub.tblSubsidyScheme ssc
WHERE	bpv.EmployeeNumber = @EmployeeNumber
AND		( bpv.EmployerNumber = @EmployerNumber
	OR	  ( epc1.EmployerNumberChild = @EmployerNumber 
		AND epc1.startdate <= @GetDate
		AND COALESCE(epc1.enddate, @GetDate+1) > @GetDate
		  )
	OR	  ( epc2.EmployerNumberParent = @EmployerNumber 
		AND epc2.startdate <= @GetDate
		AND COALESCE(epc1.enddate, @GetDate+1) > @GetDate
		  )
		)
AND		(	(@StartDate BETWEEN bpv.StartDate AND bpv.EndDate)
		OR	(@EndDate BETWEEN bpv.StartDate AND bpv.EndDate)
		OR	(@StartDate < bpv.StartDate AND @EndDate > bpv.EndDate)
		)
AND		ssc.SubsidySchemeID = 2
GROUP BY 
		bpv.CourseID,
		bpv.CourseName,
		ssc.SubsidySchemeID,
		ssc.SubsidySchemeName

UNION

--	Actual Horus declaration for the same EmployerNumber/Employee no overlap.
SELECT	NULL				AS DeclarationID,
		bpv.CourseID		AS EducationID,
		bpv.CourseName + ' (' + CAST(bpv.CourseID AS varchar(10)) + ')'	AS EducationName,
		MIN(bpv.StartDate)	AS StartDate,
		MAX(bpv.EndDate)	AS EndDate,
		ssc.SubsidySchemeID,
		ssc.SubsidySchemeName,
		CAST(0 AS bit)		AS ModifyOnly,
		CAST(1 AS bit)		AS ExtendOnly,
		NULL				AS UltimateEndDate,
		CAST(CASE WHEN MAX(bpv.EndDate) <= CAST(DATEADD(MONTH, 6, GETDATE()) AS date)
				THEN 1
				ELSE 0
			 END AS bit)	AS CanExtend
FROM	hrs.viewBPV bpv
LEFT JOIN sub.tblEmployer_ParentChild epc1 ON epc1.EmployerNumberParent = bpv.EmployerNumber
LEFT JOIN sub.tblEmployer_ParentChild epc2 ON epc2.EmployerNumberChild = bpv.EmployerNumber
CROSS JOIN sub.tblSubsidyScheme ssc
WHERE	bpv.EmployeeNumber = @EmployeeNumber
AND		( bpv.EmployerNumber = @EmployerNumber
	OR	  ( epc1.EmployerNumberChild = @EmployerNumber 
		AND epc1.startdate <= @GetDate
		AND COALESCE(epc1.enddate, @GetDate+1) > @GetDate
		  )
	OR	  ( epc2.EmployerNumberParent = @EmployerNumber 
		AND epc2.startdate <= @GetDate
		AND COALESCE(epc1.enddate, @GetDate+1) > @GetDate
		  )
		)
AND		bpv.CourseID = @EducationID
AND		ssc.SubsidySchemeID = 2
AND		COALESCE(@EducationID, 0) <> 0
GROUP BY 
		bpv.CourseID,
		bpv.CourseName,
		ssc.SubsidySchemeID,
		ssc.SubsidySchemeName

/* Get ultimate enddate.	*/
--	Determine EducationID.
IF ISNULL(@EducationID, 0) = 0
BEGIN
	;WITH cteLastEducation AS	
	(
		SELECT	MAX(StartDate)	AS MaxStartDate
		FROM	@tblResult t1
	)
	SELECT	@EducationID = res.EducationID
	FROM	@tblResult res
	INNER JOIN cteLastEducation cte ON cte.MaxStartDate = res.StartDate
END

-- Execute stip.uspCalculateUltimateDiplomaDate.
IF	ISNULL(@EducationID, 0) <> 0
AND (SELECT COUNT(1) FROM @tblResult) > 0
BEGIN
	DECLARE @RC int,
			@DeclarationID int = 0

	DECLARE @tblDeclarationSorted	stip.uttUltimateDiplomaDate

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
	EXECUTE @RC = stip.uspCalculateUltimateDiplomaDate 
			@DeclarationID,
			@EmployerNumber,
			@EmployeeNumber,
			@EducationID,
			@StartDate,
			@EndDate

	SELECT	TOP 1
			@UltimateEnddate = UltimateDiplomaDate
	FROM	@tblDeclarationSorted

	-- Update @tblResult with correct ultimate diplomadate.
	UPDATE	@tblResult
	SET		UltimateEndDate = @UltimateEnddate
	WHERE	EducationID = @EducationID
END

SELECT * FROM @tblResult

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== stip.uspDeclaration_CheckOnRunningEducation ===========================================	*/
