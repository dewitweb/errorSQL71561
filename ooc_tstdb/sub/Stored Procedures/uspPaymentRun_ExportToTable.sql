CREATE PROCEDURE [sub].[uspPaymentRun_ExportToTable] 
@PaymentRunID	int
AS
/*	==========================================================================================
	Purpose:	Create new export files for Exact in xml format

	Parameter:	@SubsidySchemeName	Name of the SubsidyScheme for which should be checked 
									if there is a paymentrun executed that has not yet been 
									exported to Exact.
	
	Note:		This procedure will export only 2 files at a time.
				One file will contain the paymentdata of the oldest paymentrun 
				    that has not been exported yet or of the paymentrun which ID had been
					given to the second parameter.
				The other file contains the data of the creditors that are linked to the paymentdata.

	07-02-2020	Sander van Houten	OTIBSUB-1890	Replaced DeclarationID by PartitionID at
                                        cte_Partition.
	27-01-2020	Sander van Houten	OTIBSUB-1847	Removed sub.viewPaymentRun_Declaration.
	02-01-2020	Sander van Houten	OTIBSUB-1793	Added check on missing (mandatory) data.
	10-12-2019	Sander van Houten	OTIBSUB-1760	Additions for determining correct cost center
                                        and grand ledger account.
	08-11-2019	Sander van Houten	OTIBSUB-1539	DeclarationStatus -> PartitionStatus.
	26-09-2019	Sander van Houten	OTIBSUB-1595	Altered WHERE-clause in cte_Partition.
	29-07-2019	Sander van Houten	OTIBSUB-1243	Do not export JournalEntryCode in range
										19990001 - 19999999.
	03-05-2019	Sander van Houten	OTIBSUB-1046	Move voucher use to partition level.
	16-04-2019	Sander van Houten	OTIBSUB-971		Split up paymentrun, e-mail sending 
													and export to Exact.
	02-04-2019	Sander van Houten	OTIBSUB-874		E-mail design changes.
	01-04-2019	Sander van Houten	OTIBSUB-902		Declarationstatus changes to 
													"Deelbetaling geëxporteerd naar Exact".
	26-03-2019	Sander van Houten	OTIBSUB-880		Added the possibility to not fysically 
													create export files.
													This is needed for the 
													automated tests of development.
	25-03-2019	Sander van Houten	Added the possibility to re-export a paymentrun.
	25-03-2019	Sander van Houten	OTIBSUB-694		Domain change to otib-online.nl.
	21-03-2019	Sander van Houten	OTIBSUB-864		Added JournalEntryCode 
													to sub.tblPaymentRun_Declaration.
	14-03-2019	Sander van Houten	Changed CostCenter from YEAR(decl.StartDate) to PartitionYear.
	12-03-2019	Sander van Houten	OTIBSUB-838		Add e-mailaddress Debra to e-mail.
	15-02-2019	Sander van Houten	OTIBSUB-404		Doorzetten geëxporteerde bestanden naar 
													uiteindelijke locatie op de HORUS-server 
													(en de Archive map).
	14-12-2018	Sander van Houten	OTIBSUB-584		Per regeling een aparte Journaalcode range.
	29-11-2018	Jaap van Assenbergh	OTIBSUB-493		Waardebonnen bij eerste betaling 
													geheel meenemen.
	15-11-2018	Jaap van Assenbergh	OTIBSUB-445		IBAN from tblPaymentRun_Declaration.
	15-08-2018	Sander van Houten	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Testdata.
DECLARE @PaymentRunID		int = 60031
--	*/

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

DECLARE	@SubsidySchemeID		int,
		@SubsidySchemeName		varchar(50),
		@XMLPayments			xml,
		@XMLCreditors			xml,
		@GLAccount				varchar(5),
		@DeclarationStatus		varchar(4),
		@NewDeclarationStatus	varchar(4),
		@FirstJournalEntryCode	int,
		@LastJournalEntryCode	int,
		@JournalCode			varchar(10),
		@PaymentRunEndDate		date

