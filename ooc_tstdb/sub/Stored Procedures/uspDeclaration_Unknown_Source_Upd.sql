
CREATE PROCEDURE [sub].[uspDeclaration_Unknown_Source_Upd]
@DeclarationID					int,
@InstituteID					int, 
@InstituteName					varchar(255),
@CourseID						int, 
@CourseName						varchar(200),
@SentToSourceSystemDate			datetime,
@ReceivedFromSourceSystemDate	datetime,
@NominalDuration				int,
@CurrentUserID					int = 1
AS
/*	==========================================================================================
	Purpose:	Update sub.tblDeclaration_Unknown_Source on the basis of DeclarationID.
	Note	24-05-2019 Jaap van Assenbergh
			DeclarationAcceptedDate is not part of the insert/update. Field is only used for 
			sending to Connect

	08-11-2019	Sander van Houten	OTIBSUB-1539	Removed update of DeclarationStatus
                                        and of partitions.
	13-06-2019	Jaap van Assenbergh	OTIBSUB-1179	NominalDuration toegevoegd
	17-05-2019	Sander van Houten	OTIBSUB-1092	Update partitionstatus.
	06-03-2019	Sander van Houten	OTIBSUB-821		Do not change DeclarationStatus 
														if DeclarationStatus >= 0004.
	14-02-2019	Sander van Houten	Permanent fix for OTIBSUB-673.
	16-01-2019	Sander van Houten	Temporary fix for OTIBSUB-673.
	03-08-2018	Sander van Houten	CurrentUserID added.
	20-07-2018	Jaap van Assenbergh	Initial version.
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
			CourseID,
			CourseName,
			SentToSourceSystemDate,
			ReceivedFromSourceSystemDate,
			NominalDuration
		)
	VALUES
		(
			@DeclarationID,
			@InstituteID,
			@InstituteName,
			@CourseID,
			@CourseName,
			@SentToSourceSystemDate,
			@ReceivedFromSourceSystemDate,
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
			CourseID						= @CourseID,
			CourseName						= @CourseName,
			SentToSourceSystemDate			= CASE	WHEN SentToSourceSystemDate IS NULL 
													THEN @SentToSourceSystemDate 
													ELSE SentToSourceSystemDate 
													END,
			ReceivedFromSourceSystemDate	= @ReceivedFromSourceSystemDate,
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

	-- Update InstituteID in tblDeclaration.
    IF @ReceivedFromSourceSystemDate IS NOT NULL
    BEGIN
        -- Save old record
        SELECT	@XMLdel = (SELECT	* 
                            FROM	sub.tblDeclaration 
                            WHERE	DeclarationID = @DeclarationID
                            AND	StartDate <= CAST(GETDATE() AS date)
                            FOR XML PATH)

        -- Update existing record.
        UPDATE	sub.tblDeclaration
        SET	    InstituteID	= @InstituteID
        WHERE	DeclarationID = @DeclarationID
        AND	StartDate <= CAST(GETDATE() AS date)


        -- Log action in tblHistory
        IF CAST(ISNULL(@XMLdel, '') AS varchar(MAX)) <> CAST(ISNULL(@XMLins, '') AS varchar(MAX))
        BEGIN
            -- Save new record
            SELECT	@XMLins = (SELECT	* 
                                FROM	sub.tblDeclaration 
                                WHERE	DeclarationID = @DeclarationID
                                FOR XML PATH)

            EXEC his.uspHistory_Add
                    'sub.tblDeclaration',
                    @KeyID,
                    @CurrentUserID,
                    @LogDate,
                    @XMLdel,
                    @XMLins
        END
    END

	-- Update record in tblDeclaration if CourseID is filled and OSR.
	IF ISNULL(@CourseID, 0) <> 0 AND @SubsidySchemeID = 1 -- OSR
	BEGIN
        -- Save old record
        SELECT	@XMLdel = (SELECT	* 
                            FROM	osr.tblDeclaration 
                            WHERE	DeclarationID = @DeclarationID
                            FOR XML PATH)

        -- Update exisiting record
        UPDATE	osr.tblDeclaration
        SET	    CourseID = @CourseID
        WHERE	DeclarationID = @DeclarationID

        -- Save new record
        SELECT	@XMLins = (SELECT	* 
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

/*	== sub.uspDeclaration_Unknown_Source_Upd ==================================================	*/
