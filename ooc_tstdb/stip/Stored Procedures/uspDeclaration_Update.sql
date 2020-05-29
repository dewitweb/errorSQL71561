

CREATE PROCEDURE [stip].[uspDeclaration_Update]
@DeclarationID				int,
@EmployerNumber				varchar(6),
@EmployeeNumber				varchar(8),
@DeclarationDate			datetime,
@InstituteID				int,
@EducationID				int,
@StartDate					date,
@EndDate					date,
@BPV_StartDate				date,
@BPV_EndDate				date,
@BPV_Extension				bit,
@BPV_TerminationReason		varchar(20),
@InstituteName				varchar(100),
@CurrentUserID				int = 1
AS

/*	==========================================================================================
	Purpose: 	Update stip.tblDeclaration on basis of DeclarationID.

	11-02-2020	Sander van Houten	OTIBSUB-1897	Corrected the code for deleting partition(s).
	27-01-2020	Sander van Houten	OTIBSUB-1852	Added BPV EmployerNumber and CourseID to 
                                        stip.Declaration_BPV.
	23-01-2020	Sander van Houten	OTIBSUB-1845	Update of declarationstatus at the end of 
                                        this procedure must be executed when there is 
                                        no partition, but there is an active BPV present.
	08-01-2020	Sander van Houten	OTIBSUB-1805	Update of declarationstatus at the end of 
                                        this procedure must not be executed when there is 
                                        no partition present.
	16-12-2019	Jaap van Assenbergh	OTIBSUB-1776	Bij goed keuren op controle lopende BPV 
										wordt er geen Logging weggeschreven van	de partitie. 
										@PartitionStatus added to stip.uspCalculateReferenceDates.
	26-11-2019	Sander van Houten	OTIBSUB-1730	If an extension for an Opscholing BPV is
                                        inserted then don't create partitions.
                                        The final partition is created when the employer
                                        terminates the declaration.
	11-11-2019	Sander van Houten	OTIBSUB-1539	DeclarationStatus -> PartitionStatus.
	10-09-2019	Sander van Houten	OTIBSUB-1497	Added DiplomaDate bit field to @tblReferenceDate.
	05-09-2019	Sander van Houten	OTIBSUB-1535	Added update of declaration amount.
	21-08-2019	Sander van Houten	OTIBSUB-1263	Added status 0027.
	21-08-2019	Sander van Houten	OTIBSUB-1499	Split up call to stip.uspCalculateReferenceDates
										and stip.uspCalculateUltimateDiplomaDate.
	14-08-2019	Sander van Houten	OTIBSUB-1453	Added call to stip.uspCalculateReferenceDates.
	02-08-2019	Sander van Houten	OTIBSUB-1400	Admin is user for Unknown Source update.
	30-07-2019	Jaap van Assenbergh	OTIBSUB-1290	Uitwisselen beroepsopleidingen en 
										instituten STIP
	29-07-2019	Sander van Houten	OTIBSUB-1415	Subtract time used in Horus of 
										nominal duration.
	03-07-2019	Sander van Houten	OTIBSUB-1263	Handle declarations for educations
										without a nominal duration.
	01-07-2019	Sander van Houten	OTIBSUB-1297	Set UserID = 1 for status change to 0023.
	18-06-2019	Sander van Houten	OTIBSUB-1147	Added STIP StartDate part.
	27-05-2019	Sander van Houten	Added calculation of partitions.
	01-05-2019	Jaap van Assenbergh	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Testdata.
DECLARE	@DeclarationID				int = 407748,
		@EmployerNumber				varchar(6) = '122160',
		@EmployeeNumber				varchar(8) = '06633940',
		@DeclarationDate			datetime = '2019-09-16 12:34:23.557',
		@InstituteID				int = 6910,
		@EducationID				int = 25349,
		@StartDate					date = '2019-08-01',
		@EndDate					date = '2021-07-31',
		@BPV_StartDate				date = '2018-01-23',
		@BPV_EndDate				date = '2018-07-31',
		@BPV_Extension				bit = 0,
		@BPV_TerminationReason		varchar(20) = NULL,
		@InstituteName				varchar(100) = '',
		@CurrentUserID				int = 1
--*/

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

