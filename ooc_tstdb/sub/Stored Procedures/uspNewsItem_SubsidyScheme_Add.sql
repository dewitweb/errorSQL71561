
CREATE PROCEDURE [sub].[uspNewsItem_SubsidyScheme_Add]
@NewsItemID			int,
@SubsidySchemeID	int,
@CurrentUserID		int = 1
AS
/*	==========================================================================================
	Purpose: 	Update sub.tblNewsItem_SubsidyScheme on basis of NewsItemID and SubsidySchemeID.

	09-10-2018	Jaap van Assenbergh	Inital version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Return		int = 1

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF (SELECT	COUNT(1)
	FROM	sub.tblNewsItem_SubsidyScheme
	WHERE	NewsItemID = @NewsItemID
	  AND	SubsidySchemeID = @SubsidySchemeID) = 0
BEGIN
	-- Add new record
	INSERT INTO sub.tblNewsItem_SubsidyScheme
		(
			NewsItemID,
			SubsidySchemeID
		)
	VALUES
		(
			@NewsItemID,
			@SubsidySchemeID
		)

	-- Save new record.
	SELECT	@XMLdel = NULL,
			@XMLins = (	SELECT 	*
						FROM	sub.tblNewsItem_SubsidyScheme
						WHERE	NewsItemID = @NewsItemID
						AND		SubsidySchemeID = @SubsidySchemeID
						FOR XML PATH )

END

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

SELECT NewsItemID = @NewsItemID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SET @Return = 0

RETURN @Return

/*	== sub.uspNewsItem_SubsidyScheme_Add =====================================================	*/
