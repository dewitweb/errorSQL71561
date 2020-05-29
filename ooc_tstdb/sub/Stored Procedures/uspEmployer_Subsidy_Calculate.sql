CREATE PROCEDURE [sub].[uspEmployer_Subsidy_Calculate]
@SubsidySchemeName	varchar(50),
@SubsidyDate		date

AS
/*	==========================================================================================
	Purpose:	Calculate subsidy amount for employers 
				for a specific subsidyscheme on a specific reference date.
				The reference date is set to the second monday in january in any year.

	06-01-2020	Jaap van Assenbergh	OTIBSUB-1806	Uitsluiten werknemers met STIP 
                                        bij berekening scholingsbudget OSR.
	06-01-2020	Sander van Houten	OTIBSUB-1806    Budget amount needs to be extracted from
                                        sub.tblApplicationSetting_Extended 
                                        not from sub.tblApplicationSetting.
	19-12-2019	Sander van Houten	OTIBSUB-1794    Only calculate budgets for a specific year
                                        if the current date >= reference date for that year.
	02-09-2019	Jaap van Assenbergh	OTIBSUB-1476    Rapportage met verplichtingen OSR
									    Save not only the amount but also the values for calculation.
	23-08-2019	Sander van Houten	OTIBSUB-1365    Simplified the procedure (a bit).
	22-08-2019	Sander van Houten	OTIBSUB-1365    Calculate budget if employers are employed
										after the referencedate.
	16-08-2019	Sander van Houten	OTIBSUB-1176    Use hrs.viewBPV instead of hrs.tblBPV.
	17-06-2019	Jaap van Assenbergh	OTIBSUB-1225    Aanpassen scholingsbudget conflicteert met 
									    subsidie berekening
	29-05-2019	Jaap van Assenbergh	OTIBSUB-1132    Definitie van 'Actieve BPV's'
	19-12-2018	Jaap van Assenbergh	OTIBSUB-1161    Verwijderen Employer_Subsidie bij laatste 
									    werknemer uit dienst
	03-01-2019	Sander van Houten	OTIBSUB-100     Scholingsbudgetten samenvoegen.
	19-12-2018	Jaap van Assenbergh	OTIBSUB-604     BPV uitsluiten scholingsbudget OSR
	14-09-2018	Jaap van Assenbergh	Added SubsideDate and SubsidyAmount in period
									from ApplicationSettings_Extended
	16-08-2018	Sander van Houten	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/* Testdata
DECLARE @SubsidySchemeName	varchar(50) = 'OSR',
		@SubsidyDate		date = NULL
--*/

SET NOCOUNT ON
DECLARE @Return int = 1

DECLARE @CurrentUserID					int = 1,	--Admin
		@SubsidySchemeID				int = 0,
		@StartMonth						int = 0,
		@ReferenceDate					date,
		@StartDate						date,
		@EndDate						date,
        @InitialCalculation             datetime,
		@SubsidyYear					varchar(20),
		@SubsidyAmountPerEmployee		decimal(19,4),
		@SubsidyAmountPerEmployer		decimal(19,4),
		@NrOfEmployees					int, 
		@NrOfEmployees_WithoutSubsidy	int

DECLARE @Employer_Subsidy TABLE 
	(
		EmployerNumber					varchar(6) NOT NULL INDEX IXes CLUSTERED,
		NrOfEmployees					int,
		NrOfEmployees_WithoutSubsidy	int,
		TotalAmount						decimal(19,4),
		NewRecord						bit NOT NULL
	)

DECLARE @Employer_Subsidy_ModifiedByOTIB TABLE 
	(
		EmployerNumber	varchar(6) NOT NULL INDEX IXmbo CLUSTERED
	)

DECLARE @WithoutSubsidy AS table
	(
		EmployerNumber varchar(6) NOT NULL INDEX IXws CLUSTERED, 
		WithoutSubsidy int
	)

DECLARE @ParentChildSubsidy AS table
	(
		EmployerNumber                  varchar(6) NOT NULL INDEX IXpcs CLUSTERED, 
		SumNrOfEmployees                int,
		SumNrOfEmployees_WithoutSubsidy	int,
		SumTotalAmount                  dec(19,4)
	)

/*	Initialize subsidydate when empty.	*/ 
IF @SubsidyDate IS NULL SET @SubsidyDate = GETDATE()

