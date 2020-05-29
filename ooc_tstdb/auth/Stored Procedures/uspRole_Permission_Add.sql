
CREATE PROCEDURE [auth].[uspRole_Permission_Add]
@RoleID			int,
@PermissionID	int,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose:	Connect a permission to a specific role

	01-05-2018	Sander van Houten	Initial version
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel				xml,
		@XMLins				xml,
		@LogDate			datetime = GETDATE(),
		@KeyID				varchar(50)

-- Insert new record in auth.tblRole_Permission
INSERT INTO auth.tblRole_Permission
	(
		RoleID,
		PermissionID
	)
VALUES
	(
		@RoleID,
		@PermissionID
	)

-- Save new data
SELECT	@XMLdel = NULL,
		@XMLins = (SELECT	* 
					FROM	auth.tblRole_Permission
					WHERE	RoleID = @RoleID
					  AND	PermissionID = @PermissionID
					FOR XML PATH)

-- Log action in tblHistory
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = CAST(@RoleID AS varchar(18)) + '|' + CAST(@PermissionID AS varchar(18))

	EXEC his.uspHistory_Add
			'auth.tblRole_Permission',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== auth.uspRolePermission_Add ============================================================	*/
