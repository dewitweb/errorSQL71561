CREATE PROCEDURE [auth].[uspUser_Upd_Email]
@UserID					int,
@CurrentUserID			int = 1
AS
/*	==========================================================================================
	Purpose:	Update a email in the table tblUser after validation

	26-04-2019	Jaap van Assenbergh OTIBSUB-1023 Contactgegevens wijzigen bij inlog met 
									werkgeversnummer
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

BEGIN
	-- Save old record
	SELECT	@XMLdel = (SELECT	* 
					   FROM		auth.tblUser
					   WHERE	UserID = @UserID
					   FOR XML PATH)

	UPDATE auth.tblUser
	SET
			Email				= Email_New
	FROM	auth.tblUser u
	INNER JOIN auth.tblUser_Email_Change uec ON uec.UserID = u.UserID
	WHERE	u.UserID = @UserID

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

DELETE	FROM auth.tblUser_Email_Change
WHERE	UserID = @UserID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

RETURN 0

/*	== auth.uspUser_Upd_Email ================================================================	*/
