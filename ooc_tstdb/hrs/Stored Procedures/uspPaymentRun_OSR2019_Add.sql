
CREATE PROCEDURE [hrs].[uspPaymentRun_OSR2019_Add]
@DeclarationNumber	varchar(6)
AS
/*	==========================================================================================
	Purpose:	Add record to sub.tblPaymentRun.

	Note:		If the DeclarationNumber parameter is NULL -> only create PaymentRun records.

	07-11-2019	Sander van Houten	OTIBSUB-1539	DeclarationStatus -> PartitionStatus.
	25-10-2019	Jaap van Assenbergh	OTIBSUB-1647	Terugboekingen mogelijk maken per partitie
	16-07-2019	Jaap van Assenbergh	OTIBSUB-1373    Aanmaken specificatie verwijderd ivm verzamel nota
	21-02-2019	Sander van Houten	OTIBSUB-792 Manier van vastlegging terugboeking 
										bij werknemer veranderen.
	10-01-2019	Sander van Houten	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

DECLARE	@SubsidySchemeID				tinyint = 1,
		@PaymentRunID					int = 0,
		@RunDate						datetime,
		@PaymentRunID_ReversalPayment	int = 0,
		@RunDate_ReversalPayment		datetime,
		@DeclarationID					int,
		@ReversalPaymentID				int = 0,
		@ReversalPaymentReason			varchar(max) = '',
		@PartitionID					int,
		@PartitionYear					varchar(20),
		@PartitionAmount				decimal(19,4),
		@PartitionAmountCorrected		decimal(19,4),
		@PaymentDate					date,
		@MaxPartition					varchar(20),
		@SubsidySchemeName				varchar(100),
		@FirstPartitionOfDeclaration	int,
		@DeclarationStatus				varchar(2),
		@CurrentUserID					int = 1,
		@RC								int

/*	Only create missing paymentrun records.	*/
IF @DeclarationNumber IS NULL
BEGIN
	SET IDENTITY_INSERT sub.tblPaymentRun ON

	-- For paid declarations.
	INSERT INTO sub.tblPaymentRun
		(
			PaymentRunID,
			SubsidySchemeID,
			RunDate,
			EndDate,
			UserID
		)
	SELECT	DISTINCT 
			decl.PaymentRunID,
			@SubsidySchemeID,
			decl.PaymentRunDate,
			decl.PaymentRunDate,
			@CurrentUserID
	FROM	hrs.tblDeclaration_OSR2019 decl
	LEFT JOIN sub.tblPaymentRun par 
	ON		par.SubsidySchemeID = @SubsidySchemeID 
	AND		par.PaymentRunID = decl.PaymentRunID
	WHERE	decl.PaymentRunID IS NOT NULL
	  AND	par.PaymentRunID IS NULL

	-- For reversals.
	INSERT INTO sub.tblPaymentRun
		(
			PaymentRunID,
			SubsidySchemeID,
			RunDate,
			EndDate,
			UserID
		)
	SELECT	DISTINCT 
			decl.PaymentRunID_ReversalPayment,
			@SubsidySchemeID,
			decl.PaymentRunDate_ReversalPayment,
			decl.PaymentRunDate_ReversalPayment,
			@CurrentUserID
	FROM	hrs.tblDeclaration_OSR2019 decl
	LEFT JOIN sub.tblPaymentRun par 
	ON		par.SubsidySchemeID = @SubsidySchemeID 
	AND		par.PaymentRunID = decl.PaymentRunID_ReversalPayment
	WHERE	decl.PaymentRunID_ReversalPayment IS NOT NULL
	  AND	decl.DeclarationStatus <> 'IO'
	  AND	par.PaymentRunID IS NULL

	SET IDENTITY_INSERT sub.tblPaymentRun OFF
END

ELSE

