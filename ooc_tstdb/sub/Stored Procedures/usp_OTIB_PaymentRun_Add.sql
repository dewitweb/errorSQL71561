
CREATE PROCEDURE [sub].[usp_OTIB_PaymentRun_Add]
@SubsidySchemeID			int,
@RunDate					datetime,
@EndDate					date,
@CurrentUserID				int = 1,
@CreateFysicalExportFiles	bit = 1,
@PaymentRunID				int	OUTPUT
AS
/*	==========================================================================================
	Purpose:	Add record to sub.tblPaymentRun.

	Note:		This procedure has a couple of steps:
				1. Create a new PaymentRunID
				2. Determine a JournalEntryCode for each employer that has an approved payment 
					or reversal processed in this run.
				3. Link the approved payments and reversals to the PaymentRunID.
				4. Update the declarations, partitions and employee_vouchers 
					of the approved payments and reversals.
				5. Create a new specification for the approved payments and reversals.
				6. Link the rejected declarations to the PaymentRunID.
				8. Update the declarations, partitions and employee_vouchers 
					of the rejected declarations.
				9. Create a new specification for the rejected payments 
					(without a value in the XML-field Specification).
				7. Give feedback to Horus on the vouchers processed.

				After this procedure there are 2 more steps to be taken:
				- Create the export files for Exact by executing the procedures
					sub.uspPaymentRun_ExportToTable and sub.uspPaymentRun_ExportToFile.
				- Send the notification e-mails to the employers by executing the procedure
					sub.uspPaymentRun_SendEmail.

				The procedures will probably be scheduled as jobs in the SQL Server Agent.

	03-02-2020	Jaap van Assenbergh	OTIBSUB-1870	Specificaties uit de betaalrun halen
	29-01-2020	Jaap van Assenbergh	OTIBSUB-1178
	07-01-2020	Sander van Houten	OTIBSUB-1814	Exclude employers with a paymentarrear.
	18-11-2019	Sander van Houten	OTIBSUB-1684	Combined paymentruns of EVC and EVC-WV.
	12-11-2019	Jaap van Assenbergh	OTIBSUB-1539	Declaratieniveau naar Partitieniveau brengen
	04-11-2019	Sander van Houten	OTIBSUB-1672	Removed the update of DS voucher tables.
                                        This now happens at the moment a declaration is rejected.
	25-10-2019	Jaap van Assenbergh	OTIBSUB-1647	Terugboekingen mogelijk maken per partitie
	24-10-2019	Sander van Houten	OTIBSUB-1642	When a payment is (partialy) reversed, 
										the future partitionamount(s) will be lowered with the reversed amount (by ratio).
	22-10-2019	Jaap van Assenbergh	OTIBSUB-1358	Terugboeking en uitbetaling van één declaratie in dezelfde betalingsrun
	14-10-2019	Sander van Houten	OTIBSUB-1618	If EVC is selected then also select EVC-WV.
	02-09-2019	Sander van Houten	OTIBSUB-1480	Register paid amounts in sub.tblPaymentRun_Declaration. 
	29-08-2019	Sander van Houten	OTIBSUB-1514	Added code for updating declarationstatus 
										0021 -> 0028.
	29-08-2019	Sander van Houten	OTIBSUB-1513	Corrected code for updating declarationstatus.
	06-08-2019	Sander van Houten	OTIBSUB-1442	Only select STIP diploma payments where 
										the diploma has been checked.
										Code for vouchers is only relevant for subsidyscheme OSR.
	29-07-2019	Sander van Houten	OTIBSUB-1243	Different JournalEntryCode range for 
										specifications that must not be exported to Exact
										This is the case if there are only rejected declarations
										(status 0007) and/or declarations without budgetamount 
										(status 0021).
	09-07-2019	Jaap van Assenbergh	OTIBSUB-1243	Notaspecificatie (verzamelnota) met afgekeurde 
													declaraties
									OTIBSUB-1345	Commit versie maken van de betaalrun
	16-05-2019	Sander van Houten	OTIBSUB-1090	Update hrs.tblVoucher (for ONT and TST).
	07-05-2019	Sander van Houten	OTIBSUB-1046	Move vouchers to partition level.
	24-04-2019	Sander van Houten	OTIBSUB-1013	Performance enhancements PaymentRun.
	16-04-2019	Sander van Houten	OTIBSUB-971		Split up paymentrun, e-mail sending and 
													export to Exact.
	01-04-2019	Sander van Houten	OTIBSUB-874		E-mail design changes.
	29-03-2019	Sander van Houten	OTIBSUB-891 Use viewEmployerEmail instead of tblEmployer.
	26-03-2019	Sander van Houten	Added the possibility to not fysically create export files.
									This is needed for the automated tests of development (OTIBSUB-880).
	13-03-2019	Sander van Houten	OTIBSUB-838 Export files directly after processing records.
	06-03-2019	Sander van Houten	OTIBSUB-824 Adjustment for freeing used voucher.
	22-02-2019	Jaap van Assenbergh	OTIBSUB-801 Paymentstop uitsluiten.
	20-02-2019	Sander van Houten	OTIBSUB-792 Manier van vastlegging terugboeking 
									bij werknemer veranderen.
	12-12-2018	Jaap van Assenbergh	OTIBSUB-533 Specificaties opslaan in tabel
	19-11-2018	Sander van Houten	OTIBSUB-98 Added Ascription into sub.tblPaymentRun_Declaration.
	15-11-2018	Jaap van Assenbergh	OTIBSUB-445 IBAN from tblEmployer to tblPaymentRun_Declaration.
	30-10-2018	Jaap van Assenbergh	OTIBSUB-385 Overzichten - filter op subsidieregeling
									Parameter @SubsidySchemeID toegevoegd.
	10-08-2018	Sander van Houten	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Testdata					
DECLARE 
@SubsidySchemeID			int = 1,
@RunDate					datetime = '2020-01-01',
@EndDate					date = '2020-01-01',
@CurrentUserID				int = 211,
@CreateFysicalExportFiles	bit = 1,
@PaymentRunID				int	
-- */

