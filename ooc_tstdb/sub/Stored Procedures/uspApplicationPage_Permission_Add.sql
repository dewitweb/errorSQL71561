CREATE PROCEDURE [sub].[uspApplicationPage_Permission_Add]
@PageID			int,
@PermissionID	int,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose:	Connect a permission to a specific applicationpage.

	12-02-2019	Sander van Houten	Initial version (OTIBSUB-722).
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel				xml,
		@XMLins				xml,
		@LogDate			datetime = GETDATE(),
		@KeyID				varchar(50)

-- Insert new record in sub.tblApplicationPage_Permission
INSERT INTO sub.tblApplicationPage_Permission
	(
		PageID,
		PermissionID
	)
VALUES
	(
		@PageID,
		@PermissionID
	)

-- Save new data
SELECT	@XMLdel = NULL,
		@XMLins = (SELECT	* 
					FROM	sub.tblApplicationPage_Permission
					WHERE	PageID = @PageID
					  AND	PermissionID = @PermissionID
					FOR XML PATH)

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

/*	== auth.uspApplication_Permission_Add ====================================================	*/