-- Set @SubsidySchemeID.
SELECT	@SubsidySchemeID = SubsidySchemeID,
		@StartMonth = StartMonth
FROM	sub.tblSubsidyScheme 
WHERE	SubsidySchemeName = @SubsidySchemeName

-- Set subsidy amount per employer for this year
SELECT	@SubsidyAmountPerEmployer = CAST(apse.SettingValue AS decimal(19,4)), 
		@StartDate = apse.StartDate, 
		@EndDate = apse.EndDate, 
		@ReferenceDate = apse.ReferenceDate,
        @InitialCalculation = apse.InitialCalculation
FROM	sub.tblApplicationSetting aps
INNER JOIN sub.tblApplicationSetting_Extended apse 
ON	    apse.ApplicationSettingID = aps.ApplicationSettingID
WHERE	aps.SettingName = 'SubsidyAmountPerEmployer'
AND		aps.SettingCode = @SubsidySchemeName
AND		@SubsidyDate BETWEEN apse.StartDate AND apse.EndDate

-- If no SubsidyAmountPerEmployer is present then quit.
IF @@ROWCOUNT = 0 
BEGIN
    GOTO uspEmployer_Subsidy_Calculate_EXIT
END

-- If the referencedate for this year is not yet reached then exit.
IF @ReferenceDate > CAST(@SubsidyDate AS date) 
BEGIN
    GOTO uspEmployer_Subsidy_Calculate_EXIT
END

-- Set subsidy amount per employee for this year
SELECT	@SubsidyAmountPerEmployee = CAST(apse.SettingValue AS decimal(19,4)), 
		@StartDate = apse.StartDate, 
		@EndDate = apse.EndDate, 
		@ReferenceDate = apse.ReferenceDate
FROM	sub.tblApplicationSetting aps
INNER JOIN sub.tblApplicationSetting_Extended apse 
ON	    apse.ApplicationSettingID = aps.ApplicationSettingID
WHERE	aps.SettingName = 'SubsidyAmountPerEmployee'
AND		aps.SettingCode = @SubsidySchemeName
AND		@SubsidyDate BETWEEN apse.StartDate AND apse.EndDate

-- If no SubsidyAmountPerEmployee is present then quit.
IF @@ROWCOUNT = 0
BEGIN
    GOTO uspEmployer_Subsidy_Calculate_EXIT
END

SET @SubsidyYear = 
	CASE
		WHEN DATEPART(YEAR,@StartDate) = DATEPART(YEAR, @EndDate) 
			THEN CONVERT(varchar(10), DATEPART(YEAR, @StartDate)) 
		ELSE (CONVERT(varchar(4), DATEPART(YEAR, @StartDate)) + '/') + CONVERT(varchar(4), DATEPART(YEAR,@EndDate))
	END

