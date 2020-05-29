CREATE PROCEDURE [auth].[uspUser_Upd]
@UserID					int,
@Initials				varchar(15),
@Firstname				varchar(50),
@Infix					varchar(15),
@Surname				varchar(50),
@Email					varchar(50),
@Phone					varchar(15),
@Loginname				varchar(50),
@PasswordHash			nvarchar(62),
@PasswordChangeCode		nvarchar(62),
@PasswordMustChange		bit,
@PasswordExpirationDate date,
@PasswordFailedAttempts tinyint,
@IsLockedOut			datetime,
@Active					bit,
@FunctionDescription	varchar(100),
@Gender					varchar(1),
@CurrentUserID			int = 1
AS
/*	==========================================================================================
	Purpose:	Insert or update a record the table tblUser

	12-07-2019	Sander van Houten		OTIBSUB-1075	Added parameter @Gender.
	21-11-2018	Sander van Houten		OTIBSUB-448		Added parameter @FunctionDescription.
	01-05-2018	Sander van Houten		Conversion from uspGebruiker_Upd for new datamodel
	01-05-2018	Sander van Houten		Veld PasswordChangeCode toegevoegd op verzoek van Niek
	23-04-2018	Sander van Houten		ERGP-73			History vastleggen in database
	05-03-2018	Sander van Houten		Initial version.
	==========================================================================================	*/

--DECLARE @ExecutedProcedureID int = 0
--EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF ISNULL(@UserID, 0) = 0
BEGIN
	-- Insert new record in auth.tblUser
	INSERT INTO auth.tblUser
		(
			Initials,
			Firstname,
			Infix,
			Surname,
			Email,
			Phone,
			Loginname,
			PasswordHash,
			PasswordChangeCode,
			PasswordMustChange,
			PasswordExpirationDate,
			PasswordFailedAttempts,
			IsLockedOut,
			Active,
			FunctionDescription,
			Gender
		)
	VALUES
		(
			@Initials,
			@Firstname,
			@Infix,
			@Surname,
			@Email,
			@Phone,
			@Loginname,
			@PasswordHash,
			@PasswordChangeCode,
			ISNULL(@PasswordMustChange, 0),
			@PasswordExpirationDate,
			@PasswordFailedAttempts,
			@IsLockedOut,
			ISNULL(@Active, 0),
			@FunctionDescription,
			@Gender
		)

	-- Retrieve added ID
	SET	@UserID = SCOPE_IDENTITY()

	-- Save new data
	SELECT	@XMLdel = NULL,
			@XMLins = (SELECT	* 
					   FROM		auth.tblUser
					   WHERE	UserID = @UserID
					   FOR XML PATH)
END
ELSE
BEGIN
	-- Save old record
	SELECT	@XMLdel = (SELECT	* 
					   FROM		auth.tblUser
					   WHERE	UserID = @UserID
					   FOR XML PATH)

	-- Update exisiting record
	UPDATE auth.tblUser
	SET
			Initials				= @Initials,
			Firstname				= @Firstname,
			Infix					= @Infix,
			Surname					= @Surname,
			Email					= @Email,
			Phone					= @Phone,
			Loginname				= @Loginname,
			PasswordHash			= @PasswordHash,
			PasswordChangeCode		= @PasswordChangeCode,
			PasswordMustChange		= ISNULL(@PasswordMustChange, 0),
			PasswordExpirationDate	= @PasswordExpirationDate,
			PasswordFailedAttempts	= @PasswordFailedAttempts,
			IsLockedOut				= @IsLockedOut,
			Active					= ISNULL(@Active, 0),
			FunctionDescription		= @FunctionDescription,
			Gender					= @Gender
	WHERE UserID = @UserID

	-- Save new record
	SELECT	@XMLins = (SELECT	* 
					   FROM		auth.tblUser
					   WHERE	UserID = @UserID
					   FOR XML PATH)
END

-- Log action in tblHistory
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @UserID

	EXEC his.uspHistory_Add
			'auth.tblUser',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

-- Return NewID
SELECT UserId = @UserID

--EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

RETURN 0



/*	== auth.uspUser_Upd ======================================================================	*/
