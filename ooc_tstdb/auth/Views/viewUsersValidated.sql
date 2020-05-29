




CREATE VIEW [auth].[viewUsersValidated]
AS
SELECT	DISTINCT
		usr.UserID,
		usr.Email,
		usr.Loginname,
		usr.Fullname
FROM	auth.tblUser usr
INNER JOIN auth.tblUserValidation usv ON usv.UserID = usr.UserID
INNER JOIN auth.tblUserLoginStatus_History usl ON usl.UserID = usr.UserID
WHERE	usr.Active = 1
  AND	usv.EmailCheck = 1