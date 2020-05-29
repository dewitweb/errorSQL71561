CREATE PROCEDURE [sub].[usp_OTIB_Declaration_Upd_AcceptReject]
@DeclarationID	int,
@Accept			bit,
@Reason			varchar(max),
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose:	Accept or Reject a declaration by an OTIB user.

	22-01-2020	Jaap van Assenbergh	OTIBSUB-1817	Rejectionreason verwijderen en historie
	13-11-2019	Sander van Houten	OTIBSUB-1681	Only update voucher(s) if a voucher is present.
	12-11-2019	Jaap van Assenbergh	OTIBSUB-1539	Declaratieniveau naar Partitieniveau brengen.
	04-11-2019	Sander van Houten	OTIBSUB-1672	Update voucher(s) if a declaration is rejected.
	04-07-2019	Sander van Houten	OTIBSUB-1325	Update partition(s) to correct status
										if declaration is accepted.
	03-07-2019	Sander van Houten	OTIBSUB-1314	Added logging.
	28-06-2019	Sander van Houten	OTIBSUB-940		Status 0021 for accepted declaration, but
										without current budget.
	18-06-2019	Sander van Houten	OTIBSUB-1228	Also select partitions with status 0006.
	24-05-2019	Jaap van Assenbergh	OTIBSUB-1078	Routing tussen DS en Etalage wijzigen
	03-04-2019	Sander van Houten	OTIBSUB-851		Recalculate PartitionAmountCorrected if accepted.
	06-03-2019	Sander van Houten	OTIBSUB-824		Adjustment for freeing used voucher.
	16-11-2018	Sander van Houten	OTIBSUB-424		Removed parameter @ApprovedAmount.
	04-10-2018	Sander van Houten	Added partitionID.
	07-11-2018  Jaap van Assenbergh	OTIBSUB-416		Parameters verwijderen uit subDeclaration_Upd
										- DeclarationStatus
										- StatusReason
										- InternalMemo.
	04-10-2018	Sander van Houten	OTIBSUB-313		Added partition data.
	03-08-2018	Sander van Houten	Added CurrentUserID.
	01-08-2018	Sander van Houten	OTIBSUB-66		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*  Testdata.
DECLARE @DeclarationID	int = 407282,
        @Accept			bit = 0,
        @Reason			varchar(max) = 'Afkeur door SVH',
        @CurrentUserID	int = 1
--  */

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

DECLARE @DeclarationStatus			varchar(4),
        @StatusXML					xml,
        @SubsidySchemeID            int

DECLARE @PartitionID				int,
		@PartitionYear				varchar(20),
		@PartitionAmount			decimal(19,2),
		@PartitionAmountCorrected	decimal(19,2),
		@PartitionStatus			varchar(4),
		@PaymentDate				date,
		@CorrectionAmount			decimal(19,2),
		@VoucherAmount				decimal(19,2),
        @PartitionPresent           bit = 0

DECLARE @RC							int,
		@EmployeeNumber				varchar(8),
		@VoucherNumber				varchar(3),
		@GrantDate					date,
		@ValidityDate				date,
		@VoucherValue				decimal(19,4),
		@AmountUsed					decimal(19,4),
		@ERT_Code					varchar(3),
		@EventName					varchar(100),
		@EventCity					varchar(100),
		@Active						bit,
		@RejectionReason			varchar(24)

IF	(
		SELECT	DeclarationStatus
		FROM	sub.tblDeclaration
		WHERE	DeclarationID = @DeclarationID
	) = '0022' AND @Accept = 1						-- Unknown Source accepted.