DECLARE @DeclarationStatus varchar(4)

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

/* Declare variables for cur_JournalEntryCode					*/
DECLARE	@EmployerNumber				varchar(6),
		@JournalEntryCode			int,
		@JournalEntryCode_Export	int,
		@JournalEntryCode_NoExport	int,
		@IBAN						varchar(34),
		@Ascription					varchar(100),
		@RowNumber					int,
		@MinPartitionStatus			varchar(4),
		@MaxPartitionStatus			varchar(4),
		@TotalAmount				decimal(19,4),
        @Previous_SubsidySchemeID   int = 0

/* Declare variables for cur_Declaration.						*/
DECLARE	@DeclarationID			int,
		@StatusReason			varchar(max),
		@ReversalPaymentID		int,
		@PartitionID			int,
		@PartitionYear			varchar(20),
		@PartitionStatus		varchar(4),
		@PartitionSequence		tinyint

/* Declare variables for cur_Partition.						*/
DECLARE	@FuturePartitionID	            int,
		@FuturePartitionYear	        varchar(20),
        @FuturePartitionAmount          decimal(18,2),
        @FuturePartitionAmountCorrected decimal(18,2),
        @FuturePaymentDate              date,
		@FuturePartitionStatus	        varchar(4),
		@Ratio							decimal(5, 2)

/* Declare variables for cur_Voucher.							*/
DECLARE @EmployeeNumber	varchar(8),
		@VoucherNumber	varchar(3),
		@GrantDate		date,
		@ValidityDate	date,
		@VoucherValue	decimal(19,4),
		@AmountUsed		decimal(19,4),
		@ERT_Code		varchar(3),
		@EventName		varchar(100),
		@EventCity		varchar(100),
		@Active			bit

DECLARE	@RC						int,
		@MaxPartition			varchar(20),
		@ExportDate				datetime = NULL,
		@NewPartitionStatus		varchar(4)

DECLARE @tblPaymentRun TABLE (PaymentRunID int)

