

CREATE PROCEDURE [auth].[uspUser_Get_ByUser]
@UserID int
AS
/*	==========================================================================================
	Puspose:	Get data from auth.tblUser with UserID

	27-06-2019	Sander van Houten		OTIBSUB-1250	Added Gender.
	26-04-2019	Jaap van Assenbergh		OTIBSUB-1023	Contactgegevens wijzigen bij inlog met 
											werkgeversnummer.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		usr.UserID,
		usr.Initials,
		usr.Firstname,
		usr.Infix,
		usr.Surname,
		usr.Loginname,
		usr.Email,
		uec.Email_New,
		uec.Creation_DateTime,
		uec.EmailValidationToken,
		usr.Phone,
		usr.FunctionDescription,
		usr.Gender,
		CAST(	CASE
					WHEN uec.UserID IS NULL 
						THEN 0 
					ELSE 1 
				END 
		as bit)  CanResendEmail
FROM	auth.tblUser usr
LEFT JOIN auth.tblUser_Email_Change uec ON uec.UserID = usr.UserID
WHERE	usr.UserID = @UserID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== auth.uspUser_Get_ByUser ===============================================================	*/
