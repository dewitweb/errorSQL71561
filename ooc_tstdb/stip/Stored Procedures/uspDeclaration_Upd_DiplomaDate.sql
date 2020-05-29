CREATE PROCEDURE [stip].[uspDeclaration_Upd_DiplomaDate]
@DeclarationID	int,
@DiplomaDate	date,
@WithAttachment	bit,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose: 	Update diplomadate in stip.tblDeclaration on basis of DeclarationID.

	Notes:		Used by front-end when a user uploads a diploma.

	12-12-2019	Sander van Houten		OTIBSUB-1760	No longer add a new partition record,
                                            it allready is insered by stip.uspDeclaration_Upd_Termination.
	22-10-2019	Sander van Houten		OTIBSUB-1634	Changed status 0024 into 0031.
	06-09-2019	Sander van Houten		OTIBSUB-1540	Added the financial settlement.
	03-09-2019	Sander van Houten		OTIBSUB-1520	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*  Testdata.
DECLARE @DeclarationID	int = 407557,
        @DiplomaDate	date = '20191212',
        @CurrentUserID	int = 50893
--  */

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

DECLARE @RC                         int,
		@PartitionID                int = 0,
		@PartitionYear              varchar(20),
		@PartitionAmount            decimal(9,4),
		@PartitionAmountCorrected   decimal(9,4),
		@PartitionStatus            varchar(4),
        @DeclarationStatus			varchar(20),
		@StatusReason				varchar(max)--,
        --@WithAttachment	            bit = 0

/* Update stip.tblDeclaration record.	*/
-- Save old record.
SELECT	@XMLdel = (	SELECT 	*
					FROM	stip.tblDeclaration
					WHERE	DeclarationID = @DeclarationID
					FOR XML PATH )

-- Update existing record.
UPDATE	stip.tblDeclaration
SET		DiplomaDate	= @DiplomaDate
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

/* Get the current data of the partition that has the status Ended (0024). */
SELECT  @PartitionID = PartitionID,
        @PartitionYear = CONVERT(varchar(7), @DiplomaDate, 120),
		@PartitionAmount = PartitionAmount,
		@PartitionAmountCorrected = PartitionAmountCorrected,
		@PartitionStatus = PartitionStatus
FROM    sub.tblDeclaration_Partition
WHERE   DeclarationID = @DeclarationID
AND     PartitionStatus = '0024'

/* Update the partition.    */
EXECUTE @RC = [sub].[uspDeclaration_Partition_Upd] 
    @PartitionID,
    @DeclarationID,
    @PartitionYear,
    @PartitionAmount,
    @PartitionAmountCorrected,
    @DiplomaDate,  -- PaymentDate
    @PartitionStatus,
    @CurrentUserID

--/* Remove all not yet processed partitions.	*/
DELETE 
FROM	sub.tblDeclaration_Partition
WHERE	DeclarationID = @DeclarationID
AND		PaymentDate >= @DiplomaDate
AND		PartitionStatus NOT IN ('0012', '0014', '0016', '0024', '0026', '0029')

/* Reverse payments if needed.	*/
DECLARE @EmployeeNumber			varchar(8),
		@tblEmployee			sub.uttEmployee,
		@ReversalPaymentReason	varchar(max) = 'Payment was done after diploma date'

DECLARE cur_Reversal CURSOR FOR 
	SELECT 	dep.PartitionID,
			dem.EmployeeNumber
	FROM	sub.tblDeclaration_Partition dep
	INNER JOIN sub.tblDeclaration_Employee dem
	ON		dem.DeclarationID = dep.DeclarationID
	WHERE	dep.DeclarationID = @DeclarationID
	AND		dep.PaymentDate >= @DiplomaDate
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
	
	-- Insert payment reversal.
	EXEC sub.uspDeclaration_Partition_ReversalPayment_Update
		@DeclarationID,
		@PartitionID,
		@tblEmployee,
		@ReversalPaymentReason,
		@CurrentUserID

	FETCH NEXT FROM cur_Reversal INTO @PartitionID, @EmployeeNumber
END

CLOSE cur_Reversal
DEALLOCATE cur_Reversal

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

    EXEC sub.uspDeclaration_Upd_DeclarationStatus
        @DeclarationID, 
        @DeclarationStatus,
        @StatusReason, 
        @CurrentUserID
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== stip.uspDeclaration_Upd_DiplomaDate ===================================================	*/
