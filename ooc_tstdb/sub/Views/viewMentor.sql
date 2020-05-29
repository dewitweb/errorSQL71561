CREATE VIEW [sub].[viewMentor]
AS

SELECT	m.MentorID, 
		m.Initials, 
		m.Amidst, 
		m.Surname, 
		m.Gender, 
		m.Email, 
		m.Phone,
		m.DateOfBirth, 
		m.SearchName, 
		m.FullName
FROM	sub.tblMentor m
WHERE	EmployeeNumber IS NULL
UNION ALL 
SELECT	m.MentorID, 
		emp.Initials, 
		emp.Amidst, 
		emp.Surname, 
		emp.Gender, 
		m.Email,
		m.Phone,
		emp.DateOfBirth, 
		emp.SearchName, 
		emp.FullName
FROM	sub.tblMentor m
INNER JOIN sub.tblEmployee emp 
	ON	emp.EmployeeNumber = m.EmployeeNumber