DECLARE @SubsidySchemeID		int = 4,
		@PaymentDate			date,
		@Partitions				xml,
		@DeclarationAmount		decimal(19,2),
		@PartitionAmount		decimal(19,2),
		@DiplomaDate			date,
		@EndDateEducation		date,
		@NominalDuration		decimal(3,1),
		@TotalUsedDuration		decimal(3,1),
		@Extension				bit = 0,
		@UserAction				varchar(6),
		@ExtensionID			int,
		@InitialStartDate		date,
		@InitialEndDate			date,
		@PreviousStartDate		date,
		@UltimateDiplomaDate	date,
        @TypeBPV                varchar(10) = 'Instroom',
		@RC						int

DECLARE @PartitionID				int,
		@PartitionYear				varchar(20),
		@PartitionAmountCorrected	decimal(19,4),
		@PartitionStatus			varchar(4),
		@VoucherNumber				varchar(3),
		@DiplomaPartition			bit

DECLARE @EmployerNumber_BPV varchar(6),
        @CourseID_BPV       int

DECLARE @Declaration TABLE (DeclarationID int)

DECLARE @Declaration_Extension TABLE (ExtensionID int)

DECLARE @tblDeclarationSorted	stip.uttUltimateDiplomaDate,
        @tblPartition			stip.uttReferenceDate

/*	Set variables.	*/
SELECT	@PaymentDate = DATEADD(D, -1, DATEADD(M, 6, @StartDate))

SELECT	@EndDateEducation = CASE WHEN NominalDuration IS NULL
								THEN @StartDate
								ELSE DATEADD(YEAR, NominalDuration, COALESCE(@BPV_Startdate, @StartDate))
							END,
		@NominalDuration = ISNULL(NominalDuration, 0)
FROM	sub.tblEducation
WHERE	EducationID = @EducationID

/*	Calculate partitionamount.	*/
SELECT	@PartitionAmount = aex.SettingValue / 2
FROM	sub.tblApplicationSetting aps
INNER JOIN sub.tblApplicationSetting_Extended aex ON aex.ApplicationSettingID = aps.ApplicationSettingID
WHERE	aps.SettingName = 'SubsidyAmountPerType'
AND		aps.SettingCode = 'STIP'
AND		@StartDate BETWEEN aex.StartDate AND aex.EndDate

/*	Determine highest ExtensionID.	*/
SELECT	@ExtensionID = MAX(ExtensionID)
FROM	sub.tblDeclaration_Extension
WHERE	DeclarationID = @DeclarationID

/*	Is this an insert or an update?	*/
IF @DeclarationID IS NULL				-- No declaration yet.
 OR (	@DeclarationID IS NOT NULL		-- No extension and no payment on partition yet.
 AND	@ExtensionID IS NULL
 AND	EXISTS (SELECT	1
				FROM	sub.tblPaymentRun_Declaration 
				WHERE	DeclarationID = @DeclarationID
			   )
	)
 OR (	@DeclarationID IS NOT NULL		-- No payment on current extension yet.
 AND	@ExtensionID IS NOT NULL
 AND	EXISTS (SELECT	1
				FROM	sub.tblDeclaration_Extension dex
				INNER JOIN sub.tblPaymentRun_Declaration pad
				ON		pad.DeclarationID = dex.DeclarationID
				INNER JOIN sub.tblDeclaration_Partition dep
				ON		dep.PartitionID = pad.PartitionID
				WHERE	dex.ExtensionID = @ExtensionID
				AND		dep.PaymentDate >= dex.StartDate
			   )
	)
BEGIN
	SET @UserAction = 'Insert'
END
ELSE
BEGIN
	SET @UserAction = 'Update'
END
	
