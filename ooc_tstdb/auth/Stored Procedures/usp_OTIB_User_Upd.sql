CREATE PROCEDURE [auth].[usp_OTIB_User_Upd]
@UserID					int,
@Initials				varchar(15),
@Firstname				varchar(50),
@Infix					varchar(15),
@Surname				varchar(50),
@Email					varchar(50),
@Phone					varchar(15),
@Loginname				varchar(50),
@Active					bit,
@CurrentUserID			int = 1
AS
/*	==========================================================================================
	Purpose:	Insert or update a record the table auth.tblUser.

	Note:		Some fields that are present in the table are never updated via the user 
				interface. Therefor this version is made.

	06-02-2019	Sander van Houten		Initial version (OTIBSUB-777)
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

DECLARE @PasswordHash			nvarchar(62) = 'Leeg',
		@PasswordChangeCode		nvarchar(62) = NULL,
		@PasswordMustChange		bit = 0,
		@PasswordExpirationDate date = NULL,
		@PasswordFailedAttempts tinyint = NULL,
		@IsLockedOut			datetime = NULL,
		@FunctionDescription	varchar(100) = NULL

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
			FunctionDescription
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
			@PasswordMustChange,
			@PasswordExpirationDate,
			@PasswordFailedAttempts,
			@IsLockedOut,
			ISNULL(@Active, 0),
			@FunctionDescription
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
			Active					= ISNULL(@Active, 0)
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

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

RETURN 0

/*	== auth.usp_OTIB_User_Upd ================================================================	*/
