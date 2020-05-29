CREATE PROCEDURE [sub].[uspEmployee_List_Employer]
@EmployerNumber		varchar(6),
@IncludeUnEmployed	bit,
@SearchString		varchar(max)
AS
/*	==========================================================================================
	Purpose:	List all employees for the employer.

	Note:		Used in "Werknemersoverzicht".

	13-11-2019	Sander van Houten	OTIBSUB-1704	Employee was not shown because of reversal.
	08-07-2019	Sander van Houten	OTIBSUB-1329	Search only from the begin of a name.
	20-05-2019	Jaap van Assenbergh	OTIBSUB-937		Zoeken op geboortedatum zonder 
										streepjes in te typen.
	21-02-2019	Sander van Houten	OTIBSUB-792		Manier van vastlegging terugboeking 
										bij werknemer veranderen.
	19-02-2019	Jaap van Assenbergh	OTIBSUB-738		Werknemersoverzicht, 
										filtering uit dienst
	04-12-2018	Sander van Houten	OTIBSUB-441		Added DateOfBirth and SpousName.
	20-09-2018	Sander van Houten	OTIBSUB-226		Removed fields.
										The fields for OTIBSUB-46 are now absolete.
										The procedure sub.uspEmployee_List is now created for 
										the dropdown list on the 'Declaratie indienen' screen.										
										Also the SubsidySchemeID parameter is removed.
	27-08-2018	Sander van Houten	OTIBSUB-46		Added fields.
	20-07-2018	Jaap van Assenbergh	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*  Testdata.
DECLARE @EmployerNumber		varchar(6) = '116220',
        @IncludeUnEmployed	bit = 0,
        @SearchString		varchar(max) = NULL
--  */

DECLARE @EmployeeDeclaration as table 
        (
            EmployeeNumber varchar(8) INDEX CI_Employee CLUSTERED, 
            DeclarationID int
        )

DECLARE @Employee as table
        (
            EmployeeNumber varchar(8),
            EmployeeName varchar(133),
            Email varchar(254),
            IBAN varchar(34),
            DateOfBirth date,
            UnEmployed bit,
            SpousName varchar(MAX)
        )

SET	@SearchString	 = ISNULL(@SearchString, '')

SELECT @SearchString = sub.usfCreateSearchString (@SearchString)

DECLARE @CurrentDate date
DECLARE @DateOfBirth date
DECLARE @SearchWord TABLE (Word nvarchar(max) NOT NULL)

SELECT @CurrentDate = CAST(GETDATE() AS date)
SELECT @DateOfBirth = sub.usfCreateDateFromString(@SearchString)

-- Get employees.
IF @DateOfBirth IS NULL				-- Searchstring is not a date
BEGIN
    INSERT INTO @SearchWord (Word)
    SELECT s FROM sub.utfSplitString(@SearchString, ' ')

    INSERT INTO @Employee
            (
                EmployeeNumber,
                EmployeeName,
                Email,
                IBAN,
                DateOfBirth,
                UnEmployed,
                SpousName
            )
        SELECT
                Search.EmployeeNumber,
                Search.EmployeeName,
                Search.Email,
                Search.IBAN,
                Search.DateOfBirth,
                Search.UnEmployed,
                Search.SpousName
        FROM
                (
                    SELECT	DISTINCT 
                            Word,
                            eme.EmployeeNumber,
                            eme.EmployeeName,
                            eme.Email,
                            eme.IBAN,
                            eme.DateOfBirth,
                            eme.UnEmployed,
                            eme.SpousName
                    FROM
                            (
                                SELECT	ee.EmployerNumber,
                                        e.EmployeeNumber,
                                        e.FullName		AS EmployeeName,
                                        e.Email,
                                        e.IBAN,
                                        e.DateOfBirth,
                                        ee.StartDate,
                                        ee.Enddate,
                                        CASE WHEN ee.StartDate <= @CurrentDate 
                                              AND ISNULL(ee.Enddate, @CurrentDate) >= @CurrentDate 
                                            THEN 0 
                                            ELSE 1 
                                        END             AS UnEmployed,
                                        e.SurnameSpous
                                        + CASE e.AmidstSpous WHEN '' THEN '' ELSE ', ' END
                                        + e.AmidstSpous	AS SpousName,
                                        e.SearchName
                                FROM	sub.tblEmployee e
                                INNER JOIN sub.viewEmployer_Employee ee 
                                ON      ee.EmployeeNumber = e.EmployeeNumber
                                WHERE	ee.EmployerNumber = @EmployerNumber

                            ) eme
                    CROSS JOIN @SearchWord sw
                    WHERE	eme.EmployerNumber = @EmployerNumber						-- ivm performance. Afdwingen op PK SEEK	
                    AND		'T' = CASE WHEN @IncludeUnEmployed = 0 
                                    THEN CASE WHEN eme.StartDate <= @CurrentDate 
                                               AND ISNULL(eme.Enddate, @CurrentDate) >= @CurrentDate 
                                            THEN 'T' 
                                         END
                                    ELSE 'T'
                                  END
                    AND		'T' = CASE WHEN @SearchString = '' THEN 'T'	
                                       WHEN CHARINDEX(sw.Word, eme.SearchName, 1) = 1 THEN 'T'
                                  END
                    AND		'T' = CASE WHEN @DateOfBirth IS NOT NULL 
                                    THEN CASE WHEN eme.DateOfBirth <= @DateOfBirth
                                            THEN 'T' 
                                         END
                                    ELSE 'T'
                                  END
                ) Search
        GROUP BY	
                Search.EmployeeNumber,
                Search.EmployeeName,
                Search.Email,
                Search.IBAN,
                Search.DateOfBirth,
                Search.UnEmployed,
                Search.SpousName
        HAVING  COUNT(Search.EmployeeNumber) >= (SELECT COUNT(Word) FROM @SearchWord)