DECLARE @tblJournalEntryCode TABLE (
		EmployerNumber			varchar(6),
		IBAN					varchar(35),
		JournalEntryCode		int,
		TotalAmount				decimal(19,2),
		NrOfDebits				int,
		TotalAmountDebit		decimal(19,2),
		NrOfCredits				int,
		TotalAmountCredit		decimal(19,2))

-- Get SubsidySchemeID.
SELECT	@SubsidySchemeID = ssc.SubsidySchemeID,
		@SubsidySchemeName = ssc.SubsidySchemeName
FROM	sub.tblPaymentRun par
INNER JOIN sub.tblSubsidyScheme ssc ON ssc.SubsidySchemeID = par.SubsidySchemeID
WHERE	par.PaymentRunID = @PaymentRunID

-- Get JournalCode.
SELECT	@JournalCode = SettingValue
FROM	sub.tblApplicationSetting
WHERE	SettingName = 'ExactExportCode'
  AND	SettingCode = 'DGBKN'

-- Check if there is any data to be exported.
IF (SELECT	COUNT(1)
	FROM	sub.tblPaymentRun_Declaration pad
	INNER JOIN sub.tblDeclaration decl
	ON		decl.DeclarationID = pad.DeclarationID
	INNER JOIN sub.tblDeclaration_Partition dep
	ON		dep.PartitionID = pad.PartitionID
	WHERE	pad.PaymentRunID = @PaymentRunID
	  AND	dep.PartitionStatus NOT IN ( '0017', '0028' )
	) = 0

-- No data, give NULL back.
BEGIN
	SELECT PaymentRunOutput = NULL

	EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

	RETURN
END

-- Data, create an xml file.
;WITH cte_Partition AS
		(
			SELECT	pad.PartitionID,
					dep.PartitionStatus
			FROM	sub.tblPaymentRun_Declaration pad
			INNER JOIN sub.tblDeclaration_Partition dep
			ON		dep.PartitionID = pad.PartitionID
			WHERE	pad.PaymentRunID = @PaymentRunID
			AND	    dep.PartitionStatus NOT IN ('0017', '0028')
		)

-- Fill JournalEntryCode table.
INSERT INTO @tblJournalEntryCode
	(
		EmployerNumber,
		IBAN,
		JournalEntryCode,
		TotalAmount,
		NrOfDebits,
		TotalAmountDebit,
		NrOfCredits,
		TotalAmountCredit
	)
SELECT	
		decl.EmployerNumber,
		pad.IBAN,
		pad.JournalEntryCode,
		CAST(SUM(CASE ISNULL(pad.ReversalPaymentID, 0)
					WHEN 0 THEN pad.PartitionAmount + ISNULL(pad.VoucherAmount, 0)
					ELSE (pad.PartitionAmount + ISNULL(pad.VoucherAmount, 0)) * -1 
					END
				) AS decimal(19,2)
			)																			AS TotalAmount,
		SUM(CASE ISNULL(pad.ReversalPaymentID, 0) 
				WHEN 0 THEN 1
				ELSE 0
			END
			) 																			AS NrOfDebits,
		CAST(SUM(CASE ISNULL(pad.ReversalPaymentID, 0) 
					WHEN 0 THEN pad.PartitionAmount + ISNULL(pad.VoucherAmount, 0)
					ELSE 0
					END
				) AS decimal(19,2)
			) 																			AS TotalAmountDebit,
		SUM(CASE ISNULL(pad.ReversalPaymentID, 0) 
				WHEN 0 THEN 0
				ELSE 1
			END
			) 																			AS NrOfCredits,
		CAST(SUM(CASE ISNULL(pad.ReversalPaymentID, 0) 
					WHEN 0 THEN 0
					ELSE pad.PartitionAmount + ISNULL(pad.VoucherAmount, 0)
					END
				) AS decimal(19,2)
			) 																			AS TotalAmountCredit
FROM	sub.tblPaymentRun_Declaration pad
INNER JOIN cte_Partition cte
ON		cte.PartitionID = pad.PartitionID
INNER JOIN sub.tblDeclaration decl
ON		decl.DeclarationID = pad.DeclarationID
WHERE	pad.PaymentRunID = @PaymentRunID
GROUP BY 
		decl.EmployerNumber, 
		pad.IBAN,
		pad.JournalEntryCode

