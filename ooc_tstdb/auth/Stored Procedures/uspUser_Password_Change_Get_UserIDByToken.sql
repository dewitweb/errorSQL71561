CREATE PROCEDURE [auth].[uspUser_Password_Change_Get_UserIDByToken]
@PasswordResetToken varchar(50)
AS
/*	==========================================================================================
	Purpose:	Get UserID from specific password change record through given token.

    Notes:      Returns the UserID if the token is (still) valid.
                This procedure is executed by the front-end.

	04-12-2019	Sander van Houten		OTIBSUB-1565    Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/* Testdata.
DECLARE @PasswordResetToken varchar(50) = '8724393yuronlkfgnvh984'
-- */

SELECT  UserID
FROM	auth.tblUser_Password_Change
WHERE	PasswordResetToken = @PasswordResetToken
AND     ValidUntil >= GETDATE()
AND     Password_New IS NULL

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== auth.uspUser_Password_Change_Get_UserIDByToken ========================================	*/