END
ELSE
BEGIN
    INSERT INTO @Employee
                (
                    EmployeeNumber,
                    EmployeeName,
                    Email,
                    IBAN,
                    DateOfBirth,
                    UnEmployed,
                    SpousName
                )
        SELECT
                e.EmployeeNumber,
                e.FullName		AS EmployeeName,
                e.Email,
                e.IBAN,
                e.DateOfBirth,
                CASE WHEN ee.StartDate <= @CurrentDate 
                      AND ISNULL(ee.Enddate, @CurrentDate) >= @CurrentDate 
                    THEN 0 
                    ELSE 1 
                END             AS UnEmployed,
                e.SurnameSpous
                + CASE e.AmidstSpous WHEN '' THEN '' ELSE ', ' END
                + e.AmidstSpous	AS SpousName
        FROM	sub.tblEmployee e
        INNER JOIN sub.viewEmployer_Employee ee 
        ON      ee.EmployeeNumber = e.EmployeeNumber
        WHERE	ee.EmployerNumber = @EmployerNumber
        AND		e.DateOfBirth = CAST(@DateOfBirth AS date)
END

-- Get declarations.
INSERT INTO @EmployeeDeclaration
    (
        EmployeeNumber,
        DeclarationID
    )
SELECT	dem.EmployeeNumber, 
        decl.DeclarationID
FROM	sub.tblDeclaration decl
INNER JOIN  sub.tblDeclaration_Employee dem
ON      dem.DeclarationID = decl.DeclarationID
WHERE   decl.EmployerNumber = @EmployerNumber

-- Get final resultset.
SELECT  sub1.EmployeeNumber,
        sub1.EmployeeName,
        sub1.Email,
        sub1.IBAN,
        sub1.DateOfBirth,
        sub1.SpousName,
        sub1.UnEmployed,
        SUM(sub1.NrOfDeclarations)  AS NrOfDeclarations
FROM    (
            SELECT  emp.EmployeeNumber,
                    emp.EmployeeName,
                    emp.Email,
                    emp.IBAN,
                    emp.DateOfBirth,
                    emp.SpousName,
                    CAST(emp.UnEmployed AS bit)     AS UnEmployed,
                    CASE WHEN ed.EmployeeNumber IS NOT NULL AND der.ReversalPaymentID IS NULL
                        THEN 1
                        ELSE 0
                    END	                            AS NrOfDeclarations
            FROM	@Employee emp
            LEFT JOIN @EmployeeDeclaration ed
            ON      ed.EmployeeNumber = emp.EmployeeNumber
            LEFT JOIN sub.tblDeclaration_Employee_ReversalPayment der
            ON		der.DeclarationID = ed.DeclarationID
            AND		der.EmployeeNumber = ed.EmployeeNumber
            LEFT JOIN sub.tblDeclaration decl
            ON      decl.DeclarationID = ed.DeclarationID
        ) sub1
GROUP BY	
        sub1.EmployeeNumber,
        sub1.EmployeeName,
        sub1.Email,
        sub1.IBAN,
        sub1.DateOfBirth,
        sub1.UnEmployed,
        sub1.SpousName
ORDER BY	
        sub1.EmployeeName

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployee_List_Employer =========================================================	*/
