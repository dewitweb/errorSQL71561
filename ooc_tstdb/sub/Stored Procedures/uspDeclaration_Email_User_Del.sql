
CREATE PROCEDURE [sub].[uspDeclaration_Email_User_Del]
@EmailID		int,
@UserID			int
AS
/*	==========================================================================================
	Purpose:	Remove Declaration_Email_User record.

	02-08-2018	Sander van Houten		Initial version (OTIBSUB-85).
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

-- Save old record
SELECT	@XMLdel = (SELECT	* 
					FROM	sub.tblDeclaration_Email_User
					WHERE	EmailID = @EmailID
					  AND	UserID = @UserID
					FOR XML PATH),
		@XMLins = NULL

-- Delete record
DELETE
FROM	sub.tblDeclaration_Email_User
WHERE	EmailID = @EmailID
  AND	UserID = @UserID

-- Log action in tblHistory
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = CAST(@EmailID AS varchar(18)) + '|' + CAST(@UserID AS varchar(18))

	EXEC his.uspHistory_Add
			'auth.tblDeclaration_Email_User',
			@KeyID,
			@UserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Email_User_Del =====================================================	*/
