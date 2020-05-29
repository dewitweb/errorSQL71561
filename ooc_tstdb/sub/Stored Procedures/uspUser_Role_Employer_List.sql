
CREATE PROCEDURE [sub].[uspUser_Role_Employer_List]
@UserID		int,
@RoleID		int
AS
/*	==========================================================================================
	Puspose:	Get all employers that the user is connected to.

	19-11-2018	Sander van Houten	Initial version (OTIBSUB-98).
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

	SELECT
			emp.EmployerName + ' (' + uro.EmployerNumber + ')'	AS LinkedEmployer
	FROM	sub.tblUser_Role_Employer uro
	INNER JOIN sub.tblEmployer emp
	ON		emp.EmployerNumber = uro.EmployerNumber
	WHERE	uro.UserID = @UserID
	  AND	uro.RoleID = @RoleID
	  AND	uro.RequestApproved IS NOT NULL
	ORDER BY 1

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== auth.uspUser_Role_Employer_List =======================================================	*/
