
CREATE PROCEDURE [stip].[uspDeclaration_Del]
@DeclarationID	int,
@CurrentUserID	int = 1
AS

/*	==========================================================================================
	Purpose: 	Delete from stip.tblDeclaration.

	01-05-2019	Jaap van Assenbergh		Initial version.
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
					FROM	stip.tblDeclaration
					WHERE	DeclarationID = @DeclarationID
					FOR XML PATH ),
		@XMLins = NULL

-- Delete record.
DELETE
FROM	stip.tblDeclaration
WHERE	DeclarationID = @DeclarationID

-- Log action in his.tblHistory.
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @DeclarationID

	EXEC his.uspHistory_Add
			'stip.tblDeclaration',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SET @Return = 0

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

usp_Exit:
RETURN @Return

/*	== stip.uspDeclaration_Del ===============================================================	*/
