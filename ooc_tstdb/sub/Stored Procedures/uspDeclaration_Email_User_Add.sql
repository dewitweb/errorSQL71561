
CREATE PROCEDURE [sub].[uspDeclaration_Email_User_Add]
@EmailID		int,
@UserID			int
AS
/*	==========================================================================================
	Purpose:	Add Declaration_Email_User record.

	02-08-2018	Sander van Houten		Initial version (OTIBSUB-85).
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

IF (SELECT	COUNT(1)
	FROM	sub.tblDeclaration_Email_User
	WHERE	EmailID = @EmailID
	  AND	UserID = @UserID) = 0
BEGIN
	INSERT INTO sub.tblDeclaration_Email_User
		(
			EmailID,
			UserID,
			HandledDate
		)
	VALUES
		(
			@EmailID,
			@UserID,
			GETDATE()
		)
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Email_User_Add ========================================================	*/
