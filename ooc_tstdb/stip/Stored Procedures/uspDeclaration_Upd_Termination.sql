
CREATE PROCEDURE [stip].[uspDeclaration_Upd_Termination]
@DeclarationID		int,
@DiplomaDate		date,
@EndDataEmployment 	date,
@TerminationDate	datetime,
@TerminationReason	varchar(20),
@WithAttachment		bit,
@CurrentUserID		int = 1
AS
/*	==========================================================================================
	Purpose: 	Terminate stip.tblDeclaration based on DeclarationID.

	20-02-2020	Sander van Houten	OTIBSUB-1917	Removed update of EndDate with TerminationDate.
	20-02-2020	Sander van Houten	OTIBSUB-1916	Recalculate the declaration amount.
	26-11-2019	Sander van Houten	OTIBSUB-1730	Added code for handling an termination of
                                        a STIP extension of an Opscholing BPV.
	25-11-2019	Jaap van Assenbergh	On terminate 
									- Update partition with e-mail
									- add the ended (0024) partition
	08-11-2019	Sander van Houten	OTIBSUB-1539	DeclarationStatus -> PartitionStatus.
	17-09-2019	Jaap van Assenbergh	OTIBSUB-1178	Betalingen na diplomadatum niet uitkeren 
                                        en wel terugvorderen
	06-09-2019	Sander van Houten	OTIBSUB-1540	Added the financial settlement.
	12-07-2019	Sander van Houten	Update declaration EndDate also.
	05-07-2019	Sander van Houten	Set declaration and partitions to status 0024 (Ended).
	01-07-2019	Sander van Houten	OTIBSUB-1251	Update last PaymentDate to DiplomaDate.
	05-06-2019	Jaap van Assenbergh	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Testdata
DECLARE @DeclarationID		int = 433308,
		@DiplomaDate		date = NULL,
		@EndDataEmployment 	date = '20190701',
		@TerminationDate	datetime = '20190701',
		@TerminationReason	varchar(20) = '0007',
		@CurrentUserID		int = 7
--	*/

