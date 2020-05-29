CREATE PROCEDURE [auth].[usp_OTIB_User_Email_Change_Add]
@Loginname		varchar(50),
@Email_New  	varchar(50),
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose:	Insert a record the table auth.tblUser_Email_Change.

	Note:		

	11-12-2019	Sander van Houten	OTIBSUB-1762    Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*  Testdata.
DECLARE @Loginname		varchar(50) = '000007',
        @Email_New		varchar(50) = 'nieuw@email.nl',
        @CurrentUserID	int = 1
--  */

DECLARE @UserEmailChangeID  int

-- Insert new record in auth.tblUser_Email_Change.
INSERT INTO auth.tblUser_Email_Change
    (
        UserID,
        Email_Old,
        Email_New,
        Creation_UserID,
        Creation_DateTime,
        EmailValidationToken
    )
SELECT  UserID,
        Email,
        @Email_New,
        @CurrentUserID,
        GETDATE(),
        'E-mail adres vergeten'
FROM    auth.tblUser
WHERE   Loginname = @Loginname

SET @UserEmailChangeID = SCOPE_IDENTITY()

SELECT UserEmailChangeID = @UserEmailChangeID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

RETURN 0

/*	== auth.usp_OTIB_User_Email_Change_Add ===================================================	*/