/*	Is this an initial declaration or an extension?	*/
IF (@UserAction = 'Insert' AND @DeclarationID IS NOT NULL)
OR (@UserAction = 'Update' AND @ExtensionID IS NOT NULL)
BEGIN
	SET @Extension = 1
END

-- Get initial enddate (for partition deletion).
IF @Extension = 1
BEGIN
	SELECT	@InitialEndDate = MAX(ISNULL(dex.EndDate, d.enddate))
	FROM	sub.tblDeclaration d
	LEFT JOIN sub.tblDeclaration_Extension dex 
	ON		dex.DeclarationID = d.DeclarationID
	AND		dex.ExtensionID <> COALESCE(@ExtensionID, 0)
	WHERE	d.DeclarationID = @DeclarationID
	GROUP BY
			d.DeclarationID
END

IF @Extension = 0
BEGIN
	/*  Get current DeclarationAmount.	*/
	IF @DeclarationID IS NOT NULL
	BEGIN 
		SELECT	@DeclarationAmount = ISNULL(DeclarationAmount, 0.00)
		FROM	sub.tblDeclaration
		WHERE	DeclarationID = @DeclarationID
	END

	/*	Create new or update existing declaration.	*/
	INSERT INTO @Declaration
	EXECUTE sub.uspDeclaration_Upd
		@DeclarationID,
		@EmployerNumber,
		@SubsidySchemeID,
		@DeclarationDate,
		@InstituteID,
		@StartDate,
		@EndDate,
		@DeclarationAmount,
		@Partitions,
		@CurrentUserID

	/*	Get new DeclarationID.	*/
	SELECT	@DeclarationID = DeclarationID 
	FROM	@Declaration

    /*  Check if this is an extension on an Opscholing BPV. */
    IF EXISTS ( 
                SELECT  1
                FROM    hrs.tblBPV
                WHERE   EmployerNumber = @EmployerNumber
                AND     EmployeeNumber = @EmployeeNumber
                AND     CourseID = @EducationID
                AND     TypeBPV = 'Opscholing'
              )
    BEGIN
        SET @TypeBPV = 'Opscholing'
    END
END
ELSE
BEGIN
	/*	Create new or update existing declaration extension.	*/
	IF @UserAction = 'Insert'
		SET @ExtensionID = 0

	INSERT INTO @Declaration_Extension
	EXECUTE sub.uspDeclaration_Extension_Upd
		@ExtensionID,
		@DeclarationID,
		@StartDate,
		@EndDate,
		@InstituteID,
		@CurrentUserID

	/*	Get new ExtensionID.	*/
	SELECT	@ExtensionID = ExtensionID 
	FROM	@Declaration_Extension
END

/*	If there is a running BPV it should be terminated.	*/
IF	@BPV_StartDate IS NOT NULL
BEGIN
	SELECT	@PartitionStatus = '0023',
			@BPV_Extension = ISNULL(@BPV_Extension, 0)

    SELECT  @EmployerNumber_BPV = EmployerNumber,
            @CourseID_BPV = CourseID
    FROM    hrs.viewBPV
    WHERE   EmployeeNumber = @EmployeeNumber
    AND     StartDate = @BPV_StartDate
    AND     EndDate = @BPV_EndDate

	EXEC stip.uspDeclaration_BPV_Upd
		@DeclarationID,
		@BPV_StartDate,
		@BPV_EndDate,
		@BPV_Extension,
		@BPV_TerminationReason,
        @TypeBPV,
        @EmployerNumber_BPV,
        @CourseID_BPV,
		1	-- UserID Admin
END

