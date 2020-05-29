CREATE PROCEDURE [auth].[uspUser_Password_Change_Get]
@PasswordChangeID   int
AS
/*	==========================================================================================
	Purpose:	Get specific password change record.

    Notes:      The password (old and new) are saved encrypted.

	04-12-2019	Sander van Houten		OTIBSUB-1565    Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/* Testdata.
DECLARE @PasswordChangeID   int = 1
-- */

-- First, open the symmetric key with which to decrypt the data.  
OPEN SYMMETRIC KEY SSN_Key_01  
   DECRYPTION BY CERTIFICATE EncryptedSetting001;  

-- Then, return the data.
SELECT
        [EmployerNumber],
        [Email],
        [PasswordResetToken],
        [Creation_DateTime],
        [ValidUntil],
		[UserID],
        CONVERT(varchar(128), DecryptByKey([Password_New])) AS Password_New,
        [SendToHorus],
        [ResultFromHorus],
        [ChangeSuccessful]
FROM	auth.tblUser_Password_Change
WHERE	PasswordChangeID = @PasswordChangeID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== auth.uspUser_Password_Change_Get ======================================================	*/