BEGIN
	/* Get all necessary information.	*/
	DECLARE cur_Partition CURSOR FOR
		SELECT	DISTINCT 
				dho.DeclarationID,
				decl.PaymentRunDate,
				COALESCE(par.PaymentRunID, -1),
				decl.PaymentRunDate_ReversalPayment,
				COALESCE(parrev.PaymentRunId, -1),
				decl.DeclarationStatus,
				dep.PartitionID
		FROM	hrs.tblDeclaration_OSR2019 decl
		INNER JOIN hrs.tblDeclaration_HorusNr_OTIBDSID dho 
		ON		dho.DeclarationNumber = decl.ParentDeclarationNumber
		INNER JOIN sub.tblDeclaration_Partition dep 
		ON		dep.DeclarationID = dho.DeclarationID 
		AND		dep.PartitionYear = LEFT(decl.StartDate, 4)
		INNER JOIN sub.tblPaymentRun par 
		ON		par.SubsidySchemeID = @SubsidySchemeID 
		AND		par.PaymentRunID = decl.PaymentRunID
		LEFT JOIN sub.tblPaymentRun parrev
		ON		parrev.SubsidySchemeID = @SubsidySchemeID 
		AND		parrev.PaymentRunID = decl.PaymentRunID_ReversalPayment
		WHERE	decl.ParentDeclarationNumber = @DeclarationNumber
		  AND	decl.DeclarationStatus <> 'IO'
		ORDER BY dep.PartitionID

	-- Process all selected records.
	OPEN cur_Partition

	FETCH NEXT FROM cur_Partition INTO @DeclarationID, @RunDate, @PaymentRunID, @RunDate_ReversalPayment, 
										@PaymentRunID_ReversalPayment, @DeclarationStatus, @PartitionID

	WHILE @@FETCH_STATUS = 0  
	BEGIN
		IF NOT EXISTS (	SELECT	1
						FROM	sub.tblPaymentRun_Declaration 
						WHERE	PaymentRunID = @PaymentRunID 
						  AND	DeclarationID = @DeclarationID
						  AND	PartitionID = @PartitionID )
		BEGIN
			-- Insert declaration/partition to tblPaymentRun_Declaration.
			INSERT INTO sub.tblPaymentRun_Declaration
				(
					PaymentRunID,
					DeclarationID,
					PartitionID,
					IBAN,
					Ascription,
					ReversalPaymentID
				)
			SELECT	@PaymentRunID,
					@DeclarationID,
					@PartitionID,
					emp.IBAN,
					emp.Ascription,
					0
			FROM	sub.tblDeclaration decl
			INNER JOIN sub.tblEmployer emp ON emp.EmployerNumber = decl.EmployerNumber
			WHERE	decl.SubsidySchemeID = @SubsidySchemeID
			  AND	decl.DeclarationID = @DeclarationID
		END

		IF @PaymentRunID_ReversalPayment <> -1
		AND NOT EXISTS (SELECT	1
						FROM	sub.tblPaymentRun_Declaration 
						WHERE	PaymentRunID = @PaymentRunID_ReversalPayment
						  AND	DeclarationID = @DeclarationID
						  AND	PartitionID = @PartitionID )
		BEGIN
			-- -- Insert record into tblDeclaration_Partition_ReversalPayment.
			-- SELECT	@ReversalPaymentID = 0,
			-- 		@ReversalPaymentReason = 'Conversie vanuit Horus'

			-- EXECUTE @RC = [sub].[uspDeclaration_Partition_ReversalPayment_Upd] 
			-- 	@ReversalPaymentID
			-- 	,@DeclarationID
			-- 	,@PartitionID
			-- 	,@ReversalPaymentReason
			-- 	,@PaymentRunID_ReversalPayment
			-- 	,@CurrentUserID

			-- SELECT	@ReversalPaymentID = drp.ReversalPaymentID
			-- FROM	sub.tblDeclaration_ReversalPayment drp
			-- INNER JOIN sub.tblDeclaration_Partition_ReversalPayment dprp
			-- 		ON	dprp.ReversalPaymentID = drp.ReversalPaymentID
			-- WHERE	drp.DeclarationID = @DeclarationID
			--   AND	dprp.PartitionID = @PartitionID
			--   AND	drp.PaymentRunID = @PaymentRunID_ReversalPayment

			-- -- Insert declaration/partition to tblPaymentRun_Declaration.
			-- INSERT INTO sub.tblPaymentRun_Declaration
			-- 	(
			-- 		PaymentRunID,
			-- 		DeclarationID,
			-- 		PartitionID,
			-- 		IBAN,
			-- 		Ascription,
			-- 		ReversalPaymentID
			-- 	)
			-- SELECT	@PaymentRunID_ReversalPayment,
			-- 		@DeclarationID,
			-- 		@PartitionID,
			-- 		emp.IBAN,
			-- 		emp.Ascription,
			-- 		@ReversalPaymentID
			-- FROM	sub.tblDeclaration decl
			-- INNER JOIN sub.tblEmployer emp ON emp.EmployerNumber = decl.EmployerNumber
			-- WHERE	decl.SubsidySchemeID = @SubsidySchemeID
			--   AND	decl.DeclarationID = @DeclarationID

            -- Reversals from Horus are no longer supported.
            INSERT INTO [ait].[tblErrorLog]
                (
                    ErrorDate,
                    ErrorNumber,
                    ErrorSeverity,
                    ErrorState,
                    ErrorProcedure,
                    ErrorLine,
                    ErrorMessage,
                    SendEmail,
                    EmailSent
                )
            SELECT  GETDATE()						AS ErrorDate,
                    1					            AS ErrorNumber,
                    1               				AS ErrorSeverity,
                    1					            AS ErrorState,
                    'hrs.uspPaymentRun_OSR2019_Add'	AS ErrorProcedure,
                    167					            AS ErrorLine,
                    'Declaratie ' + @DeclarationID + ' is teruggeboekt in Horus. Handmatige actie nodig!'
                                					AS ErrorMessage,
                    1								AS SendEmail,
                    NULL							AS EmailSent
		END

		FETCH NEXT FROM cur_Partition INTO @DeclarationID, @RunDate, @PaymentRunID, @RunDate_ReversalPayment, 
											@PaymentRunID_ReversalPayment, @DeclarationStatus, @PartitionID
	END

	CLOSE cur_Partition
	DEALLOCATE cur_Partition
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== hrs.uspPaymentRun_OSR2019_Add =========================================================	*/
