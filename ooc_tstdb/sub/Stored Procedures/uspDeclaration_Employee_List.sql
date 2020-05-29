CREATE PROCEDURE [sub].[uspDeclaration_Employee_List]
@DeclarationID	int
AS
/*	==========================================================================================
	Purpose:	List all data from tblDeclaration_Employee_ReversalPayment 
				for a declaration/partition.

	17-09-2019	Sander van Houten		OTIBSUB-1577	Show DateOfBirth behind EmployeeName.
	21-02-2019	Sander van Houten		OTIBSUB-792		Manier van vastlegging terugboeking 
											bij werknemer veranderen.
	11-10-2018	Jaap van Assenbergh		OTIBSUB-233		EmployeeName added on list.
	19-07-2018	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		de.DeclarationID,
		de.EmployeeNumber,
		e.FullName + CASE WHEN e.DateOfBirth IS NULL 
						THEN ''
						ELSE ' (' + CONVERT(varchar(10), e.DateOfBirth, 105) + ')'
					 END	AS EmployeeName,
		MAX(der.ReversalPaymentID)	AS ReversalPaymentID
FROM	sub.tblDeclaration_Employee de
INNER JOIN sub.tblEmployee e ON e.EmployeeNumber = de.EmployeeNumber
LEFT JOIN sub.tblDeclaration_Employee_ReversalPayment der 
ON		der.DeclarationID = de.DeclarationID
AND		der.EmployeeNumber = de.EmployeeNumber
WHERE	de.DeclarationID = @DeclarationID
GROUP BY 
		de.DeclarationID,
		de.EmployeeNumber,
		e.FullName,
		e.DateOfBirth
ORDER BY 
		de.EmployeeNumber

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Employee_List =======================================================	*/
