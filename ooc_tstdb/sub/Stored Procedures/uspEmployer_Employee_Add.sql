
CREATE PROCEDURE [sub].[uspEmployer_Employee_Add]
@EmployerNumber varchar(6),
@EmployeeNumber varchar(8),
@StartDate		datetime,
@EndDate		datetime,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose:	Insert a new record into sub.tblEmployer_Employee.

	02-08-2018	Sander van Houten		Initial version.
	========================================================================================== */

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

-- Add new record
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

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/* == sub.uspEmployer_Employee_Add ========================================================== */
