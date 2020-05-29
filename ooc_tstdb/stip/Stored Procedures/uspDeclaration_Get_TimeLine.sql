CREATE PROCEDURE [stip].[uspDeclaration_Get_TimeLine]
@DeclarationID	int,
@UserID			int
AS
/*	==========================================================================================
	Purpose:	Get timeline information on a specific declaration.

	06-02-2020	Sander van Houten	OTIBSUB-1888	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*  Testdata.
DECLARE @DeclarationID	int = 407375,
        @UserID			int = 1
--  */

DECLARE @RowNumber              int,
        @LastRowNumber          int,
        @EmployerNumber         varchar(6),
        @PreviousEmployerNumber varchar(6) = '',
        @StartDate              date,
        @EmployerStartDate      date,
        @EndDate                date,
        @EmployerEndDate        date

DECLARE @tblTimeLine TABLE
(
    DeclarationType     varchar(20),
    DeclarationID       int,
    ExtensionID         int,
    EmployeeNumber      varchar(8),
    EducationID         int,
    EmployerNumber      varchar(6),
    EmployerStartDate   date,
    EmployerEndDate     date,
    StartDate           date,
    EndDate             date,
    PeriodDuration      int,
    NominalDuration     int,
    PaymentDate         date,
    RowNumber           int
)

--  Insert regular STIP data.
INSERT INTO @tblTimeLine
    (
        DeclarationType,
        DeclarationID,
        ExtensionID,
        EmployeeNumber,
        EducationID,
        EmployerNumber,
        EmployerStartDate,
        EmployerEndDate,
        StartDate,
        EndDate,
        PeriodDuration,
        NominalDuration,
        PaymentDate,
        RowNumber
    )
SELECT  'STIP'      AS DeclarationType,
        d.DeclarationID,
        0           AS ExtensionID,
        d.EmployeeNumber,
        d.EducationID,
        d.EmployerNumber,
        NULL,
        NULL,
        d.StartDate,
        CASE WHEN d.TerminationDate IS NULL
            THEN d.EndDate
            ELSE CASE WHEN d.TerminationDate < d.EndDate
                    THEN d.TerminationDate
                    ELSE d.EndDate
                 END
        END         AS EndDate,
        CASE WHEN d.TerminationDate IS NULL
            THEN DATEDIFF(MM, d.StartDate, DATEADD(DD, 1, d.EndDate))
            ELSE CASE WHEN d.TerminationDate < d.EndDate
                    THEN DATEDIFF(MM, d.StartDate, DATEADD(DD, 1, d.TerminationDate))
                    ELSE DATEDIFF(MM, d.StartDate, DATEADD(DD, 1, d.EndDate))
                 END
        END         AS PeriodDuration,
        d.NominalDuration,
        dep.PaymentDate,
        0
FROM	stip.viewDeclaration d
INNER JOIN sub.tblDeclaration_Partition dep
ON      dep.DeclarationID = d.DeclarationID
WHERE	d.DeclarationID = @DeclarationID
AND     dep.PaymentDate <= CASE WHEN d.TerminationDate IS NULL
                            THEN d.EndDate
                            ELSE CASE WHEN d.TerminationDate < d.EndDate
                                    THEN d.TerminationDate
                                    ELSE d.EndDate
                                 END
                           END

--  Insert STIP extension(s) data.
INSERT INTO @tblTimeLine
    (
        DeclarationType,
        DeclarationID,
        ExtensionID,
        EmployeeNumber,
        EducationID,
        EmployerNumber,
        EmployerStartDate,
        EmployerEndDate,
        StartDate,
        EndDate,
        PeriodDuration,
        NominalDuration,
        PaymentDate,
        RowNumber
    )
SELECT  'STIP_Verlenging'      AS DeclarationType,
        d.DeclarationID,
        dex.ExtensionID,
        d.EmployeeNumber,
        d.EducationID,
        d.EmployerNumber,
        NULL,
        NULL,
        dex.StartDate,
        CASE WHEN d.TerminationDate IS NULL
            THEN dex.EndDate
            ELSE CASE WHEN d.TerminationDate < dex.EndDate
                    THEN d.TerminationDate
                    ELSE dex.EndDate
                 END
        END         AS EndDate,
        CASE WHEN d.TerminationDate IS NULL
            THEN DATEDIFF(MM, d.StartDate, DATEADD(DD, 1, dex.EndDate))
            ELSE CASE WHEN d.TerminationDate < dex.EndDate
                    THEN DATEDIFF(MM, d.StartDate, DATEADD(DD, 1, d.TerminationDate))
                    ELSE DATEDIFF(MM, d.StartDate, DATEADD(DD, 1, dex.EndDate))
                 END
        END         AS PeriodDuration,
        d.NominalDuration,
        dep.PaymentDate,
        0
