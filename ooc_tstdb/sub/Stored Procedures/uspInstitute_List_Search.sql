
CREATE PROCEDURE [sub].[uspInstitute_List_Search]
@SubsidySchemeID	int,
@EmployerNumber		varchar(6),
@SearchString		varchar(max)
AS
/*	==========================================================================================
	Purpose:	Get list of institutes per scheme with optional search parameter.

	23-09-2019	Jaap van Assenbergh		OTIBSUB-501
										Nieuw ingevoerd instituut direct kunnen kiezen bij volgende declaratie, 
										ook als deze nog niet in Etalage behandeld is
	30-06-2018	Jaap van Assenbergh		OTIBET-221 Instituut aanmaken dat niet in DS gekozen 
										kan worden
	02-11-2018	Sander van Houten		Added SubsidySchemeID parameter (OTIBSUB-402).
	25-07-2018	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

	SET	@SearchString	 = ISNULL(@SearchString, '')

	SELECT @SearchString = sub.usfCreateSearchString (@SearchString)

	DECLARE @SearchWord TABLE 
			(
				Word nvarchar(max) NOT NULL
			)

	DECLARE @Institute TABLE 
			(
				InstituteID int, 
				InstituteName nvarchar(max)
			)

	DECLARE @SelectFromDate	date

	INSERT INTO @SearchWord (Word)
    SELECT	s 
	FROM	sub.utfSplitString(@SearchString, ' ')

	/*	For OSR there is a year and a period of three months. For EVC there is no period. */ 
	SELECT	@SelectFromDate = StartDate	
	FROM	sub.viewApplicationSetting_SubsidyAmountPerEmployee
	WHERE	ReferenceDate <= Getdate()
	AND		SubsidySchemeID = @SubsidySchemeID

	IF @SelectFromDate IS NULL 
		SET @SelectFromDate = '1900-01-01'

	IF	(
			SELECT	ISNULL(ss.LinkedInstitutes, 0)
			FROM	sub.tblSubsidyScheme ss
			WHERE	ss.SubsidySchemeID = @SubsidySchemeID
		) = 1
	BEGIN
		INSERT INTO @Institute(InstituteID, InstituteName)
		SELECT	DISTINCT
				InstituteID,
				InstituteName
		FROM
				(
					SELECT	DISTINCT
							swo.Word,
							i.InstituteID,
							i.InstituteName + CASE WHEN ISNULL(i.[Location], '') = '' THEN '' ELSE ' (' +  i.[Location] + ')' END InstituteName
					FROM	sub.tblInstitute i
					INNER JOIN sub.tblSubsidyScheme_Institute ssi ON ssi.InstituteID = i.InstituteID AND SubsidySchemeID = @SubsidySchemeID
					CROSS JOIN @SearchWord swo
					WHERE
						(	i.Enddate IS NULL 
						OR	i.Enddate >= @SelectFromDate
						)
					AND	'T' = 
							CASE 
								WHEN		@SearchString = '' 
									THEN 'T'	
								WHEN		CHARINDEX(swo.Word, i.SearchName, 1) > 0 
									THEN 'T'
							END
				) Search
		GROUP BY	InstituteID,
					InstituteName
		HAVING COUNT(InstituteID) >= (SELECT COUNT(Word) FROM @SearchWord)
	END
	ELSE
	BEGIN
		INSERT INTO @Institute(InstituteID, InstituteName)
		SELECT	InstituteID,
				InstituteName
		FROM	
				(
					SELECT	DISTINCT
							swo.Word,
							i.InstituteID,
							i.InstituteName + CASE WHEN ISNULL(i.[Location], '') = '' THEN '' ELSE ' (' +  i.[Location] + ')' END InstituteName
					FROM	sub.tblInstitute i
					CROSS JOIN @SearchWord swo
					WHERE
						(	i.EndDate IS NULL 
						OR	i.EndDate >= @SelectFromDate
						)
					AND	'T' = 
							CASE 
								WHEN		@SearchString = '' 
									THEN 'T'	
								WHEN		CHARINDEX(swo.Word, i.SearchName, 1) > 0 
									THEN 'T'
							END
				) Search
		GROUP BY	InstituteID,
					InstituteName
		HAVING COUNT(InstituteID) >= (SELECT COUNT(Word) FROM @SearchWord)
		ORDER BY	InstituteName

		/* Regardless of the subsidyscheme, show all unknown institutes by employer. */ 

		INSERT INTO @Institute
		SELECT	DISTINCT 0, InstituteName
		FROM	sub.tblDeclaration_Unknown_Source dus
		INNER JOIN sub.tblDeclaration decl ON decl.DeclarationID = dus.DeclarationID
		CROSS JOIN @SearchWord swo
		WHERE decl.EmployerNumber = @EmployerNumber
		AND		dus.InstituteID IS NULL
		AND	'T' = 
			CASE 
				WHEN		@SearchString = '' 
					THEN 'T'	
				WHEN		CHARINDEX(swo.Word, sub.usfCreateSearchString (dus.InstituteName), 1) > 0 
					THEN 'T'
			END
	END

	SELECT	InstituteID, InstituteName
	FROM	@Institute
	WHERE	InstituteID NOT IN
			(
				SELECT	SettingValue 
				FROM	sub.viewApplicationSetting_InvisibleInstitute
			)
	ORDER BY InstituteName

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspInstitute_List_Search ==========================================================	*/