-- Get first and last issued JournalEntryCodes for this PaymentRun.
SELECT	@FirstJournalEntryCode = MIN(JournalEntryCode),
		@LastJournalEntryCode = MAX(JournalEntryCode)
FROM	sub.tblPaymentRun_Declaration
WHERE	PaymentRunID = @PaymentRunID
AND		LEFT(JournalEntryCode, 2) <> '99'

-- Get payment output.
SET @XMLPayments =	
	( 
		SELECT	
				(	
					SELECT
					jec.JournalEntryCode											AS "@entry",
					jec.JournalEntryCode											AS [Description],
					REPLACE(CONVERT(varchar(10), GETDATE(), 102), '.', '-')			AS [Date],
					REPLACE(CONVERT(varchar(10), GETDATE(), 102), '.', '-')			AS [DocumentDate],
					(
						SELECT	'I'													AS "@type",
								@JournalCode										AS "@code"
						FOR XML PATH('Journal'), TYPE
					),
					(
						SELECT	(
									SELECT 'EUR'									AS "@code"
									FOR XML PATH('Currency'), TYPE
								),
								jec.TotalAmount										AS [Value]
						FOR XML PATH('Amount'), TYPE
					),
					(
						SELECT	ROW_NUMBER() OVER (ORDER BY	t1.declarationID ASC, t1.PartitionYear ASC, t1.FinEntryLineType ASC)	AS "@number",
								REPLACE(CONVERT(varchar(10), GETDATE(), 102), '.', '-') AS [Date],
								(
									SELECT	[sub].[usfGetPaymentLedger] (
										CASE t1.SubsidySchemeName
                                            WHEN 'EVC' THEN t1.DeclarationDate
                                            WHEN 'EVC-WV' THEN t1.DeclarationDate
                                            WHEN 'OSR' THEN CAST(t1.PartitionYear + '0101' AS date)
                                            WHEN 'STIP' THEN t1.StartDate
                                            ELSE t1.DeclarationDate
                                        END,
										t1.SubsidySchemeName, 
										t1.TypeOfDebit, 
										t1.ERT_Code, 
										NULL )											AS "@code"
									FOR XML PATH('GLAccount'), TYPE
								),
								(
                                    SELECT 	CASE t1.SubsidySchemeName
												WHEN 'EVC' THEN YEAR(t1.DeclarationDate)
												WHEN 'EVC-WV' THEN YEAR(t1.DeclarationDate)
                                                WHEN 'OSR' THEN YEAR(t1.PartitionYear)
												WHEN 'STIP' THEN YEAR(t1.StartDate)
												ELSE YEAR(t1.DeclarationDate)
											END											AS "@code"
									FOR XML PATH('Costcenter'), TYPE
								),
								(
									SELECT	t1.EmployerNumber							AS "@code"
									FOR XML PATH('Creditor'), TYPE
								),
								(
									SELECT	(
												SELECT 'EUR'							AS "@code"
												FOR XML PATH('Currency'), TYPE
											),
											CASE ISNULL(t1.ReversalPaymentID, 0) 
												WHEN 0 THEN CAST(t1.Amount AS decimal(19,2))	
												ELSE 0
											END											AS [Debit],
											CASE ISNULL(t1.ReversalPaymentID, 0) 
												WHEN 0 THEN 0	
												ELSE CAST(t1.Amount AS decimal(19,2))
											END											AS [Credit]
									FOR XML PATH('Amount'), TYPE
								)
						FROM (
								-- Standard journals.
								SELECT	1 AS FinEntryLineType,
										decl.DeclarationID,
										COALESCE(dex.StartDate, decl.StartDate) AS StartDate,
										decl.DeclarationDate,
										sus.SubsidySchemeName,
										dep.PartitionYear,
										decl.EmployerNumber,
										pad.ReversalPaymentID,
										dep.PartitionAmountCorrected	        AS Amount,
										sus.SubsidySchemeName			        AS TypeOfDebit,
										NULL							        AS ERT_Code,
										''								        AS EmployeeNumber
								FROM	sub.tblPaymentRun_Declaration pad
								INNER JOIN sub.tblDeclaration decl
								ON		decl.DeclarationID = pad.DeclarationID
								INNER JOIN sub.tblSubsidyScheme sus
								ON		sus.SubsidySchemeID = decl.SubsidySchemeID
								INNER JOIN sub.tblDeclaration_Partition dep
								ON		dep.PartitionID = pad.PartitionID
                                LEFT JOIN sub.tblDeclaration_Extension dex
                                ON      dex.DeclarationID = dep.DeclarationID
                                AND     dex.StartDate <= dep.PaymentDate
                                AND     dex.EndDate >= dep.PaymentDate
								WHERE	pad.PaymentRunID = @PaymentRunID
								AND	    LEFT(pad.JournalEntryCode, 2) <> '99'
								AND	    decl.EmployerNumber = jec.EmployerNumber
								AND	    dep.PartitionStatus NOT IN ( '0017', '0028' )
								AND	    dep.PartitionAmountCorrected <> 0
								UNION
								-- Journals for vouchers.
								SELECT	2 AS FinEntryLineType,
										decl.DeclarationID,
										decl.StartDate,
										decl.DeclarationDate,
										sus.SubsidySchemeName,
										CAST(YEAR(decl.StartDate) AS varchar(4))	AS PartitionYear,
										decl.EmployerNumber,
										0											AS ReversalPaymentID,
										dpv.DeclarationValue						AS Amount,
										'ERT'										AS TypeOfDebit,
										evo.ERT_Code,
										evo.EmployeeNumber							AS EmployeeNumber
								FROM	sub.tblPaymentRun_Declaration pad
								INNER JOIN sub.tblDeclaration decl
								ON		decl.DeclarationID = pad.DeclarationID
								INNER JOIN sub.tblSubsidyScheme sus
								ON		sus.SubsidySchemeID = decl.SubsidySchemeID
								INNER JOIN sub.tblDeclaration_Partition dep
								ON		dep.PartitionID = pad.PartitionID
								INNER JOIN sub.viewPaymentRun_Declaration vpad
								ON		vpad.DeclarationID = decl.DeclarationID
								AND		vpad.PaymentRunID = pad.PaymentRunID
								INNER JOIN sub.tblDeclaration_Partition_Voucher dpv
								ON		dpv.DeclarationID = decl.DeclarationID
								AND		dpv.PartitionID = dep.PartitionID
								INNER JOIN sub.tblDeclaration_Employee dem
								ON		dem.DeclarationID = dpv.DeclarationID
								AND		dem.EmployeeNumber = dpv.EmployeeNumber
								INNER JOIN sub.tblEmployee_Voucher evo
								ON		evo.EmployeeNumber = dpv.EmployeeNumber
								AND		evo.VoucherNumber = dpv.VoucherNumber
								WHERE	pad.PaymentRunID = @PaymentRunID
								AND	    LEFT(pad.JournalEntryCode, 2) <> '99'
								AND	    decl.EmployerNumber = jec.EmployerNumber
								AND	    dep.PartitionStatus NOT IN ( '0017', '0028' )
								AND	    vpad.SumVoucherAmount <> 0
								) AS t1
						FOR XML PATH('FinEntryLine'), TYPE
					)
					FROM	@tblJournalEntryCode jec
					ORDER BY jec.EmployerNumber
					FOR XML PATH('GLEntry'), TYPE
				)
		FOR XML PATH('GLEntries'), ROOT('eExact')
	)