FROM	stip.viewDeclaration d
INNER JOIN sub.tblDeclaration_Extension dex
ON      dex.DeclarationID = d.DeclarationID
INNER JOIN sub.tblDeclaration_Partition dep
ON      dep.DeclarationID = d.DeclarationID
WHERE	d.DeclarationID = @DeclarationID
AND     dep.PaymentDate BETWEEN dex.StartDate AND CASE WHEN d.TerminationDate IS NULL
                                                    THEN DATEDIFF(MM, d.StartDate, DATEADD(DD, 1, dex.EndDate))
                                                    ELSE CASE WHEN d.TerminationDate < dex.EndDate
                                                            THEN DATEDIFF(MM, d.StartDate, DATEADD(DD, 1, d.TerminationDate))
                                                            ELSE DATEDIFF(MM, d.StartDate, DATEADD(DD, 1, dex.EndDate))
                                                         END
                                                  END

--  Insert BPV data.
INSERT INTO @tblTimeLine
    (
        DeclarationType,
        DeclarationID,
        ExtensionID,
        EmployeeNumber,
        EducationID,
        EmployerNumber,
        EmployerStartDate,
        EmployerEndDate,
        StartDate,
        EndDate,
        PeriodDuration,
        NominalDuration,
        PaymentDate,
        RowNumber
    )
SELECT  'BPV'               AS DeclarationType,
        d.DeclarationID,
        0                   AS ExtensionID,
        d.EmployeeNumber,
        d.EducationID,
        bpv.EmployerNumber,
        NULL,
        NULL,
        bpv.StartDate,
        bpv.EndDate,
        DATEDIFF(MM, bpv.StartDate, DATEADD(DD, 1, bpv.EndDate)),
        d.NominalDuration,
        dtg.ReferenceDate   AS PaymentDate,
        0
FROM	stip.viewDeclaration d
INNER JOIN hrs.viewBPV bpv
ON 		bpv.EmployeeNumber = d.EmployeeNumber
AND 	bpv.CourseID = d.EducationID
INNER JOIN hrs.viewBPV_DTG dtg
ON 		dtg.DSR_ID = bpv.DSR_ID
WHERE	d.DeclarationID = @DeclarationID
--AND     dtg.PaymentStatus = 1

--  Set RowNumbers.
;WITH cteTimeLine
AS
(
    SELECT  StartDate,
            PaymentDate,
            ROW_NUMBER () OVER (PARTITION BY DeclarationID ORDER BY  StartDate, PaymentDate ASC) AS RowNumber
    FROM    @tblTimeLine
)
UPDATE  t1
SET     t1.RowNumber = cte.RowNumber
FROM    @tblTimeLine t1
INNER JOIN cteTimeLine cte
ON      cte.StartDate = t1.StartDate
AND     cte.PaymentDate = t1.PaymentDate

--  Insert pause period(s).
INSERT INTO @tblTimeLine
    (
        DeclarationType,
        DeclarationID,
        ExtensionID,
        EmployeeNumber,
        EducationID,
        EmployerNumber,
        EmployerStartDate,
        EmployerEndDate,
        StartDate,
        EndDate,
        PeriodDuration,
        NominalDuration,
        PaymentDate,
        RowNumber
    )
SELECT  'PAUZE'         AS DeclarationType,
        t1.DeclarationID,
        0               AS ExtensionID,
        t1.EmployeeNumber,
        t1.EducationID,
        t1.EmployerNumber,
        NULL,
        NULL,
        DATEADD(D, 1, t1.EndDate)       AS StartDate,
        DATEADD(D, -1, t2.StartDate)    AS EndDate,
        DATEDIFF(MM, DATEADD(D, 1, t1.EndDate), DATEADD(DD, 1, DATEADD(D, -1, t2.StartDate)))    AS PeriodDuration,
        t1.NominalDuration,
        NULL                            AS PaymentDate,
        t1.RowNumber
FROM    @tblTimeLine t1
INNER JOIN @tblTimeLine t2
ON      t2.DeclarationID = t1.DeclarationID
WHERE   t2.RowNumber = t1.RowNumber + 1
AND     t2.StartDate <> t1.StartDate
AND     DATEDIFF(D, t1.EndDate, t2.StartDate) > 1

--  Reset RowNumbers.
;WITH cteTimeLine
AS
(
    SELECT  StartDate,
            COALESCE(PaymentDate, '20990101') AS PaymentDate,
            ROW_NUMBER () OVER (PARTITION BY DeclarationID ORDER BY StartDate, PaymentDate ASC) AS RowNumber
    FROM    @tblTimeLine
)
UPDATE  t1
SET     t1.RowNumber = cte.RowNumber
FROM    @tblTimeLine t1
INNER JOIN cteTimeLine cte
ON      cte.StartDate = t1.StartDate
AND     cte.PaymentDate = COALESCE(t1.PaymentDate, '20990101')

