
CREATE PROCEDURE [osr].[uspDeclaration_Upd]
@DeclarationID			int,
@CourseID				int,
@Location				varchar(100),
@ElearningSubscription	bit,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose: 	Update osr.tblDeclaration on basis of DeclarationID.

	01-11-2018	Jaap van Assenbergh	Inital version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Return		int = 1

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF (SELECT	COUNT(DeclarationID)
	FROM	osr.tblDeclaration
	WHERE	DeclarationID = @DeclarationID) = 0
BEGIN
	-- Add new record
	INSERT INTO osr.tblDeclaration
		(
			DeclarationID,
			CourseID,
			[Location],
			ElearningSubscription
		)
	VALUES
		(
			@DeclarationID,
			@CourseID,
			@Location,
			@ElearningSubscription
		)

	-- Save new record.
	SELECT	@XMLdel = NULL,
			@XMLins = (	SELECT 	*
						FROM	osr.tblDeclaration
						WHERE	DeclarationID = @DeclarationID
						FOR XML PATH )

END
ELSE
BEGIN
	-- Save old record.
	SELECT	@XMLdel = (	SELECT 	*
						FROM	osr.tblDeclaration
						WHERE	DeclarationID = @DeclarationID
						FOR XML PATH )

	-- Update existing record.
	UPDATE	osr.tblDeclaration
	SET
			CourseID				= @CourseID,
			[Location]				= @Location,
			ElearningSubscription	= @ElearningSubscription
	WHERE	DeclarationID = @DeclarationID

	-- Save new record.
	SELECT	@XMLins = (	SELECT 	*
						FROM	osr.tblDeclaration
						WHERE	DeclarationID = @DeclarationID
						FOR XML PATH )
END

-- Log action in his.tblHistory.
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @DeclarationID

	EXEC his.uspHistory_Add
			'osr.tblDeclaration',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SET @Return = 0

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

RETURN @Return

/*	== osr.uspDeclaration_Upd ================================================================	*/
