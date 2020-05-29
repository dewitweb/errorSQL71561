
CREATE PROCEDURE [sub].[uspSubsidyScheme_Institute_Add_Del]
@SubsidySchemeID	int,
@InstituteID		int,
@Add				bit,
@CurrentUserID		int = 1
AS
/*	==========================================================================================
	Purpose: 	Add or delete sub.tblSubsidyScheme_Institute

	20-11-2018	Jaap van Assenbergh	Inital version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Return		int = 1

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF @Add = 1 
	AND 
		(
			SELECT	COUNT(1) 
			FROM	tblSubsidyScheme_Institute 
			WHERE	SubsidySchemeID = @SubsidySchemeID 
			AND		InstituteID = @InstituteID
		) = 0 
BEGIN
	-- Add new record
	INSERT INTO sub.tblSubsidyScheme_Institute
		(
			SubsidySchemeID,
			InstituteID
		)
	VALUES
		(
			@SubsidySchemeID,
			@InstituteID
		)

	-- Save new record.
	SELECT	@XMLdel = NULL,
			@XMLins = (	SELECT 	*
						FROM	sub.tblSubsidyScheme_Institute
						WHERE	SubsidySchemeID = @SubsidySchemeID
						AND		InstituteID = @InstituteID
						FOR XML PATH )
END
ELSE
BEGIN
	-- Save old record.
	SELECT	@XMLdel = (	SELECT 	*
						FROM	sub.tblSubsidyScheme_Institute
						WHERE	SubsidySchemeID = @SubsidySchemeID
						AND		InstituteID = @InstituteID
						FOR XML PATH )

	-- Update existing record.
	DELETE 
	FROM	sub.tblSubsidyScheme_Institute
	WHERE	SubsidySchemeID = @SubsidySchemeID
	AND		InstituteID		= @InstituteID

	-- Save new record.
	SELECT	@XMLins = (	SELECT 	*
						FROM	sub.tblSubsidyScheme_Institute
						WHERE	SubsidySchemeID = @SubsidySchemeID
						AND		InstituteID = @InstituteID
						FOR XML PATH )
END

-- Log action in his.tblHistory.
IF CAST(ISNULL(@XMLdel, '') AS varchar(MAX)) <> CAST(ISNULL(@XMLins, '') AS varchar(MAX))
BEGIN
	SET @KeyID = @SubsidySchemeID

	EXEC his.uspHistory_Add
			'sub.tblSubsidyScheme_Institute',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SET @Return = 0

RETURN @Return

/*	== sub.uspSubsidyScheme_Institute_Upd ====================================================	*/