/*  Insert @SubsidySchemeID into a table variable.   */
DECLARE @tblSubsidyScheme   sub.uttSubsidySchemeID
INSERT INTO @tblSubsidyScheme (SubsidySchemeID) VALUES (@SubsidySchemeID)

/*	Get first JournalEntryCode for this run.	*/
DECLARE @FirstJournalEntryCode_Export	int

SELECT	@FirstJournalEntryCode_Export = MAX(jec.JournalEntryCode)
FROM	sub.tblJournalEntryCode jec
INNER JOIN sub.tblPaymentRun_Declaration prd ON prd.JournalEntryCode = jec.JournalEntryCode
INNER JOIN sub.tblPaymentRun pr ON pr.PaymentRunID = prd.PaymentRunID
WHERE	pr.SubsidySchemeID IN 
                            (
                                SELECT	SubsidySchemeID 
                                FROM	@tblSubsidyScheme
                            )
AND		LEFT(jec.JournalEntryCode, 2) <> '99'

IF ISNULL(@FirstJournalEntryCode_Export, 0) = 0
BEGIN
	/* De oude manier. Is alleen van toepassing voor de eerste nieuwe run.	*/
	SELECT	@FirstJournalEntryCode_Export = CAST(aps.SettingValue AS int)
	FROM	sub.tblSubsidyScheme ssc
	INNER JOIN sub.tblApplicationSetting aps
	ON		aps.SettingName = 'LastJournalEntryCode'
	AND		aps.SettingCode = ssc.SubsidySchemeName
	WHERE	ssc.SubsidySchemeID IN 
								(
									SELECT	SubsidySchemeID 
									FROM	@tblSubsidyScheme
								)

	/* Is alleen van toepassing voor de eerste run van een nieuwe regeling.	*/
	IF ISNULL(@FirstJournalEntryCode_Export, 0) = 0
	BEGIN
		SELECT	@FirstJournalEntryCode_Export = CAST(aps.SettingValue AS int)
		FROM	sub.tblSubsidyScheme ssc
		INNER JOIN sub.tblApplicationSetting aps
		ON		aps.SettingName = 'JournalEntryCode'
		AND		aps.SettingCode = ssc.SubsidySchemeName
		WHERE	ssc.SubsidySchemeID IN 
                                    (
                                        SELECT	SubsidySchemeID 
                                        FROM	@tblSubsidyScheme
                                    )
	END
END

/*	Get first JournalEntryCode for rejections only for this run.	*/
DECLARE @FirstJournalEntryCode_NoExport	int

SELECT	@FirstJournalEntryCode_NoExport = MAX(jec.JournalEntryCode)
FROM	sub.tblJournalEntryCode jec
WHERE	LEFT(jec.JournalEntryCode, 2) = '99'

IF @FirstJournalEntryCode_NoExport IS NULL
	SET @FirstJournalEntryCode_NoExport = 99000000

/*  If EVC is selected then also select EVC-WV (OTIBSUB-1618).  */
IF EXISTS ( SELECT  1
            FROM    @tblSubsidyScheme
            WHERE   SubsidySchemeID = 3)
BEGIN
    INSERT INTO @tblSubsidyScheme (SubsidySchemeID) VALUES (5)
END

