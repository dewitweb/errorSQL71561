CREATE PROCEDURE [auth].[uspApplication_Del]
@ApplicationID	int,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose:	Delete a record from the table tblApplication

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
					FROM	auth.tblApplication
					WHERE	ApplicationID = @ApplicationID
					FOR XML PATH),
		@XMLins = NULL

-- Delete record
DELETE
FROM	auth.tblApplication
WHERE	ApplicationID = @ApplicationID

-- Log action in tblHistory
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @ApplicationID

	EXEC his.uspHistory_Add
			'auth.tblApplication',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== auth.uspApplication_Del ===============================================================	*/
