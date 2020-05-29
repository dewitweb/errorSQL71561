
CREATE PROCEDURE [auth].[uspUser_Get_ByLoginname]
@Loginname varchar(50)
AS
/*	==========================================================================================
	Purpose:	Get data from auth.tblUser with Loginname

	27-06-2019	Sander van Houten		OTIBSUB-1250	Added Gender.
	26-11-2018	Jaap van Assenbergh		Zoeken op login.
	19-07-2018	Jaap van Assenbergh		Zoeken op login en Email.
	01-05-2018	Sander van Houten		Conversion from uspGebruiker_Get_ByInlognaam 
											for new datamodel.
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
	WHERE	usr.Loginname = @Loginname

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== auth.uspUser_Get_ByLoginname ==========================================================	*/
