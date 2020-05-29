
CREATE PROCEDURE [auth].[uspUser_Role_Add]
@UserID			int,
@RoleID			int,
@CurrentUserID	int
AS
/*	==========================================================================================
	Purpose:	Connect a role to a specific user

	01-05-2018	Sander van Houten	Initial version
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

-- Insert new record in auth.tblUser_Role
INSERT INTO auth.tblUser_Role
	(
		UserID,
		RoleID
	)
VALUES
	(
		@UserID,
		@RoleID
	)

-- Save new data
SELECT	@XMLdel = NULL,
		@XMLins = (SELECT	* 
					FROM	auth.tblUser_Role
					WHERE	UserID = @UserID
					  AND	RoleID = @RoleID
					FOR XML PATH)

-- Log action in tblHistory
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = CAST(@UserID AS varchar(18)) + '|' + CAST(@RoleID AS varchar(18))

	EXEC his.uspHistory_Add
			'auth.tblUser_Role',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== auth.uspUserRole_Add ==================================================================	*/
