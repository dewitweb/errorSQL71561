CREATE PROCEDURE [sub].[uspDeclaration_List_Payment]
@SearchString		varchar(max),
@SubsidySchemeID 	sub.uttSubsidySchemeID READONLY,
@Employernumber		varchar(6),
@PeriodFrom			date,
@PeriodTo			date,
@CountOfPayment		int	OUTPUT,
@AmountPayment		decimal(19,4) OUTPUT
AS
/*	==========================================================================================
	Purpose:	List declaration and payments.

	08-11-2019	Sander van Houten	OTIBSUB-1539	DeclarationStatus -> PartitionStatus.
	15-10-2019	Sander van Houten	OTIBSUB-1618	If EVC is selected then also select EVC-WV.
	10-09-2019	Sander van Houten	OTIBSUB-1084	Changed code for selecting AmountPayment.
	03-09-2019	Sander van Houten	OTIBSUB-1480	Changed code for selecting AmountPayment.
	16-08-2019	Sander van Houten	OTIBSUB-1478	Corrected code to not show the situations
										where there is 0 euro's paid.
	16-07-2019	Jaap van Assenbergh	OTIBSUB-1373		Specificatie op declaratieniveau of 
                                        op verzamelnota.
	14-06-2019	Sander van Houten	OTIBSUB-1147	Added STIP EndDate part.
	14-06-2019	Sander van Houten	OTIBSUB-1197	Added search option on JournalEntryCode.
	14-06-2019	Sander van Houten	OTIBSUB-999		Added STIP parts.
	14-05-2019	Sander van Houten	OTIBSUB-1084	Added status 0016 to selection.
	03-05-2019	Sander van Houten	OTIBSUB-1031	Added JournalEntryCode to resultset.
	02-05-2019	Sander van Houten	OTIBSUB-1019	Duplicate rows and wrong order in screen.
	30-11-2018	Jaap van Assenbergh	OTIBSUB-975		Betalingsoverzicht. 
										Voucherbedrag + Scholingbudgetbedrag.
										Datum Uitbetaald niet uit DeclarationPartition 
										maar uit betaalrun.
	17-01-2019	Sander van Houten	OTIBSUB-678		Show CanDownloadSpecification on existence 
										of specification.
	30-11-2018	Jaap van Assenbergh	OTIBSUB-462		Toevoegen term EVC/EVC500 
										bij afhandelen declaraties.
	30-10-2018	Jaap van Assenbergh	OTIBSUB-385		Overzichten - filter op subsidieregeling.
										Multiple subsidy schemes possible. 
										Userdefined Table Type.
	03-09-2018	Jaap van Assenbergh	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Testdata 
DECLARE	@SearchString		varchar(max) = N'19200991',
		@SubsidySchemeID	sub.uttSubsidySchemeID,
		@Employernumber		varchar(6) = '116220',
		@PeriodFrom			date = NULL,
		@PeriodTo			date = NULL,
		@CountOfPayment		int,
		@AmountPayment		decimal(19,4)

INSERT INTO @SubsidySchemeID (SubsidySchemeID) VALUES (1)
--  */

SELECT	@SearchString		= ISNULL(@SearchString, ''),
        @Employernumber		= ISNULL(@Employernumber, '')

/*	Declare table variable for output of sub.uspDeclaration_List */
DECLARE @Declaration_List_Partition as TABLE
    (
        SubsidySchemeID				int,
        SubsidySchemeName			varchar(50),
        DeclarationID				int,
        EmployerNumber				varchar(6),
        DeclarationDate				datetime,
        CourseName					varchar(200),
        SearchName					varchar(200),
        DeclarationStatus			varchar(4),
        StartDate					date,
        EndDate						date,
        DeclarationAmount			decimal(19, 4),
        JournalEntryCode			int
    )

/*	Declare table variable for payments							*/
DECLARE @Declaration_Payment as TABLE
    (
        DeclarationID				int,
        SpecificationSequence		int,
        AmountPayment				decimal(19, 4),
        PaymentDate					date,
        CanDownloadSpecification	bit,
        JournalEntryCode			int
    )

/*	==	This part nearly is equal to sub.uspDeclaration_List	==	*/ 
/*	Prepaire SearchString													*/
SELECT @SearchString = sub.usfCreateSearchString (@SearchString)

DECLARE @SearchWord TABLE (Word nvarchar(max) NOT NULL)

INSERT INTO @SearchWord (Word)
SELECT s FROM sub.utfSplitString(@SearchString, ' ')

/*  Insert @SubsidySchemeID into a modifiable table variable.   */
DECLARE @tblSubsidyScheme   sub.uttSubsidySchemeID

INSERT INTO @tblSubsidyScheme 
    (
        SubsidySchemeID
    ) 