-- Get creditor output.
SET @XMLCreditors =	
	( 
		SELECT	
				(	
					SELECT
					jec.EmployerNumber																	AS "@code",
					'A'																					AS "@status",
					emp.EmployerName																	AS [Name],
					emp.Phone																			AS [Phone],
					(
						SELECT	
								(
									SELECT	'1'															AS "@default",
											'--'														AS [LastName],
											(	
												SELECT 
														(
															SELECT	'V'									AS "@type",
																	emp.BusinessAddressStreet + ' ' 
																	+ emp.BusinessAddressHousenumber	AS [AddressLine1],
																	emp.BusinessAddressZipcode			AS [PostalCode],
																	emp.BusinessAddressCity				AS [City],
																	(	
																		SELECT	emp.BusinessAddressCountrycode	AS "@code"
																		FOR XML PATH('Country'), TYPE
																	)
															FOR XML PATH('Address'), TYPE
														)
												FOR XML PATH('Addresses'), TYPE
											)
									FOR XML PATH('Contact'), TYPE
								)
						FOR XML PATH('Contacts'), TYPE
					),
					(	
						SELECT	jec.EmployerNumber								AS "@code",
								(	
									SELECT	'EUR'								AS "@code"
									FOR XML PATH('Currency'), TYPE
								),
								(	
									SELECT	
											(
												SELECT	jec.IBAN				AS "@code",
														(	
															SELECT	'IBA'		AS "@code"
															FOR XML PATH('BankAccountType'), TYPE
														),
														(	
															SELECT	''			AS "@code",
																	''			AS [Name],
																	jec.IBAN	AS [IBAN],
																	''			AS [BIC]
															FOR XML PATH('Bank'), TYPE
														)
												FOR XML PATH('BankAccount'), TYPE
											)
									FOR XML PATH('BankAccounts'), TYPE
								)
						FOR XML PATH('Creditor'), TYPE
					)
					FROM	@tblJournalEntryCode jec
					INNER JOIN sub.tblEmployer emp
					ON		emp.EmployerNumber = jec.EmployerNumber
					ORDER BY jec.EmployerNumber
					FOR XML PATH('Account'), TYPE
				)
		FOR XML PATH('Accounts'), ROOT('eExact')
	)

