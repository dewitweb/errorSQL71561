CREATE VIEW [sub].[viewUserEmailEmployer]
AS

SELECT	emp.EmployerNumber,
		usr.UserID,
		CASE ISNULL(usr.Email, '')
			WHEN '' THEN ISNULL(emp.Email, '')
			ELSE usr.Email
		END									AS Email,
		ISNULL(usr.Email, '')				AS Email_DSUser,
		ISNULL(emp.Email, '')				AS Email_MNemployer
FROM	sub.tblEmployer emp
INNER JOIN sub.tblUser_Role_Employer ure ON ure.EmployerNumber = emp.EmployerNumber
INNER JOIN auth.tblUser usr ON usr.UserID = ure.UserID
