CREATE PROCEDURE [sub].[uspDeclaration_Email_Upd]
@EmailID		int,
@DeclarationID	int,
@EmailDate		datetime,
@EmailSubject	varchar(50),
@EmailBody		varchar(MAX),
@Direction		varchar(10),
@HandledDate	datetime,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose:	Update sub.tblDeclaration_email on the basis of EmailID.

	06-09-2019	Sander van Houten		OTIBSUB-1033	Set PartitionAmountCorrected to 0.00 
											when updating partitions to status 0006.
	18-06-2019	Sander van Houten		OTIBSUB-1228	Also update partitions to status 0006.
	02-08-2018	Sander van Houten		CurrentUserID added.
	27-07-2018	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50),
		@NewEmail	bit = 0

IF ISNULL(@EmailID, 0) = 0
BEGIN
	-- Add new record
	INSERT INTO sub.tblDeclaration_Email
		(
			DeclarationID,
			EmailDate,
			EmailSubject,
			EmailBody,
			Direction,
			HandledDate
		)
	VALUES
		(
			@DeclarationID,
			@EmailDate,
			@EmailSubject,
			@EmailBody,
			@Direction,
			@HandledDate
		)

	-- Save new EmailID
	SET	@EmailID = SCOPE_IDENTITY()

	-- Save new record
	SELECT	@XMLdel = NULL,
			@XMLins = (SELECT * 
					   FROM sub.tblDeclaration_Email 
					   WHERE EmailID = @EmailID 
					   FOR XML PATH)

	-- Set flag for new question to declarant
	IF @Direction = 'out'
		SET @NewEmail = 1
END
ELSE
BEGIN
	-- Save old record
	SELECT	@XMLdel = (SELECT * 
					   FROM sub.tblDeclaration_Email 
					   WHERE EmailID = @EmailID 
					   FOR XML PATH)

	-- Update exisiting record
	UPDATE	sub.tblDeclaration_Email
	SET
			DeclarationID	= @DeclarationID,
			EmailDate		= @EmailDate,
			EmailSubject	= @EmailSubject,
			EmailBody		= @EmailBody,
			Direction		= @Direction,
			HandledDate		= @HandledDate
	WHERE	EmailID = @EmailID

	-- Save new record
	SELECT	@XMLins = (SELECT * 
					   FROM sub.tblDeclaration_Email 
					   WHERE EmailID = @EmailID 
					   FOR XML PATH)
END

-- Log action in tblHistory
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @EmailID

	EXEC his.uspHistory_Add
			'sub.tblDeclaration_Email',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

-- Update DeclarationStatus
IF @NewEmail = 1
BEGIN
	DECLARE @DeclarationStatus			varchar(4) = '0006',
			@StatusReason				varchar(max) = NULL,
			@PartitionID				int,
			@PartitionYear				varchar(20),
			@PartitionAmount			decimal(19,4),
			@PartitionAmountCorrected	decimal(19,4) = 0.00,
			@PaymentDate				date

	EXECUTE [sub].[uspDeclaration_Upd_DeclarationStatus] 
		@DeclarationID,
		@DeclarationStatus,
		@StatusReason,
		@CurrentUserID

	/*	Update partition(s).	*/
	DECLARE cur_Partition CURSOR FOR 
	SELECT	PartitionID,
			PartitionYear,
			PartitionAmount,
			PaymentDate
	FROM	sub.tblDeclaration_Partition
	WHERE	DeclarationID = @DeclarationID
	  AND	PartitionStatus IN ('0005', '0006', '0007', '0008', '0009', '0022')

	OPEN cur_Partition
	FETCH NEXT FROM cur_Partition INTO @PartitionID, @PartitionYear, @PartitionAmount, @PaymentDate

	WHILE @@FETCH_STATUS = 0 
	BEGIN
		--	Update partition.
		EXECUTE [sub].[uspDeclaration_Partition_Upd] 
			@PartitionID,
			@DeclarationID,
			@PartitionYear,
			@PartitionAmount,
			@PartitionAmountCorrected,
			@PaymentDate,
			@DeclarationStatus,	-- = @PartitionStatus,
			@CurrentUserID

		FETCH NEXT FROM cur_Partition INTO @PartitionID, @PartitionYear, @PartitionAmount, @PaymentDate
	END
	CLOSE cur_Partition
	DEALLOCATE cur_Partition
END

SELECT EmailID = @EmailID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Email_Upd ===========================================================	*/