/*  Main process.  */
DECLARE cur_JournalEntryCode CURSOR 
	LOCAL    
	FAST_FORWARD    
	READ_ONLY    
	FOR	
		SELECT	jec.SubsidySchemeID,
                jec.EmployerNumber,
				jec.IBAN,
				jec.Ascription,
				jec.RowNumber,
				jec.MinPartitionStatus,
				jec.MaxPartitionStatus,
				jec.TotalAmount
		FROM	(
					SELECT	
							@SubsidySchemeID                                                        AS SubsidySchemeID,
                            decl.EmployerNumber,
							ROW_NUMBER() OVER (ORDER BY decl.EmployerNumber ASC)  					AS RowNumber,
							emp.IBAN,
							emp.Ascription,
							MIN(dep.PartitionStatus)												AS MinPartitionStatus,
							MAX(dep.PartitionStatus)												AS MaxPartitionStatus,
							SUM(dep.PartitionAmountCorrected + dep.VoucherValue)					AS TotalAmount
					FROM	sub.tblDeclaration decl
					INNER JOIN sub.viewDeclaration_Partition_AmmountInPaymentRun dep  --PartitionStatus IN ('0007', '0009', '0016', '0021' AND '0024' WITH DeclarationStatus '0031')
							ON	dep.DeclarationID = decl.DeclarationID
					INNER JOIN sub.tblEmployer emp 
							ON	emp.EmployerNumber = decl.EmployerNumber
					LEFT JOIN sub.tblEmployer_PaymentStop eps
							ON	eps.EmployerNumber = decl.EmployerNumber
							AND	eps.StartDate <= @EndDate
							AND	COALESCE(eps.EndDate, @EndDate) >= @EndDate
							AND	eps.PaymentstopType = '0001'
                    LEFT JOIN   sub.tblPaymentArrear pa
                            ON  pa.EmployerNumber = decl.EmployerNumber
                            AND	DATEDIFF(DAY, pa.FeesPaidUntill, GETDATE()) > 30
					LEFT JOIN stip.viewDeclaration stpd 
							ON	stpd.DeclarationID = decl.DeclarationID
					WHERE	decl.SubsidySchemeID IN 
                            (
                                SELECT	SubsidySchemeID 
                                FROM	@tblSubsidyScheme
                            )
					AND		dep.PaymentDate <= @EndDate
					AND		eps.PaymentStopID IS NULL
                    AND     (   pa.FeesPaidUntill IS NULL
                            OR  (   pa.FeesPaidUntill IS NOT NULL
                                AND dep.PartitionStatus <> '0009'
                                )
                            )
					GROUP BY 
							decl.EmployerNumber,
							emp.IBAN,
							emp.Ascription
				) jec
		ORDER BY jec.RowNumber

OPEN cur_JournalEntryCode

FETCH	FROM cur_JournalEntryCode
INTO	@SubsidySchemeID,
        @EmployerNumber,
		@IBAN,
		@Ascription,
		@RowNumber,
		@MinPartitionStatus,
		@MaxPartitionStatus,
		@TotalAmount