-- Calculate subsidy amounts
IF ISNULL(@SubsidySchemeID, 0) <> 0
BEGIN
	-- STEP 1.
	-- Get all employers with an ModifiedByOTIB changed amount
	INSERT INTO  @Employer_Subsidy_ModifiedByOTIB (EmployerNumber)
	SELECT	LEFT(KeyID, 6)
	FROM	his.tblHistory
	WHERE	TableName = 'sub.tblEmployer_Subsidy'
	AND		SUBSTRING(KeyID, 8, 1) = 1			-- OSR
	AND		UserID <> 1							-- Not modified by Systeem
	AND		OldValue.value('(/row/Amount)[1]', 'varchar(max)') <> NewValue.value('(/row/Amount)[1]', 'varchar(max)')	
	AND		NewValue.value('(/row/SubsidyYear)[1]', 'varchar(max)') = @SubsidyYear

	-- STEP 2.
	-- Insert all employers for calculating that do not have an ModifiedByOTIB changed amount and
	-- have one ore more employers in employment before, on or after the referencedate 
	-- (but before the current date).
	INSERT INTO @Employer_Subsidy
		(
			EmployerNumber,
			NrOfEmployees,
			NrOfEmployees_WithoutSubsidy,
			TotalAmount,
			NewRecord
		)
	SELECT	emp.EmployerNumber, 
			0							NrOfEmployees,
			0							NrOfEmployees_WithoutSubsidy,
			@SubsidyAmountPerEmployer	TotalAmount,
			1							NewRecord
	FROM	sub.tblEmployer emp
	INNER JOIN sub.tblEmployer_Employee eme 
	ON		eme.EmployerNumber = emp.EmployerNumber
	WHERE	COALESCE(emp.EndDateMembership, @ReferenceDate) >= @ReferenceDate
	AND		eme.StartDate <= @SubsidyDate
	AND		COALESCE(eme.EndDate, @ReferenceDate) >= @ReferenceDate
	AND		emp.EmployerNumber NOT IN
			(
				SELECT  EmployerNumber
				FROM	@Employer_Subsidy_ModifiedByOTIB
			)
	GROUP BY emp.EmployerNumber

	-- STEP 3.
	-- Update all employer records with personal budgets
	-- if the employer has an employmentdate before or on the referencedate
	-- and does not have a running BPV.
	UPDATE	ems
	SET		ems.NrOfEmployees = 
			ISNULL(
			(
				SELECT	COUNT(1)
				FROM	sub.tblEmployer_Employee eme
				WHERE	eme.EmployerNumber = ems.EmployerNumber
				AND		eme.StartDate <= @ReferenceDate
				AND		ISNULL(eme.Enddate, @ReferenceDate) >= @ReferenceDate
				GROUP BY eme.EmployerNumber
			), 0)
	FROM	@Employer_Subsidy ems

	INSERT INTO @WithoutSubsidy
	SELECT	EmployerNumber, COUNT(1) WithoutSubsidy
	FROM	(	
				SELECT	bpv.EmployerNumber, bpv.EmployeeNumber 
				FROM	hrs.viewBPV bpv
				INNER JOIN	sub.tblEmployer_Employee eme 
						ON	eme.EmployerNumber = bpv.EmployerNumber 
						AND eme.EmployeeNumber = bpv.EmployeeNumber
						AND	eme.StartDate <= @ReferenceDate
						AND	ISNULL(eme.Enddate, @ReferenceDate) >= @ReferenceDate
				WHERE	bpv.StartDate <= @ReferenceDate
				AND		COALESCE(bpv.EndDate, @ReferenceDate) >= @ReferenceDate	
			UNION
				SELECT	stip.EmployerNumber, stip.EmployeeNumber
				FROM	stip.viewDeclaration stip
				INNER JOIN	sub.tblEmployer_Employee eme 
						ON	eme.EmployerNumber = stip.EmployerNumber 
						AND eme.EmployeeNumber = stip.EmployeeNumber
						AND	eme.StartDate <= @ReferenceDate
						AND	ISNULL(eme.Enddate, @ReferenceDate) >= @ReferenceDate
				WHERE	stip.StartDate <= @ReferenceDate
				AND		COALESCE(stip.EndDate, @ReferenceDate) >= @ReferenceDate
				AND		stip.DeclarationStatus NOT IN ('0023')
			) StipAndBPV
	GROUP BY EmployerNumber

	UPDATE	ems
	SET		ems.NrOfEmployees_WithoutSubsidy = WithoutSubsidy
	FROM	@Employer_Subsidy ems
	INNER JOIN @WithoutSubsidy ws 
			ON	ws.EmployerNumber = ems.EmployerNumber

	UPDATE	ems
	SET		ems.TotalAmount = ems.TotalAmount + ((ems.NrOfEmployees - ems.NrOfEmployees_WithoutSubsidy) * @SubsidyAmountPerEmployee)
	FROM	@Employer_Subsidy ems

	-- STEP 4.
	-- Move the budgets of the child companies to the parent company.
	INSERT INTO @ParentChildSubsidy
        (
            EmployerNumber,
            SumNrOfEmployees,
            SumNrOfEmployees_WithoutSubsidy,
            SumTotalAmount
        )
	SELECT  epc.EmployerNumberParent,
			SUM(ems.NrOfEmployees)		            AS SumNrOfEmployees,
			SUM(ems.NrOfEmployees_WithoutSubsidy)	AS SumNrOfEmployees_WithoutSubsidy,
			SUM(ems.TotalAmount)		            AS SumTotalAmount
	FROM	sub.tblEmployer_ParentChild epc 
	INNER JOIN @Employer_Subsidy ems 
	ON		ems.EmployerNumber = epc.EmployerNumberChild
	WHERE	@SubsidyDate BETWEEN epc.StartDate AND COALESCE(epc.EndDate, '20990101')
	GROUP BY 
			epc.EmployerNumberParent

	UPDATE	tmp
	SET		tmp.NrOfEmployees = tmp.NrOfEmployees + pcs.SumNrOfEmployees,
			tmp.TotalAmount = tmp.TotalAmount + pcs.SumTotalAmount
	FROM	@Employer_Subsidy tmp
	INNER JOIN @ParentChildSubsidy pcs 
	ON	    pcs.EmployerNumber = tmp.EmployerNumber

	-- If there is no parent record yet (because there are no active employees with that company)... create one.
    INSERT INTO @Employer_Subsidy
        (
            EmployerNumber,
            NrOfEmployees,
            NrOfEmployees_WithoutSubsidy,
            TotalAmount,
            NewRecord
        )
    SELECT  pcs.EmployerNumber,
            pcs.SumNrOfEmployees,
            pcs.SumNrOfEmployees_WithoutSubsidy,
            pcs.SumTotalAmount,
            CASE WHEN ems.EmployerNumber IS NULL
                THEN 1
                ELSE 0
            END AS NewRecord
    FROM    @ParentChildSubsidy pcs
    LEFT JOIN @Employer_Subsidy tmp
    ON      tmp.EmployerNumber = pcs.EmployerNumber
    LEFT JOIN sub.tblEmployer_Subsidy ems
    ON      ems.EmployerNumber = pcs.EmployerNumber
	AND		ems.SubsidySchemeID = @SubsidySchemeID
	AND		ems.StartDate = @StartDate
    WHERE   tmp.NewRecord IS NULL

    -- And remove the records of the child companies.
	DELETE	tmp
	FROM	@Employer_Subsidy tmp
	INNER JOIN sub.tblEmployer_ParentChild epc 
	ON		epc.EmployerNumberChild = tmp.EmployerNumber
	WHERE	@SubsidyDate BETWEEN epc.StartDate AND COALESCE(epc.EndDate, '20990101')

	-- STEP 5.
	-- Remove budgets from employers with a budget but without employees (anymore).
	-- This should never be the case!
	UPDATE	sub.tblEmployer_Subsidy
	SET		Amount = 0
	WHERE	EmployerNumber NOT IN 
			(
				SELECT	EmployerNumber
				FROM	@Employer_Subsidy
				UNION ALL
				SELECT	EmployerNumber
				FROM	@Employer_Subsidy_ModifiedByOTIB
			)
	AND		SubsidySchemeID = @SubsidySchemeID
	AND		StartDate = @StartDate

	-- STEP 6.
	-- Remove those who already had a record for this year and had no change in subsidy amount.
	DELETE	tmp
	FROM	@Employer_Subsidy tmp
	INNER JOIN sub.tblEmployer_Subsidy ems 
			ON	ems.EmployerNumber = tmp.EmployerNumber
	WHERE	ems.SubsidySchemeID = @SubsidySchemeID
	AND		ems.StartDate = @StartDate
	AND		ems.Amount = tmp.TotalAmount
	AND 	ISNULL(ems.NumberOfEmployee, 0) = tmp.NrOfEmployees
	AND		ISNULL(ems.NumberOfEmployee_WithoutSubsidy, 0) = tmp.NrOfEmployees_WithoutSubsidy

	-- STEP 7.
	-- Set indication NewRecord to false if a record already exists.
	UPDATE	tmp
	SET		tmp.NewRecord = 0
	FROM	@Employer_Subsidy tmp
	INNER JOIN sub.tblEmployer_Subsidy ems
			ON ems.EmployerNumber = tmp.EmployerNumber
	WHERE	ems.SubsidySchemeID = @SubsidySchemeID
	AND		ems.StartDate = @StartDate

	-- STEP 8.
	/* Remove subsidies of active child companies.	*/
	DELETE	ems
	FROM	sub.tblEmployer_Subsidy ems
	INNER JOIN sub.tblEmployer_ParentChild epc
			ON	epc.EmployerNumberChild = ems.EmployerNumber
	INNER JOIN @ParentChildSubsidy pcs 
			ON	pcs.EmployerNumber = epc.EmployerNumberParent
	WHERE	@SubsidyDate BETWEEN epc.StartDate AND COALESCE(epc.EndDate, '20990101')
    AND     @SubsidyDate BETWEEN ems.StartDate AND COALESCE(ems.EndDate, '20990101')

	-- STEP 9.
	/* Update subsidies that have changed */
	DECLARE @updEmployerNumber varchar(8),
			@updStartDate	date,
			@updEndDate		date,
			@updAmount		decimal(19,4)
	
	DECLARE cur_emsupd CURSOR FOR 
		SELECT	ems.EmployerNumber,
				ems.StartDate,
				ems.EndDate,
				tmp.TotalAmount,
				tmp.NrOfEmployees,
				tmp.NrOfEmployees_WithoutSubsidy
		FROM	@Employer_Subsidy tmp
		INNER JOIN sub.tblEmployer_Subsidy ems
				ON ems.EmployerNumber = tmp.EmployerNumber
		WHERE	tmp.NewRecord = 0	
		AND		ems.SubsidySchemeID = @SubsidySchemeID
		AND		ems.StartDate = @StartDate
		
	OPEN cur_emsupd

	FETCH FROM cur_emsupd 
	INTO @updEmployerNumber, @updStartDate, @updEndDate, @updAmount, @NrOfEmployees, @NrOfEmployees_WithoutSubsidy

	WHILE @@FETCH_STATUS = 0  
	BEGIN
		BEGIN TRANSACTION updSub
		-- Update existing record

