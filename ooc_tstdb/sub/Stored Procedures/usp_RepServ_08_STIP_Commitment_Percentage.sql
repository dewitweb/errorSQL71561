CREATE PROCEDURE [sub].[usp_RepServ_08_STIP_Commitment_Percentage]
@StartDate                      date = '20190801',
@EndDate                        date = NULL,
@tblSnapshotDetailsPercentage   stip.uttSnapshotDetailsPercentage READONLY
AS
/*	==========================================================================================
	Purpose:	Calculation of the percentage for the STIP financial commitments.

    Notes:      This procedure is used in: 08 STIP Verplichtingen overzicht inclusief voorspelling.rdl
                The parameters EndDate and @tblSnapshotDetailsPercentage are optional.

	30-01-2020	Sander van Houten	OTIBSUB-1846    Added @tblSnapshotDetailsPercentage.
	05-12-2019	Sander van Houten	OTIBSUB-1635    Added parameter @CheckOnDeclarationDate.
	05-12-2019	Sander van Houten	OTIBSUB-1635    Added parameter @CheckOnDeclarationDate.
	21-11-2019	Sander van Houten	OTIBSUB-1691    Changed WHERE-clause on 
                                        PaymentDate to DeclarationDate.
	14-11-2019	Sander van Houten	OTIBSUB-1690    Added parameters StartDate and EndDate
                                        and added PaymentDate to resultset.
	25-10-2019	Sander van Houten	OTIBSUB-1635    Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*  Testdata.
DECLARE @StartDate                      date = '20190801',
        @EndDate                        date = '20991231',
        @tblSnapshotDetailsPercentage   stip.uttSnapshotDetailsPercentage

-- INSERT INTO @tblSnapshotDetailsPercentage
-- 	(
-- 		DeclarationID,
--         PaymentDate,
--         AmountToBePaid
--     )
-- VALUES	(414414, '2021-07-31', 800.00)
--  */

-- First set the end date if not given by the user.
IF @EndDate IS NULL
BEGIN
    SET @EndDate = CAST('20991231' AS date)
END

-- And calculate the commitmentpercentage.
DECLARE @CommitmentPercentage   decimal(5,2)

IF (SELECT COUNT(1) FROM @tblSnapshotDetailsPercentage) > 0
BEGIN   -- If the table is filled use the data inside instead of re-selecting it (for performance).
    SELECT  CAST((SUM(sub1.X) - SUM(sub1.Y)) / CAST(SUM(sub1.X) AS decimal(19,4)) AS decimal(19,4)) AS CommitmentPercentage,
            SUM(sub1.X)                                                                             AS X,
            SUM(sub1.Y)                                                                             AS Y
    FROM (
            SELECT  CASE WHEN AmountToBePaid = 0.00
                        THEN 0
                        ELSE 1
                    END     AS X,
                    CASE WHEN AmountToBePaid = 0.00
                        THEN 1
                        ELSE 0
                    END     AS Y
            FROM    @tblSnapshotDetailsPercentage sdp
            WHERE   PaymentDate >= @StartDate 
        ) sub1
