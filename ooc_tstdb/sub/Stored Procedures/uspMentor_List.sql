CREATE PROCEDURE [sub].[uspMentor_List]
@EmployerNumber varchar(6),
@SearchString	varchar(max)
AS
/*	==========================================================================================
	Purpose: 	Get list from sub.tblMentor.

	18-11-2019	Sander van Houten		OTIBSUB-1719	Only show mentors that were connected 
                                            to this company by a declaration earlier.
	02-07-2019	Sander van Houten		OTIBSUB-1300	Added employmentperiod for notification.
	28-06-2019	Sander van Houten		OTIBSUB-1286	Include employements at childcompanies.
	22-05-2019	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*  Testdata.
DECLARE @EmployerNumber varchar(6) = '060899',
        @SearchString	varchar(max) = ''
--  */

DECLARE @GetDate Date = GETDATE()

SET	@SearchString	 = ISNULL(@SearchString, '')

SELECT @SearchString = sub.usfCreateSearchString (@SearchString)

DECLARE @SearchWord TABLE (Word nvarchar(max) NOT NULL)

INSERT INTO @SearchWord (Word)
SELECT s FROM sub.utfSplitString(@SearchString, ' ')

SELECT 
		final.MentorID,
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
					mentor.MentorID,
					mentor.EmployeeNumber,
					mentor.CRMID,
					mentor.Initials,
					mentor.Amidst,
					mentor.Surname,
					mentor.Gender,
					mentor.Phone,
					mentor.Email,
					mentor.DateOfBirth,
					mentor.SearchName,
					mentor.FullName,
					mentor.StartDate,
					mentor.EndDate,
					ROW_NUMBER() OVER
						(
							PARTITION BY mentor.EmployeeNumber 
							ORDER BY CASE WHEN @GetDate BETWEEN ISNULL(mentor.StartDate, @Getdate) 
															AND ISNULL(mentor.EndDate, @Getdate)
											THEN 0 
											ELSE 1
										END,
										mentor.StartDate desc
						) RowNumber
			FROM
				(
					SELECT
							men.MentorID,
							eme.EmployeeNumber,
							men.CRMID,
							eme.Initials,
							eme.Amidst,
							eme.Surname,
							eme.Gender,
							men.Phone,
							men.Email,
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
					LEFT JOIN  sub.tblMentor men ON men.EmployeeNumber = eme.EmployeeNumber
					CROSS JOIN @SearchWord
					WHERE	emp.EmployerNumber = @EmployerNumber
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
											THEN 'T'
									END	
						)

					UNION ALL

					SELECT
							men.MentorID,
							eme.EmployeeNumber,
							men.CRMID,
							eme.Initials,
							eme.Amidst,
							eme.Surname,
							eme.Gender,
							men.Phone,
							men.Email,
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
					LEFT JOIN  sub.tblMentor men ON men.EmployeeNumber = eme.EmployeeNumber
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
											THEN 'T'
									END	
						)

					UNION ALL

					SELECT
							men.MentorID,
							men.EmployeeNumber,
							men.CRMID,
							men.Initials,
							men.Amidst,
							men.Surname,
							men.Gender,
							men.Phone,
							men.Email,
							men.DateOfBirth,
							men.SearchName,
							men.FullName,
							NULL StartDate,
							NULL EndDate,
							1 RowNumber
					FROM	sub.tblMentor men
                    INNER JOIN stip.tblDeclaration_Mentor dem ON dem.MentorID = men.MentorID
                    INNER JOIN sub.tblDeclaration d ON d.DeclarationID = dem.DeclarationID
					CROSS JOIN @SearchWord
					WHERE   d.EmployerNumber = @EmployerNumber
                    AND     'T' = 
                                CASE 
                                    WHEN		@SearchString = '' 
                                        THEN 'T'	
                                    WHEN		CHARINDEX(Word, men.FullName, 1) = 1 
                                        THEN 'T'
                                END
				) Mentor
	) Final
WHERE final.RowNumber = 1
ORDER BY 
		final.FullName
 
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspMentor_List ====================================================================	*/
