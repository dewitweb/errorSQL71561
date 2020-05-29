
CREATE PROCEDURE evc.uspDeclaration_Del
@DeclarationID			int,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose: 	Delete from evc.tblDeclaration.

	05-11-2018	Jaap van Assenbergh	Inital version.
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
					FROM	evc.tblDeclaration
					WHERE	DeclarationID = @DeclarationID
					FOR XML PATH ),
		@XMLins = NULL

-- Delete record.
DELETE
FROM	evc.tblDeclaration
WHERE	DeclarationID = @DeclarationID

-- Log action in his.tblHistory.
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @DeclarationID

	EXEC his.uspHistory_Add
			'evc.tblDeclaration',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SET @Return = 0

RETURN @Return

/*	== evc.uspDeclaration_Del ================================================================	*/