/*	Update DeclarationStatus and JournalEntryCode of exported declarations.	*/
-- Create temp table for JournalEntryCodes.
DECLARE @tblDeclaration_JournalEntryCode TABLE
	(
		EmployerNumber		varchar(6),
		DeclarationID		int,
		PartitionID			int,
		JournalEntryCode	int
	)

-- Fill temp table.
INSERT INTO @tblDeclaration_JournalEntryCode 
	(
		EmployerNumber,
		DeclarationID,
		PartitionID,
		JournalEntryCode
	)
SELECT	jec.EmployerNumber,
		pad.DeclarationID,
		pad.PartitionID,
		jec.JournalEntryCode
FROM	@tblJournalEntryCode jec
INNER JOIN sub.tblDeclaration decl ON decl.EmployerNumber = jec.EmployerNumber
INNER JOIN sub.tblPaymentRun_Declaration pad ON	pad.DeclarationID = decl.DeclarationID
INNER JOIN sub.tblDeclaration_Partition dep ON dep.PartitionID = pad.PartitionID
WHERE	pad.PaymentRunID = @PaymentRunID

DECLARE	@DeclarationID			    int,
		@PartitionID			    int,
		@PartitionStatus		    varchar(4),
		@CurrentUserID			    int = 1,
		@PreviousDeclarationID	    int = 0,
		@PreviousDeclarationStatus  int = ''

DECLARE @RC							int,
		@PartitionYear				varchar(20),
		@PartitionAmount			decimal(19,4),
		@PartitionAmountCorrected	decimal(19,4),
		@PaymentDate				date

DECLARE cur_Partitions CURSOR FOR 
	SELECT	d.DeclarationID,
            d.DeclarationStatus,
			dep.PartitionID,
			dep.PartitionStatus
	FROM	@tblDeclaration_JournalEntryCode jec
	INNER JOIN sub.tblPaymentRun_Declaration pad
	ON		pad.PartitionID = jec.PartitionID
	INNER JOIN sub.tblDeclaration_Partition dep
	ON		dep.PartitionID = pad.PartitionID
	INNER JOIN sub.tblDeclaration d
	ON		d.DeclarationID = pad.DeclarationID
	WHERE	pad.PaymentRunID = @PaymentRunID
	
OPEN cur_Partitions