/*	Create partitions.	*/
IF @NominalDuration > 0.0 AND @TypeBPV = 'Instroom'   --No BPV or Instroom.
BEGIN
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
	EXECUTE @RC = [stip].[uspCalculateUltimateDiplomaDate] 
		@DeclarationID,
		@EmployerNumber,
		@EmployeeNumber,
		@EducationID,
		@StartDate,
		@EndDate

	INSERT INTO @tblPartition
		(
			PartitionID,
			DeclarationID,
			PartitionYear,
			PartitionAmount,
			PartitionAmountCorrected,
			PaymentDate,
			PartitionStatus,
			CreatePartition,
			DiplomaPartition
		)
	EXECUTE @RC = [stip].[uspCalculateReferenceDates] 
		@DeclarationID,
		@PartitionStatus,
		@EmployerNumber,
		@EmployeeNumber,
		@EducationID,
		@StartDate,
		@EndDate,
		@tblDeclarationSorted
END

-- Add/Update record(s) in sub.tblDeclaration_Partition.
-- Then add refill table variable with new data
-- and delete absolete records from tblDeclaration_Partition.
DECLARE cur_Partition_del CURSOR FOR 
	SELECT 
			dep.PartitionID
	FROM	sub.tblDeclaration_Partition dep
	LEFT JOIN @tblPartition par
	ON		par.DeclarationID = dep.DeclarationID
	AND		par.PartitionYear = dep.PartitionYear
	AND		par.CreatePartition = 1
	WHERE	dep.DeclarationID = @DeclarationID
	AND		dep.PaymentDate > COALESCE(@InitialEndDate, DATEADD(D, -1, dep.PaymentDate))
	AND		par.DeclarationID IS NULL
		
OPEN cur_Partition_del

FETCH NEXT FROM cur_Partition_del INTO @PartitionID

WHILE @@FETCH_STATUS = 0  
BEGIN
	IF @VoucherNumber IS NOT NULL
	BEGIN
		EXECUTE sub.uspDeclaration_Partition_Voucher_Delete
			@DeclarationID,
			@EmployeeNumber,
			@VoucherNumber,
			@CurrentUserID,
			@PartitionID
	END

	EXECUTE sub.uspDeclaration_Partition_Del
		@PartitionID,
		@CurrentUserID

	FETCH NEXT FROM cur_Partition_del INTO @PartitionID
END

CLOSE cur_Partition_del
DEALLOCATE cur_Partition_del

-- and then insert new or update existing records in tblDeclaration_Partition.
DECLARE cur_Partition_upd CURSOR FOR 
	SELECT 
			t1.PartitionID,
			t1.PartitionYear,
			t1.PartitionAmount,
			t1.PartitionAmountCorrected,
			t1.PaymentDate,
			t1.PartitionStatus,
			t1.DiplomaPartition
	FROM @tblPartition t1
	INNER JOIN sub.tblDeclaration_Partition t2 ON t2.PartitionID = t1.PartitionID
	WHERE	t1.CreatePartition = 1
		AND (
				t1.PartitionYear <> t2.PartitionYear
			OR 	t1.PartitionAmount <> t2.PartitionAmount
			OR 	t1.PartitionAmountCorrected <> t2.PartitionAmountCorrected
			OR 	t1.PaymentDate <> t2.PaymentDate
			OR 	t1.PartitionStatus <> t2.PartitionStatus
			)

	UNION

	SELECT 
			t1.PartitionID,
			t1.PartitionYear,
			t1.PartitionAmount,
			t1.PartitionAmountCorrected,
			t1.PaymentDate,
			t1.PartitionStatus,
			t1.DiplomaPartition
	FROM @tblPartition t1
	LEFT JOIN sub.tblDeclaration_Partition t2 ON t2.PartitionID = t1.PartitionID
	WHERE	t1.CreatePartition = 1
	AND		t2.DeclarationID IS NULL

OPEN cur_Partition_upd

FETCH NEXT FROM cur_Partition_upd INTO @PartitionID, @PartitionYear, @PartitionAmount, @PartitionAmountCorrected, 
										@PaymentDate, @PartitionStatus, @DiplomaPartition

