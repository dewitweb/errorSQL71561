CREATE PROCEDURE [auth].[uspUser_Upd_ByUser]
@UserID					int,
@Initials				varchar(15),
@Firstname				varchar(50),
@Infix					varchar(15),
@Surname				varchar(50),
@Email					varchar(50),
@Phone					varchar(15),
@Gender					varchar(1),
@FunctionDescription	varchar(100),
@EmailValidationToken	varchar(50)
AS
/*	==========================================================================================
	Purpose:	Update a record in auth.tblUser by the employer.

	12-07-2019	Sander van Houten		OTIBSUB-1075	Added parameter @Gender.
	11-07-2019	Sander van Houten		OTIBSUB-1075	Moved Horus update to hrs.uspHorusContactPerson_Upd. 
	21-06-2019	Sander van Houten		OTIBSUB-1075	Update Horus. 
	26-04-2019	Jaap van Assenbergh		OTIBSUB-1023	Contactgegevens wijzigen bij inlog met 
											werkgeversnummer.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Testdata.
DECLARE @UserID					int = 46185,
		@Initials				varchar(15) = 'H.A.',
		@Firstname				varchar(50) = 'Hetty',
		@Infix					varchar(15) = NULL,
		@Surname				varchar(50) = 'Linstra',
		@Email					varchar(50) = 'Contactpersoon@otib.nl',
		@Phone					varchar(15) = '0599-613427',
		@Gender					varchar(1) = 'V',
		@FunctionDescription	varchar(100) = 'Medewerker personeelszaken',
		@EmailValidationToken	varchar(50) = 'test'
--	*/

--	Declare variables.
DECLARE @RC						int,
		@Email_Old				varchar(50),
		@Loginname				varchar(50),
		@PasswordHash			nvarchar(62),
		@PasswordChangeCode		nvarchar(62),
		@PasswordMustChange		bit,
		@PasswordExpirationDate date,
		@PasswordFailedAttempts tinyint,
		@IsLockedOut			datetime,
		@Active					bit,
		@NewContact				bit = 0

DECLARE @SQL			varchar(max),
		@Result			varchar(8000),
		@FinalResult	varchar(50) = 'Goed',
		@cpn_id			varchar(10),
		@ErrorNumber	int,
		@ErrorLine		int,
		@ErrorMessage	varchar(200)

DECLARE @tblResult TABLE (Result xml)

--	Retrieve current data.
SELECT 	@Email_Old = Email,
		@Loginname = Loginname,
		@PasswordHash = PasswordHash,
		@PasswordChangeCode = PasswordChangeCode,
		@PasswordMustChange = PasswordMustChange,
		@PasswordExpirationDate = PasswordExpirationDate,
		@PasswordFailedAttempts = PasswordFailedAttempts,
		@IsLockedOut = IsLockedOut,
		@Active = Active
FROM	auth.tblUser
WHERE	UserID = @UserID

/*	Update User record.	*/
EXECUTE	auth.uspUser_Upd
			@UserID,
			@Initials,
			@Firstname,
			@Infix,
			@Surname,
			@Email_Old,
			@Phone,
			@Loginname,
			@PasswordHash,
			@PasswordChangeCode,
			@PasswordMustChange,
			@PasswordExpirationDate,
			@PasswordFailedAttempts,
			@IsLockedOut,
			@Active,
			@FunctionDescription,
			@Gender,
			@UserID

/*	Check on e-mailaddress.	*/
IF @Email <> @Email_Old
BEGIN
	--	Insert or Update tblUser_Email_Change record if e-mailaddress has changed.
	IF	(
			SELECT	COUNT(UserID)
			FROM	auth.tblUser_Email_Change
			WHERE	UserID = @UserID
		) = 0
	BEGIN
		INSERT INTO auth.tblUser_Email_Change 
			(UserID, Email_Old, Email_New, Creation_UserID, EmailValidationToken)
		VALUES
			(@UserID, @Email_Old, @Email, @UserID, @EmailValidationToken)
	END
	ELSE
	BEGIN
		UPDATE	auth.tblUser_Email_Change 
		SET		Email_New = @Email,
				Creation_DateTime = GETDATE(),
				EmailValidationToken = @EmailValidationToken
		WHERE	UserID = @UserID
	END
END
ELSE 
BEGIN		
	-- Delete tblUser_Email_Change records when new e-mailaddress is equal to the current e-mailaddress.
	DELETE	
	FROM	auth.tblUser_Email_Change
	WHERE	UserID = @UserID
END

/*	Update Horus (OTIBSB-1075).	*/
EXECUTE @RC = [hrs].[uspHorusContactPerson_Upd] 
	@Loginname,
	@UserID,
	@Initials,
	@Firstname,
	@Infix,
	@Surname,
	@Email,
	@Phone,
	@Gender

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== auth.uspUser_Upd_ByUser ===============================================================	*/
