CREATE PROCEDURE [sub].[uspEmployee_List]
@EmployerNumber		varchar(6),
@SearchString		varchar(max),
@SubsidySchemeID	int,
@StartDate			date = NULL
AS
/*	==========================================================================================
	Purpose:	List all employees for the employer.

	Note:		This procedure is the standard version that can be used for dropdown lists 
				like the one on the "Declaratie indienen" screen.										

	25-09-2019	Sander van Houten		OTIBSUB-518		Added date checks for EVC.
	08-07-2019	Sander van Houten		OTIBSUB-1329	Search only from the begin of a name.
	20-05-2019	Jaap van Assenbergh		OTIBSUB-937		Zoeken op geboortedatum zonder streepjes in te typen.
	08-06-2019	Sander van Houten		OTIBSUB-1015	Added code for STIP (SubsidySchemeID=4).
	05-03-2019	Sander van Houten		OTIBSUB-820		Do not show employees who are no longer employed.
	31-01-2019	Sander van Houten		OTIBSUB-736/737	Added parameter @SubsidySchemeID 
											in order to only show the correct employees.
	04-12-2018	Sander van Houten		OTIBSUB-441		Added EmployeeName, DateOfBirth and SpousName.
	26-11-2018	Jaap van Assenbergh		OTIBSUB-499		Date of birth after the name of employees.
	20-09-2018	Sander van Houten		OTIBSUB-226		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Testdata.
DECLARE	@EmployerNumber		varchar(6) = '000007',
		@SearchString		varchar(max) = '',
		@SubsidySchemeID	int = 3,
		@StartDate			date = GETDATE()
--*/

DECLARE @Employee as table
		(
			EmployeeNumber varchar(8),
			EmployeeDisplayName varchar(133), 
			EmployeeName varchar(133),
			DateOfBirth varchar(20),
			SpousName varchar(MAX),
			Email varchar(254),
			IBAN varchar(34)
		)

SET	@SearchString = ISNULL(@SearchString, '')

SELECT @SearchString = sub.usfCreateSearchString (@SearchString)

DECLARE @CurrentDate date
DECLARE @DateOfBirth date
DECLARE @SearchWord TABLE (Word nvarchar(max) NOT NULL)

SELECT @CurrentDate = CAST(GETDATE() AS date)
SELECT @DateOfBirth = sub.usfCreateDateFromString(@SearchString)
	
IF @DateOfBirth IS NULL				-- Searchstring is not a date
BEGIN

	INSERT INTO @SearchWord (Word)
	SELECT s FROM sub.utfSplitString(@SearchString, ' ')

	INSERT INTO @Employee(EmployeeNumber, EmployeeDisplayName, EmployeeName, DateOfBirth, SpousName, Email, IBAN)
	SELECT
			sub.EmployeeNumber,
			RTRIM(sub.EmployeeName) 
			+ CASE WHEN DateOfBirth IS NOT NULL 
				THEN ' (' + CONVERT(varchar(10), sub.DateOfBirth, 105) + ')'
				ELSE ''
				END
			+ ' ' + sub.EmployeeNumber					AS EmployeeDisplayName,
			RTRIM(sub.EmployeeName)						AS EmployeeName,
			CONVERT(varchar(10), sub.DateOfBirth, 105)	AS DateOfBirth,
			sub.SpousName,
			sub.Email,
			sub.IBAN
	FROM
		(
			SELECT
					EmployeeNumber,
					EmployeeName,
					Email,
					IBAN,
					DateOfBirth,
					SpousName
			FROM
					(
						SELECT	DISTINCT Word,
								emp.EmployeeNumber,
								emp.FullName						AS EmployeeName,
								emp.Email,
								emp.IBAN,
								emp.DateOfBirth,
								emp.SurnameSpous
								+ CASE emp.AmidstSpous WHEN '' THEN '' ELSE ', ' END
								+ emp.AmidstSpous					AS SpousName
						FROM	sub.viewEmployer_Employee eme
						INNER JOIN sub.tblEmployee emp ON emp.EmployeeNumber = eme.EmployeeNumber
						LEFT JOIN sub.tblEmployer_Subsidy esu ON esu.EmployerNumber = eme.EmployerNumber
																AND esu.SubsidySchemeID = @SubsidySchemeID
																AND esu.SubsidyYear = COALESCE(YEAR(eme.EndDate), YEAR(GETDATE()))
						CROSS JOIN @SearchWord
						WHERE	eme.EmployerNumber = @EmployerNumber
							AND	'T' = CASE 
										WHEN @SearchString = '' 
											THEN 'T'	
										WHEN CHARINDEX(Word, emp.SearchName, 1) = 1
											THEN 'T'
										END
							AND	(( 
									 @SubsidySchemeID = 1	--OSR; Show employee until latest EndDeclarationPeriod date.
								AND	 COALESCE(esu.EndDeclarationPeriod, '20990101') >= CAST(GETDATE() AS date)
								AND	 eme.StartDate <= @StartDate
								AND	 COALESCE(eme.EndDate, @StartDate) >= @StartDate
									)
								OR
									( 
									 @SubsidySchemeID IN (3, 5)	--EVC;	Show employee until 1 year after enddate employment.
								AND	 COALESCE(eme.EndDate, '20990101') > CAST(DATEADD(YEAR, -1, GETDATE()) AS date)
								AND	 eme.StartDate <= @StartDate
								AND	 COALESCE(eme.EndDate, @StartDate) >= @StartDate
									)
								OR   @SubsidySchemeID = 4
								)
					) Search
			GROUP BY	EmployeeNumber,
						EmployeeName,
						Email,
						IBAN,
						DateOfBirth,
						SpousName
			HAVING COUNT(EmployeeNumber) >= (SELECT COUNT(Word) FROM @SearchWord)
		) AS sub
	GROUP BY	sub.EmployeeNumber,
				sub.EmployeeName,
				sub.Email,
				sub.IBAN,
				sub.DateOfBirth,
				sub.SpousName
