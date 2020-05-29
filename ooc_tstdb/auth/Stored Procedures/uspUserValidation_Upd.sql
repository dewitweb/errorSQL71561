CREATE PROCEDURE [auth].[uspUserValidation_Upd]
@UserID						int,
@ContactDetailsCheck		bit,
@AgreementCheck				bit,
@EmailCheck					bit,
@EmailValidationToken		varchar(50),
@EmailValidationDateTime	datetime,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose: 	Update auth.tblUserValidation on basis of UserID.

	24-05-2019	Sander van Houten		OTIBSUB-704		Signal Horus that the agreementcheck is 
											valitated by the user.
	21-11-2018	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Return				int = 1,
		@AgreementCheckPrev	bit = 0

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF (
	SELECT	UserID 
	FROM	tblUserValidation 
	WHERE	UserID = @UserID) IS NULL
BEGIN
	-- Add new record
	INSERT INTO auth.tblUserValidation
		(
			UserID,
			ContactDetailsCheck,
			AgreementCheck,
			EmailCheck,
			EmailValidationToken,
			EmailValidationDateTime
		)
	VALUES
		(
			@UserID,
			@ContactDetailsCheck,
			@AgreementCheck,
			@EmailCheck,
			@EmailValidationToken,
			@EmailValidationDateTime
		)

	-- Save new record.
	SELECT	@XMLdel = NULL,
			@XMLins = (	SELECT 	*
						FROM	auth.tblUserValidation
						WHERE	UserID = @UserID
						FOR XML PATH )

END
ELSE
BEGIN
	-- Save old record.
	SELECT	@XMLdel = (	SELECT 	*
						FROM	auth.tblUserValidation
						WHERE	UserID = @UserID
						FOR XML PATH )

	-- Save previous status of AgreementCheck.
	SELECT 	@AgreementCheckPrev = AgreementCheck
	FROM	auth.tblUserValidation
	WHERE	UserID = @UserID

	-- Update existing record.
	UPDATE	auth.tblUserValidation
	SET		ContactDetailsCheck		= @ContactDetailsCheck,
			AgreementCheck			= @AgreementCheck,
			EmailCheck				= @EmailCheck,
			EmailValidationToken	= @EmailValidationToken,
			EmailValidationDateTime	= @EmailValidationDateTime
	WHERE	UserID = @UserID

	-- Save new record.
	SELECT	@XMLins = (	SELECT 	*
						FROM	auth.tblUserValidation
						WHERE	UserID = @UserID
						FOR XML PATH )
END

-- Log action in his.tblHistory.
IF CAST(ISNULL(@XMLdel, '') AS varchar(MAX)) <> CAST(ISNULL(@XMLins, '') AS varchar(MAX))
BEGIN
	SET @KeyID = @UserID

	EXEC his.uspHistory_Add
			'auth.tblUserValidation',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

-- If AgreementCheck is validated in this update, signal Horus of the event.
IF @AgreementCheck = 1 AND @AgreementCheckPrev = 0
AND EXISTS(SELECT 1 FROM sys.servers WHERE NAME = N'HORUS_P')
BEGIN
	DECLARE @SQL			varchar(max),
			@Result			varchar(8000),
			@EmployerNumber	varchar(8)

	SELECT	@EmployerNumber = Loginname
	FROM	auth.tblUser
	WHERE	UserID = @UserID

	SET	@SQL = 'BEGIN ? :=OLCOWNER.HRS_PCK_OTIBDS.WGR_AKKOORD_OVEREENKOMST_OO('
				+ '''' + @EmployerNumber + ''', '
				+ '''Ja'''
				+ '); END;'

	IF DB_NAME() = 'OTIBDS'
		EXEC(@SQL, @Result OUTPUT) AT HORUS_P
	ELSE
		EXEC(@SQL, @Result OUTPUT) AT HORUS_A

	-- Save old record.
	SELECT	@XMLdel = (	SELECT 	*
						FROM	auth.tblUserValidation
						WHERE	UserID = @UserID
						FOR XML PATH )

	-- Update existing record.
	UPDATE	auth.tblUserValidation
	SET		HorusUpdated = @LogDate,
			HorusResult = @Result
	WHERE	UserID = @UserID

	-- Save new record.
	SELECT	@XMLins = (	SELECT 	*
						FROM	auth.tblUserValidation
						WHERE	UserID = @UserID
						FOR XML PATH )
END

SELECT UserID = @UserID

SET @Return = 0

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

RETURN @Return

/*	== auth.uspUserValidation_Upd ============================================================	*/