DECLARE @Return						int = 1,
		@DeclarationStatus			varchar(20),
		@StatusReason				varchar(max),
		@PartitionYear				varchar(20),
		@PartitionAmount			dec(9,4),
		@PartitionAmountCorrected	dec(9,4) = 0.00,
		@PaymentDate				date

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF @TerminationReason <> '0000'
BEGIN
	IF @TerminationDate IS NULL
	BEGIN
		SET @TerminationDate = CAST(@LogDate AS date)
	END

	/* Initial Termination is without certificate */
	SELECT	@PartitionYear = CONVERT(varchar(7), COALESCE(@DiplomaDate, @TerminationDate), 120),	
			@PartitionAmount = 0,
			@PartitionAmountCorrected = 0,
			@PaymentDate = COALESCE(@DiplomaDate, @TerminationDate)

	-- Save old record.
	SELECT	@XMLdel = (	SELECT 	*
						FROM	stip.tblDeclaration
						WHERE	DeclarationID = @DeclarationID
						FOR XML PATH )

	-- Update existing record.
	UPDATE	stip.tblDeclaration
	SET		DiplomaDate				= @DiplomaDate,
			TerminationDate			= @TerminationDate,
			TerminationReason		= @TerminationReason
	WHERE	DeclarationID = @DeclarationID

	-- Save new record.
	SELECT	@XMLins = (	SELECT 	*
						FROM	stip.tblDeclaration
						WHERE	DeclarationID = @DeclarationID
						FOR XML PATH )

	-- Log action in his.tblHistory.
	IF CAST(ISNULL(@XMLdel, '') AS varchar(MAX)) <> CAST(ISNULL(@XMLins, '') AS varchar(MAX))
	BEGIN
		SET @KeyID = @DeclarationID

		EXEC his.uspHistory_Add
				'stip.tblDeclaration',
				@KeyID,
				@CurrentUserID,
				@LogDate,
				@XMLdel,
				@XMLins
	END

	-- -- Update declaration EndDate.
	-- UPDATE	sub.tblDeclaration_Extension
	-- SET		EndDate = @TerminationDate
	-- WHERE	DeclarationID = @DeclarationID
	-- AND		EndDate > @TerminationDate

	-- IF @@ROWCOUNT = 0
	-- BEGIN
	-- 	UPDATE	sub.tblDeclaration
	-- 	SET		EndDate = @TerminationDate
	-- 	WHERE	DeclarationID = @DeclarationID
	-- 	AND		EndDate > @TerminationDate
	-- END

	/* Update active partition (with e-mail) to cancelled.	*/
	UPDATE  dep
	SET		PartitionStatus = '0029'
	FROM	sub.tblDeclaration_Partition dep
	INNER JOIN stip.tblEmail_Partition ep
	ON      ep.PartitionID = dep.PartitionID
	WHERE	dep.DeclarationID = @DeclarationID
	AND 	(
				(@TerminationReason <> '0006' AND PaymentDate > @TerminationDate)
			OR	(@TerminationReason = '0006' AND PaymentDate >= @TerminationDate)
			)
	AND		PartitionStatus NOT IN ('0007', '0012', '0014', '0016', '0017', '0029')

	UPDATE  dep
	SET		dep.PartitionStatus = '0024'
	FROM	sub.tblDeclaration_Partition dep
	INNER JOIN stip.tblEmail_Partition ep
	ON      ep.PartitionID = dep.PartitionID
	WHERE	dep.DeclarationID = @DeclarationID
	AND 	dep.PaymentDate = @DiplomaDate
	AND		dep.PartitionStatus NOT IN ('0007', '0012', '0014', '0016', '0017')

	/* Update all not payed partitions before termination.				*/
	UPDATE	sub.tblDeclaration_Partition
	SET		PartitionStatus = 
				CASE WHEN PaymentDate <= GETDATE() 
					THEN '0009' 
					ELSE '0001'
				END
	WHERE	DeclarationID = @DeclarationID
	AND 	(
				(@TerminationReason <> '0006' AND PaymentDate <= @TerminationDate)
			OR	(@TerminationReason = '0006' AND PaymentDate < @TerminationDate)
			)
	AND		PartitionStatus IN ('0001', '0002', '0026')

	/* Remove all not yet processed partitions.				*/
	DELETE  
	FROM	sub.tblDeclaration_Partition
	WHERE	DeclarationID = @DeclarationID
	AND 	(
				(@TerminationReason <> '0006' AND PaymentDate > @TerminationDate)
			OR	(@TerminationReason = '0006' AND PaymentDate >= @TerminationDate)
			)
	AND		PartitionStatus NOT IN ('0012', '0014', '0016', '0024', '0026', '0029')

	/*	Determine PartitionAmount.	*/
	IF EXISTS (
				SELECT  1
				FROM    stip.tblDeclaration_BPV d
				WHERE   DeclarationID = @DeclarationID
				AND     TypeBPV = 'Opscholing'
				)
	BEGIN   -- If Opscholing BPV (OTIBSUB-1730).
		SELECT	@PartitionAmount = aex.SettingValue
		FROM	sub.tblApplicationSetting aps
		INNER JOIN	sub.tblApplicationSetting_Extended aex 
		ON	    aex.ApplicationSettingID = aps.ApplicationSettingID
		WHERE	aps.SettingName = 'SubsidyAmountPerType'
		AND		aps.SettingCode = 'BPV'
	END
	ELSE
	BEGIN   -- If not Opscholing BPV.
		SELECT	@PartitionAmount = aex.SettingValue / 2
		FROM	sub.tblApplicationSetting aps
		INNER JOIN	sub.tblApplicationSetting_Extended aex 
		ON	    aex.ApplicationSettingID = aps.ApplicationSettingID
		WHERE	aps.SettingName = 'SubsidyAmountPerType'
		AND		aps.SettingCode = 'STIP'
	END

	-- Reverse payments if needed.
	IF	@TerminationReason <> '0006'
	BEGIN
		DECLARE @PartitionID			int,
				@EmployeeNumber			varchar(8),
				@tblEmployee			sub.uttEmployee,
				@ReversalPaymentReason	varchar(max) = 'Payment was done after ending education'

		DECLARE @tblReversalPayment TABLE (ReversalPaymentID int)

		DECLARE @RC					int,
				@ReversalPaymentID	int = NULL,
				@PaymentRunID       int = NULL

		DECLARE cur_Reversal CURSOR FOR 
			SELECT 	dep.PartitionID,
					dem.EmployeeNumber
			FROM	sub.tblDeclaration_Partition dep
			INNER JOIN sub.tblDeclaration_Employee dem
			ON		dem.DeclarationID = dep.DeclarationID
			WHERE	dep.DeclarationID = @DeclarationID
			AND 	(
						(@TerminationReason <> '0006' AND PaymentDate > @TerminationDate)
					OR	(@TerminationReason = '0006' AND PaymentDate >= @TerminationDate)
					)
			AND		dep.PartitionStatus IN ('0012', '0014')
		
		OPEN cur_Reversal

		FETCH NEXT FROM cur_Reversal INTO @PartitionID, @EmployeeNumber

		WHILE @@FETCH_STATUS = 0  
		BEGIN
			DELETE FROM @tblEmployee

			INSERT INTO @tblEmployee 
				(
					EmployeeNumber, 
					ReversalPaymentID
				)
			VALUES
				(
					@EmployeeNumber,
					0
				)
	
			/* Create or update Declaration_ReversalPayment record. */
			INSERT INTO @tblReversalPayment (ReversalPaymentID)
			EXEC @RC = [sub].[uspDeclaration_ReversalPayment_Upd] 
				@ReversalPaymentID,
				@DeclarationID,
				@ReversalPaymentReason,
				@PaymentRunID,
				@CurrentUserID

			SELECT	TOP 1 
					@ReversalPaymentID = ReversalPaymentID 
			FROM	@tblReversalPayment

			-- Insert payment reversal.
			EXECUTE @RC = [sub].[uspDeclaration_Partition_ReversalPayment_Update] 
				@ReversalPaymentID,
				@DeclarationID,
				@PartitionID,
				@tblEmployee,
				@ReversalPaymentReason,
				@CurrentUserID

			FETCH NEXT FROM cur_Reversal INTO @PartitionID, @EmployeeNumber
		END

		CLOSE cur_Reversal
		DEALLOCATE cur_Reversal
	END

	/* Add partition with status 0024 */ 
	--DO NOT USE EXEC sub.uspDeclaration_Partition_Upd because SELECT @PartitionID by declaration and subsidy year
	IF NOT EXISTS (
					SELECT  1
					FROM    sub.tblDeclaration_Partition
					WHERE   DeclarationID = @DeclarationID
					AND     PartitionStatus = '0024'
				  )
	BEGIN
		INSERT INTO sub.tblDeclaration_Partition
			(	DeclarationID, 
				PartitionYear, 
				PartitionAmount,
				PartitionAmountCorrected,
				PaymentDate,
				PartitionStatus
			)
		VALUES	
			(
				@DeclarationID, 
				@PartitionYear,
				@PartitionAmount,
				@PartitionAmountCorrected,
				@PaymentDate,
				'0024'
			)

		-- Save new PartitionID
		SET	@PartitionID = SCOPE_IDENTITY()

		-- Save new record
		SELECT	@XMLdel = NULL,
				@XMLins = ( SELECT	* 
							FROM	sub.tblDeclaration_Partition 
							WHERE	PartitionID = @PartitionID
							FOR XML PATH )

		SET @KeyID = @PartitionID

		EXEC his.uspHistory_Add
			'sub.tblDeclaration_Partition',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
	END

	IF	@TerminationReason = '0006'		-- Termination with diploma.
	AND	@DiplomaDate IS NOT NULL
	BEGIN	-- Update diploma date partition.
		EXEC stip.uspDeclaration_Upd_DiplomaDate
			@DeclarationID,
			@DiplomaDate,
			@WithAttachment,
			@CurrentUserID
	END
END

/*	Finally update Declaration.	*/
SELECT @DeclarationStatus = sub.usfGetDeclarationStatusByPartition(@DeclarationID, NULL, NULL)

/*	In the function will be checked if there is an attachment of the type 'Certificate'.
	Because the front-end first executes this procedure and later on inserts the attachment 
    the function always returns 'without certificate'.
	So if the status with certificate without attachment and the parameter @WithAttachment = 1 
	then switch the declarationstatus to 0031 (Verify certificate by OTIB).     */
IF @DeclarationStatus = '0030' AND @WithAttachment = 1
BEGIN
    SET @DeclarationStatus = '0031'
END

EXEC sub.uspDeclaration_Upd_DeclarationStatus
    @DeclarationID, 
    @DeclarationStatus,
    @StatusReason, 
    @CurrentUserID

/*	And update the declaration amount.	*/
DECLARE @DeclarationAmount	    decimal(19,2),
        @DeclarationAmount_New	decimal(19,2)

SELECT	@DeclarationAmount = DeclarationAmount
FROM	sub.tblDeclaration
WHERE	DeclarationID = @DeclarationID

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

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== stip.uspDeclaration_Upd_Termination ===================================================	*/
