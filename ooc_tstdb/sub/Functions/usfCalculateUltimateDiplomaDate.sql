
CREATE FUNCTION [sub].[usfCalculateUltimateDiplomaDate]
/*	==============================================================
	Purpose:	Get the ultimate diplomadate for a Declaration.

	Input	:	DeclarationID

	23-01-2020	Sander van Houten   Initial version
	==============================================================	*/
(
	@DeclarationID		int
)
RETURNS date
AS
BEGIN
    DECLARE @EmployerNumber	varchar(6),
            @EmployeeNumber	varchar(8),
            @EducationID	int,
            @StartDate		date,
            @EndDate		date

    DECLARE @NominalDuration		tinyint,
            @Partitions				xml,
            @UltimateDiplomaDate	date,
            @PartitionAmount		decimal(19,2)
        
    DECLARE @tblDeclaration	TABLE
        (
            SubsidySchemeID	int,
            EmployerNumber	varchar(6),
            StartDate		date,
            EndDate			date,
            DeclarationID	int,
            ExtensionID		int,
            PauseYears		tinyint,
            PauseMonths		tinyint,
            PauseDays		tinyint,
            PauseYearsAll	tinyint,
            PauseMonthsAll	tinyint,
            PauseDaysAll	tinyint
        )
            
    DECLARE @tblDeclarationSorted TABLE
        (
            RecordID		int IDENTITY(1,1),
            SubsidySchemeID	int,
            EmployerNumber	varchar(6),
            StartDate		date,
            EndDate			date,
            DeclarationID	int,
            ExtensionID		int,
            PauseYears		tinyint,
            PauseMonths		tinyint,
            PauseDays		tinyint,
            PauseYearsAll	tinyint,
            PauseMonthsAll	tinyint,
            PauseDaysAll	tinyint
        )

    /* Get data from declaration.   */
    SELECT  @EmployerNumber	= EmployerNumber,
            @EmployeeNumber	= EmployeeNumber,
            @EducationID = EducationID,
            @StartDate = StartDate,
            @EndDate= EndDate,
            @NominalDuration = ISNULL(NominalDuration, 0)
    FROM    stip.viewDeclaration
    WHERE   DeclarationID = @DeclarationID

    IF @NominalDuration = 0
    /*  Give back a default date.  */
    BEGIN
        SET	@UltimateDiplomaDate = '19000101'
    END
    ELSE
    /* Get all declarations and extensions.	*/
    BEGIN
        -- BPV.
        INSERT INTO @tblDeclaration
            (
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
        SELECT	3,
                bpv.EmployerNumber,
                bpv.StartDate,
                bpv.EndDate,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0
        FROM	hrs.viewBPV bpv
        WHERE	bpv.EmployeeNumber = @EmployeeNumber
        AND		bpv.CourseID = @EducationID

        -- STIP (Initial declarations).
        INSERT INTO @tblDeclaration
            (
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
        SELECT	4,
                d.EmployerNumber,
                d.StartDate,
                d.EndDate,
                d.DeclarationID,
                0,
                0,
                0,
                0,
                0,
                0,
                0
        FROM	sub.tblDeclaration_Employee dem
        INNER JOIN sub.tblDeclaration d ON d.DeclarationID = dem.DeclarationID
        INNER JOIN stip.tblDeclaration stpd ON stpd.DeclarationID = d.DeclarationID
        WHERE	dem.EmployeeNumber = @EmployeeNumber
        AND		stpd.EducationID = @EducationID

        -- STIP (Extensions).
        INSERT INTO @tblDeclaration
            (
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
        SELECT	4,
                d.EmployerNumber,
                dex.StartDate,
                dex.EndDate,
                dex.DeclarationID,
                dex.ExtensionID,
                0,
                0,
                0,
                0,
                0,
                0
        FROM	sub.tblDeclaration_Employee dem
        INNER JOIN sub.tblDeclaration d ON d.DeclarationID = dem.DeclarationID
        INNER JOIN stip.tblDeclaration stpd ON stpd.DeclarationID = d.DeclarationID
        INNER JOIN sub.tblDeclaration_Extension dex ON dex.DeclarationID = d.DeclarationID
        WHERE	dem.EmployeeNumber = @EmployeeNumber
        AND		stpd.EducationID = @EducationID

        -- Remove a declaration/extension that is being updated.
        DELETE
        FROM	@tblDeclaration
        WHERE	SubsidySchemeID = 4
        AND		(
                    StartDate >= @StartDate
                OR	(	StartDate < @StartDate
                    AND	EndDate >= @StartDate
                    )
                )

        -- STIP (New declaration/extension).
        INSERT INTO @tblDeclaration
            (
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
        VALUES
            (
                4,
                @EmployerNumber,
                @StartDate,
                @EndDate,
                ISNULL(@DeclarationID, 0),
                0,
                0,
                0,
                0,
                0,
                0,
                0
            )

        -- Sort the declaration table.
        INSERT INTO @tblDeclarationSorted
            (
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
        SELECT	SubsidySchemeID,
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
        FROM	@tblDeclaration
        ORDER BY
                StartDate

        /* Correct data. No overlap is allowed.	*/
        UPDATE	t1
        SET		t1.EndDate = DATEADD(DAY, -1, t2.StartDate)
        FROM	@tblDeclarationSorted t1
        INNER JOIN @tblDeclarationSorted t2
        ON		t2.RecordID = t1.RecordID + 1
        WHERE	t1.EndDate >= t2.StartDate

        /* Calculate ultimate diplomadate.	*/
        DECLARE @InitialStartDate		date,
                @DiplomaDate			date,
                @curEmployerNumber		int,
                @curStartDate			date,
                @curEndDate				date,
                @prvEmployerNumber		int,
                @prvStartDate			date,
                @prvEndDate				date,
                @prvRecordID			int,
                @PauseYears				tinyint = 0,
                @PauseMonths			tinyint = 0,
                @PauseDays				tinyint = 0,
                @PauseYearsAll			tinyint = 0,
                @PauseMonthsAll			tinyint = 0,
                @PauseDaysAll			tinyint = 0
                
        -- First determine initial startdate.
        SELECT	@InitialStartDate = MIN(StartDate)
        FROM	@tblDeclarationSorted

        -- Then calculate the total pauseperiod (in months and days).
        DECLARE cur_Declaration CURSOR FOR 
            SELECT	StartDate,
                    EndDate,
                    EmployerNumber
            FROM	@tblDeclarationSorted
            ORDER BY 
                    RecordID
                
        OPEN cur_Declaration

        FETCH NEXT FROM cur_Declaration INTO @curStartDate, @curEndDate, @curEmployerNumber

        WHILE @@FETCH_STATUS = 0  
        BEGIN
            IF @prvEndDate IS NOT NULL
            BEGIN
                SELECT	@PauseYears = @PauseYears + CASE WHEN DifferenceInYears < 0 THEN 0 ELSE DifferenceInYears END,
                        @PauseMonths = @PauseMonths + CASE WHEN DifferenceInMonths < 0 THEN 0 ELSE DifferenceInMonths END,
                        @PauseDays = @PauseDays + CASE WHEN DifferenceInDays < 0 THEN 0 ELSE DifferenceInDays END,
                        @PauseYearsAll = @PauseYearsAll + CASE WHEN DifferenceInYears < 0 THEN 0 ELSE DifferenceInYears END,
                        @PauseMonthsAll = @PauseMonthsAll + CASE WHEN DifferenceInMonths < 0 THEN 0 ELSE DifferenceInMonths END,
                        @PauseDaysAll = @PauseDaysAll + CASE WHEN DifferenceInDays < 0 THEN 0 ELSE DifferenceInDays END
                FROM	sub.utfGetDateDifferenceInYearsMonthsDays(@prvEndDate, @curStartDate)

                UPDATE	@tblDeclarationSorted
                SET		PauseYears = @PauseYears,
                        PauseMonths = @PauseMonths,
                        PauseDays = @PauseDays,
                        PauseYearsAll = @PauseYearsAll,
                        PauseMonthsAll = @PauseMonthsAll,
                        PauseDaysAll = @PauseDaysAll
                WHERE	StartDate = @curStartDate
            END

            SELECT	@prvStartDate = @curStartDate,
                    @prvEndDate = @curEndDate,
                    @prvEmployerNumber = @curEmployerNumber

            FETCH NEXT FROM cur_Declaration INTO @curStartDate, @curEndDate, @curEmployerNumber
        END

        CLOSE cur_Declaration
        DEALLOCATE cur_Declaration

        -- Then calculate diplomadate derived from 
        -- initial startdate, nominal duration and pauseperiods, minus 1 day.
        SET @DiplomaDate = @InitialStartDate
        SET @DiplomaDate = DATEADD(YEAR, @NominalDuration, @DiplomaDate)
        SET @DiplomaDate = DATEADD(DAY, -1, @DiplomaDate)
        SET @DiplomaDate = DATEADD(YEAR, @PauseYearsAll, @DiplomaDate)
        SET @DiplomaDate = DATEADD(MONTH, @PauseMonthsAll, @DiplomaDate)
        SET @DiplomaDate = DATEADD(DAY, @PauseDaysAll, @DiplomaDate)

        -- Then calculate ultimate diplomadate (= diplomadate + 12 months).
        SET @UltimateDiplomaDate = DATEADD(MONTH, 12, @DiplomaDate)
    END

	RETURN @UltimateDiplomaDate
END

/*	==	sub.usfCalculateUltimateDiplomaDate ======================	*/
