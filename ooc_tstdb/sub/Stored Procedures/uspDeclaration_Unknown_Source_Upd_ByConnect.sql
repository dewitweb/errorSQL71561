

CREATE PROCEDURE [sub].[uspDeclaration_Unknown_Source_Upd_ByConnect]
@DeclarationID					int,
@InstituteID					int, 
@CourseID						int, 
@NominalDuration				int,
@SentToSourceSystemDate			datetime,
@ReceivedFromSourceSystemDate	datetime,
@CurrentUserID					int = 1
AS
/*	==========================================================================================
	Purpose:	Update sub.tblDeclaration_Unknown_Source on the basis of DeclarationID.

	08-11-2019	Sander van Houten	OTIBSUB-1539	Removed update of DeclarationStatus.
	24-05-2019	Jaap van Assenbergh	OTIBSUB-1078    Routing tussen DS en Etalage wijzigen.
	17-05-2019	Sander van Houten	OTIBSUB-1092	Update partitionstatus.
	10-05-2019	Sander van Houten	OTIBSUB-1068	Initial version.
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

-- Save old record
SELECT	@XMLdel = (SELECT * 
					FROM   sub.tblDeclaration_Unknown_Source 
					WHERE  DeclarationID = @DeclarationID
					FOR XML PATH)

-- Update existing record
UPDATE	sub.tblDeclaration_Unknown_Source
SET	    InstituteID						= @InstituteID,
		CourseID						= @CourseID,
		SentToSourceSystemDate			= CASE WHEN SentToSourceSystemDate IS NULL 
											THEN @SentToSourceSystemDate 
											ELSE SentToSourceSystemDate 
										  END,
		ReceivedFromSourceSystemDate	= @ReceivedFromSourceSystemDate,
		NominalDuration					= @NominalDuration
WHERE	DeclarationID = @DeclarationID

-- Save new record
SELECT	@XMLins = (SELECT   * 
					FROM    sub.tblDeclaration_Unknown_Source 
					WHERE   DeclarationID = @DeclarationID
					FOR XML PATH)

-- Log action in tblHistory
IF CAST(ISNULL(@XMLdel, '') AS varchar(MAX)) <> CAST(ISNULL(@XMLins, '') AS varchar(MAX))
BEGIN
	SELECT	@KeyID = CAST(@DeclarationID AS varchar(18)),
			@RowCount = 0

	EXEC his.uspHistory_Add
			'sub.tblDeclaration_Unknown_Source',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins

	IF ISNULL(@CourseID, 0) <> 0
	BEGIN
        SELECT  @XMLdel = NULL,
                @XMLins = NULL

	    -- Update record in tblDeclaration if CourseID is filled
		IF @SubsidySchemeID = 1 -- OSR
		BEGIN
			-- Save old record
			SELECT	@XMLdel = (SELECT	* 
								FROM	osr.tblDeclaration 
								WHERE	DeclarationID = @DeclarationID
								FOR XML PATH)

			-- Update existing record
			UPDATE	osr.tblDeclaration
			SET	    CourseID = @CourseID
			WHERE	DeclarationID = @DeclarationID

			-- Save new record
			SELECT	@XMLins = (SELECT	* 
								FROM	osr.tblDeclaration 
								WHERE	DeclarationID = @DeclarationID
								FOR XML PATH)
		END

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

		IF	(
				SELECT	ISNULL(InstituteID, 0)
				FROM	sub.tblDeclaration 
				WHERE	DeclarationID = @DeclarationID
			)  <> ISNULL(@InstituteID, 0)
		BEGIN
			-- Save old record
			SELECT	@XMLdel = (SELECT	* 
								FROM	sub.tblDeclaration 
								WHERE	DeclarationID = @DeclarationID
								FOR XML PATH)

			-- Update existing record
			UPDATE	sub.tblDeclaration
			SET		InstituteID = @InstituteID
			WHERE	DeclarationID = @DeclarationID

			-- Save new record
			SELECT	@XMLins = (SELECT	* 
								FROM	sub.tblDeclaration 
								WHERE	DeclarationID = @DeclarationID
								FOR XML PATH)

			-- Log action in tblHistory
            EXEC his.uspHistory_Add
                    'sub.tblDeclaration',
                    @KeyID,
                    @CurrentUserID,
                    @LogDate,
                    @XMLdel,
                    @XMLins
		END
	END
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Unknown_Source_Upd_ByConnect =======================================	*/
