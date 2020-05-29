
CREATE PROCEDURE [sub].[uspNewsItem_NewsItemPage_Add]
@NewsItemID			int,
@PageCode			varchar(50),
@CurrentUserID		int = 1
AS
/*	==========================================================================================
	Purpose: 	Add sub.tblNewsItem_NewsItemPage on basis of NewsItemID and PageId.

	09-10-2018	Jaap van Assenbergh	Inital version.
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
FROM	sub.viewApplicationSetting_NewsItemPage
WHERE	PageCode = @PageCode

IF (SELECT	COUNT(1)
	FROM	sub.tblNewsItem_NewsItemPage
	WHERE	NewsItemID = @NewsItemID
	  AND	PageID = @PageID) = 0
BEGIN
	-- Add new record
	INSERT INTO sub.tblNewsItem_NewsItemPage
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
						FROM	sub.tblNewsItem_NewsItemPage
						WHERE	NewsItemID = @NewsItemID
						AND		PageID = @PageID
						FOR XML PATH )

END

-- Log action in his.tblHistory.
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @NewsItemID

	EXEC his.uspHistory_Add
			'sub.tblNewsItem_NewsItemPage',
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

/*	== sub.uspNewsItem_NewsItemPage_Add ======================================================	*/