END
ELSE
BEGIN
	INSERT INTO @Employee(EmployeeNumber, EmployeeDisplayName, EmployeeName, DateOfBirth, SpousName, Email, IBAN)
	SELECT
			sub.EmployeeNumber,
			RTRIM(sub.EmployeeName) 
			+ CASE WHEN DateOfBirth IS NOT NULL 
				THEN ' (' + CONVERT(varchar(10), sub.DateOfBirth, 105) + ')'
				ELSE ''
				END
			+ ' ' + sub.EmployeeNumber					AS EmployeeDisplayName,
			RTRIM(sub.EmployeeName)						AS EmployeeName,
			CONVERT(varchar(10), sub.DateOfBirth, 105)	AS DateOfBirth,
			sub.SpousName,
			sub.Email,
			sub.IBAN
	FROM
		(
			SELECT
					EmployeeNumber,
					EmployeeName,
					Email,
					IBAN,
					DateOfBirth,
					SpousName
			FROM
					(
						SELECT	emp.EmployeeNumber,
								emp.FullName						AS EmployeeName,
								emp.Email,
								emp.IBAN,
								emp.DateOfBirth,
								emp.SurnameSpous
								+ CASE emp.AmidstSpous WHEN '' THEN '' ELSE ', ' END
								+ emp.AmidstSpous					AS SpousName
						FROM	sub.viewEmployer_Employee eme
						INNER JOIN sub.tblEmployee emp ON emp.EmployeeNumber = eme.EmployeeNumber
						LEFT JOIN sub.tblEmployer_Subsidy esu ON esu.EmployerNumber = eme.EmployerNumber
																AND esu.SubsidySchemeID = @SubsidySchemeID
																AND esu.SubsidyYear = COALESCE(YEAR(eme.EndDate), YEAR(GETDATE()))
						WHERE	eme.EmployerNumber = @EmployerNumber
							AND	emp.DateOfBirth = @DateOfBirth

					) Search
			GROUP BY	EmployeeNumber,
						EmployeeName,
						Email,
						IBAN,
						DateOfBirth,
						SpousName
			HAVING COUNT(EmployeeNumber) >= (SELECT COUNT(Word) FROM @SearchWord)
		) AS sub
	GROUP BY	sub.EmployeeNumber,
				sub.EmployeeName,
				sub.Email,
				sub.IBAN,
				sub.DateOfBirth,
				sub.SpousName
END

SELECT	EmployeeNumber, 
		EmployeeDisplayName, 
		EmployeeName, 
		DateOfBirth, 
		Email, 
		IBAN
FROM	@Employee
ORDER BY EmployeeName

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployee_List ==================================================================	*/
