
CREATE PROCEDURE [stip].[uspDeclaration_Upd]
@DeclarationID			int,
@EducationID			int,
@DiplomaDate			date,
@DiplomaCheckedByUserID	int,
@DiplomaCheckedDate		datetime,
@TerminationDate		datetime,
@TerminationReason		varchar(20),
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose: 	Update stip.tblDeclaration on basis of DeclarationID.

	01-05-2019	Jaap van Assenbergh	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Return		int = 1

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF (SELECT	COUNT(DeclarationID)
	FROM	stip.tblDeclaration
	WHERE	DeclarationID = @DeclarationID) = 0
BEGIN
	-- Add new record
	INSERT INTO stip.tblDeclaration
		(
			DeclarationID,
			EducationID,
			DiplomaDate,
			DiplomaCheckedByUserID,
			DiplomaCheckedDate,
			TerminationDate,
			TerminationReason
		)
	VALUES
		(
			@DeclarationID,
			@EducationID,
			@DiplomaDate,
			@DiplomaCheckedByUserID,
			@DiplomaCheckedDate,
			@TerminationDate,
			@TerminationReason
		)

	-- Save new record.
	SELECT	@XMLdel = NULL,
			@XMLins = (	SELECT 	*
						FROM	stip.tblDeclaration
						WHERE	DeclarationID = @DeclarationID
						FOR XML PATH )

END
ELSE
BEGIN
	-- Save old record.
	SELECT	@XMLdel = (	SELECT 	*
						FROM	stip.tblDeclaration
						WHERE	DeclarationID = @DeclarationID
						FOR XML PATH )

	-- Update existing record.
	UPDATE	stip.tblDeclaration
	SET
			EducationID				= @EducationID,
			DiplomaDate				= @DiplomaDate,
			DiplomaCheckedByUserID	= @DiplomaCheckedByUserID,
			DiplomaCheckedDate		= @DiplomaCheckedDate,
			TerminationDate			= @TerminationDate,
			TerminationReason		= @TerminationReason
	WHERE	DeclarationID = @DeclarationID

	-- Save new record.
	SELECT	@XMLins = (	SELECT 	*
						FROM	stip.tblDeclaration
						WHERE	DeclarationID = @DeclarationID
						FOR XML PATH )
END

-- Log action in his.tblHistory.
IF CAST(ISNULL(@XMLdel, '') AS varchar(MAX)) <> CAST(ISNULL(@XMLins, '') AS varchar(MAX))
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

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== stip.uspDeclaration_Upd ===============================================================	*/
