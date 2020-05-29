CREATE PROCEDURE [evcwv].[uspDeclaration_Upd]
@DeclarationID		int,
@MentorCode			varchar(4),
@ParticipantID		int,
@OutflowPossibility	varchar(4), 
@CurrentUserID		int = 1
AS
/*	==========================================================================================
	Purpose: 	Update evcwv.tblDeclaration on basis of DeclarationID.

	14-10-2019	Sander van Houten		OTIBSUB-1618	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Return		int = 1

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF (SELECT	COUNT(DeclarationID)
	FROM	evcwv.tblDeclaration
	WHERE	DeclarationID = @DeclarationID) = 0
BEGIN
	-- Add new record
	INSERT INTO evcwv.tblDeclaration
		(
			DeclarationID,
			MentorCode,
			ParticipantID,
			OutflowPossibility
		)
	VALUES
		(
			@DeclarationID,
			@MentorCode,
			@ParticipantID,
			@OutflowPossibility
		)

	-- Save new record.
	SELECT	@XMLdel = NULL,
			@XMLins = (	SELECT 	*
						FROM	evcwv.tblDeclaration
						WHERE	DeclarationID = @DeclarationID
						FOR XML PATH )

END
ELSE
BEGIN
	-- Save old record.
	SELECT	@XMLdel = (	SELECT 	*
						FROM	evcwv.tblDeclaration
						WHERE	DeclarationID = @DeclarationID
						FOR XML PATH )

	-- Update existing record.
	UPDATE	evcwv.tblDeclaration
	SET
			MentorCode				= @MentorCode,
			ParticipantID			= @ParticipantID,
			OutflowPossibility		= @OutflowPossibility
	WHERE	DeclarationID = @DeclarationID

	-- Save new record.
	SELECT	@XMLins = (	SELECT 	*
						FROM	evcwv.tblDeclaration
						WHERE	DeclarationID = @DeclarationID
						FOR XML PATH )
END

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

/*	== evcwv.uspDeclaration_Upd ==============================================================	*/
