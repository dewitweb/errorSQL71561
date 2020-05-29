
CREATE PROCEDURE [stip].[uspDeclaration_Mentor_Upd]
@DeclarationID	int,
@MentorID		int,
@StartDate		date,
@EndDate		date,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose: 	Update stip.tblDeclaration_Mentor on basis of DeclarationID.

	02-05-2019	Jaap van Assenbergh	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Return		int = 1

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF (SELECT	COUNT(DeclarationID)
	FROM	stip.tblDeclaration_Mentor
	WHERE	DeclarationID = @DeclarationID) = 0
BEGIN
	-- Add new record
	INSERT INTO stip.tblDeclaration_Mentor
		(
			DeclarationID,
			MentorID,
			StartDate,
			EndDate
		)
	VALUES
		(
			@DeclarationID,
			@MentorID,
			@StartDate,
			@EndDate
		)

	SET	@DeclarationID = SCOPE_IDENTITY()

	-- Save new record.
	SELECT	@XMLdel = NULL,
			@XMLins = (	SELECT 	*
						FROM	stip.tblDeclaration_Mentor
						WHERE	DeclarationID = @DeclarationID
						FOR XML PATH )

END
ELSE
BEGIN
	-- Save old record.
	SELECT	@XMLdel = (	SELECT 	*
						FROM	stip.tblDeclaration_Mentor
						WHERE	DeclarationID = @DeclarationID
						FOR XML PATH )

	-- Update existing record.
	UPDATE	stip.tblDeclaration_Mentor
	SET
			MentorID		= @MentorID,
			StartDate		= @StartDate,
			EndDate			= @EndDate
	WHERE	DeclarationID = @DeclarationID

	-- Save new record.
	SELECT	@XMLins = (	SELECT 	*
						FROM	stip.tblDeclaration_Mentor
						WHERE	DeclarationID = @DeclarationID
						FOR XML PATH )
END

-- Log action in his.tblHistory.
IF CAST(ISNULL(@XMLdel, '') AS varchar(MAX)) <> CAST(ISNULL(@XMLins, '') AS varchar(MAX))
BEGIN
	SET @KeyID = @DeclarationID

	EXEC his.uspHistory_Add
			'stip.tblDeclaration_Mentor',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SELECT DeclarationID = @DeclarationID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== stip.uspDeclaration_Mentor_Upd ========================================================	*/