SELECT  SubsidySchemeID 
FROM    @SubsidySchemeID
ORDER BY 
        SubsidySchemeID

/*  If EVC is selected then also select EVC-WV (OTIBSUB-1618).  */
IF EXISTS ( SELECT  1
            FROM    @tblSubsidyScheme
            WHERE   SubsidySchemeID = 3)
BEGIN
    INSERT INTO @tblSubsidyScheme (SubsidySchemeID) VALUES (5)
END

/*	Select Declarations														*/
INSERT INTO @Declaration_List_Partition
SELECT 
        Search.SubsidySchemeID,
        Search.SubsidySchemeName,
        Search.DeclarationID,
        Search.EmployerNumber,
        Search.DeclarationDate,
        Search.CourseName,
        Search.SearchName,
        Search.DeclarationStatus,
        Search.StartDate,
        Search.EndDate,
        Search.DeclarationAmount,
        Search.JournalEntryCode
FROM
        (
            SELECT	DISTINCT 
                    Word,
                    d.SubsidySchemeID,
                    s.SubsidySchemeName +
                        CASE WHEN evcd.IsEVC500 = 1 OR evcwvd.IsEVC500 = 1
                            THEN '-500' 
                            ELSE ''
                        END											AS SubsidySchemeName,
                    d.DeclarationID,
                    d.EmployerNumber,
                    d.DeclarationDate,
                    COALESCE(osrd.CourseName, stpd.EducationName)	AS CourseName,
                    COALESCE(c.SearchName, e.SearchName)			AS SearchName,
                    d.DeclarationStatus,
                    d.StartDate,
                    d.EndDate,
                    d.DeclarationAmount,
                    CASE WHEN CHARINDEX(sw.Word, pd.JournalEntryCode, 1) > 0
                        THEN pd.JournalEntryCode
                        ELSE NULL
                    END												AS JournalEntryCode
            FROM	sub.tblDeclaration d
            INNER JOIN sub.tblSubsidyScheme s ON s.SubsidySchemeID = d.SubsidySchemeID
            INNER JOIN sub.tblDeclaration_Partition dep ON dep.DeclarationID = d.DeclarationID
            LEFT JOIN osr.viewDeclaration osrd ON osrd.DeclarationID = d.DeclarationID
            LEFT JOIN evc.viewDeclaration evcd ON evcd.DeclarationID = d.DeclarationID
            LEFT JOIN evcwv.viewDeclaration evcwvd ON evcwvd.DeclarationID = d.DeclarationID
            LEFT JOIN stip.viewDeclaration stpd ON stpd.DeclarationID = d.DeclarationID
            LEFT JOIN sub.tblCourse c ON c.CourseID = osrd.CourseID
            LEFT JOIN sub.tblEducation e ON e.EducationID = stpd.EducationID
            LEFT JOIN sub.tblPaymentRun_Declaration pd ON pd.DeclarationID = d.DeclarationID
            CROSS JOIN @SearchWord sw
            WHERE	d.SubsidySchemeID IN
                    (
                        SELECT	SubsidySchemeID 
                        FROM	@tblSubsidyScheme
                    )
            AND		@Employernumber = d.Employernumber
            AND		dep.PartitionStatus IN ('0012', '0014', '0016')
            AND		(
                        'T' = CASE WHEN	@SearchString = '' THEN 'T'
                                    WHEN CHARINDEX(sw.Word, s.SubsidySchemeName, 1) > 0 THEN 'T'
                                END
                OR		'T' = CASE WHEN	@SearchString = '' THEN	'T'
                                    WHEN CHARINDEX(sw.Word, CAST(d.DeclarationID AS varchar(6)), 1) > 0 THEN 'T'
                                END
                OR		'T' = CASE WHEN	@SearchString = '' THEN	'T'
                                    WHEN CHARINDEX(sw.Word, c.SearchName, 1) > 0 THEN 'T'
                                END
                OR		'T' = CASE WHEN	@SearchString = '' THEN	'T'
                                    WHEN CHARINDEX(sw.Word, e.SearchName, 1) > 0 THEN 'T'
                                END
                OR		'T' = CASE WHEN	@SearchString = '' THEN 'T'
                                    WHEN CHARINDEX(sw.Word, pd.JournalEntryCode, 1) > 0 THEN 'T'
                                END
                    )
        ) Search
        GROUP BY	
                Search.DeclarationID,
                Search.EmployerNumber,
                Search.SubsidySchemeID,
                Search.SubsidySchemeName,
                Search.DeclarationDate,
                Search.CourseName,
                Search.SearchName,
                Search.DeclarationStatus,
                Search.StartDate,
                Search.EndDate,
                Search.DeclarationAmount,
                Search.JournalEntryCode
        HAVING COUNT(Search.DeclarationID) >= (SELECT COUNT(Search.Word) FROM @SearchWord) 
        ORDER BY
        	    Search.DeclarationDate

