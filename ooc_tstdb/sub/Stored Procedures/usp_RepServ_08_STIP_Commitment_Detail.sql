CREATE PROCEDURE [sub].[usp_RepServ_08_STIP_Commitment_Detail]
@StartDate              date = '20190801',
@EndDate                date = NULL,
@UserName               varchar(100) = '',
@CreateSnapshot         bit = 0
AS
/*	==========================================================================================
	Purpose:	Details of the STIP financial commitments details.

	28-01-2020	Sander van Houten	OTIBSUB-1846    Added provisional diploma dates.
	17-12-2019	Sander van Houten	OTIBSUB-1766    Added parameters @UserName and 
                                        @CreateSnapshot extra code to save the data.
	05-12-2019	Sander van Houten	OTIBSUB-1635    Added parameter @CheckOnDeclarationDate.
	15-11-2019	Sander van Houten	OTIBSUB-1697    Added output field EducationLevel.
	14-11-2019	Sander van Houten	OTIBSUB-1690    Added parameters StartDate and EndDate
                                        and added PaymentDate to resultset.
	25-10-2019	Sander van Houten	OTIBSUB-1635    Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*  Testdata.
DECLARE @StartDate              date = '20190801',
        @EndDate                date = '20991231',
        @UserName               varchar(100) = 'SYSTEEM',
        @CreateSnapshot         bit = 0
--  */

/*  Declare variables.  */
DECLARE @Getdate                datetime = GETDATE(),
        @SnapshotID             int,
        @PartitionAmountBPV     decimal(19,4),
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

/*  Set EndDate.    */
IF @EndDate IS NULL
BEGIN
    SET @EndDate = '20991231'
END

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

IF @CreateSnapshot = 1
BEGIN
    DECLARE @tblCommitmentPercentage TABLE
        (
            Calculated_CommitmentPercentage decimal(9,4),
            Calculated_X                    int,
            Calculated_Y                    int
        )

    INSERT INTO @tblCommitmentPercentage
        (
            Calculated_CommitmentPercentage,
            Calculated_X,
            Calculated_Y
        )
    EXEC [sub].[usp_RepServ_08_STIP_Commitment_Percentage] 
        @StartDate,
        @EndDate

    INSERT INTO sub.tblRepServ_08_Snapshot
        (
            Creation_DateTime,
            Creation_UserName,
            StartDate,
            EndDate,
            Calculated_CommitmentPercentage,
            Calculated_X,
            Calculated_Y
        )
    SELECT  @Getdate,
            @UserName,
            @StartDate,
            @EndDate,
            Calculated_CommitmentPercentage * 100,
            Calculated_X,
            Calculated_Y
    FROM    @tblCommitmentPercentage

    SET @SnapshotID = SCOPE_IDENTITY()

    INSERT INTO sub.tblRepServ_08_Snapshot_Details
        (
            SnapshotID,
            PartitionYear,
            PartitionMonth,
            EmployerNumber,
            EmployeeNumber,
            DeclarationID,
            PaymentDate,
            AmountToBePaid,
            EducationLevel
        )
    SELECT	@SnapshotID,
            PartitionYear,
            PartitionMonth,
            EmployerNumber,
            EmployeeNumber,
            DeclarationID,
            PaymentDate,
            AmountToBePaid,
            EducationLevel
    FROM    @tblSnapshot_Details
    ORDER BY 
            EmployerNumber,
            EmployeeNumber,
            DeclarationID,
            PaymentDate
END

/*  Return resultset.   */
SELECT	PartitionYear,
        PartitionMonth,
        EmployerNumber,
        EmployeeNumber,
        DeclarationID,
        PaymentDate,
        AmountToBePaid,
        EducationLevel
FROM    @tblSnapshot_Details
ORDER BY 
        EmployerNumber,
        EmployeeNumber,
        DeclarationID,
        PaymentDate

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	==	sub.usp_RepServ_08_STIP_Commitment_Detail ========================================	*/
