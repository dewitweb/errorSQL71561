
CREATE PROCEDURE ait.uspMaintenance_Upd
@RecordID	int,
@StartDate	datetime,
@Duration	smallint,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose: 	Update ait.tblMaintenance on basis of RecordID.

	06-05-2019	Sander van Houten	OTIBSUB-964		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Return		int = 1

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF ISNULL(@RecordID, 0) = 0
BEGIN
	-- Add new record
	INSERT INTO ait.tblMaintenance
		(
			StartDate,
			Duration
		)
	VALUES
		(
			@StartDate,
			@Duration
		)

	SET	@RecordID = SCOPE_IDENTITY()

	-- Save new record.
	SELECT	@XMLdel = NULL,
			@XMLins = (	SELECT 	*
						FROM	ait.tblMaintenance
						WHERE	RecordID = @RecordID
						FOR XML PATH )

END
ELSE
BEGIN
	-- Save old record.
	SELECT	@XMLdel = (	SELECT 	*
						FROM	ait.tblMaintenance
						WHERE	RecordID = @RecordID
						FOR XML PATH )

	-- Update existing record.
	UPDATE	ait.tblMaintenance
	SET
			StartDate	= @StartDate,
			Duration	= @Duration
	WHERE	RecordID = @RecordID

	-- Save new record.
	SELECT	@XMLins = (	SELECT 	*
						FROM	ait.tblMaintenance
						WHERE	RecordID = @RecordID
						FOR XML PATH )
END

-- Log action in his.tblHistory.
IF CAST(ISNULL(@XMLdel, '') AS varchar(MAX)) <> CAST(ISNULL(@XMLins, '') AS varchar(MAX))
BEGIN
	SET @KeyID = @RecordID

	EXEC his.uspHistory_Add
			'ait.tblMaintenance',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SELECT RecordID = @RecordID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== ait.uspMaintenance_Upd ================================================================	*/
