
CREATE PROCEDURE stip.uspEmail_Partition_Del
@EmailID			int,
@CurrentUserID	int = 1
AS

/*	==========================================================================================
	Purpose: 	Delete from stip.tblEmail_Partition.

	02-05-2019	Jaap van Assenbergh	Inital version.
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
					FROM	stip.tblEmail_Partition
					WHERE	EmailID = @EmailID
					FOR XML PATH ),
		@XMLins = NULL

-- Delete record.
DELETE
FROM	stip.tblEmail_Partition
WHERE	EmailID = @EmailID

-- Log action in his.tblHistory.
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @EmailID

	EXEC his.uspHistory_Add
			'stip.tblEmail_Partition',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SET @Return = 0

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== stip.uspEmail_Partition_Del ===========================================================	*/
