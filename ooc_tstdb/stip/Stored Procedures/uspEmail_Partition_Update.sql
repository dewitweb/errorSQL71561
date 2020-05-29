CREATE PROCEDURE [stip].[uspEmail_Partition_Update]
@DeclarationID	int,
@ReplyDate		datetime,
@ReplyCode		varchar(4),
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose: 	Update stip.tblEmail_Partition on basis of DeclarationID.

	Notes:		This procedure is executed by the front-end when a user reacts 
				to an education status update e-mail that was sent.

	22-01-2020	Sander van Houten	OTIBSUB-1842	Set PartitionStatus = 0009 if ReplyCode = '0000'.
	30-09-2019	Sander van Houten	OTIBSUB-1598	Added transaction.
	06-08-2019	Sander van Houten	OTIBSUB-1327	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

DECLARE	@PartitionID	int,
		@EmailID		int,
		@LetterType		tinyint,
		@RC             int,
        @Return         int

BEGIN TRY
BEGIN TRANSACTION
	/*	Get correct PartitionID and EmailID.	*/
	SELECT	@PartitionID = PartitionID
	FROM	sub.tblDeclaration_Partition
	WHERE	DeclarationID = @DeclarationID
	AND		PartitionStatus = '0026'

	IF @PartitionID IS NOT NULL
	BEGIN
		SELECT	@EmailID = MAX(EmailID)
		FROM	stip.tblEmail_Partition
		WHERE	PartitionID = @PartitionID

		SELECT	@LetterType = MAX(LetterType)
		FROM	stip.tblEmail_Partition
		WHERE	PartitionID = @PartitionID
		AND		EmailID = @EmailID

		/*	Insert replycode and replydate.	*/
		EXECUTE @RC = stip.uspEmail_Partition_Upd 
			@EmailID,
			@PartitionID,
			@ReplyDate,
			@ReplyCode,
			@LetterType,
			@CurrentUserID

		/*	Update declaration and partition.	*/
		IF @ReplyCode = '0000'
		BEGIN	
			-- The education is still being followed. Payment can be done.
			-- Only update the declaration- and partitionstatus.
			DECLARE @DeclarationStatus	varchar(24),
					@StatusReason		varchar(max) = '',
					@PartitionStatus	varchar(4) = '0009'
		
			EXECUTE @RC = sub.uspDeclaration_Partition_Upd_PartitionStatus
				@PartitionID,
				@PartitionStatus,
				@CurrentUserID

            SET @DeclarationStatus = sub.usfGetDeclarationStatusByPartition(@DeclarationID, @PartitionID, @PartitionStatus)

			EXECUTE @RC = sub.uspDeclaration_Upd_DeclarationStatus 
				@DeclarationID,
				@DeclarationStatus,
				@StatusReason,
				@CurrentUserID
		END

        SET @Return = 0
	END
    -- ELSE
    -- BEGIN   -- The link has allready been used or the declaration has otherwise been updated.
    --     SELECT 0/0
    -- END

	COMMIT TRANSACTION
END TRY

BEGIN CATCH
	ROLLBACK TRANSACTION

	--		RAISERROR ('%s',16, 1, @variable_containing_error)
END CATCH

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== stip.uspEmail_Partition_Update ========================================================	*/
