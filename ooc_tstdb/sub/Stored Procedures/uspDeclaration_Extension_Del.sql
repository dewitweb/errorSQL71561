
CREATE PROCEDURE sub.uspDeclaration_Extension_Del
@ExtensionID			int,
@CurrentUserID	int = 1
AS

/*	==========================================================================================
	Purpose: 	Delete from sub.tblDeclaration_Extension.

	01-05-2019	Sander van Houten	OTIBSUB-1007	Inital version.
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
					FROM	sub.tblDeclaration_Extension
					WHERE	ExtensionID = @ExtensionID
					FOR XML PATH ),
		@XMLins = NULL

-- Delete record.
DELETE
FROM	sub.tblDeclaration_Extension
WHERE	ExtensionID = @ExtensionID

-- Log action in his.tblHistory.
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @ExtensionID

	EXEC his.uspHistory_Add
			'sub.tblDeclaration_Extension',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SET @Return = 0

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Extension_Del ======================================================	*/
