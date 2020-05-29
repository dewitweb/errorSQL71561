
CREATE PROCEDURE [sub].[uspEmployer_Del]
@EmployerNumber	varchar(8),
@CurrentUserID	int = 1
AS

/*	==========================================================================================
	Purpose:	Remove employer record.

	02-08-2018	Sander van Houten		CurrentUserID added.
	20-07-2018	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

-- Delete record sub.tblEmployer_Employer
DELETE
FROM	sub.tblEmployer_Employee
WHERE	EmployerNumber = @EmployerNumber
	
-- Delete record sub.tblEmployer
DELETE
FROM	sub.tblEmployer
WHERE	EmployerNumber = @EmployerNumber

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployer_Del ====================================================================	*/
