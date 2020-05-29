CREATE PROCEDURE [stip].[uspDeclaration_Unknown_Source_Upd]
@DeclarationID					int,
@InstituteID					int, 
@InstituteName					varchar(255),
@SentToSourceSystemDate			datetime,
@ReceivedFromSourceSystemDate	datetime,
@EducationID					int,
@NominalDuration				int,
@CurrentUserID					int = 1
AS
/*	==========================================================================================
	Purpose:	Update sub.tblDeclaration_Unknown_Source on the basis of DeclarationID.

	Notes:		24-05-2019 Jaap van Assenbergh
				DeclarationAcceptedDate is not part of the insert/update. Field is only used for 
				sending to Connect

	02-08-2019	Sander van Houten		Status of a declaration does not need to change.
	13-06-2019	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/
DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

DECLARE @SubsidySchemeID	int,
		@RowCount			int

SELECT	@SubsidySchemeID = SubsidySchemeID 
FROM	sub.tblDeclaration 
WHERE	DeclarationID = @DeclarationID

IF (SELECT	COUNT(DeclarationID)
	FROM	sub.tblDeclaration_Unknown_Source
	WHERE	DeclarationID = @DeclarationID) = 0
BEGIN
	-- Add new record
	INSERT INTO sub.tblDeclaration_Unknown_Source
		(
			DeclarationID,
			InstituteID,
			InstituteName,
			SentToSourceSystemDate,
			ReceivedFromSourceSystemDate,
			EducationID,
			NominalDuration
		)
	VALUES
		(
			@DeclarationID,
			@InstituteID,
			@InstituteName,
			@SentToSourceSystemDate,
			@ReceivedFromSourceSystemDate,
			@EducationID,
			@NominalDuration
		)

	-- Save new record
	SELECT	@XMLdel = NULL,
			@XMLins = (SELECT * 
					   FROM   sub.tblDeclaration_Unknown_Source 
					   WHERE  DeclarationID = @DeclarationID
					   FOR XML PATH)
END
ELSE
BEGIN
	-- Save old record
	SELECT	@XMLdel = (SELECT * 
					   FROM   sub.tblDeclaration_Unknown_Source 
					   WHERE  DeclarationID = @DeclarationID
					   FOR XML PATH)

	-- Update exisiting record
	UPDATE	sub.tblDeclaration_Unknown_Source
	SET
			InstituteID						= @InstituteID,
			InstituteName					= @InstituteName,
			SentToSourceSystemDate			= @SentToSourceSystemDate,
			ReceivedFromSourceSystemDate	= @ReceivedFromSourceSystemDate,
			/* EducationID can not be unknown. Only the combination of Institute and Education. */
			NominalDuration					= @NominalDuration
	WHERE	DeclarationID = @DeclarationID

	-- Save new record
	SELECT	@XMLins = (SELECT * 
					   FROM   sub.tblDeclaration_Unknown_Source 
					   WHERE  DeclarationID = @DeclarationID
					   FOR XML PATH)
END

-- Log action in tblHistory
IF CAST(ISNULL(@XMLdel, '') AS varchar(MAX)) <> CAST(ISNULL(@XMLins, '') AS varchar(MAX))
BEGIN
	SELECT	@KeyID = @DeclarationID,
			@RowCount = 0

	EXEC his.uspHistory_Add
			'sub.tblDeclaration_Unknown_Source',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== stip.uspDeclaration_Unknown_Source_Upd ================================================	*/
