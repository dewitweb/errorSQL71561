
CREATE PROCEDURE sub.uspNewsItem_Upd
@NewsItemID				int,
@NewsItemName			varchar(200),
@NewsItemType			varchar(4),
@StartDate				date,
@EndDate				date,
@Title					varchar(200),
@NewsItemMessage		varchar(MAX),
@CalendarDisplayDate	date,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose: 	Update sub.tblNewsItem on basis of NewsItemID.

	22-10-2018	Jaap van Assenbergh	Inital version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Return		int = 1

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF ISNULL(@NewsItemID, 0) = 0
BEGIN
	-- Add new record
	INSERT INTO sub.tblNewsItem
		(
			NewsItemName,
			NewsItemType,
			StartDate,
			EndDate,
			Title,
			NewsItemMessage,
			CalendarDisplayDate
		)
	VALUES
		(
			@NewsItemName,
			@NewsItemType,
			@StartDate,
			@EndDate,
			@Title,
			@NewsItemMessage,
			@CalendarDisplayDate
		)

	SET	@NewsItemID = SCOPE_IDENTITY()

	-- Save new record.
	SELECT	@XMLdel = NULL,
			@XMLins = (	SELECT 	*
						FROM	sub.tblNewsItem
						WHERE	NewsItemID = @NewsItemID
						FOR XML PATH )

END
ELSE
BEGIN
	-- Save old record.
	SELECT	@XMLdel = (	SELECT 	*
						FROM	sub.tblNewsItem
						WHERE	NewsItemID = @NewsItemID
						FOR XML PATH )

	-- Update existing record.
	UPDATE	sub.tblNewsItem
	SET
			NewsItemName		= @NewsItemName,
			NewsItemType		= @NewsItemType,
			StartDate			= @StartDate,
			EndDate				= @EndDate,
			Title				= @Title,
			NewsItemMessage		= @NewsItemMessage,
			CalendarDisplayDate	= @CalendarDisplayDate
	WHERE	NewsItemID = @NewsItemID

	-- Save new record.
	SELECT	@XMLins = (	SELECT 	*
						FROM	sub.tblNewsItem
						WHERE	NewsItemID = @NewsItemID
						FOR XML PATH )
END

-- Log action in his.tblHistory.
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @NewsItemID

	EXEC his.uspHistory_Add
			'sub.tblNewsItem',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SELECT NewsItemID = @NewsItemID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SET @Return = 0

RETURN @Return

/*	== sub.uspNewsItem_Upd ===================================================================	*/
