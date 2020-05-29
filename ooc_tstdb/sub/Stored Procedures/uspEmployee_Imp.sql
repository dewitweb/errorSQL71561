
CREATE PROCEDURE [sub].[uspEmployee_Imp]
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose:	Import employee data from OTIBMNData database.

	17-10-2018	Sander van Houten	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SET NOCOUNT ON

DECLARE	@StartTimeStamp	datetime = GETDATE(),
		@TimeStamp		datetime = GETDATE()

DECLARE @Employee TABLE (
	EmployeeNumber	varchar(8),
	Initials		varchar(10) NULL,
	Amidst			varchar(20) NULL,
	Surname			varchar(200) NULL,
	Gender			varchar(1) NULL,
	AmidstSpous		varchar(10) NULL,
	SurnameSpous	varchar(100) NULL,
	Email			varchar(254),
	IBAN			varchar(34),
	DateOfBirth		date,
	ImportAction	varchar(6) )

/*	Log start of import.	*/
SET @TimeStamp = GETDATE()

INSERT INTO sub.tblImportLog
			([Log]
			,[TimeStamp]
			,Duration)
		VALUES
			('De import van MN werknemer data is gestart.'
			,@StartTimeStamp
			,0)

/*	Select all new employees	*/
INSERT INTO @Employee 
	(
		EmployeeNumber,
		Initials,
		Amidst,
		Surname,
		Gender,
		AmidstSpous,
		SurnameSpous,
		Email,
		IBAN,
		DateOfBirth,
		ImportAction 
	)
SELECT	crm.nummer,
		crm.voorletters,
		crm.voorvoegsels,
		crm.naam,
		crm.geslacht,
		crm.voorvoegselsEchtgenoot,
		crm.naamEchtgenoot,
		'',
		'',
		geboortedatum,
		'insert'
FROM	crm.viewEmployee_MNData_MostRecent crm
LEFT JOIN sub.tblEmployee emp
	ON	emp.EmployeeNumber = crm.nummer
WHERE	emp.EmployeeNumber IS NULL

/*	Log inserts.	*/
INSERT INTO sub.tblImportLog
           ([Log]
		   ,[TimeStamp]
		   ,Duration)
     VALUES
           ('Er zijn ' + CAST(@@ROWCOUNT AS varchar(10)) + ' nieuwe werknemer records geselecteerd.'
           ,GETDATE()
           ,DATEDIFF(ss, @TimeStamp, GETDATE()))

/*	Select all existing employees that are updated in CRM	*/
SET @TimeStamp = GETDATE()

INSERT INTO @Employee 
	(
		EmployeeNumber,
		Initials,
		Amidst,
		Surname,
		Gender,
		AmidstSpous,
		SurnameSpous,
		Email,
		IBAN,
		DateOfBirth,
		ImportAction 
	)
SELECT	crm.nummer,
		crm.voorletters,
		crm.voorvoegsels,
		crm.naam,
		crm.geslacht,
		crm.voorvoegselsEchtgenoot,
		crm.naamEchtgenoot,
		emp.Email,
		emp.IBAN,
		geboortedatum,
		'update'
FROM	crm.viewEmployee_MNData_MostRecent crm
INNER JOIN sub.tblEmployee emp
ON		emp.EmployeeNumber = crm.nummer
WHERE	ISNULL(emp.Initials, '') <> ISNULL(voorletters, '')
   OR	ISNULL(emp.Amidst, '') <> ISNULL(voorvoegsels, '')
   OR	ISNULL(emp.Surname, '') <> ISNULL(naam, '')
   OR	ISNULL(emp.Gender, '') <> ISNULL(geslacht, '')
   OR	ISNULL(emp.AmidstSpous, '') <> ISNULL(voorvoegselsEchtgenoot, '')
   OR	ISNULL(emp.SurnameSpous, '') <> ISNULL(naamEchtgenoot, '')
   OR	ISNULL(emp.DateOfBirth, '19000101') <> ISNULL(geboortedatum, '19000101')

/*	Log updates.	*/
INSERT INTO sub.tblImportLog
           ([Log]
		   ,[TimeStamp]
		   ,Duration)
     VALUES
           ('Er zijn ' + CAST(@@ROWCOUNT AS varchar(10)) + ' te wijzigen werknemer records geselecteerd.'
           ,GETDATE()
           ,DATEDIFF(ss, @TimeStamp, GETDATE()))

IF (SELECT COUNT(1) FROM @Employee) > 0
BEGIN
	/*	Use standard procedure to process changes	*/
	DECLARE @EmployeeNumber	varchar(8),
			@Initials		varchar(10),
			@Amidst			varchar(20),
			@Surname		varchar(200),
			@Gender			varchar(1),
			@AmidstSpous	varchar(10),
			@SurnameSpous	varchar(100),
			@Email			varchar(254),
			@IBAN			varchar(34),
			@DateOfBirth	date,
			@RC				int

	DECLARE cur_Employee CURSOR FOR 
		SELECT 
			EmployeeNumber,
			Initials,
			Amidst,
			Surname,
			Gender,
			AmidstSpous,
			SurnameSpous,
			Email,
			IBAN,
			DateOfBirth
		FROM @Employee
		ORDER BY	ImportAction DESC, 
					EmployeeNumber ASC

	OPEN cur_Employee

	FETCH NEXT FROM cur_Employee INTO @EmployeeNumber, @Initials, @Amidst, @Surname, @Gender, 
										@AmidstSpous, @SurnameSpous, @Email, @IBAN, @DateOfBirth

	WHILE @@FETCH_STATUS = 0  
	BEGIN
		/* Call standard procedure	*/
		EXECUTE @RC = [sub].[uspEmployee_Upd] 
			@EmployeeNumber,
			@Initials,
			@Amidst,
			@Surname,
			@Gender,
			@AmidstSpous,
			@SurnameSpous,
			@Email,
			@IBAN,
			@DateOfBirth,
			@CurrentUserID

		FETCH NEXT FROM cur_Employee INTO @EmployeeNumber, @Initials, @Amidst, @Surname, @Gender, 
											@AmidstSpous, @SurnameSpous, @Email, @IBAN, @DateOfBirth
	END

	CLOSE cur_Employee
	DEALLOCATE cur_Employee
END

/*	Log end of import.	*/
INSERT INTO sub.tblImportLog
			([Log]
			,[TimeStamp]
			,Duration)
		VALUES
			('De import van MN werknemer data is geëindigd.'
			,GETDATE()
			,DATEDIFF(ss, @StartTimeStamp, GETDATE()))

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployee_Imp ===================================================================	*/