--  Update BPV DeclarationType if it is an extension.
UPDATE  t2
SET     t2.DeclarationType = 'BPV_Verlenging'
FROM    @tblTimeLine t1
INNER JOIN @tblTimeLine t2
ON      t2.DeclarationType = t1.DeclarationType
WHERE   t2.StartDate > t1.StartDate
AND     t1.DeclarationType = 'BPV'

/*  Add provisional diplomadate if there is no diplomadate partition present.   */
--  Check if a diploma is uploaded.
DECLARE @DiplomaDate    date

SELECT  @DiplomaDate = d.DiplomaDate
FROM    sub.tblDeclaration_Attachment dat
INNER JOIN stip.tblDeclaration d
ON      d.DeclarationID = dat.DeclarationID
WHERE   dat.DeclarationID = @DeclarationID
AND     dat.DocumentType = 'Certificate'
ORDER BY
        dat.DocumentType

--  Get last rownumber of @tblTimeLine.
SELECT  @LastRowNumber = MAX(RowNumber)
FROM    @tblTimeLine

IF NOT EXISTS (SELECT 1 FROM @tblTimeLine WHERE RowNumber = @LastRowNumber AND PaymentDate = @DiplomaDate)
BEGIN   --  Insert record for provisional diplomadate
    SELECT @DiplomaDate = sub.usfCalculateUltimateDiplomaDate(@DeclarationID)

    INSERT INTO @tblTimeLine
        (
            DeclarationType,
            DeclarationID,
            ExtensionID,
            EmployeeNumber,
            EducationID,
            EmployerNumber,
            EmployerStartDate,
            EmployerEndDate,
            StartDate,
            EndDate,
            PeriodDuration,
            NominalDuration,
            PaymentDate,
            RowNumber
        )
    SELECT  'DIPLOMA'                       AS DeclarationType,
            t1.DeclarationID,
            0                               AS ExtensionID,
            t1.EmployeeNumber,
            t1.EducationID,
            t1.EmployerNumber,
            NULL,
            NULL,
            DATEADD(D, 1, t1.EndDate)       AS StartDate,
            @DiplomaDate                    AS EndDate,
            DATEDIFF(MM, DATEADD(D, 1, t1.EndDate), @DiplomaDate)    AS PeriodDuration,
            t1.NominalDuration,
            NULL                            AS PaymentDate,
            t1.RowNumber + 1
    FROM    @tblTimeLine t1
    WHERE   t1.RowNumber = @LastRowNumber
END

--  Mark employer period(s).
DECLARE cur_TimeLine CURSOR FOR 
SELECT  RowNumber, 
        EmployerNumber,
        StartDate,
        EndDate
FROM 	@tblTimeLine
ORDER BY
        RowNumber

SET @LastRowNumber = 0

OPEN cur_TimeLine 

FETCH NEXT FROM cur_TimeLine INTO @RowNumber, @EmployerNumber, @StartDate, @EndDate

WHILE @@FETCH_STATUS = 0 
BEGIN
    IF @EmployerNumber <> @PreviousEmployerNumber
    BEGIN
        UPDATE  @tblTimeLine
        SET     @EmployerEndDate = @EmployerEndDate
        WHERE   EmployerNumber = @PreviousEmployerNumber
        AND     StartDate = @EmployerStartDate
        AND     RowNumber < @RowNumber

        UPDATE  @tblTimeLine
        SET     EmployerEndDate = @EmployerEndDate
        WHERE   EmployerNumber = @PreviousEmployerNumber
        AND     EmployerStartDate = @EmployerStartDate
        AND     RowNumber <= @LastRowNumber

        SET @EmployerStartDate = @StartDate
    END

    UPDATE  @tblTimeLine
    SET     EmployerStartDate = @EmployerStartDate
    WHERE   RowNumber = RowNumber

    SELECT  @PreviousEmployerNumber = @EmployerNumber,
            @EmployerEndDate = @EndDate,
            @LastRowNumber = @RowNumber

    FETCH NEXT FROM cur_TimeLine INTO @RowNumber, @EmployerNumber, @StartDate, @EndDate
END 

CLOSE cur_TimeLine 
DEALLOCATE cur_TimeLine

--  Update last record.
UPDATE  @tblTimeLine
SET     EmployerEndDate = @EmployerEndDate
WHERE   EmployerNumber = @PreviousEmployerNumber
AND     EmployerStartDate = @EmployerStartDate
AND     RowNumber <= @LastRowNumber

--  Mark referencedates that were not paid.
UPDATE  @tblTimeLine
SET     PaymentDate = NULL
WHERE   PaymentDate > EndDate

--  Give back complete timeline.
SELECT  DeclarationType,
        DeclarationID,
        ExtensionID,
        EmployeeNumber,
        EducationID,
        EmployerNumber,
        EmployerStartDate,
        EmployerEndDate,
        StartDate,
        EndDate,
        PeriodDuration,
        NominalDuration,
        PaymentDate
FROM    @tblTimeLine
ORDER BY
        RowNumber

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== stip.uspDeclaration_Get_TimeLine ======================================================	*/
