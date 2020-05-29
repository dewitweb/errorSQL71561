CREATE PROCEDURE [osr].[uspDeclaration_Unknown_Source_Upd]
@DeclarationID					int,
@InstituteID					int, 
@InstituteName					varchar(255),
@CourseID						int, 
@CourseName						varchar(200),
@SentToSourceSystemDate			datetime,
@ReceivedFromSourceSystemDate	datetime,
@CurrentUserID					int = 1
AS
/*	==========================================================================================
	Purpose:	Update sub.tblDeclaration_Unknown_Source on the basis of DeclarationID.

	11-11-2019	Sander van Houten	OTIBSUB-1539	Removed updates of DeclarationStatus 
                                        and PartitionStatus.
	01-07-2019	Sander van Houten	OTIBSUB-1299	Added PartitionStatus update.
	20-11-2018	Jaap van Assenbergh	OSR Specifiek
	03-08-2018	Sander van Houten	CurrentUserID added.
	20-07-2018	Jaap van Assenbergh	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

SET @KeyID = @DeclarationID

DECLARE @SubsidySchemeID		int = 1,
		@DeclarationStatusNew	varchar(20)

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
			CourseID,
			CourseName,
			SentToSourceSystemDate,
			ReceivedFromSourceSystemDate
		)
	VALUES
		(
			@DeclarationID,
			@InstituteID,
			@InstituteName,
			@CourseID,
			@CourseName,
			@SentToSourceSystemDate,
			@ReceivedFromSourceSystemDate
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

	-- Update existing record
	UPDATE	sub.tblDeclaration_Unknown_Source
	SET 	InstituteID						= @InstituteID,
			InstituteName					= @InstituteName,
			CourseID						= @CourseID,
			CourseName						= @CourseName,
			SentToSourceSystemDate			= @SentToSourceSystemDate,
			ReceivedFromSourceSystemDate	= @ReceivedFromSourceSystemDate
	WHERE	DeclarationID = @DeclarationID

	-- Save new record
	SELECT	@XMLins = (SELECT * 
					   FROM   sub.tblDeclaration_Unknown_Source 
					   WHERE  DeclarationID = @DeclarationID
					   FOR XML PATH)
END

-- Log action in tblHistory
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @DeclarationID

	EXEC his.uspHistory_Add
            'sub.tblDeclaration_Unknown_Source',
            @KeyID,
            @CurrentUserID,
            @LogDate,
            @XMLdel,
            @XMLins

	-- Update record in tblDeclaration if CourseID is filled
	IF ISNULL(@CourseID, 0) <> 0
	BEGIN
		-- Save old record
		SELECT	@XMLdel = ( SELECT	* 
							FROM	sub.tblDeclaration 
							WHERE	DeclarationID = @DeclarationID
							FOR XML PATH)

		-- Update exisiting record.
		IF @ReceivedFromSourceSystemDate IS NOT NULL
		BEGIN	--Option 1.
			UPDATE	sub.tblDeclaration
			SET		InstituteID = @InstituteID
			WHERE	DeclarationID = @DeclarationID

            -- Save new record
            SELECT	@XMLins = ( SELECT	* 
                                FROM	sub.tblDeclaration 
                                WHERE	DeclarationID = @DeclarationID
                                FOR XML PATH)
        END

		-- Log action in tblHistory
		IF CAST(ISNULL(@XMLdel, '') AS varchar(MAX)) <> CAST(ISNULL(@XMLins, '') AS varchar(MAX))
		BEGIN
			EXEC his.uspHistory_Add
					'sub.tblDeclaration',
					@KeyID,
					@CurrentUserID,
					@LogDate,
					@XMLdel,
					@XMLins
		END

		-- Save old record
		SELECT	@XMLdel = ( SELECT	* 
							FROM	osr.tblDeclaration 
							WHERE	DeclarationID = @DeclarationID
							FOR XML PATH)

		-- Update existing record
		UPDATE	osr.tblDeclaration
		SET 	CourseID = @CourseID
		WHERE	DeclarationID = @DeclarationID

		-- Save new record
		SELECT	@XMLins = ( SELECT	* 
							FROM	osr.tblDeclaration 
							WHERE	DeclarationID = @DeclarationID
							FOR XML PATH)

		-- Log action in tblHistory
		IF CAST(ISNULL(@XMLdel, '') AS varchar(MAX)) <> CAST(ISNULL(@XMLins, '') AS varchar(MAX))
		BEGIN
			EXEC his.uspHistory_Add
					'osr.tblDeclaration',
					@KeyID,
					@CurrentUserID,
					@LogDate,
					@XMLdel,
					@XMLins
		END
	END
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== osr.uspDeclaration_Unknown_Source_Upd ==================================================	*/
