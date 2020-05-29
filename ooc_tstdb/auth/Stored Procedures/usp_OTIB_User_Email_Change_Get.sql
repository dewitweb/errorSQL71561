CREATE PROCEDURE [auth].[usp_OTIB_User_Email_Change_Get]
@UserEmailChangeID  int
AS
/*	==========================================================================================
	Purpose:	Get the details of an e-mail change from the table auth.tblUser_Email_Change.

	16-12-2019	Sander van Houten	OTIBSUB-1762    Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

-- Get record from auth.tblUser_Email_Change
SELECT  uec.UserID,
        uec.Email_Old,
        uec.Email_New,
        emp.EmployerNumber,
        emp.EmployerName,
        uec.Creation_UserID,
        cru.Fullname    AS Creation_UserName,
        uec.Creation_DateTime,
        uec.EmailValidationToken,
        uec.Validation_UserID,
        uec.Validation_DateTime,
        uec.Validation_Result,
        uec.Validation_Reason
FROM    auth.tblUser_Email_Change uec
INNER JOIN auth.tblUser usr ON usr.UserID = uec.UserID
INNER JOIN sub.tblEmployer emp ON emp.EmployerNumber = usr.Loginname
INNER JOIN auth.tblUser cru ON cru.UserID = uec.Creation_UserID
WHERE   uec.UserEmailChangeID = @UserEmailChangeID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

RETURN 0

/*	== auth.usp_OTIB_User_Email_Change_Get ===================================================	*/