/*	==	This part nearly is equal to sub.uspDeclaration_List.	==	*/ 
INSERT INTO @Declaration_Payment 
    (
        DeclarationID, 
        SpecificationSequence, 
        AmountPayment, 
        PaymentDate, 
        CanDownloadSpecification,
        JournalEntryCode
    )
SELECT	
        dlp.DeclarationID, 
        dsp.SpecificationSequence					AS SpecificationSequence, 
        ISNULL(vpad.SumPartitionAmount, 0.00) 
            + ISNULL(vpad.SumVoucherAmount, 0.00)	AS AmountPayment,
        COALESCE(par.ExportDate, par.RunDate)		AS PaymentDate,
        CASE WHEN dsp.Specification IS NULL AND jec.Specification IS NULL
            THEN 0
            ELSE 1
        END											AS CanDownloadSpecification,
        prd.JournalEntryCode
FROM	@Declaration_List_Partition dlp
INNER JOIN sub.tblDeclaration_Partition dep
ON		dep.DeclarationID = dlp.DeclarationID
INNER JOIN sub.tblPaymentRun_Declaration prd 
ON		prd.DeclarationID = dlp.DeclarationID 
AND		prd.PartitionID = dep.PartitionID
AND		prd.JournalEntryCode = COALESCE(dlp.JournalEntryCode, prd.JournalEntryCode)
INNER JOIN sub.tblPaymentRun par 
ON		par.PaymentRunID = prd.PaymentRunID
INNER JOIN sub.viewPaymentRun_Declaration vpad 
ON		vpad.DeclarationID = dlp.DeclarationID 
AND		vpad.PaymentRunID = prd.PaymentRunID
LEFT JOIN sub.tblDeclaration_Specification dsp
ON		dsp.DeclarationID = dlp.DeclarationID 
AND		dsp.PaymentRunID = prd.PaymentRunID
LEFT JOIN sub.tblJournalEntryCode jec
ON		jec.JournalEntryCode = prd.JournalEntryCode
WHERE 	COALESCE(vpad.SumPartitionAmount, 1.00) <> 0.00
OR		COALESCE(vpad.SumVoucherAmount, 1.00) <> 0.00

/*	Count and sum of payments.	*/
SELECT	@CountOfPayment = COUNT(dp.DeclarationID),
        @AmountPayment = SUM(dp.AmountPayment)
FROM	@Declaration_Payment dp 
WHERE	1 = CASE WHEN @PeriodFrom IS NULL 
                THEN 1
                ELSE CASE WHEN dp.PaymentDate >= @PeriodFrom 
                        THEN 1
                        ELSE 0
                     END 
            END
AND		1 = CASE WHEN @PeriodTo IS NULL 
                THEN 1 
                ELSE CASE WHEN dp.PaymentDate <= @PeriodTo 
                        THEN 1 
                        ELSE 0
                     END
            END

/*	Select returnset.   */ 
SELECT	
        dp.PaymentDate,
        dlp.DeclarationID,
        dp.SpecificationSequence,
        dlp.SubsidySchemeID,
        dlp.SubsidySchemeName,
        dlp.EmployerNumber,
        dlp.DeclarationDate,
        dlp.CourseName,
        dlp.DeclarationStatus,
        dlp.StartDate,
        (	
            SELECT	MAX(ISNULL(t2.EndDate, t1.EndDate))
            FROM	sub.tblDeclaration t1
            LEFT JOIN sub.tblDeclaration_Extension t2 
            ON		t2.DeclarationID = t1.DeclarationID
            WHERE	t1.DeclarationID = dlp.DeclarationID
            GROUP BY 
                    t1.DeclarationID
        )	AS EndDate,
        dlp.DeclarationAmount,
        dp.CanDownloadSpecification,
        dp.AmountPayment,
        dp.JournalEntryCode
FROM	@Declaration_List_Partition dlp
INNER JOIN @Declaration_Payment dp ON dp.DeclarationID = dlp.DeclarationID
WHERE	1 = CASE WHEN @PeriodFrom IS NULL 
                THEN 1
                ELSE CASE WHEN dp.PaymentDate >= @PeriodFrom 
                        THEN 1
                        ELSE 0
                     END 
            END
AND		1 = CASE WHEN @PeriodTo IS NULL 
                THEN 1 
                ELSE CASE WHEN dp.PaymentDate <= @PeriodTo 
                        THEN 1 
                        ELSE 0
                     END
            END
ORDER BY
        dp.PaymentDate,
        dlp.DeclarationID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_List_Payment =======================================================	*/