BEGIN
	-- Save old record
	SELECT	@XMLdel = (SELECT * 
					   FROM   sub.tblDeclaration_Unknown_Source 
					   WHERE  DeclarationID = @DeclarationID
					   FOR XML PATH)

	-- Update exisiting record
	UPDATE	sub.tblDeclaration_Unknown_Source 
	SET		DeclarationAcceptedDate = @LogDate		-- DeclarationAcceptedDate is trigger to go to Connect.
	WHERE	DeclarationID = @DeclarationID
	AND		DeclarationAcceptedDate IS NULL

	-- Save new record
	SELECT	@XMLins = (SELECT * 
					   FROM   sub.tblDeclaration_Unknown_Source 
					   WHERE  DeclarationID = @DeclarationID
					   FOR XML PATH)

	-- Log action in tblHistory
	SELECT	@KeyID = CAST(@DeclarationID AS varchar(6))

	EXEC his.uspHistory_Add
			'sub.tblDeclaration_Unknown_Source',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins

	-- Log user action on declaration level in tblHistory
	SELECT	@XMLdel = CAST('<triggeraction>1</triggeraction>' AS xml),
			@XMLins = CAST('<row><triggeraction>Declaratie ' + @KeyID 
                        + ' is goedgekeurd voor verdere verwerking.</triggeraction></row>' AS xml)

	EXEC his.uspHistory_Add
			'sub.tblDeclaration',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins

	-- Process declaration via AutomatedChecks.
	SET @StatusXML = 
		N'<partitionstatussen>
			<partitionstatus>0022</partitionstatus>
		</partitionstatussen>'

	EXEC osr.uspDeclaration_AutomatedChecks @StatusXML