WHILE @@FETCH_STATUS = 0  
BEGIN

	EXECUTE sub.uspDeclaration_Partition_Upd
		@PartitionID,
		@DeclarationID,
		@PartitionYear,
		@PartitionAmount,
		@PartitionAmountCorrected,
		@PaymentDate,
		@PartitionStatus,
		@CurrentUserID

	IF @DiplomaPartition = 1
	BEGIN
		SET @DiplomaDate = @PaymentDate
	END

	FETCH NEXT FROM cur_Partition_upd INTO @PartitionID, @PartitionYear, @PartitionAmount, @PartitionAmountCorrected, 
											@PaymentDate, @PartitionStatus, @DiplomaPartition
END

CLOSE cur_Partition_upd
DEALLOCATE cur_Partition_upd

/*	Set DiplomaDate.	*/
IF	@DiplomaDate IS NULL
AND	@EndDate > (SELECT DATEADD(MONTH, -6, @EndDateEducation))
BEGIN
	SET	@DiplomaDate = @EndDate
END

/*	Insert or update STIP-part of declaration.	*/
BEGIN
	EXECUTE stip.uspDeclaration_Upd
		@DeclarationID, 
		@EducationID,
		@DiplomaDate,
		NULL,
		NULL,
		NULL,
		NULL,
		@CurrentUserID
END

/*	Update the declaration amount.	*/
DECLARE @DeclarationAmount_New	decimal(19,2)

SELECT	@DeclarationAmount_New = DeclarationAmount
FROM	stip.viewDeclaration_DynamicAmount
WHERE	DeclarationID = @DeclarationID

IF ISNULL(@DeclarationAmount, 0.00) <> @DeclarationAmount_New
BEGIN
	EXEC sub.uspDeclaration_Upd_DeclarationAmount
		@DeclarationID,
		@DeclarationAmount_New,
		1
END

DECLARE @DeclarationStatus	varchar(20) = NULL,
		@DeclarationReason	varchar(max) = NULL

IF ISNULL(@InstituteID, 0) = 0
	OR ISNULL(@NominalDuration, 0) = 0
BEGIN
	EXEC stip.uspDeclaration_Unknown_Source_Upd
		@DeclarationID,
		@InstituteID,
		@InstituteName,
		NULL,
		NULL,
		@EducationID,
		@NominalDuration,
		1

	IF ISNULL(@NominalDuration, 0) = 0
	BEGIN	-- And the status of the STIP-declaration must be adjusted.
		SET	@DeclarationStatus = '0027'

		EXEC sub.uspDeclaration_Upd_DeclarationStatus
			@DeclarationID,
			@DeclarationStatus,
			@DeclarationReason,
			1	-- UserID Systeem
	END
END
ELSE
BEGIN
	IF	(											-- Unknown combination of education and institute
			SELECT	COUNT(1) 
			FROM	sub.tblEducation_Institute
			WHERE	EducationID = @EducationID 
			AND		InstituteID = @InstituteID
		) = 0
	BEGIN
		EXEC stip.uspDeclaration_Unknown_Source_Upd
			@DeclarationID,
			@InstituteID,
			NULL,
			NULL,
			NULL,
			@EducationID,
			@NominalDuration,
			1	
	END
END

--  Get status of active partition (OTIBSUB-1539).
SELECT	@DeclarationStatus = PartitionStatus
FROM	sub.tblDeclaration_Partition
WHERE	PartitionID = sub.usfGetActivePartitionByDeclaration (@DeclarationID, GETDATE())		

-- In case of active BPV, but no partition. Set DeclarartionStatus to 0023 (Check on active BPV).
IF  @DeclarationStatus IS NULL AND @PartitionStatus = '0023'
BEGIN
    SET @DeclarationStatus = @PartitionStatus
END

-- Update the status of the declaration.
IF @DeclarationStatus IS NOT NULL
BEGIN
    EXEC sub.uspDeclaration_Upd_DeclarationStatus
        @DeclarationID,
        @DeclarationStatus,
        @DeclarationReason,
        1	-- UserID Admin
END

/*	Give back the DeclarationID.	*/
SELECT	DeclarationID = @DeclarationID,
		ExtensionID = @ExtensionID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== stip.uspDeclaration_Update ============================================================	*/
