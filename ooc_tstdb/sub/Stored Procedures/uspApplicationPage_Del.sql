


CREATE PROCEDURE [sub].[uspApplicationPage_Del]
@PageID			int,
@CurrentUserID	int = 1
AS

/*	==========================================================================================
	Purpose: 	Delete from sub.tblApplicationPage.

	21-02-2019	Jaap van Assenbergh	Inital version.
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
					FROM	sub.tblApplicationPage
					WHERE	PageID = @PageID
					FOR XML PATH ),
		@XMLins = NULL

-- Delete record.
DELETE
FROM	sub.tblApplicationPage
WHERE	PageID = @PageID

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

SET @Return = 0

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

RETURN @Return

/*	== sub.uspApplicationPage_Del ===========================================================	*/