END
ELSE
BEGIN
	IF	(
			SELECT	DeclarationStatus
			FROM	sub.tblDeclaration
			WHERE	DeclarationID = @DeclarationID
			AND		SubsidySchemeID = 4
		) = '0031'						-- Certificat accept/reject.
	BEGIN
		EXEC stip.usp_OTIB_Declaration_Upd_Diploma_AcceptReject 
				@DeclarationID, @Accept, @Reason, @CurrentUserID
	END 

	ELSE		-- Normal accept/reject
	BEGIN
		SET	@PartitionStatus = CASE @Accept WHEN 0 THEN '0007' ELSE '0009' END

		/*	First update partition(s).	*/
		DECLARE cur_Partition CURSOR FOR 
		SELECT	PartitionID
		FROM	sub.tblDeclaration_Partition
		WHERE	DeclarationID = @DeclarationID
		AND	    PartitionStatus IN ('0005', '0006', '0008', '0022', '0023')

		OPEN cur_Partition
		FETCH NEXT FROM cur_Partition INTO @PartitionID

		WHILE @@FETCH_STATUS = 0 
		BEGIN
			--  Register that a partition is present.
			SET @PartitionPresent = 1

			--	Recalculate PartitionAmountCorrect.
			SELECT	@CorrectionAmount = CAST(sub.usfGetPartitionAmountCorrected(@PartitionID, 0) AS decimal(19,2))

			SELECT	@PartitionYear = MAX(dep.PartitionYear),
					@PartitionAmount = MAX(dep.PartitionAmount),
					@PartitionAmountCorrected = CASE WHEN @PartitionStatus = '0007'
													THEN 0.00
													ELSE CASE WHEN @CorrectionAmount < 0.00
															THEN 0.00
															ELSE @CorrectionAmount 
														 END
												END,
					@PaymentDate = MAX(dep.PaymentDate),
					@VoucherAmount = SUM(ISNULL(dpv.DeclarationValue, 0.00)),
					@SubsidySchemeID = MAX(decl.SubsidySchemeID)
			FROM	sub.tblDeclaration decl
			INNER JOIN sub.tblDeclaration_Partition dep 
			ON		dep.DeclarationID = decl.DeclarationID
			LEFT JOIN sub.tblDeclaration_Partition_Voucher dpv 
			ON		dpv.DeclarationID = dep.DeclarationID 
			AND		dpv.PartitionID = dep.PartitionID
			WHERE	dep.PartitionID = @PartitionID
			GROUP BY 
					dep.PartitionID

			--	Correct status.
			IF @PartitionStatus = '0009'
			BEGIN
				IF @PaymentDate > @LogDate	
				BEGIN   -- Ingepland
					SET @PartitionStatus = '0001'
				END
				ELSE
				BEGIN
					IF (@PartitionAmountCorrected + @VoucherAmount) = 0.00
					BEGIN   -- If no subsidybudget is left and no voucher has been used.
						SET	@PartitionStatus = '0021'
					END
				END

				DECLARE crs_Rejection CURSOR    
					LOCAL    
					FAST_FORWARD    
					READ_ONLY    
					FOR	SELECT	PartitionID, RejectionReason
						FROM	sub.tblDeclaration_Rejection
						WHERE	DeclarationID = @DeclarationID
					OPEN crs_Rejection
					FETCH FROM crs_Rejection
					INTO @PartitionID, @RejectionReason
				WHILE @@FETCH_STATUS = 0   
				BEGIN

					EXECUTE sub.uspDeclaration_Rejection_Del @DeclarationID, @PartitionID, @RejectionReason, @CurrentUserID

					FETCH NEXT FROM crs_Rejection
					INTO @PartitionID, @RejectionReason
				END
				CLOSE crs_Rejection
				DEALLOCATE crs_Rejection
			END

			--	Update partition.
			EXEC sub.uspDeclaration_Partition_Upd
				@PartitionID,
				@DeclarationID,
				@PartitionYear,
				@PartitionAmount,
				@PartitionAmountCorrected,
				@PaymentDate,
				@PartitionStatus,
				@CurrentUserID

			--  Update voucher amount if OSR declaration is rejected.
			IF  @SubsidySchemeID = 1    -- OSR
			AND @PartitionStatus = '0007'
			BEGIN
				-- Initialize @GrantDate.
				SET @GrantDate = NULL

				DECLARE cur_Voucher CURSOR FOR 
				   SELECT	dpv.EmployeeNumber,
							dpv.VoucherNumber,
							emv.GrantDate,
							emv.ValidityDate,
							emv.VoucherValue,
							emv.AmountUsed - dpv.DeclarationValue,
							emv.ERT_Code,
							emv.EventName,
							emv.EventCity,
							emv.Active
					FROM	sub.tblDeclaration_Partition_Voucher dpv
					INNER JOIN sub.tblEmployee_Voucher emv
					ON		emv.EmployeeNumber = dpv.EmployeeNumber
					AND		emv.VoucherNumber = dpv.VoucherNumber
					WHERE	dpv.DeclarationID = @DeclarationID
					AND		dpv.PartitionID = @PartitionID

		
				OPEN cur_Voucher

				FETCH NEXT FROM cur_Voucher
				INTO	@EmployeeNumber, 
						@VoucherNumber, 
						@GrantDate, 
						@ValidityDate, 
						@VoucherValue, 
						@AmountUsed, 
						@ERT_Code, 
						@EventName, 
						@EventCity, 
						@Active

				WHILE @@FETCH_STATUS = 0  
				BEGIN
					IF @GrantDate IS NOT NULL
					BEGIN
						EXECUTE @RC = [sub].[uspEmployee_Voucher_Upd]
							@EmployeeNumber,
							@VoucherNumber,
							@GrantDate,
							@ValidityDate,
							@VoucherValue,
							@AmountUsed,
							@ERT_Code,
							@EventName,
							@EventCity,
							@Active,
							1	--1=Admin

						-- Update hrs.tblVoucher (OTIBSUB-1090).
						UPDATE	hrs.tblVoucher
						SET		AmountUsed = @AmountUsed,
								AmountBalance = @VoucherValue - @AmountUsed
						WHERE	EmployeeNumber = @EmployeeNumber
						AND		VoucherNumber = @VoucherNumber	

						-- And update Horus.
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
						SELECT	
								dem.EmployeeNumber,
								decl.EmployerNumber,
								emv.ERT_Code,
								emv.GrantDate,
								@DeclarationID,
								dpv.VoucherNumber,
								dpv.DeclarationValue,
								'0007'	AS DeclarationStatus
						FROM	sub.tblDeclaration decl
						INNER JOIN	sub.tblDeclaration_Partition dep
						ON		dep.DeclarationID = decl.DeclarationID
						INNER JOIN	sub.tblDeclaration_Employee dem 
						ON		dem.DeclarationID = decl.DeclarationID
						INNER JOIN sub.tblDeclaration_Partition_Voucher dpv
						ON		dpv.DeclarationID = dem.DeclarationID
						AND		dpv.EmployeeNumber = dem.EmployeeNumber
						INNER JOIN sub.tblEmployee_Voucher emv
						ON		emv.EmployeeNumber = dpv.EmployeeNumber
						AND		emv.VoucherNumber = dpv.VoucherNumber
						WHERE	dem.DeclarationID = @DeclarationID
						AND		dep.PartitionStatus = '0007'
					END

					FETCH NEXT FROM cur_Voucher 
					INTO	@EmployeeNumber, 
							@VoucherNumber, 
							@GrantDate, 
							@ValidityDate, 
							@VoucherValue, 
							@AmountUsed, 
							@ERT_Code, 
							@EventName, 
							@EventCity, 
							@Active
				END

				CLOSE cur_Voucher
				DEALLOCATE cur_Voucher
			END

			FETCH NEXT FROM cur_Partition INTO @PartitionID
		END

		CLOSE cur_Partition
		DEALLOCATE cur_Partition

		/*  If this is a rejected STIP declaration without partitions
			then insert a rejected partition.   */
		IF  (SELECT SubsidySchemeID FROM sub.tblDeclaration WHERE DeclarationID = @DeclarationID) = 4
		AND @PartitionPresent = 0
		BEGIN
			IF @Accept = 0
			BEGIN
				-- Fill variables.
				SELECT	@PartitionID = 0,
						@PartitionYear = CONVERT(varchar(7), @LogDate, 120),
						@PartitionAmountCorrected = 0.00,
						@PaymentDate = CAST(@LogDate AS date)

				IF EXISTS ( 
							SELECT  1
							FROM    stip.viewDeclaration d
							INNER JOIN hrs.tblBPV bpv
							ON      bpv.EmployerNumber = d.EmployerNumber
							AND     bpv.EmployeeNumber = d.EmployeeNumber
							AND     bpv.CourseID = d.EducationID
							AND     bpv.TypeBPV = 'Opscholing'
							WHERE   d.DeclarationID = @DeclarationID
						)
				BEGIN   -- Opscholing.
					SELECT	@PartitionAmount = aex.SettingValue
					FROM	sub.tblApplicationSetting aps
					INNER JOIN sub.tblApplicationSetting_Extended aex 
					ON      aex.ApplicationSettingID = aps.ApplicationSettingID
					WHERE	aps.SettingName = 'SubsidyAmountPerType'
					AND		aps.SettingCode = 'BPV'
					AND		CAST(@LogDate AS date) BETWEEN aex.StartDate AND aex.EndDate
				END
				ELSE
				BEGIN   -- Instroom.
					SELECT	@PartitionAmount = aex.SettingValue / 2
					FROM	sub.tblApplicationSetting aps
					INNER JOIN sub.tblApplicationSetting_Extended aex 
					ON      aex.ApplicationSettingID = aps.ApplicationSettingID
					WHERE	aps.SettingName = 'SubsidyAmountPerType'
					AND		aps.SettingCode = 'STIP'
					AND		CAST(@LogDate AS date) BETWEEN aex.StartDate AND aex.EndDate
				END

				-- Insert partition record.
				EXEC sub.uspDeclaration_Partition_Upd
					@PartitionID,
					@DeclarationID,
					@PartitionYear,
					@PartitionAmount,
					@PartitionAmountCorrected,
					@PaymentDate,
					@PartitionStatus,
					@CurrentUserID

    			SELECT @DeclarationStatus = sub.usfGetDeclarationStatusByPartition(@DeclarationID, NULL, NULL)
			END
			ELSE
			BEGIN
				SET @DeclarationStatus = '0034'
			END
		END
		ELSE
		BEGIN
			SELECT @DeclarationStatus = sub.usfGetDeclarationStatusByPartition(@DeclarationID, NULL, NULL)
		END

		/*	Finally update Declaration.	*/
		EXEC sub.uspDeclaration_Upd_DeclarationStatus
				@DeclarationID,
				@DeclarationStatus,
				@Reason,
				@CurrentUserID
	END
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.usp_OTIB_Declaration_Upd_AcceptReject =============================================	*/
