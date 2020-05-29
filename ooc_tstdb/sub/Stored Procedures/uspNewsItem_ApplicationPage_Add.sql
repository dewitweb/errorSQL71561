
CREATE PROCEDURE [sub].[uspNewsItem_ApplicationPage_Add]
@NewsItemID			int,
@PageCode			varchar(50),
@CurrentUserID		int = 1
AS
/*	==========================================================================================
	Purpose: 	Add sub.tblNewsItem_NewsItemPage on basis of NewsItemID and PageId.

	17-12-2018	Sander van Houten		OTIBSUB-575 Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Return		int = 1

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

DECLARE @PageID	int

SELECT	@PageID = PageID
FROM	sub.tblApplicationPage
WHERE	PageCode = @PageCode

IF (SELECT	COUNT(1)
	FROM	sub.tblNewsItem_ApplicationPage
	WHERE	NewsItemID = @NewsItemID
	  AND	PageID = @PageID) = 0
BEGIN
	-- Add new record
	INSERT INTO sub.tblNewsItem_ApplicationPage
		(
			NewsItemID,
			PageID
		)
	VALUES
		(
			@NewsItemID,
			@PageID
		)

	-- Save new record.
	SELECT	@XMLdel = NULL,
			@XMLins = (	SELECT 	*
						FROM	sub.tblNewsItem_ApplicationPage
						WHERE	NewsItemID = @NewsItemID
						AND		PageID = @PageID
						FOR XML PATH )

END

-- Log action in his.tblHistory.
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @NewsItemID

	EXEC his.uspHistory_Add
			'sub.tblNewsItem_ApplicationPage',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SELECT NewsItemID = @NewsItemID

SET @Return = 0

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

RETURN @Return

/*	== sub.uspNewsItem_ApplicationPage_Add ======================================================	*/
