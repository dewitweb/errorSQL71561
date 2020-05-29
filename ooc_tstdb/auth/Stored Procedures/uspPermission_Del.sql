
CREATE PROCEDURE [auth].[uspPermission_Del]
@PermissionID	int,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose:	Delete a record from the table tblPermission

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
					FROM	auth.tblPermission
					WHERE	PermissionID = @PermissionID
					FOR XML PATH),
		@XMLins = NULL

-- Delete record
DELETE
FROM	auth.tblPermission
WHERE	PermissionID = @PermissionID


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

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== auth.uspPermission_Del=================================================================	*/