--		print @updEmployerNumber

		EXEC sub.uspEmployer_Subsidy_Upd
			@updEmployerNumber,
			@SubsidySchemeID,
			@updStartDate,
			@updEndDate,
			@updAmount,
			@SubsidyAmountPerEmployer,
			@SubsidyAmountPerEmployee,
			@NrOfEmployees, 
			@NrOfEmployees_WithoutSubsidy,
			NULL,
			@CurrentUserID

		COMMIT TRANSACTION updSub

		FETCH NEXT FROM cur_emsupd 
		INTO @updEmployerNumber, @updStartDate, @updEndDate, @updAmount, @NrOfEmployees, @NrOfEmployees_WithoutSubsidy
	END

	CLOSE cur_emsupd
	DEALLOCATE cur_emsupd

	-- STEP 10.
	/* Add new subsidies */
	DECLARE @newEmployerNumber varchar(8),
			@newStartDate	date,
			@newEndDate		date,
			@newAmount		decimal(19,4)
	
	DECLARE cur_emsnew CURSOR FOR 
		SELECT	tmp.EmployerNumber,
				@StartDate,
				@EndDate,
				tmp.TotalAmount,
				tmp.NrOfEmployees,
				tmp.NrOfEmployees_WithoutSubsidy
		FROM	@Employer_Subsidy tmp
		WHERE	tmp.NewRecord = 1	
		
	OPEN cur_emsnew

	FETCH FROM cur_emsnew 
	INTO @newEmployerNumber, @newStartDate, @EndDate, @newAmount, @NrOfEmployees, @NrOfEmployees_WithoutSubsidy

	WHILE @@FETCH_STATUS = 0  
	BEGIN
		-- Add new record
		BEGIN TRANSACTION addSub

		EXEC sub.uspEmployer_Subsidy_Upd
			@newEmployerNumber,
			@SubsidySchemeID,
			@newStartDate,
			@EndDate,
			@newAmount,
			@SubsidyAmountPerEmployer,
			@SubsidyAmountPerEmployee,
			@NrOfEmployees, 
			@NrOfEmployees_WithoutSubsidy,
			NULL,
			@CurrentUserID

		COMMIT TRANSACTION addSub
		FETCH NEXT FROM cur_emsnew 
		INTO @newEmployerNumber, @newStartDate, @EndDate, @newAmount, @NrOfEmployees, @NrOfEmployees_WithoutSubsidy
	END

	CLOSE cur_emsnew
	DEALLOCATE cur_emsnew

    -- Register that the calculation of scholingsbudget was done for the first time for this year.
    -- IF @InitialCalculation IS NULL
    -- BEGIN
    --     UPDATE  apse
    --     SET     apse.InitialCalculation = GETDATE()
    --     FROM	sub.tblApplicationSetting aps
    --     INNER JOIN sub.tblApplicationSetting_Extended apse 
    --             ON	apse.ApplicationSettingID = aps.ApplicationSettingID
    --     WHERE	aps.SettingName = 'SubsidyAmountPerEmployer'
    --     AND		aps.SettingCode = @SubsidySchemeName
    --     AND		@SubsidyDate BETWEEN apse.StartDate AND apse.EndDate
    -- END
END

SET @Return = 0

uspEmployer_Subsidy_Calculate_EXIT:

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

RETURN @Return

/*	== sub.uspEmployer_Subsidy_Calculate =====================================================	*/
