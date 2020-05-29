
CREATE PROCEDURE ait.uspMaintenance_Del
@RecordID			int,
@CurrentUserID	int = 1
AS

/*	==========================================================================================
	Purpose: 	Delete from ait.tblMaintenance.

	06-05-2019	Sander van Houten	OTIBSUB-964		Inital version.
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
					FROM	ait.tblMaintenance
					WHERE	RecordID = @RecordID
					FOR XML PATH ),
		@XMLins = NULL

-- Delete record.
DELETE
FROM	ait.tblMaintenance
WHERE	RecordID = @RecordID

-- Log action in his.tblHistory.
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @RecordID

	EXEC his.uspHistory_Add
			'ait.tblMaintenance',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SET @Return = 0

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== ait.uspMaintenance_Del ================================================================	*/
