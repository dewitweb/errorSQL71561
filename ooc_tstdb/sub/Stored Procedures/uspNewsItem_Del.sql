
CREATE PROCEDURE [sub].[uspNewsItem_Del]
@NewsItemID			int,
@CurrentUserID	int = 1
AS

/*	==========================================================================================
	Purpose: 	Delete from sub.tblNewsItem.

	09-10-2018	Jaap van Assenbergh	Inital version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Return		int = 1

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

-- Save old record.
SELECT	@XMLdel = (	SELECT 	*
					FROM	sub.tblNewsItem
					WHERE	NewsItemID = @NewsItemID
					FOR XML PATH ),
		@XMLins = NULL

-- Delete record.
DELETE
FROM	sub.tblNewsItem_ApplicationPage
WHERE	NewsItemID = @NewsItemID

DELETE
FROM	sub.tblNewsItem_NewsItemPage
WHERE	NewsItemID = @NewsItemID

DELETE
FROM	sub.tblNewsItem_SubsidyScheme
WHERE	NewsItemID = @NewsItemID

DELETE
FROM	sub.tblNewsItem
WHERE	NewsItemID = @NewsItemID

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

SET @Return = 0

RETURN @Return

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspNewsItem_Del ===================================================================	*/
