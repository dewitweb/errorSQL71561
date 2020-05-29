
CREATE PROCEDURE [auth].[uspUserLoginStatus_Upd]
 @UserID			int,
 @LastLogin			datetime,
 @LastLogout		datetime,
 @LoggedIn			bit,
 @UserAgentString	varchar(255)
AS
/*	==========================================================================================
	Purpose:	Insert or update a record in the table tblUserLoginStatus

	21-05-2019	Jaap van Assenbergh	OTIBSUB-1098 Bij inloggen gebruiker de user agent loggen
	29-11-2018	Sander van Houten	Het bijwerken van de tabel auth.tblUserLoginStatus_History
									toegevoegd
	01-05-2018	Sander van Houten	Conversion from uspUserLoginStatus_Upd for new datamodel
	21-03-2018	Sander van Houten   Bijwerken auth.tblGebruikerInlogStatus op basis van GebruikerID
	========================================================================================== */

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

IF NOT EXISTS (	SELECT	1 
				FROM	auth.tblUserLoginStatus 
				WHERE	UserID = ISNULL(@UserID, 0))
BEGIN
	-- Insert record into auth.tblUserLoginStatus.
	INSERT INTO auth.tblUserLoginStatus
		(
			UserID,
			LastLogin,
			LastLogout,
			LoggedIn
		)
	VALUES
		(
			@UserID,
			@LastLogin,
			@LastLogout,
			@LoggedIn
		)

	-- Insert record into auth.tblUserLoginStatus_History.
	INSERT INTO auth.tblUserLoginStatus_History
		(
			UserID,
			LastLogin,
			LastLogout,
			UserAgentString
		)
	VALUES
		(
			@UserID,
			@LastLogin,
			@LastLogout,
			@UserAgentString
		)
END
ELSE
BEGIN
	-- First update or add record in auth.tblUserLoginStatus_History.
	IF EXISTS (	SELECT	1
				FROM	auth.tblUserLoginStatus_History
				WHERE	UserID = @UserID
				  AND	LastLogin = @LastLogin)
	BEGIN
		UPDATE	auth.tblUserLoginStatus_History
		SET		LastLogout = @LastLogout
		WHERE	UserID = @UserID
		  AND	LastLogin = @LastLogin
	END
	ELSE
	BEGIN
		INSERT INTO auth.tblUserLoginStatus_History
			(
				UserID,
				LastLogin,
				LastLogout,
				UserAgentString
			)
		VALUES
			(
				@UserID,
				@LastLogin,
				@LastLogout,
				@UserAgentString
			)
	END

	-- Then update the record in auth.tblUserLoginStatus.
	UPDATE	auth.tblUserLoginStatus
	SET		LastLogin = @LastLogin,
			LastLogout = @LastLogout,
			LoggedIn = @LoggedIn
	WHERE	UserID = @UserID
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/* == auth.uspUserLoginStatus_Upd ============================================================  */
