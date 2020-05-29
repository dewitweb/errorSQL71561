CREATE PROCEDURE [sub].[uspEducation_List]
	@SearchString	varchar(max),
	@EligibleDate	date
AS
/*	==========================================================================================
	Purpose: 	Get list from sub.tblEducation.

	06-05-2019	Jaap van Assenbergh	Inital version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SET	@SearchString	 = ISNULL(@SearchString, '')

SELECT @SearchString = sub.usfCreateSearchString (@SearchString)

DECLARE @SearchWord TABLE (Word nvarchar(max) NOT NULL)

INSERT INTO @SearchWord (Word)
SELECT s FROM sub.utfSplitString(@SearchString, ' ')

SELECT
		EducationID,
		CASE	WHEN ISNUMERIC(@SearchString) = 1 
				THEN CAST(EducationID AS varchar(10)) + ' (' + EducationName + ')'
				ELSE EducationName + ' (' + CAST(EducationID AS varchar(10)) + ')'
		END EducationName,
		EducationType,
		EducationLevel,
		StartDate,
		LatestStartDate,
		EndDate,
		Duration,
		SearchName,
		IsEligible,
		DRank
FROM
		(
			SELECT
					ed.EducationID,
					ed.EducationName,
					ed.EducationType,
					ed.EducationLevel,
					ed.StartDate,
					ed.LatestStartDate,
					ed.EndDate,
					ed.Duration,
					ed.SearchName,
					CASE WHEN ISNULL(eie.EducationID, 0) = 0 THEN 0 ELSE 1 END IsEligible,
					DENSE_RANK() OVER(ORDER BY COUNT(ed.EducationID) DESC) DRank
			FROM	sub.tblEducation ed
			LEFT JOIN sub.tblEducation_IsEligible eie
					ON	eie.EducationID = ed.EducationID
					AND	eie.FromDate <= @EligibleDate
					AND (
							eie.UntilDate IS NULL
						OR
							eie.UntilDate > @EligibleDate
						)
			CROSS JOIN @SearchWord w
			WHERE	
					'T' = 
						CASE 
							WHEN		@SearchString = '' 
								THEN 'T'	
							WHEN		CHARINDEX(Word, CAST(ed.EducationID AS varchar(6)), 1) > 0 
								THEN	'T'
							WHEN		CHARINDEX(Word, ed.SearchName, 1) > 0 
								THEN	'T'
						END
			GROUP BY
					ed.EducationID,
					eie.EducationID,
					ed.EducationName,
					ed.EducationType,
					ed.EducationLevel,
					ed.StartDate,
					ed.LatestStartDate,
					ed.EndDate,
					ed.Duration,
					ed.SearchName
		) EducationRank
WHERE DRank <= 2
ORDER BY DRank, EducationName

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEducation_List =================================================================	*/
