
CREATE PROCEDURE [osr].[uspDeclaration_Get_Duplicates]
@DeclarationID	int
AS
/*	==========================================================================================
	Purpose:	Get declaration information on bases of a DeclarationID 
				and provide the same information for all duplicates.

	Notes:		DuplicateType 1 = Declaration that is being submitted.
				DuplicateType 2 = Declaration that already exists.

	13-05-2019	Sander van Houten		OTIBSUB-1074	Simplified procedure.
	21-02-2019	Sander van Houten		OTIBSUB-792		Manier van vastlegging terugboeking 
														bij werknemer veranderen.
	03-01-2019	Sander van Houten		OTIBSUB-431		Added PaidAmount and remove ApprovedAmount.
	07-11-2018	Sander van Houten		OTIBSUB-391		Added DeclarationID to the resultset.
	27-09-2018	Sander van Houten		OTIBSUB-285		Intial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		1		AS DuplicateType,
		d.DeclarationID
FROM	osr.viewDeclaration d
WHERE	d.DeclarationID = @DeclarationID

UNION

SELECT
		2		AS DuplicateType,
		d.DeclarationID
FROM	osr.viewDeclaration dup
INNER JOIN osr.viewDeclaration d
		ON d.EmployerNumber = dup.EmployerNumber
		AND d.CourseID = dup.CourseID
		AND d.StartDate = dup.StartDate
		AND d.EndDate = dup.EndDate
INNER JOIN sub.tblDeclaration_Employee emp1
		ON	emp1.DeclarationID = dup.DeclarationID
INNER JOIN sub.tblDeclaration_Employee emp2
		ON	emp2.DeclarationID = d.DeclarationID
LEFT JOIN sub.tblDeclaration_Employee_ReversalPayment de1
		ON de1.DeclarationID = dup.DeclarationID
LEFT JOIN sub.tblDeclaration_Employee_ReversalPayment de2
		ON de2.DeclarationID = d.DeclarationID
		AND de2.EmployeeNumber = de1.EmployeeNumber
WHERE	dup.DeclarationID = @DeclarationID
AND		d.DeclarationID <> dup.DeclarationID
AND		emp2.EmployeeNumber = emp1.EmployeeNumber
AND		de1.ReversalPaymentID IS NULL
AND		de2.ReversalPaymentID IS NULL

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== osr.uspDeclaration_Get_Duplicates =====================================================	*/
