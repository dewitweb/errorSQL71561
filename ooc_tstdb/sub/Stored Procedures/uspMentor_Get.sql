
CREATE PROCEDURE sub.uspMentor_Get
@MentorID	int
AS
/*	==========================================================================================
	Purpose: 	Get data from sub.tblMentor on basis of MentorID.

	22-05-2019	Jaap van Assenbergh	Inital version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		MentorID,
		men.EmployeeNumber,
		CRMID,
		CASE WHEN eme.EmployeeNumber IS NULL THEN men.Initials ELSE eme.Initials END		Initials,
		CASE WHEN eme.EmployeeNumber IS NULL THEN men.Amidst ELSE eme.Amidst END			Amidst,
		CASE WHEN eme.EmployeeNumber IS NULL THEN men.Surname ELSE eme.Surname END			Surname,
		CASE WHEN eme.EmployeeNumber IS NULL THEN men.Gender ELSE eme.Gender END			Gender,
		men.Phone,
		men.Email,
		CASE WHEN eme.EmployeeNumber IS NULL THEN men.DateOfBirth ELSE eme.DateOfBirth END	DateOfBirth,
		CASE WHEN eme.EmployeeNumber IS NULL THEN men.SearchName ELSE eme.SearchName END	SearchName,
		CASE WHEN eme.EmployeeNumber IS NULL THEN men.FullName ELSE eme.FullName END		FullName
FROM	sub.tblMentor men
LEFT JOIN sub.tblEmployee eme ON eme.EmployeeNumber = men.EmployeeNumber
WHERE	MentorID = @MentorID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== uspMentor_Get =========================================================================	*/
