
CREATE PROCEDURE [auth].[uspPermission_Upd]
@PermissionID			int,
@PermissionCode			varchar(50),
@PermissionDescription	varchar(100),
@ApplicationID			int = -1,
@CurrentUserID			int = 1
AS
/*	==========================================================================================
	Purpose:	Insert or update a record in the table tblPermission

	01-05-2018	Sander van Houten	Initial version
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF ISNULL(@PermissionID, 0) = 0
BEGIN
	INSERT INTO auth.tblPermission
		(
			PermissionCode,
			PermissionDescription_EN,
			PermissionDescription_NL,
			ApplicationID
		)
	VALUES
		(
			@PermissionCode,
			@PermissionDescription,
			@PermissionDescription,
			@ApplicationID
		)

	SET	@PermissionID = SCOPE_IDENTITY()

	-- Save new data
	SELECT	@XMLdel = NULL,
			@XMLins = (SELECT	* 
					   FROM		auth.tblPermission
					   WHERE	PermissionID = @PermissionID
					   FOR XML PATH)
END
ELSE
BEGIN
	-- Save old record
	SELECT	@XMLdel = (SELECT	* 
					   FROM		auth.tblPermission
					   WHERE	PermissionID = @PermissionID
					   FOR XML PATH)

	-- Update exisiting record
	UPDATE	auth.tblPermission
	SET		PermissionCode = @PermissionCode,
			PermissionDescription_EN = @PermissionDescription,
			PermissionDescription_NL = @PermissionDescription,
			ApplicationID = @ApplicationID
	WHERE	PermissionID = @PermissionID

	-- Save new record
	SELECT	@XMLins = (SELECT	* 
					   FROM		auth.tblPermission
					   WHERE	PermissionID = @PermissionID
					   FOR XML PATH)
END

-- Log action in tblHistory
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @PermissionID

	EXEC his.uspHistory_Add
			'auth.tblPermission',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SELECT PermissionID = @PermissionID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== auth.uspPermission_Upd ================================================================	*/