CREATE PROCEDURE [auth].[usp_OTIB_User_Email_Change_List]
@CurrentUserID  int
AS
/*	==========================================================================================
	Purpose:	Lists open changes from the table auth.tblUser_Email_Change.

	Note:		An open change has the following criteria:
                - EmailValidationToken is filles with 'E-mail adres vergeten'.
                - Validation_UserID is NULL.

	11-12-2019	Sander van Houten	OTIBSUB-1762    Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

-- Get records from auth.tblUser_Email_Change
SELECT  uec.UserEmailChangeID,
        emp.EmployerName
FROM    auth.tblUser_Email_Change uec
INNER JOIN auth.tblUser usr ON usr.UserID = uec.UserID
INNER JOIN sub.tblEmployer emp ON emp.EmployerNumber = usr.Loginname
WHERE   uec.EmailValidationToken = 'E-mail adres vergeten'
AND     uec.Validation_UserID IS NULL
AND     uec.Creation_UserID <> @CurrentUserID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

RETURN 0

/*	== auth.usp_OTIB_User_Email_Change_List ==================================================	*/
