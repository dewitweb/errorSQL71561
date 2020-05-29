


CREATE PROCEDURE [sub].[uspEmployee_Get_WithEmployerNumber]
@EmployeeNumber	varchar(8),
@EmployerNumber	varchar(6)
AS
/*	==========================================================================================
	Purpose:	List all employee data at an employer.

	Note:		Used in "Declaratie bevestigen".

	23-04-2019	Jaap van Assenbergh		OTIBSUB-985
										Logmeldingen: "User ... triggered a forbidden resource." 
										bij opvragen vouchers
	11-12-2018	Jaap van Assenbergh		OTIBSUB-567
										Meerdere werknemers met hetzelfde nummer?	
	04-12-2018	Sander van Houten		Added EmployeeDisplayName (OTIBSUB-441)
										and removed fields Email and IBAN.
	28-08-2018	Sander van Houten		Initial version (OTIBSUB-48).
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

	SELECT	DISTINCT
			t1.EmployeeNumber,
			RTRIM(t1.FullName)		AS EmployeeName,
			RTRIM(t1.FullName) 
			+ CASE WHEN DateOfBirth IS NOT NULL 
				THEN ' (' + CONVERT(varchar(10), DateOfBirth, 105) + ')'
				ELSE ''
			  END
			+ ' ' + t1.EmployeeNumber	AS EmployeeDisplayName
	FROM	sub.tblEmployee t1
	INNER JOIN sub.viewEmployer_Employee t2
	ON t2.EmployeeNumber = t1.EmployeeNumber
	WHERE	t1.EmployeeNumber = @EmployeeNumber
	  AND	t2.EmployerNumber = @EmployerNumber

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployee_Get_WithEmployerNumber ================================================	*/
