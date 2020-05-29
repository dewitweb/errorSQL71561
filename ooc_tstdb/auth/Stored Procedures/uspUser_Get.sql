
CREATE PROCEDURE [auth].[uspUser_Get]
@UserID int
AS
/*	==========================================================================================
	Puspose:	Get data from auth.tblUser with UserID

	27-06-2019	Sander van Houten		OTIBSUB-1250	Added Gender.
	01-05-2018	Sander van Houten		Conversion from uspGebruiker_Get for new datamodel.
	01-05-2018	Sander van Houten		Veld WachtwoordWijzigCode toegevoegd op verzoek van Niek.
	05-03-2018	Sander van Houten		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

	SELECT
			usr.UserID,
			usr.Initials,
			usr.Firstname,
			usr.Infix,
			usr.Surname,
			usr.Email,
			usr.Phone,
			usr.Loginname,
			usr.PasswordHash,
			usr.PasswordChangeCode,
			usr.PasswordMustChange,
			usr.PasswordExpirationDate,
			usr.PasswordFailedAttempts,
			usr.IsLockedOut,
			usr.Active,
			usr.Fullname,
			usr.FunctionDescription,
			usr.Gender
	FROM	auth.tblUser usr
	WHERE	usr.UserID = @UserID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== auth.uspUser_Get ======================================================================	*/
