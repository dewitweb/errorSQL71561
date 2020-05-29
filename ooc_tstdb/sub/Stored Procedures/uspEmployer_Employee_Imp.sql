CREATE PROCEDURE [sub].[uspEmployer_Employee_Imp]
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose:	Import link between employer and employee from OTIBMNData database.

	30-09-2019	Sander van Houten		OTIBSUB-1600	Changed import sequence to 
											delete - update - insert.
	23-07-2019	Jaap van Assenbergh		OTIBSUB-1385	Import dienstverbanden en betalingsachterstanden 
											veroorzaakt een grote transaction log file.
	07-05-2019	Sander van Houten		OTIBSUB-1044	Added import of sub.tblEMployee_ScopeOfEmployment.
	24-01-2019	Sander van Houten		Simplified procedure to initialize and refill.
	03-10-2018	Sander van Houten		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE	@StartTimeStamp	datetime = GETDATE(),
		@TimeStamp		datetime = GETDATE()

--DECLARE @startDate datetime2 
--SET @startDate = SysDateTime()
--DECLARE @nowDate datetime2 
--SET @nowDate = SysDateTime()

--PRINT '- Starttijd: ' + CAST(@startDate as varchar(20))

DECLARE @Employer_Employee AS table
	(
		EmployerNumber varchar(6),
        EmployeeNumber varchar(8),
        StartDate date,
        EndDate date 
		INDEX Employer_Employee CLUSTERED (EmployerNumber, EmployeeNumber, StartDate)
	)

DECLARE @Employee_ScopeOfEmployment AS table
	(
		EmployeeNumber varchar(8),
        EmployerNumber varchar(6),
        StartDate date,
		EndDate date INDEX Employer_Employee,
		ScopeOfEmployment decimal(10,2)
		INDEX Employee_ScopeOfEmployment CLUSTERED (EmployeeNumber, EmployerNumber, StartDate)
	)

/*	Log start of import.	*/
INSERT INTO sub.tblImportLog
	(
		[Log],
		[TimeStamp],
		Duration
	)
VALUES
	(
		'De import van MN dienstverbanden data is gestart.',
		@StartTimeStamp,
		0
	)
	
/*	Initialize target table 1.	*/
INSERT INTO @Employer_Employee
	(
		EmployerNumber,
        EmployeeNumber,
        StartDate,
        EndDate
	)
SELECT	EmployerNumber, 
		EmployeeNumber, 
		StartDate,
		EndDate
FROM	crm.viewEmployer_Employee_MNData_All
WHERE	COALESCE(EndDate, '20990101') > '20180101'

--PRINT '- Initialize target table 1: ' + CAST(DATEDIFF(millisecond, @nowDate, SysDateTime()) as varchar(20)) + ' Ms'
--SET @nowDate = SysDateTime()

/*	Delete from target table 1.	*/
SET @TimeStamp = GETDATE()

DELETE	del
FROM	sub.tblEmployer_Employee del
LEFT JOIN @Employer_Employee ere
		ON	ere.EmployerNumber = del.EmployerNumber
		AND		ere.EmployeeNumber = del.EmployeeNumber
		AND		ere.StartDate = del.StartDate
WHERE ere.EmployerNumber IS NULL

--PRINT '- Delete from target table 1: ' + CAST(DATEDIFF(millisecond, @nowDate, SysDateTime()) as varchar(20)) + ' Ms'
--SET @nowDate = SysDateTime()

/*	Log deletes.	*/
INSERT INTO sub.tblImportLog
	(
		[Log],
		[TimeStamp],
		Duration
	)
VALUES
	(
		'Er zijn ' + CAST(@@ROWCOUNT AS varchar(10)) + ' dienstverband records verwijderd.',
		GETDATE(),
		DATEDIFF(ss, @TimeStamp, GETDATE())
	)

/*	Update target table 1.	*/
SET @TimeStamp = GETDATE()

UPDATE	upd
SET		upd.EndDate = ere.EndDate
FROM	sub.tblEmployer_Employee upd
INNER JOIN @Employer_Employee ere
		ON	ere.EmployerNumber = upd.EmployerNumber 
		AND	ere.EmployeeNumber = upd.EmployeeNumber 
		AND	ere.StartDate = upd.StartDate
WHERE	ISNULL(upd.EndDate, '1900-01-01') <> ISNULL(ere.EndDate, '1900-01-01')

--PRINT '- Update target table 1: ' + CAST(DATEDIFF(millisecond, @nowDate, SysDateTime()) as varchar(20)) + ' Ms'
--SET @nowDate = SysDateTime()

/*	Log updates.	*/
INSERT INTO sub.tblImportLog
	(
		[Log],
		[TimeStamp],
		Duration
	)
VALUES
	(
		'Er zijn ' + CAST(@@ROWCOUNT AS varchar(10)) + ' dienstverband records bijgewerkt.',
		GETDATE(),
		DATEDIFF(ss, @TimeStamp, GETDATE())
	)

--PRINT '- SQL statement: ' + CAST(DATEDIFF(millisecond, @nowDate, SysDateTime()) as varchar(20)) + ' Ms'
--SET @nowDate = SysDateTime()

/*	Insert into target table 1.	*/
SET @TimeStamp = GETDATE()

INSERT INTO sub.tblEmployer_Employee
	(
		EmployerNumber,
        EmployeeNumber,
        StartDate,
        EndDate
	)
SELECT	eme.EmployerNumber, 
		eme.EmployeeNumber, 
		eme.StartDate,
		eme.EndDate
FROM	@Employer_Employee eme
WHERE	NOT EXISTS
	(
		SELECT	ere.EmployerNumber
		FROM	sub.tblEmployer_Employee ere
		WHERE	ere.EmployerNumber = eme.EmployerNumber
		AND		ere.EmployeeNumber = eme.EmployeeNumber
		AND		ere.StartDate = eme.StartDate
	)

