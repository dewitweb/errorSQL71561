CREATE PROCEDURE [sub].[uspDeclaration_Extension_Upd]
@ExtensionID	int,
@DeclarationID	int,
@StartDate		date,
@EndDate		date,
@InstituteID	int,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose: 	Update sub.tblDeclaration_Extension on basis of ExtensionID.

	01-05-2019	Sander van Houten	OTIBSUB-1007	Inital version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Return		int = 1

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF ISNULL(@ExtensionID, 0) = 0
BEGIN
	-- Add new record
	INSERT INTO sub.tblDeclaration_Extension
		(
			DeclarationID,
			StartDate,
			EndDate,
			InstituteID
		)
	VALUES
		(
			@DeclarationID,
			@StartDate,
			@EndDate,
			@InstituteID
		)

	SET	@ExtensionID = SCOPE_IDENTITY()

	-- Save new record.
	SELECT	@XMLdel = NULL,
			@XMLins = (	SELECT 	*
						FROM	sub.tblDeclaration_Extension
						WHERE	ExtensionID = @ExtensionID
						FOR XML PATH )

END
ELSE
BEGIN
	-- Save old record.
	SELECT	@XMLdel = (	SELECT 	*
						FROM	sub.tblDeclaration_Extension
						WHERE	ExtensionID = @ExtensionID
						FOR XML PATH )

	-- Update existing record.
	UPDATE	sub.tblDeclaration_Extension
	SET
			DeclarationID	= @DeclarationID,
			StartDate		= @StartDate,
			EndDate			= @EndDate,
			InstituteID		= @InstituteID
	WHERE	ExtensionID = @ExtensionID

	-- Save new record.
	SELECT	@XMLins = (	SELECT 	*
						FROM	sub.tblDeclaration_Extension
						WHERE	ExtensionID = @ExtensionID
						FOR XML PATH )
END

-- Log action in his.tblHistory.
IF CAST(ISNULL(@XMLdel, '') AS varchar(MAX)) <> CAST(ISNULL(@XMLins, '') AS varchar(MAX))
BEGIN
	SET @KeyID = @ExtensionID

	EXEC his.uspHistory_Add
			'sub.tblDeclaration_Extension',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SELECT ExtensionID = @ExtensionID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Extension_Upd ======================================================	*/