END
ELSE
BEGIN   -- Otherwise, select the necessary data.
    DECLARE @PartitionAmountBPV     decimal(19,4),
            @PartitionAmountSTIP    decimal(19,4)

    DECLARE @tblSnapshot_Details TABLE
        (
            PartitionYear   varchar(20) NOT NULL,
            PartitionMonth  varchar(2) NOT NULL,
            EmployerNumber  varchar(6) NOT NULL,
            EmployeeNumber  varchar(8) NOT NULL,
            DeclarationID   int NOT NULL,
            PaymentDate     date NOT NULL,
            AmountToBePaid  decimal(19, 4) NOT NULL,
            EducationLevel  int NULL,
            UNIQUE CLUSTERED (DeclarationID, PaymentDate)
        )

    DECLARE @tblSnapshot_Details_Diploma TABLE
        (
            EmployerNumber  varchar(6) NOT NULL,
            EmployeeNumber  varchar(8) NOT NULL,
            DeclarationID   int NOT NULL,
            PaymentDate     date NOT NULL,
            AmountToBePaid  decimal(19, 4) NOT NULL,
            EducationLevel  int NULL,
            UNIQUE CLUSTERED (DeclarationID, PaymentDate)
        )

        /*  Get PartitionAmounts for BPV/STIP.  */ 
        SELECT	@PartitionAmountBPV = aex.SettingValue
        FROM	sub.tblApplicationSetting aps
        INNER JOIN	sub.tblApplicationSetting_Extended aex 
        ON	    aex.ApplicationSettingID = aps.ApplicationSettingID
        WHERE	aps.SettingName = 'SubsidyAmountPerType'
        AND		aps.SettingCode = 'BPV'

        SELECT	@PartitionAmountSTIP = aex.SettingValue / 2
        FROM	sub.tblApplicationSetting aps
        INNER JOIN	sub.tblApplicationSetting_Extended aex 
        ON	    aex.ApplicationSettingID = aps.ApplicationSettingID
        WHERE	aps.SettingName = 'SubsidyAmountPerType'
        AND		aps.SettingCode = 'STIP'

        /*  Insert data into table variable.    */
        -- First all available data from the view (with partitions only and without provisional diplomadate).
        INSERT INTO @tblSnapshot_Details
            (
                PartitionYear,
                PartitionMonth,
                EmployerNumber,
                EmployeeNumber,
                DeclarationID,
                PaymentDate,
                AmountToBePaid,
                EducationLevel
            )
        SELECT	PartitionYear,
                PartitionMonth,
                EmployerNumber,
                EmployeeNumber,
                DeclarationID,
                PaymentDate,
                AmountToBePaid,
                EducationLevel
        FROM    stip.viewRepServ_STIP_Commitments
        WHERE   PaymentDate >= @StartDate

        -- Then the provisional diploma partitions for STIP declarations with partition(s).
        INSERT INTO @tblSnapshot_Details_Diploma
            (
                EmployerNumber,
                EmployeeNumber,
                DeclarationID,
                PaymentDate,
                AmountToBePaid,
                EducationLevel
            )
        SELECT	
                MIN(snd.EmployerNumber),
                MIN(snd.EmployeeNumber),
                snd.DeclarationID,
                [sub].[usfCalculateUltimateDiplomaDate](snd.DeclarationID)  AS PaymentDate,
                CASE WHEN ISNULL(MIN(bpv.TypeBPV), 'Instroom') = 'Opscholing'
                    THEN @PartitionAmountBPV
                    ELSE @PartitionAmountSTIP
                END                                                         AS AmountToBePaid,
                MIN(snd.EducationLevel)
        FROM    @tblSnapshot_Details snd
        INNER JOIN sub.tblDeclaration d
        ON      d.DeclarationID = snd.DeclarationID
        LEFT JOIN stip.tblDeclaration_BPV bpv
        ON      bpv.DeclarationID = snd.DeclarationID
        WHERE   d.DeclarationStatus <> '0031'
        GROUP BY 
                snd.DeclarationID

        -- Then the provisional diploma partitions for STIP declarations without partition(s).
        INSERT INTO @tblSnapshot_Details_Diploma
            (
                EmployerNumber,
                EmployeeNumber,
                DeclarationID,
                PaymentDate,
                AmountToBePaid,
                EducationLevel
            )
        SELECT	
                MIN(d.EmployerNumber),
                MIN(d.EmployeeNumber),
                d.DeclarationID,
                [sub].[usfCalculateUltimateDiplomaDate](d.DeclarationID)  AS PaymentDate,
                CASE WHEN ISNULL(MIN(bpv.TypeBPV), 'Instroom') = 'Opscholing'
                    THEN @PartitionAmountBPV
                    ELSE @PartitionAmountSTIP
                END                                                         AS AmountToBePaid,
                MIN(d.EducationLevel)
        FROM    stip.viewDeclaration d
        LEFT JOIN @tblSnapshot_Details snd
        ON      snd.DeclarationID = d.DeclarationID
        LEFT JOIN stip.tblDeclaration_BPV bpv
        ON      bpv.DeclarationID = d.DeclarationID
        WHERE   d.DeclarationStatus NOT IN ('0031', '0035')
        AND     snd.DeclarationID IS NULL
        GROUP BY 
                d.DeclarationID

        -- Remove provisional diplomadates earlier than the given StartDate.
        DELETE
        FROM    @tblSnapshot_Details_Diploma
        WHERE   PaymentDate < @StartDate

        -- Now combine them.
        INSERT INTO @tblSnapshot_Details
            (
                PartitionYear,
                PartitionMonth,
                EmployerNumber,
                EmployeeNumber,
                DeclarationID,
                PaymentDate,
                AmountToBePaid,
                EducationLevel
            )
        SELECT	YEAR(t1.PaymentDate)                                        AS PartitionYear,
                RIGHT('00' + CAST(MONTH(t1.PaymentDate) AS varchar(2)), 2)  AS PartitionMonth,
                t1.EmployerNumber,
                t1.EmployeeNumber,
                t1.DeclarationID,
                t1.PaymentDate,
                t1.AmountToBePaid,
                t1.EducationLevel
        FROM    @tblSnapshot_Details_Diploma t1
        LEFT JOIN @tblSnapshot_Details t2
        ON      t2.DeclarationID = t1.DeclarationID
        AND     t2.PaymentDate = t1.PaymentDate
        WHERE   t2.DeclarationID IS NULL

        -- Now calculate the percentage.
        SELECT  CAST((SUM(sub1.X) - SUM(sub1.Y)) / CAST(SUM(sub1.X) AS decimal(19,4)) AS decimal(19,4)) AS CommitmentPercentage,
                SUM(sub1.X)                                                                             AS X,
                SUM(sub1.Y)                                                                             AS Y
        FROM (
                SELECT  CASE WHEN AmountToBePaid = 0.00
                            THEN 0
                            ELSE 1
                        END     AS X,
                        CASE WHEN AmountToBePaid = 0.00
                            THEN 1
                            ELSE 0
                        END     AS Y
                FROM    @tblSnapshot_Details
            ) sub1
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	==	sub.usp_RepServ_08_STIP_Commitment_Percentage ========================================	*/
