CREATE VIEW [sub].[viewEmployerEmail]
AS

SELECT	emp.EmployerNumber,
		CASE ISNULL(emp.Email, '')
			WHEN '' THEN CASE ISNULL(usr.Email, '')
							WHEN '' THEN CASE ISNULL(wgr.Email_ContactPerson, '')
											WHEN '' THEN wgr.Email
											ELSE wgr.Email_ContactPerson
										 END
									ELSE usr.Email
						 END
			ELSE emp.Email
		END									AS Email,
		ISNULL(usr.Email, '')				AS Email_DSUser,
		ISNULL(emp.Email, '')				AS Email_MNemployer,
		wgr.Email							AS Email_HorusEmployer,
		ISNULL(wgr.Email_ContactPerson, '')	AS Email_HorusContactPerson,
		usr.UserID
FROM	sub.tblEmployer emp
LEFT JOIN auth.viewUsersValidated usr ON usr.Loginname = emp.EmployerNumber
LEFT JOIN hrs.tblWGR wgr ON wgr.EmployerNumber = emp.EmployerNumber