FETCH NEXT FROM cur_Partitions INTO @DeclarationID, @DeclarationStatus, @PartitionID, @PartitionStatus

WHILE @@FETCH_STATUS = 0  
BEGIN
    -- Update declarationstatus after looping through partitions.
    IF @PreviousDeclarationID <> @DeclarationID AND @PreviousDeclarationID <> 0
    BEGIN
        SELECT @NewDeclarationStatus = sub.usfGetDeclarationStatusByPartition(@PreviousDeclarationID, NULL, NULL)

        IF @NewDeclarationStatus <> @PreviousDeclarationStatus
        BEGIN
            EXEC sub.uspDeclaration_Upd_DeclarationStatus
                @PreviousDeclarationID,
                @NewDeclarationStatus,
                NULL,
                @CurrentUserID
        END
    END

	-- Update partitionstatus (if paid or reversed).
	IF @PartitionStatus = '0010'
	BEGIN
		SELECT
				@PartitionYear = PartitionYear,
				@PartitionAmount = PartitionAmount,
				@PartitionAmountCorrected = PartitionAmountCorrected,
				@PaymentDate = PaymentDate
		FROM	sub.tblDeclaration_Partition
		WHERE	PartitionID = @PartitionID

		EXEC @RC = [sub].[uspDeclaration_Partition_Upd] 
			@PartitionID,
			@DeclarationID,
			@PartitionYear,
			@PartitionAmount,
			@PartitionAmountCorrected,
			@PaymentDate,
			'0012',	--Betaling geëxporteerd naar Exact
			@CurrentUserID
	END

	SELECT  @PreviousDeclarationID = @DeclarationID,
            @PreviousDeclarationStatus = @DeclarationStatus

	FETCH NEXT FROM cur_Partitions INTO @DeclarationID, @DeclarationStatus, @PartitionID, @PartitionStatus
END

CLOSE cur_Partitions
DEALLOCATE cur_Partitions

-- Update declarationstatus of last declaration.
SELECT @NewDeclarationStatus = sub.usfGetDeclarationStatusByPartition(@DeclarationID, NULL, NULL)

IF @NewDeclarationStatus <> @PreviousDeclarationStatus
BEGIN
    EXEC sub.uspDeclaration_Upd_DeclarationStatus
        @PreviousDeclarationID,
        @NewDeclarationStatus,
        NULL,
        @CurrentUserID
END

/* Insert record into sub.tblPaymentRun_XMLExport.	*/
DECLARE @NrOfCreditors int,
		@NrOfDebits int,
		@NrOfCredits int,
		@TotalAmountCredit decimal(9,2),
		@TotalAmountDebit decimal(9,2),
		@CreationDate datetime = @LogDate,
		@ExportDate datetime = NULL

SELECT	@NrOfCreditors = COUNT(DISTINCT EmployerNumber),
		@NrOfDebits = SUM(NrOfDebits),
		@NrOfCredits = SUM(NrOfCredits),
		@TotalAmountCredit = SUM(TotalAmountCredit),
		@TotalAmountDebit = SUM(TotalAmountDebit)
FROM	@tblJournalEntryCode

EXECUTE @RC = sub.uspPaymentRun_XMLExport_Upd 
			@PaymentRunID,
			@XMLCreditors,
			@XMLPayments,
			@NrOfCreditors,
			@NrOfDebits,
			@NrOfCredits,
			@TotalAmountCredit,
			@TotalAmountDebit,
			@FirstJournalEntryCode,
			@LastJournalEntryCode,
			@CreationDate,
			@ExportDate,
			@CurrentUserID

/*  Check for known errors. */
DECLARE @Return int = 0

-- Check on empty GLAccount (OTIBSUB-1788 / OTIBSUB-1793)
IF EXISTS ( 
            SELECT  1 
            FROM    sub.tblPaymentRun_XMLExport 
            WHERE   PaymentRunID = @PaymentRunID
            AND     CAST(XMLPayments AS varchar(max)) LIKE '%GLAccount/%'
          )
BEGIN
    SET @Return = 1
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

RETURN @Return

/*	== sub.uspPaymentRun_ExportToTable =======================================================	*/
