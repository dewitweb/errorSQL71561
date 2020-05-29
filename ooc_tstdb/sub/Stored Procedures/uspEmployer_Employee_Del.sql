
CREATE PROCEDURE [sub].[uspEmployer_Employee_Del]
@EmployerNumber varchar(6),
@EmployeeNumber varchar(8),
@StartDate		datetime,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose:	Remove Employer_Employee record.

	Notes:		Either parameter is optional.
				If both parameters are filled, only the concerning employee of the concerning
					employer will be deleted.
				If @EmployerNumber is NULL and @EmployeeNumber is filled, all records of that 
					employee will be deleted (at all employers).
				If @EmployerNumber is filled and @EmployeeNumber is NULL, all employees of that 
					employer will by deleted.
				If both parameters are NULL, all records in the table will be deleted.

	02-08-2018 Sander van Houten    Initial version.
	========================================================================================== */

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE	@EmployerToBeUnlinked	varchar(6),
		@EmployeeToBeUnlinked	varchar(8),
		@StartDateToBeUnlinked	datetime

DECLARE cur_Emp CURSOR FOR 
	SELECT	EmployerNumber,
			EmployeeNumber,
			StartDate
	FROM	sub.tblEmployer_Employee
	WHERE	EmployerNumber = COALESCE(@EmployerNumber, EmployerNumber)
	  AND	EmployeeNumber = COALESCE(@EmployeeNumber, EmployeeNumber)
	  AND	StartDate = COALESCE(@StartDate, StartDate)

-- Loop through cursor to log the deletion for all records
OPEN cur_emp

FETCH NEXT FROM cur_emp INTO @EmployerToBeUnlinked, @EmployeeToBeUnlinked, @StartDateToBeUnlinked

WHILE @@FETCH_STATUS = 0  
BEGIN
	-- Delete exisiting record
	DELETE
	FROM	sub.tblEmployer_Employee
	WHERE	EmployerNumber = @EmployerToBeUnlinked
	  AND	EmployeeNumber = @EmployeeToBeUnlinked
	  AND	StartDate = @StartDateToBeUnlinked

	FETCH NEXT FROM cur_emp INTO @EmployerToBeUnlinked, @EmployeeToBeUnlinked, @StartDateToBeUnlinked
END

CLOSE cur_emp
DEALLOCATE cur_emp

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/* == sub.uspEmployer_Employee_Del =========================================================== */
