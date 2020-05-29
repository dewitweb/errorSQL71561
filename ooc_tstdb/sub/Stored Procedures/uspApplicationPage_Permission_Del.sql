CREATE PROCEDURE [sub].[uspApplicationPage_Permission_Del]
@PageID			int,
@PermissionID	int,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Puspose:	Delete a specific permission connection for a specific applicationpage.

	12-02-2019	Sander van Houten	Initial version (OTIBSUB-722).
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

-- Save old record
SELECT	@XMLdel = (SELECT	* 
					FROM	sub.tblApplicationPage_Permission
					WHERE	PageID = @PageID
					  AND	PermissionID = @PermissionID
					FOR XML PATH),
		@XMLins = NULL

-- Delete record
DELETE
FROM	sub.tblApplicationPage_Permission
WHERE	PageID = @PageID
  AND	PermissionID = @PermissionID

-- Log action in tblHistory
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = CAST(@PageID AS varchar(18)) + '|' + CAST(@PermissionID AS varchar(18))

	EXEC his.uspHistory_Add
			'sub.tblApplicationPage_Permission',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspApplicationPage_Permission_Del =================================================	*/
