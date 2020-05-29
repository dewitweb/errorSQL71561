CREATE PROCEDURE [sub].[uspCourse_List_Institute]
	@InstituteID	int,
	@InstituteName	varchar(255),
	@EmployerNumber	varchar(6),
	@SearchString	varchar(max),
	@Startdate		date				-- JvA 21-11-2018 Waar we nog niets mee doen
AS
/*	==========================================================================================
	23-09-2019	Jaap van Assenbergh		OTIBSUB-501
										Nieuw ingevoerd instituut direct kunnen kiezen bij volgende declaratie, 
										ook als deze nog niet in Etalage behandeld is
	19-02-2019	Jaap van Assenbergh
				OTIBSUB-793 Uitbreiden output uspCourse_List_Institute met "subsidiabel"
	10-01-2019	Jaap van Assenbergh
				OTIBSUB-649 Zoeken naar opleiding is niet optimaal
	25-07-2018	Jaap van Assenbergh
				Ophalen lijst uit sub.tblCourse by InstituteID
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

	SET	@SearchString	 = ISNULL(@SearchString, '')

	SELECT @SearchString = sub.usfCreateSearchString (@SearchString)

	DECLARE @SearchWord TABLE 
			(
				Word nvarchar(max) NOT NULL
			)

	DECLARE @Course TABLE 
			(
				CourseID		int,
				CourseName		nvarchar(200),
				IsEligible	bit,
				DRank			int
			)


	INSERT INTO @SearchWord (Word)
    SELECT s FROM sub.utfSplitString(@SearchString, ' ')

	IF ISNULL(@InstituteID, 0) <> 0
	BEGIN
		INSERT INTO @Course(CourseID, CourseName, IsEligible, DRank)
		SELECT	
				CourseID,
				CourseName,
				IsEligible,
				DRank
		FROM	(
					SELECT	
							CourseID,
							CourseName, 
							IsEligible,
							DENSE_RANK() OVER(ORDER BY IsEligible, COUNT(CourseID) DESC) DRank
					FROM
							(
								SELECT
										c.CourseID,
										c.CourseName, 
										CASE WHEN cie.CourseID IS NULL THEN 0 ELSE 1 END IsEligible,
										w.Word
								FROM	sub.tblCourse c
								LEFT JOIN sub.tblCourse_IsEligible cie
										ON	cie.CourseID = c.CourseID
										AND	cie.FromDate <= @Startdate
										AND (
												cie.UntilDate IS NULL
											OR
												cie.UntilDate > @Startdate
											)
									CROSS JOIN @SearchWord w
								WHERE	InstituteID = @InstituteID
								AND		COALESCE(FollowedUpByCourseID, 0) = 0
								AND
									'T' = 
										CASE 
											WHEN		@SearchString = '' 
												THEN 'T'	
											WHEN		CHARINDEX(Word, SearchName, 1) > 0 
												THEN	'T'
										END
								AND	ClusterNumber NOT IN
									(
										SELECT	SettingValue 
										FROM	sub.viewApplicationSetting_InvisibleCluster
									)

							) Search
					GROUP BY	CourseID,
								CourseName,
								IsEligible
				) DR
		WHERE DRank <= 2
	END
	
	INSERT INTO @Course(CourseID, CourseName, IsEligible, DRank)
	SELECT	DISTINCT 0, CourseName, 1, 0
	FROM	sub.tblDeclaration_Unknown_Source dus
	INNER JOIN sub.tblDeclaration decl ON decl.DeclarationID = dus.DeclarationID
	CROSS JOIN @SearchWord swo
	WHERE decl.EmployerNumber = @EmployerNumber
	AND		dus.CourseID IS NULL
	AND		(	
				dus.InstituteID = @InstituteID
			OR
				dus.InstituteName = @InstituteName
			)
	AND	'T' = 
		CASE 
			WHEN		@SearchString = '' 
				THEN 'T'	
			WHEN		CHARINDEX(swo.Word, sub.usfCreateSearchString (dus.CourseName), 1) > 0 
				THEN 'T'
		END

	SELECT	CourseID,
			CourseName,
			IsEligible
	FROM	@Course
	ORDER BY DRank, CourseName

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspCourse_List_Institute ==========================================================	*/
