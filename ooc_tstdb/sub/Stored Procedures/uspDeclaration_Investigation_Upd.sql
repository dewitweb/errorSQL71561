
CREATE PROCEDURE [sub].[uspDeclaration_Investigation_Upd]
@DeclarationID		int,
@InvestigationDate	datetime,
@InvestigationMemo	varchar(MAX),
@CurrentUserID		int = 1
AS
/*	==========================================================================================
	Purpose:	Update sub.tblDeclaration_Investigation on the basis of DeclarationID.

	02-08-2018	Sander van Houten		CurrentUserID added.
	23-07-2018	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF (SELECT	COUNT(DeclarationID)
	FROM	sub.tblDeclaration_Investigation
	WHERE	DeclarationID = @DeclarationID) = 0
BEGIN
	-- Add new record
	INSERT INTO sub.tblDeclaration_Investigation
		(
			DeclarationID,
			InvestigationDate,
			InvestigationMemo
		)
	VALUES
		(
			@DeclarationID,
			@InvestigationDate,
			@InvestigationMemo
		)

	-- Save new DeclarationID
	SET	@DeclarationID = SCOPE_IDENTITY()

	-- Save new record
	SELECT	@XMLdel = NULL,
			@XMLins = (SELECT	* 
					   FROM		sub.tblDeclaration_Investigation 
					   WHERE	DeclarationID = @DeclarationID 
					   FOR XML PATH)
END
ELSE
BEGIN
	-- Save old record
	SELECT	@XMLdel = (SELECT	* 
					   FROM		sub.tblDeclaration_Investigation 
					   WHERE	DeclarationID = @DeclarationID 
					   FOR XML PATH)

	-- Update exisiting record
	UPDATE	sub.tblDeclaration_Investigation
	SET
			InvestigationDate	= @InvestigationDate,
			InvestigationMemo	= @InvestigationMemo
	WHERE	DeclarationID = @DeclarationID

	-- Save new record
	SELECT	@XMLins = (SELECT	* 
					   FROM		sub.tblDeclaration_Investigation 
					   WHERE	DeclarationID = @DeclarationID 
					   FOR XML PATH)
END

-- Log action in tblHistory
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @DeclarationID

	EXEC his.uspHistory_Add
			'sub.tblDeclaration_Investigation',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SELECT DeclarationID = @DeclarationID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Investigation_Upd ===================================================	*/