--PRINT '- Insert into target table 1: ' + CAST(DATEDIFF(millisecond, @nowDate, SysDateTime()) as varchar(20)) + ' Ms'
--SET @nowDate = SysDateTime()

/*	Log inserts.	*/
INSERT INTO sub.tblImportLog
	(
		[Log],
		[TimeStamp],
		Duration
	)
VALUES
	(
		'Er zijn ' + CAST(@@ROWCOUNT AS varchar(10)) + ' dienstverband records toegevoegd.',
		GETDATE(),
		DATEDIFF(ss, @TimeStamp, GETDATE())
	)

/*	Initialize target table 2.	*/
INSERT INTO @Employee_ScopeOfEmployment
	(
		EmployeeNumber,
		EmployerNumber,
		StartDate,
		EndDate,
		ScopeOfEmployment
	)
SELECT	EmployeeNumber,
		EmployerNumber,
		StartDate,
		EndDate,
		ScopeOfEmployment
FROM	crm.viewEmployee_ScopeOfEmployment_MNData_All 
WHERE	COALESCE(EndDate, '20990101') > '20150801'

--PRINT '- Initialize target table 2: ' + CAST(DATEDIFF(millisecond, @nowDate, SysDateTime()) as varchar(20)) + ' Ms'
--SET @nowDate = SysDateTime()

/*	Delete from target table 2.	*/
SET @TimeStamp = GETDATE()

DELETE	del
FROM	sub.tblEmployee_ScopeOfEmployment del
LEFT JOIN @Employee_ScopeOfEmployment esoe
		ON	esoe.EmployeeNumber = del.EmployeeNumber
		AND	esoe.EmployerNumber = del.EmployerNumber
		AND	esoe.StartDate = del.StartDate
WHERE esoe.EmployeeNumber IS NULL

--PRINT '- Delete from target table 2: ' + CAST(DATEDIFF(millisecond, @nowDate, SysDateTime()) as varchar(20)) + ' Ms'
--SET @nowDate = SysDateTime()

/*	Log deletes.	*/
INSERT INTO sub.tblImportLog
	(
		[Log],
		[TimeStamp],
		Duration
	)
VALUES
	(
		'Er zijn ' + CAST(@@ROWCOUNT AS varchar(10)) + ' dienstverbanduren records verwijderd.',
		GETDATE(),
		DATEDIFF(ss, @TimeStamp, GETDATE())
	)

/*	Update target table 2.	*/
SET @TimeStamp = GETDATE()

UPDATE	upd
SET		upd.EndDate = esoe.EndDate,
		upd.ScopeOfEmployment = esoe.ScopeOfEmployment
FROM	sub.tblEmployee_ScopeOfEmployment upd
INNER JOIN @Employee_ScopeOfEmployment esoe
		ON	esoe.EmployeeNumber = upd.EmployeeNumber 
		AND	esoe.EmployerNumber = upd.EmployerNumber 
		AND	esoe.StartDate = upd.StartDate
WHERE	ISNULL(upd.EndDate, '1900-01-01') <> ISNULL(esoe.EndDate, '1900-01-01')
OR		ISNULL(upd.ScopeOfEmployment, 0) <> ISNULL(esoe.ScopeOfEmployment, 0)

--PRINT '- Update target table 2: ' + CAST(DATEDIFF(millisecond, @nowDate, SysDateTime()) as varchar(20)) + ' Ms'
--SET @nowDate = SysDateTime()

/*	Log updates.	*/
INSERT INTO sub.tblImportLog
	(
		[Log],
		[TimeStamp],
		Duration
	)
VALUES
	(
		'Er zijn ' + CAST(@@ROWCOUNT AS varchar(10)) + ' dienstverbanduren records bijgewerkt.',
		GETDATE(),
		DATEDIFF(ss, @TimeStamp, GETDATE())
	)

/*	Insert into target table 2.	*/
SET @TimeStamp = GETDATE()

INSERT INTO sub.tblEmployee_ScopeOfEmployment
	(
		EmployeeNumber,
		EmployerNumber,
		StartDate,
		EndDate,
		ScopeOfEmployment
	)
SELECT	upd.EmployeeNumber,
		upd.EmployerNumber,
		upd.StartDate,
		upd.EndDate,
		upd.ScopeOfEmployment
FROM	@Employee_ScopeOfEmployment upd
WHERE	NOT EXISTS
	(
		SELECT	esoe.EmployerNumber
		FROM	sub.tblEmployee_ScopeOfEmployment esoe
		WHERE	esoe.EmployeeNumber = upd.EmployeeNumber
		AND		esoe.EmployerNumber = upd.EmployerNumber
		AND		esoe.StartDate = upd.StartDate
	)

--PRINT '- Insert into target table 2: ' + CAST(DATEDIFF(millisecond, @nowDate, SysDateTime()) as varchar(20)) + ' Ms'
--SET @nowDate = SysDateTime()

/*	Log inserts.	*/
INSERT INTO sub.tblImportLog
	(
		[Log],
		[TimeStamp],
		Duration
	)
VALUES
	(
		'Er zijn ' + CAST(@@ROWCOUNT AS varchar(10)) + ' dienstverbanduren records toegevoegd.',
		GETDATE(),
		DATEDIFF(ss, @TimeStamp, GETDATE())
	)

/*	Log end of import.	*/
INSERT INTO sub.tblImportLog
			([Log]
			,[TimeStamp]
			,Duration)
		VALUES
			('De import van MN dienstverbanden data is geëindigd.'
			,GETDATE()
			,DATEDIFF(ss, @StartTimeStamp, GETDATE()))

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployer_Employee_Imp ==========================================================	*/
