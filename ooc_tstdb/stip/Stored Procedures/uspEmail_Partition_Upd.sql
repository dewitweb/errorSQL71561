CREATE PROCEDURE [stip].[uspEmail_Partition_Upd]
@EmailID		int,
@PartitionID	int,
@ReplyDate		datetime,
@ReplyCode		varchar(4),
@LetterType		tinyint,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose: 	Update stip.tblEmail_Partition on basis of EmailID.

	02-05-2019	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Return		int = 1

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF	(
		SELECT COUNT(1)
		FROM	stip.tblEmail_Partition
		WHERE	EmailID = @EmailID
	) = 0
BEGIN
	-- Add new record
	INSERT INTO stip.tblEmail_Partition
		(
			EmailID,
			PartitionID,
			ReplyDate,
			ReplyCode,
			LetterType
		)
	VALUES
		(
			@EmailID,
			@PartitionID,
			@ReplyDate,
			@ReplyCode,
			@LetterType
		)

	SET	@EmailID = SCOPE_IDENTITY()

	-- Save new record.
	SELECT	@XMLdel = NULL,
			@XMLins = (	SELECT 	*
						FROM	stip.tblEmail_Partition
						WHERE	EmailID = @EmailID
						FOR XML PATH )

END
ELSE
BEGIN
	-- Save old record.
	SELECT	@XMLdel = (	SELECT 	*
						FROM	stip.tblEmail_Partition
						WHERE	EmailID = @EmailID
						FOR XML PATH )

	-- Update existing record.
	UPDATE	stip.tblEmail_Partition
	SET
			PartitionID	= @PartitionID,
			ReplyDate	= @ReplyDate,
			ReplyCode	= @ReplyCode,
			LetterType	= @LetterType
	WHERE	EmailID = @EmailID

	-- Save new record.
	SELECT	@XMLins = (	SELECT 	*
						FROM	stip.tblEmail_Partition
						WHERE	EmailID = @EmailID
						FOR XML PATH )
END

-- Log action in his.tblHistory.
IF CAST(ISNULL(@XMLdel, '') AS varchar(MAX)) <> CAST(ISNULL(@XMLins, '') AS varchar(MAX))
BEGIN
	SET @KeyID = @EmailID

	EXEC his.uspHistory_Add
			'stip.tblEmail_Partition',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SELECT EmailID = @EmailID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== stip.uspEmail_Partition_Upd ===========================================================	*/
