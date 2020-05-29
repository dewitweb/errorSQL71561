
CREATE PROCEDURE [sub].[usp_OTIB_Employer_List]
@SearchString		varchar(max),
@SortBy				varchar(50)	= 'EmployerNumber',
@SortDescending		bit			= 0,
@PageNumber			int,
@RowspPage			int
AS
/*	==========================================================================================
	Purpose:	Get all employers with number of current employees and payment stops.

	Note:		Used on screen Werkgeversoverzicht.

	12-02-2019	Jaap van Assenbergh		OTIBSUB-570 Lots of reeds on tblEmployer_PaymentStop
	16-01-2019	Sander van Houten		Only count employees that have started there employment
										(OTIBSUB-672).
	08-10-2018	Jaap van Assenbergh		Paging (OTIBSUB-328)
	05-10-2018	Sander van Houten		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @GetDate date = GETDATE()

SELECT	@SearchString	= ISNULL(@SearchString, '')

/*	Prepaire SearchString													*/
SELECT	@SearchString = sub.usfCreateSearchString (@SearchString)

DECLARE @SearchWord TABLE (Word nvarchar(max) NOT NULL)
DECLARE @PaymentStop TABLE (EmployerNumnber nvarchar(6) NOT NULL, PaymentStop varchar(100))
	
INSERT INTO @SearchWord (Word)
SELECT s FROM sub.utfSplitString(@SearchString, ' ')

INSERT INTO @PaymentStop(EmployerNumnber, PaymentStop)
SELECT	EmployerNumber, PaymentStop
FROM	(
			SELECT	ROW_NUMBER () OVER (PARTITION BY EmployerNumber ORDER BY StartDate Desc) RowNr,
					eps.EmployerNumber, 'Vanaf ' + CONVERT(varchar(10), eps.StartDate, 105) + 
					CASE WHEN eps.EndDate IS NULL THEN '' ELSE ' tot ' + CONVERT(varchar(10), eps.EndDate, 105) END PaymentStop
			FROM	sub.tblEmployer_PaymentStop eps
			WHERE	eps.StartDate <= @GetDate 
			AND 	COALESCE(eps.EndDate, '20990101') > @GetDate 
		) ps
WHERE RowNr = 1

SELECT
		EmployerName,
		EmployerNumber,
		NrOfEmployees,
		PaymentStop
FROM
		(
			SELECT
					EmployerName,
					EmployerNumber,
					NrOfEmployees,
					PaymentStop,
					CASE WHEN @SortDescending = 0 THEN CAST(SortBy AS varchar(MAX)) ELSE NULL END	AS SortByAsc,
					CASE WHEN @SortDescending = 1 THEN CAST(SortBy AS varchar(MAX)) ELSE NULL END	AS SortByDesc
			FROM
					(
						SELECT	DISTINCT Word,
								EmployerName,
								EmployerNumber,
								NrOfEmployees,
								PaymentStop,
								SortBy
						FROM
								(
									SELECT
											emr.EmployerName,
											emr.SearchName,
											emr.EmployerNumber,
											(
												SELECT COUNT(1) FROM sub.tblEmployer_Employee eme
												WHERE		eme.EmployerNumber = emr.EmployerNumber
												AND		eme.StartDate <= @GetDate
												AND 	COALESCE(eme.EndDate, '20990101') > @GetDate
											) AS NrOfEmployees,
											ps.PaymentStop,
									CASE
											WHEN @SortBy = 'EmployerNumber'		THEN emr.EmployerNumber 
											WHEN @SortBy = 'EmployerName'		THEN emr.EmployerName 
									END	SortBy
									FROM	sub.tblEmployer emr
									LEFT JOIN sub.tblEmployer_Employee eme
										ON		eme.EmployerNumber = emr.EmployerNumber
										AND		eme.StartDate <= @GetDate
										AND 	COALESCE(eme.EndDate, '20990101') > @GetDate
									LEFT JOIN @PaymentStop ps ON ps.EmployerNumnber = emr.EmployerNumber
								) CountNrOfEmployees
						CROSS JOIN @SearchWord sw
						WHERE	
								(
											'T' = 	
												CASE
													WHEN		@SearchString = '' 
														THEN 'T'
													WHEN		CHARINDEX(sw.Word, SearchName, 1) > 0 
														THEN	'T'
												END

									OR		'T' = 	
												CASE
													WHEN		@SearchString = '' 
														THEN 'T'
													WHEN		CHARINDEX(sw.Word, EmployerNumber, 1) > 0 
														THEN	'T'
												END
								)
					) Search
					GROUP BY
								EmployerName,
								EmployerNumber,
								NrOfEmployees,
								PaymentStop,
								SortBy
					HAVING COUNT(EmployerNumber) >= (SELECT COUNT(Word) FROM @SearchWord)
		) OrderBy
		ORDER BY	ROW_NUMBER() OVER (ORDER BY SortByAsc ASC, SortByDesc DESC)
		OFFSET ((@PageNumber - 1) * @RowspPage) ROWS
		FETCH NEXT @RowspPage ROWS ONLY;

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.usp_OTIB_Employer_List ============================================================	*/