WHILE @@FETCH_STATUS = 0
BEGIN
	BEGIN TRY
	BEGIN TRANSACTION
		IF @SubsidySchemeID <> @Previous_SubsidySchemeID
		BEGIN 
			SET @Previous_SubsidySchemeID = @SubsidySchemeID

			/* Add new record into the PaymentRun table.	*/
			INSERT INTO @tblPaymentRun (PaymentRunID)
			EXECUTE @RC = sub.uspPaymentRun_Upd 
						@PaymentRunID,
						@RunDate,
						@EndDate,
						@ExportDate,
						@CurrentUserID,
						@SubsidySchemeID,
						@CurrentUserID

			-- Get new PaymentRunID.
			SELECT	TOP 1
					@PaymentRunID = PaymentRunID
			FROM	@tblPaymentRun
		END

		IF @TotalAmount = 0.00 OR (@MinPartitionStatus = '0007' AND @MaxPartitionStatus = '0007')
		BEGIN
			SET @FirstJournalEntryCode_NoExport = @FirstJournalEntryCode_NoExport + 1

			SET @JournalEntryCode = @FirstJournalEntryCode_NoExport
		END
		ELSE
		BEGIN
			SET @FirstJournalEntryCode_Export = @FirstJournalEntryCode_Export + 1

			SET @JournalEntryCode = @FirstJournalEntryCode_Export
		END

		INSERT INTO sub.tblJournalEntryCode 
			(
				JournalEntryCode, 
				EmployerNumber, 
				PaymentRunID, 
				IBAN, 
				Ascription
			)
		VALUES 
			(
				@JournalEntryCode, 
				@EmployerNumber, 
				@PaymentRunID, 
				@IBAN, 
				@Ascription
			)

		/* Add all declarations and reversals to tblPaymentRun_Declaration.	*/
		INSERT INTO sub.tblPaymentRun_Declaration
			(
				PaymentRunID,
				DeclarationID,
				PartitionID,
				IBAN,
				Ascription,
				ReversalPaymentID,
				JournalEntryCode,
				PartitionAmount,
				VoucherAmount
			)
		SELECT	
				@PaymentRunID,
				decl.DeclarationID,
				dep.PartitionID,
				@IBAN,
				@Ascription,
				ISNULL(drp.ReversalPaymentID, 0),
				@JournalEntryCode,
				dep.PartitionAmountCorrected,
				dep.VoucherValue						
		FROM	sub.tblDeclaration decl
		INNER JOIN sub.viewDeclaration_Partition_AmmountInPaymentRun dep
		ON		dep.DeclarationID = decl.DeclarationID
		LEFT JOIN sub.tblDeclaration_ReversalPayment drp
		ON		drp.DeclarationID = decl.DeclarationID 
		AND		drp.PaymentRunID IS NULL
		LEFT JOIN sub.tblDeclaration_Partition_ReversalPayment dprp
		ON		dprp.PartitionID = dep.PartitionID
		AND		dprp.ReversalPaymentID = drp.ReversalPaymentID
		LEFT JOIN sub.tblEmployer_PaymentStop eps
		ON		eps.EmployerNumber = decl.EmployerNumber
		AND		eps.StartDate <= @EndDate
		AND		COALESCE(eps.EndDate, @EndDate) >= @EndDate
		AND		eps.PaymentstopType = '0001'
        LEFT JOIN   sub.tblPaymentArrear pa
        ON      pa.EmployerNumber = decl.EmployerNumber
        AND	    DATEDIFF(DAY, pa.FeesPaidUntill, GETDATE()) > 30
		LEFT JOIN stip.viewDeclaration stpd 
		ON		stpd.DeclarationID = decl.DeclarationID
		WHERE	decl.SubsidySchemeID IN ( 
											SELECT 	SubsidySchemeID
											FROM	@tblSubsidyScheme
										)
		AND		decl.EmployerNumber = @EmployerNumber
		AND		dep.PaymentDate <= @EndDate
		AND		eps.PaymentStopID IS NULL
        AND     (   pa.FeesPaidUntill IS NULL
                OR  (   pa.FeesPaidUntill IS NOT NULL
                    AND dep.PartitionStatus <> '0009'
                    )
                )
		AND		(	decl.SubsidySchemeID <> 4
				OR
					(		
							decl.SubsidySchemeID = 4
						AND	
							decl.DeclarationStatus = '0031'
						AND
							dep.PartitionStatus = '0024'
					)
				)
		--GROUP BY 
		--		decl.DeclarationID,
		--		dep.PartitionID,
		--		dpr.ReversalPaymentID,
		--		dep.PartitionAmountCorrected

		-- Update PartitionStatus of declarations and reversals.
		DECLARE cur_Declarations CURSOR 
			LOCAL    
			STATIC
			READ_ONLY
			FORWARD_ONLY
			FOR 
			SELECT	decl.DeclarationID,
					decl.StatusReason,
					pad.PartitionID,
					pad.ReversalPaymentID,
					dep.PartitionYear,
					dep.PartitionStatus,
					ROW_NUMBER() OVER(PARTITION BY dep.DeclarationID 
											ORDER BY dep.DeclarationID, dep.PartitionYear
										) AS PartitionSequence
			FROM	sub.tblDeclaration decl
			INNER JOIN	sub.tblPaymentRun_Declaration pad 
			ON		pad.DeclarationID = decl.DeclarationID
			INNER JOIN	sub.tblDeclaration_Partition dep 
			ON		dep.PartitionID = pad.PartitionID
			WHERE	pad.PaymentRunID = @PaymentRunID
			AND		pad.JournalEntryCode = @JournalEntryCode
			ORDER BY 
					pad.DeclarationID, 
					dep.PartitionYear

		--	Loop through cursor.
		OPEN cur_Declarations

		FETCH FROM cur_Declarations 
		INTO	@DeclarationID,
				@StatusReason,
				@PartitionID, 
				@ReversalPaymentID, 
				@PartitionYear,
				@PartitionStatus,
				@PartitionSequence

		WHILE @@FETCH_STATUS = 0  
		BEGIN
			-- Get the last partition for this declaration according to the year.
			SELECT	@MaxPartition = MAX(PartitionYear)
			FROM	sub.tblDeclaration_Partition
			WHERE	DeclarationID = @DeclarationID

			IF	@PartitionStatus = '0007'
			BEGIN
				SET @NewPartitionStatus = '0017'
			END
			ELSE IF @PartitionStatus = '0021'
				 BEGIN
					SET @NewPartitionStatus = '0028'
				 END
				 ELSE
				 BEGIN
					SET @NewPartitionStatus = '0010'
				 END

			-- Update partition
			EXEC @RC = sub.uspDeclaration_Partition_Upd_PartitionStatus
				@PartitionID,
				@NewPartitionStatus,
				@CurrentUserID

				/*	Finally update Declaration.	*/
				SELECT @DeclarationStatus = sub.usfGetDeclarationStatusByPartition(@DeclarationID, NULL, NULL)

				EXEC sub.uspDeclaration_Upd_DeclarationStatus
						@DeclarationID,
						@DeclarationStatus,
						@StatusReason,
						@CurrentUserID

			-- Update sub.tblDeclaration_Partition_ReversalPayment record.
			UPDATE	sub.tblDeclaration_ReversalPayment
			SET		PaymentRunID = @PaymentRunID
			WHERE	ReversalPaymentID = @ReversalPaymentID

			IF @SubsidySchemeID = 1 --Only with OSR.
			BEGIN
                -- Correct partitionamount of future partition(s) on reversal.
                IF  @PartitionStatus = '0016'
                AND @PartitionYear <> @MaxPartition
                BEGIN
					-- Get ratio of reversed amount.
					SELECT 	@Ratio = ((pad.PartitionAmount * -1) / dep.PartitionAmount) * 100
					FROM 	sub.tblPaymentRun_Declaration pad
					INNER JOIN sub.tblDeclaration_ReversalPayment drp
							ON	drp.PaymentRunID = pad.PaymentRunID
							AND	drp.DeclarationID = pad.DeclarationID
					INNER JOIN sub.tblDeclaration_Partition_ReversalPayment dprp
							ON	dprp.ReversalPaymentID = pad.ReversalPaymentID
					INNER JOIN sub.tblDeclaration_Partition dep
							ON 	dep.PartitionID = dprp.PartitionID
					WHERE 	pad.PaymentRunID = @PaymentRunID
                    AND     pad.ReversalPaymentID <> 0
					AND 	dprp.PartitionID = @PartitionID

                    DECLARE cur_Partition CURSOR
                        LOCAL    
                        STATIC
                        READ_ONLY
                        FORWARD_ONLY
                        FOR  
                        SELECT 
                                dep.PartitionID
                        FROM	sub.tblPaymentRun_Declaration pad
						INNER JOIN sub.tblDeclaration_ReversalPayment drp
								ON	drp.PaymentRunID = pad.PaymentRunID
								AND	drp.DeclarationID = pad.DeclarationID
						INNER JOIN sub.tblDeclaration_Partition dep
								ON	dep.DeclarationID = drp.DeclarationID
                        WHERE	pad.PaymentRunID = @PaymentRunID
                        AND     pad.ReversalPaymentID <> 0
						AND     dep.PartitionYear > @PartitionYear
                        AND     dep.PartitionStatus = '0001'
                        ORDER BY 
                                dep.PartitionYear

                    OPEN cur_Partition

                    FETCH FROM cur_Partition INTO @FuturePartitionID

                    WHILE @@FETCH_STATUS = 0  
                    BEGIN
						-- Get partition data.
						SELECT 	@FuturePartitionYear = PartitionYear,
								@FuturePartitionAmount = PartitionAmount - (PartitionAmount * (@Ratio / 100)),
								@FuturePartitionAmountCorrected = 0.00,
								@FuturePaymentDate = PaymentDate,
								@FuturePartitionStatus = PartitionStatus
						FROM 	sub.tblDeclaration_Partition
						WHERE 	PartitionID = @FuturePartitionID

                        -- Update the partition amount.
                        EXECUTE @RC = [sub].[uspDeclaration_Partition_Upd] 
                            @FuturePartitionID,
                            @DeclarationID,
                            @FuturePartitionYear,
                            @FuturePartitionAmount,
                            @FuturePartitionAmountCorrected,
                            @FuturePaymentDate,
                            @FuturePartitionStatus,
                            1	--1=Admin

                        FETCH FROM cur_Partition INTO @FuturePartitionID
                    END

                    CLOSE cur_Partition
                    DEALLOCATE cur_Partition                   
                END

				/* Update Horus.	*/
				INSERT INTO hrs.tblVoucher_Used 
					(
						EmployeeNumber,
						EmployerNumber,
						ERT_Code,
						GrantDate,
						DeclarationID,
						VoucherNumber,
						AmountUsed,
						VoucherStatus
					)
				SELECT	dem.EmployeeNumber,
						decl.EmployerNumber,
						emv.ERT_Code,
						emv.GrantDate,
						decl.DeclarationID,
						dpv.VoucherNumber,
						dpv.DeclarationValue,
						CASE ISNULL(der.ReversalPaymentID, 0) 
							WHEN 0 THEN decl.DeclarationStatus
							ELSE '0016'
						END
				FROM	sub.tblPaymentRun_Declaration pad
				INNER JOIN sub.tblDeclaration decl
				ON		decl.DeclarationID = pad.DeclarationID
				INNER JOIN sub.tblDeclaration_Employee dem
				ON		dem.DeclarationID = pad.DeclarationID
				INNER JOIN sub.tblDeclaration_Partition_Voucher dpv
				ON		dpv.DeclarationID = pad.DeclarationID
				AND		dpv.PartitionID = pad.PartitionID
				AND		dpv.EmployeeNumber = dem.EmployeeNumber
				INNER JOIN sub.tblEmployee_Voucher emv
				ON		emv.EmployeeNumber = dpv.EmployeeNumber
				AND		emv.VoucherNumber = dpv.VoucherNumber
				LEFT JOIN sub.tblDeclaration_Employee_ReversalPayment der
				ON		der.DeclarationID = pad.DeclarationID
				AND		der.EmployeeNumber = dpv.EmployeeNumber
				AND		der.ReversalPaymentID = pad.ReversalPaymentID
				WHERE	pad.PaymentRunID = @PaymentRunID
				AND		decl.DeclarationID = @DeclarationID
			END

			--IF @PartitionSequence = 1
			--BEGIN
			--	EXEC	@RC = sub.uspDeclaration_Specification_Upd
			--			@DeclarationID,
			--			NULL,
			--			@PaymentRunID,
			--			@CurrentUserID
			--END

			FETCH NEXT FROM cur_Declarations 
			INTO	@DeclarationID,
					@StatusReason, 
					@PartitionID,
					@ReversalPaymentID,
					@PartitionYear,
					@PartitionStatus,
					@PartitionSequence
		END

		CLOSE cur_Declarations
		DEALLOCATE cur_Declarations

		--EXECUTE @RC = sub.uspJournalEntryCode_Specification_Upd		-- Removed from here to the job OTIB-DS Automatic paymentrun export
		--    @JournalEntryCode,
		--    @CurrentUserID

		COMMIT TRANSACTION
	END TRY

	BEGIN CATCH
	ROLLBACK TRANSACTION

--		RAISERROR ('%s',16, 1, @variable_containing_error)

	END CATCH

	FETCH NEXT FROM cur_JournalEntryCode
	INTO	@SubsidySchemeID,
			@EmployerNumber,
			@IBAN,
			@Ascription,
			@RowNumber,
			@MinPartitionStatus,
			@MaxPartitionStatus,
			@TotalAmount

END

CLOSE cur_JournalEntryCode
DEALLOCATE cur_JournalEntryCode

/* Finalize PaymentRun.	*/
UPDATE	sub.tblPaymentRun
SET		Completed = GETDATE()
WHERE	PaymentRunID = @PaymentRunID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.usp_OTIB_PaymentRun_Add ===========================================================	*/
