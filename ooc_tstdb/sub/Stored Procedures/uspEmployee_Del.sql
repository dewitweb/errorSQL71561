
CREATE PROCEDURE [sub].[uspEmployee_Del]
@EmployeeNumber	varchar(8),
@CurrentUserID	int = 1
AS

/*	==========================================================================================
	Purpose:	Remove employee record.

	02-08-2018	Sander van Houten		CurrentUserID added.
	20-07-2018	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

-- Delete record sub.tblEmployer_Employee
DELETE
FROM	sub.tblEmployer_Employee
WHERE	EmployeeNumber = @EmployeeNumber
	
-- Delete record sub.tblEmployee
DELETE
FROM	sub.tblEmployee
WHERE	EmployeeNumber = @EmployeeNumber

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployee_Del ====================================================================	*/
