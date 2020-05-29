
CREATE PROCEDURE sub.uspNewsItem_SubsidyScheme_Del
@NewsItemID			int,
@SubsidySchemeID	int,
@CurrentUserID		int = 1
AS

/*	==========================================================================================
	Purpose: 	Delete from sub.tblNewsItem_SubsidyScheme.

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
					FROM	sub.tblNewsItem_SubsidyScheme
					WHERE	NewsItemID = @NewsItemID
					AND		SubsidySchemeID = @SubsidySchemeID
					FOR XML PATH ),
		@XMLins = NULL

-- Delete record.
DELETE
FROM	sub.tblNewsItem_SubsidyScheme
WHERE	NewsItemID = @NewsItemID
AND		SubsidySchemeID = @SubsidySchemeID

-- Log action in his.tblHistory.
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @NewsItemID

	EXEC his.uspHistory_Add
			'sub.tblNewsItem_SubsidyScheme',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SET @Return = 0

RETURN @Return

/*	== sub.uspNewsItem_SubsidyScheme_Del =====================================================	*/
