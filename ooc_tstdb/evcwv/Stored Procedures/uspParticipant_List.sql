
CREATE PROCEDURE [evcwv].[uspParticipant_List]
@EmployerNumber varchar(6),
@SearchString	varchar(max),
@StartDate		date = NULL
AS
/*	==========================================================================================
	Purpose: 	Get list from sub.tblParticipant.

	15-10-2019	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @GetDate Date = GETDATE()

SET	@SearchString	 = ISNULL(@SearchString, '')

SELECT @SearchString = sub.usfCreateSearchString (@SearchString)

DECLARE @SearchWord TABLE (Word nvarchar(max) NOT NULL)

INSERT INTO @SearchWord (Word)
SELECT s FROM sub.utfSplitString(@SearchString, ' ')

SELECT 
		final.ParticipantID,
		final.EmployeeNumber,
		final.CRMID,
		final.Initials,
		final.Amidst,
		final.Surname,
		final.Gender,
		final.Phone,
		final.Email,
		final.DateOfBirth,
		final.SearchName,
		final.FullName,
		final.StartDate,
		final.EndDate
FROM 
		(
			SELECT
					Participant.ParticipantID,
					Participant.EmployeeNumber,
					Participant.CRMID,
					Participant.Initials,
					Participant.Amidst,
					Participant.Surname,
					Participant.Gender,
					Participant.Phone,
					Participant.Email,
					Participant.DateOfBirth,
					Participant.SearchName,
					Participant.FullName,
					Participant.StartDate,
					Participant.EndDate,
					ROW_NUMBER() OVER
						(
							PARTITION BY Participant.EmployeeNumber 
							ORDER BY CASE WHEN @GetDate BETWEEN ISNULL(Participant.StartDate, @Getdate) 
															AND ISNULL(Participant.EndDate, @Getdate)
											THEN 0 
											ELSE 1
										END,
										Participant.StartDate desc
						) RowNumber
			FROM
				(
					SELECT
							par.ParticipantID,
							eme.EmployeeNumber,
							par.CRMID,
							eme.Initials,
							eme.Amidst,
							eme.Surname,
							eme.Gender,
							par.Phone,
							par.Email,
							eme.DateOfBirth,
							eme.SearchName,
							CASE	WHEN eme.EmployeeNumber IS NULL 
									THEN eme.Surname 
									ELSE eme.Surname + ' (MN' + eme.EmployeeNumber + ')' 
							END +
							CASE	WHEN ee.EmployerNumber = @EmployerNumber
									THEN ''
									ELSE ' (' + emp.EmployerName + ')'
							END FullName,
							ee.StartDate,
							ee.EndDate,
							ROW_NUMBER() OVER
								(
									PARTITION BY eme.EmployeeNumber 
									ORDER BY CASE WHEN @GetDate BETWEEN ee.StartDate 
																	AND ISNULL(ee.EndDate, @Getdate)
													THEN 0 
													ELSE 1
												END,
												ee.StartDate desc
								) RowNumber
					FROM	sub.tblEmployee eme
					INNER JOIN sub.tblEmployer_Employee ee ON ee.EmployeeNumber = eme.EmployeeNumber
					INNER JOIN sub.tblEmployer emp ON emp.EmployerNumber = ee.EmployerNumber
					LEFT JOIN  evcwv.tblParticipant par ON par.EmployeeNumber = eme.EmployeeNumber
					CROSS JOIN @SearchWord
					WHERE	emp.EmployerNumber = @EmployerNumber
					AND	 COALESCE(ee.EndDate, '20990101') > CAST(DATEADD(YEAR, -1, GETDATE()) AS date)
					AND	 ee.StartDate <= @StartDate
					AND	 COALESCE(ee.EndDate, @StartDate) >= @StartDate
					AND
						(
								'T' = 
									CASE 
										WHEN		@SearchString = '' 
											THEN 'T'	
										WHEN		CHARINDEX(Word, eme.SearchName, 1) = 1 
											THEN	'T'
									END
							OR	
								'T' = 
									CASE 
										WHEN		@SearchString = '' 
											THEN 'T'	
										WHEN		CHARINDEX(Word, eme.EmployeeNumber, 1) = 1 
											THEN	'T'
									END	
						)

					UNION ALL

					SELECT
							par.ParticipantID,
							eme.EmployeeNumber,
							par.CRMID,
							eme.Initials,
							eme.Amidst,
							eme.Surname,
							eme.Gender,
							par.Phone,
							par.Email,
							eme.DateOfBirth,
							eme.SearchName,
							CASE	WHEN eme.EmployeeNumber IS NULL 
									THEN eme.Surname 
									ELSE eme.Surname + ' (MN' + eme.EmployeeNumber + ')' 
							END +
							CASE	WHEN ee.EmployerNumber = @EmployerNumber
									THEN ''
									ELSE ' (' + emp.EmployerName + ')'
							END FullName,
							ee.StartDate,
							ee.EndDate,
							ROW_NUMBER() OVER
								(
									PARTITION BY eme.EmployeeNumber 
									ORDER BY CASE WHEN @GetDate BETWEEN ee.StartDate 
																	AND ISNULL(ee.EndDate, @Getdate)
													THEN 0 
													ELSE 1
												END,
												ee.StartDate desc
								) RowNumber
					FROM	sub.tblEmployee eme
					INNER JOIN sub.tblEmployer_Employee ee ON ee.EmployeeNumber = eme.EmployeeNumber
					INNER JOIN sub.tblEmployer_ParentChild epc ON epc.EmployerNumberChild = ee.EmployerNumber
					INNER JOIN sub.tblEmployer emp ON emp.EmployerNumber = epc.EmployerNumberChild
					LEFT JOIN  evcwv.tblParticipant par ON par.EmployeeNumber = eme.EmployeeNumber
					CROSS JOIN @SearchWord
					WHERE	epc.EmployerNumberParent = @EmployerNumber
					AND
						(
								'T' = 
									CASE 
										WHEN		@SearchString = '' 
											THEN 'T'	
										WHEN		CHARINDEX(Word, eme.SearchName, 1) = 1 
											THEN	'T'
									END
							OR	
								'T' = 
									CASE 
										WHEN		@SearchString = '' 
											THEN 'T'	
										WHEN		CHARINDEX(Word, eme.EmployeeNumber, 1) = 1 
											THEN	'T'
									END	
						)

					--UNION ALL

					--SELECT
					--		par.ParticipantID,
					--		par.EmployeeNumber,
					--		par.CRMID,
					--		par.Initials,
					--		par.Amidst,
					--		par.Surname,
					--		par.Gender,
					--		par.Phone,
					--		par.Email,
					--		par.DateOfBirth,
					--		par.SearchName,
					--		par.FullName,
					--		NULL StartDate,
					--		NULL EndDate,
					--		1 RowNumber
					--FROM	evcwv.tblParticipant par
					--CROSS JOIN @SearchWord
					--WHERE
					--	'T' = 
					--		CASE 
					--			WHEN		@SearchString = '' 
					--				THEN 'T'	
					--			WHEN		CHARINDEX(Word, par.FullName, 1) = 1 
					--				THEN	'T'
					--		END
				) Participant
	) Final
WHERE final.RowNumber = 1
ORDER BY 
		final.FullName
 
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== evcwv.uspParticipant_List ==================================================================	*/
