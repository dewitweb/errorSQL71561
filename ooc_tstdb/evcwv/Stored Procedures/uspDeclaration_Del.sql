
CREATE PROCEDURE [evcwv].[uspDeclaration_Del]
@DeclarationID	int,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose: 	Delete from evcwv.tblDeclaration.

	14-10-2019	Sander van Houten		OTIBSUB-1618	Initial version.
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
					FROM	evcwv.tblDeclaration
					WHERE	DeclarationID = @DeclarationID
					FOR XML PATH ),
		@XMLins = NULL

-- Delete record.
DELETE
FROM	evcwv.tblDeclaration
WHERE	DeclarationID = @DeclarationID

-- Log action in his.tblHistory.
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @DeclarationID

	EXEC his.uspHistory_Add
			'evcwv.tblDeclaration',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SET @Return = 0

RETURN @Return

/*	== evcwv.uspDeclaration_Del ==============================================================	*/
