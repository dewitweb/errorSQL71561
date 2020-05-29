
CREATE PROCEDURE [sub].[uspEmployer_Employee_Upd]
@EmployerNumber varchar(6),
@EmployeeNumber varchar(8),
@StartDate		datetime,
@EndDate		datetime,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose:	Add/update a record into sub.tblEmployer_Employee.

	03-10-2018	Sander van Houten		Initial version.
	========================================================================================== */

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

IF (SELECT	COUNT(EmployerNumber)
	FROM	sub.tblEmployer_Employee
	WHERE	EmployerNumber = @EmployerNumber
		AND	EmployeeNumber = @EmployeeNumber
		AND	StartDate = @StartDate) = 0
BEGIN
	-- Insert new record
	INSERT INTO sub.tblEmployer_Employee
		(
			EmployerNumber,
			EmployeeNumber,
			StartDate,
			EndDate
		)
	VALUES
		(
			@EmployerNumber,
			@EmployeeNumber,
			@StartDate,
			@EndDate
		)
END
ELSE
BEGIN
	-- Update exisiting record
	UPDATE	sub.tblEmployer_Employee
	SET		EndDate	= @EndDate
	WHERE	EmployerNumber = @EmployerNumber
	  AND	EmployeeNumber = @EmployeeNumber
	  AND	StartDate = @StartDate
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/* == sub.uspEmployer_Employee_Upd ========================================================== */
