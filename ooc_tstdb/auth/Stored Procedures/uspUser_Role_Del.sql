
CREATE PROCEDURE [auth].[uspUser_Role_Del]
@UserID			int,
@RoleID			int,
@CurrentUserID	int
AS
/*	==========================================================================================
	Puspose:	Delete a specific role connection for a specific user

	01-05-2018	Sander van Houten	Initial version
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

-- Save old record
SELECT	@XMLdel = (SELECT	* 
					FROM	auth.tblUser_Role
					WHERE	UserID = @UserID
					  AND   RoleID = @RoleID
					FOR XML PATH),
		@XMLins = NULL

-- Delete record
DELETE
FROM	auth.tblUser_Role
WHERE	UserID = @UserID
  AND   RoleID = @RoleID

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

/*	== auth.uspUser_Role_Del =================================================================	*/
