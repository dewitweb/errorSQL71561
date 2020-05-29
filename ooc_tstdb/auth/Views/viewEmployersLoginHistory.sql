CREATE VIEW auth.viewEmployersLoginHistory
AS
SELECT	TOP 10000000
		uls.RecordID,
		uls.UserID,
		uls.LastLogin,
		uls.LastLogout,
		usr.Loginname,
		usr.Initials,
		usr.Firstname,
		usr.Infix,
		usr.Surname,
		usr.Phone,
		usr.FunctionDescription,
		uva.ContactDetailsCheck,
		uva.AgreementCheck,
		uva.EmailCheck,
		uva.EmailValidationDateTime
FROM	auth.tblUserLoginStatus_History uls
INNER JOIN auth.tblUser usr ON usr.UserID = uls.UserID
LEFT JOIN auth.tblUserValidation uva ON uva.UserID = usr.UserID
WHERE	LEN(usr.Loginname) = 6
ORDER BY 1