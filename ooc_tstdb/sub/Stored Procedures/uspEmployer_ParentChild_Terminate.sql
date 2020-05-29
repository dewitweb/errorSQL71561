CREATE PROCEDURE [sub].[uspEmployer_ParentChild_Terminate]
@RecordID		int,
@EndDate		date,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose: 	Terminate a concern relation.

	30-09-2019	Sander van Houten		OTIBSUB-100		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

-- Save old record.
SELECT	@XMLdel = (	SELECT 	*
					FROM	sub.tblEmployer_ParentChild
					WHERE	RecordID = @RecordID
					FOR XML PATH )

-- Update existing record.
UPDATE	sub.tblEmployer_ParentChild
SET		EndDate	= @EndDate
WHERE	RecordID = @RecordID

-- Save new record.
SELECT	@XMLins = (	SELECT 	*
					FROM	sub.tblEmployer_ParentChild
					WHERE	RecordID = @RecordID
					FOR XML PATH )

-- Log action in his.tblHistory.
IF CAST(ISNULL(@XMLdel, '') AS varchar(MAX)) <> CAST(ISNULL(@XMLins, '') AS varchar(MAX))
BEGIN
	SET @KeyID = CAST(@RecordID AS varchar(18))

	EXEC his.uspHistory_Add
			'sub.tblEmployer_ParentChild',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployer_ParentChild_Terminate =================================================	*/
