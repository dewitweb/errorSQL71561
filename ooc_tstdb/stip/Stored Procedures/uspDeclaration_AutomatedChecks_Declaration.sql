CREATE PROCEDURE [stip].[uspDeclaration_AutomatedChecks_Declaration]
@DeclarationID	int
AS
/*	==========================================================================================
	Purpose:	Perform automated checks on all declaration with status "Ingediend" or 
				"Nieuwe opleiding afgehandeld"

	Notes:		

	12-11-2019	Sander van Houten	OTIBSUB-1696	Removed check on IBAN.
	12-11-2019	Sander van Houten	OTIBSUB-1539	DeclarationStatus -> PartitionStatus.
	12-08-2019	Sander van Houten	OTIBSUB-870		The checks on declaration level only needs 
                                        to occur once (when the first partition is not yet processed).
	08-06-2019	Sander van Houten	OTIBSUB-1114	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/* 	Testdata.
DECLARE @DeclarationID	int = 411069
--	*/

/*  Declare variables.  */
DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

DECLARE @GetDate			date = GETDATE(),
		@Accepted			bit = 0,
		@CurrentUserID		int = 1,
		@EmployerNumber		varchar(6),
        @FeesPaidUntill     date

DECLARE @tblRejectedDeclarations TABLE 
	(
		DeclarationID	int NOT NULL,
		RejectionReason varchar(24) NOT NULL,
		RejectionXML	xml NULL 
	)

/*	Checks on declaration level.	*/

-- 01. Check on payment arrear.
--     If there is a payment arrear, no other checks need to be done!
SELECT  @EmployerNumber = d.EmployerNumber,
		@FeesPaidUntill = pa.FeesPaidUntill
FROM	sub.tblDeclaration d
INNER JOIN sub.tblPaymentArrear pa ON pa.EmployerNumber = d.EmployerNumber
WHERE	d.DeclarationID = @DeclarationID
AND	    DATEDIFF(DAY, pa.FeesPaidUntill, GETDATE()) > 30

IF @FeesPaidUntill IS NOT NULL  -- A payment arrear is present!
BEGIN
	-- Remove all rejection reasons.
    DELETE
    FROM	sub.tblDeclaration_Rejection
    WHERE	DeclarationID = @DeclarationID

	-- And insert a new rejection reason for a payment arrear.
	INSERT INTO sub.tblDeclaration_Rejection
		(
			DeclarationID,
			PartitionID,
			RejectionReason,
			RejectionDateTime,
			RejectionXML
		)
	SELECT	@DeclarationID,
			0           AS PartitionID,
			'0004'      AS RejectionReason,
			@GetDate    AS RejectionDateTime,
			(SELECT	
					(SELECT	@EmployerNumber		"@Number",
							@FeesPaidUntill		DocumentDate
						FOR XML PATH('Employer'), TYPE
					)
				FOR XML PATH('PaymentArrears'), ROOT('Rejection')
			)		    AS RejectionXML
END
ELSE
BEGIN
	/* Check on other rejection reasons.	*/
	-- Insert code here.

	/* Create records for rejected declarations in sub.tblDeclaration_Rejection.	*/
	INSERT INTO sub.tblDeclaration_Rejection
		(
			DeclarationID,
			RejectionReason,
			RejectionDateTime,
			RejectionXML
		)
	SELECT	DeclarationID,
			RejectionReason,
			@LogDate AS [RejectionDateTime],
			RejectionXML
	FROM	@tblRejectedDeclarations
	ORDER BY	
			DeclarationID,
			RejectionReason
END
/*	--	End of rejectionreasons session ------------------------------------------------------	*/

/*	If no rejection reasons have been registrered, do checks on partition level.	*/
--IF NOT EXISTS (	
--				SELECT 	1
--				FROM 	sub.tblDeclaration_Rejection
--				WHERE 	DeclarationID = @DeclarationID
--			  )
--BEGIN
	DECLARE @PartitionID				int,
			@PartitionYear				varchar(20),
			@PartitionAmount			decimal(19,4),
			@PartitionAmountCorrected	decimal(19,4),
			@PaymentDate				date,
			@PartitionStatus			varchar(4),
			@DeclarationStatus			varchar(4)

	-- Check partitions.
	DECLARE cur_Partitions CURSOR FOR 
		SELECT	dep.PartitionID
		FROM	sub.tblDeclaration d
		INNER JOIN sub.tblDeclaration_Partition dep ON dep.DeclarationID = d.DeclarationID
		WHERE	d.DeclarationID = @DeclarationID
		AND		dep.PaymentDate <= GETDATE()
		AND		dep.PartitionStatus IN ('0001', '0002')
			
	OPEN cur_Partitions

	FETCH NEXT FROM cur_Partitions INTO @PartitionID

	WHILE @@FETCH_STATUS = 0  
	BEGIN
		EXEC stip.uspDeclaration_AutomatedChecks_Partition @PartitionID

		FETCH NEXT FROM cur_Partitions INTO @PartitionID
	END

	CLOSE cur_Partitions
	DEALLOCATE cur_Partitions
--END

/* Update status of declaration.	*/
IF EXISTS (	
			SELECT 	1
			FROM 	sub.tblDeclaration_Rejection
			WHERE 	DeclarationID = @DeclarationID
		  )
BEGIN
	DECLARE @StatusReason	varchar(max) = 'Automatische controle'

	-- Get the new status by checking the active partition status.
	SELECT @DeclarationStatus = sub.usfGetDeclarationStatusByPartition(@DeclarationID, NULL, NULL)

	EXEC sub.uspDeclaration_Upd_DeclarationStatus
		@DeclarationID,
		@DeclarationStatus,
		@StatusReason,
		1      
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== stip.uspDeclaration_AutomatedChecks_Declaration ===================================	*/
