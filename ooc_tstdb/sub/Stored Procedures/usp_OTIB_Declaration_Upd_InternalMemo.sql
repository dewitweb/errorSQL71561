
CREATE PROCEDURE [sub].[usp_OTIB_Declaration_Upd_InternalMemo]
@DeclarationID	int,
@InternalMemo	varchar(max),
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose:	Update declaration (only the internal memo).

	31-08-2018	Sander van Houten		Initial version (on request by Maurice).
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

-- Save old record
SELECT	@XMLdel = (SELECT	* 
					FROM	sub.tblDeclaration 
					WHERE	DeclarationID = @DeclarationID 
					FOR XML PATH)

-- Update exisiting record
UPDATE	sub.tblDeclaration
SET
		InternalMemo = @InternalMemo
WHERE	DeclarationID = @DeclarationID

-- Save new record
SELECT	@XMLins = (SELECT	* 
					FROM	sub.tblDeclaration 
					WHERE	DeclarationID = @DeclarationID 
					FOR XML PATH)

-- Log action in tblHistory
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @DeclarationID

	EXEC his.uspHistory_Add
			'sub.tblDeclaration',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

RETURN 0

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Upd_InternalMemoOnly ===============================================	*/
