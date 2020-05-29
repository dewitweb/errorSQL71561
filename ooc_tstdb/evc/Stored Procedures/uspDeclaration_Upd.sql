CREATE PROCEDURE [evc].[uspDeclaration_Upd]
@DeclarationID		int,
@QualificationLevel	varchar(4), 
@MentorCode			varchar(4),
@CurrentUserID		int = 1
AS
/*	==========================================================================================
	Purpose: 	Update evc.tblDeclaration on basis of DeclarationID.

	02-11-2018	Jaap van Assenbergh	Inital version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Return		int = 1

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF (SELECT	COUNT(DeclarationID)
	FROM	evc.tblDeclaration
	WHERE	DeclarationID = @DeclarationID) = 0
BEGIN
	-- Add new record
	INSERT INTO evc.tblDeclaration
		(
			DeclarationID,
			QualificationLevel,
			MentorCode
		)
	VALUES
		(
			@DeclarationID,
			@QualificationLevel,
			@MentorCode	
		)

	-- Save new record.
	SELECT	@XMLdel = NULL,
			@XMLins = (	SELECT 	*
						FROM	evc.tblDeclaration
						WHERE	DeclarationID = @DeclarationID
						FOR XML PATH )

END
ELSE
BEGIN
	-- Save old record.
	SELECT	@XMLdel = (	SELECT 	*
						FROM	evc.tblDeclaration
						WHERE	DeclarationID = @DeclarationID
						FOR XML PATH )

	-- Update existing record.
	UPDATE	evc.tblDeclaration
	SET
			QualificationLevel		= @QualificationLevel,
			MentorCode				= @MentorCode
	WHERE	DeclarationID = @DeclarationID

	-- Save new record.
	SELECT	@XMLins = (	SELECT 	*
						FROM	evc.tblDeclaration
						WHERE	DeclarationID = @DeclarationID
						FOR XML PATH )
END

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

/*	== evc.uspDeclaration_Upd ================================================================	*/
