
CREATE PROCEDURE sub.uspApplicationPage_Upd
@PageID				int,
@PageCode			varchar(50),
@PageDescription_EN	varchar(100),
@PageDescription_NL	varchar(100),
@ApplicationID		int,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose: 	Update sub.tblApplicationPage on basis of PageID.

	21-02-2019	Jaap van Assenbergh	Inital version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Return		int = 1

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF ISNULL(@PageID, 0) = 0
BEGIN
	-- Add new record
	INSERT INTO sub.tblApplicationPage
		(
			PageCode,
			PageDescription_EN,
			PageDescription_NL,
			ApplicationID
		)
	VALUES
		(
			@PageCode,
			@PageDescription_EN,
			@PageDescription_NL,
			@ApplicationID
		)

	SET	@PageID = SCOPE_IDENTITY()

	-- Save new record.
	SELECT	@XMLdel = NULL,
			@XMLins = (	SELECT 	*
						FROM	sub.tblApplicationPage
						WHERE	PageID = @PageID
						FOR XML PATH )

END
ELSE
BEGIN
	-- Save old record.
	SELECT	@XMLdel = (	SELECT 	*
						FROM	sub.tblApplicationPage
						WHERE	PageID = @PageID
						FOR XML PATH )

	-- Update existing record.
	UPDATE	sub.tblApplicationPage
	SET
			PageCode			= @PageCode,
			PageDescription_EN	= @PageDescription_EN,
			PageDescription_NL	= @PageDescription_NL,
			ApplicationID		= @ApplicationID
	WHERE	PageID = @PageID

	-- Save new record.
	SELECT	@XMLins = (	SELECT 	*
						FROM	sub.tblApplicationPage
						WHERE	PageID = @PageID
						FOR XML PATH )
END

-- Log action in his.tblHistory.
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @PageID

	EXEC his.uspHistory_Add
			'sub.tblApplicationPage',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SELECT PageID = @PageID

SET @Return = 0

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

RETURN @Return

/*	== sub.uspApplicationPage_Upd ============================================================	*/
