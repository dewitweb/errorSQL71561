
CREATE PROCEDURE [sub].[uspNewsItem_ApplicationPage_Del]
@NewsItemID			int,
@PageCode			varchar(50),
@CurrentUserID		int = 1
AS

/*	==========================================================================================
	Purpose: 	Delete from sub.tblNewsItem_NewsItemPage.

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

-- Save old record.
SELECT	@XMLdel = (	SELECT 	*
					FROM	sub.tblNewsItem_ApplicationPage
					WHERE	NewsItemID = @NewsItemID
					AND		PageID = @PageID
					FOR XML PATH ),
		@XMLins = NULL

-- Delete record.
DELETE
FROM	sub.tblNewsItem_ApplicationPage
WHERE	NewsItemID = @NewsItemID
AND		PageID = @PageID

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

SET @Return = 0

RETURN @Return

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspNewsItem_ApplicationPage_Del ===================================================	*/
