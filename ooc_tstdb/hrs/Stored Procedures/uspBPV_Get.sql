
CREATE PROCEDURE hrs.uspBPV_Get
@EmployeeNumber		varchar(8),
@EmployerNumber		varchar(6),
@StartDate			date,
@CourseID			int
AS
/*	==========================================================================================
	Purpose: 	Get data from hrs.tblBPV on basis of EmployeeNumber.

	06-06-2019	Jaap van Assenbergh	Inital version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		EmployeeNumber,
		EmployerNumber,
		StartDate,
		EndDate,
		CourseID,
		CourseName,
		StatusCode,
		StatusDescription
FROM	hrs.tblBPV
WHERE	EmployerNumber = @EmployerNumber
AND		EmployeeNumber = @EmployeeNumber
AND		StartDate = @StartDate
AND		CourseID = @CourseID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== uspBPV_Get ============================================================================	*/
