
CREATE PROCEDURE [sub].[uspDeclaration_Upd_DeclarationAmount]
@DeclarationID		int,
@DeclarationAmount	decimal(19,4),
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose:	Update declaration amount only

	Notes:		This procedure is used for STIP declarations.

	05-09-2019	Sander van Houten		OTIBSUB-1535	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

-- Save old record.
SELECT	@XMLdel = (SELECT * 
				   FROM   sub.tblDeclaration 
				   WHERE  DeclarationID = @DeclarationID
				   FOR XML PATH)

-- Update existing record.
UPDATE	sub.tblDeclaration
SET
		DeclarationAmount	= @DeclarationAmount
WHERE	DeclarationID		= @DeclarationID

-- Save new record
SELECT	@XMLins = (SELECT * 
				   FROM   sub.tblDeclaration 
				   WHERE  DeclarationID = @DeclarationID
				   FOR XML PATH)

-- Log action in tblHistory.
IF CAST(ISNULL(@XMLdel, '') AS varchar(MAX)) <> CAST(ISNULL(@XMLins, '') AS varchar(MAX))
BEGIN
	SET @KeyID = CAST(@DeclarationID AS varchar(18))

	EXEC his.uspHistory_Add
			'sub.tblDeclaration',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Upd_DeclarationAmount ==============================================	*/
