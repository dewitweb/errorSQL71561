
CREATE PROCEDURE [sub].[usp_OTIB_Employer_Subsidy_GracePeriod_List]
@UserID	int
AS
/*	==========================================================================================
	Purpose:	List all submitted GracePeriod requests which are not handled fully yet.

	14-01-2020	Sander van Houten	OTIBSUB-1827      Initial version.
	==========================================================================================	*/

/*	Testdata.
DECLARE @UserID	int = 4149
--*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE	@CheckPermission	bit = 0

-- Check if the current user has the permission to approve the GracePeriod request.
IF EXISTS (	SELECT  1
			FROM	auth.tblUser_Role uro
			INNER JOIN auth.tblRole_Permission rpe ON rpe.RoleID = uro.RoleID
			INNER JOIN auth.tblPermission per ON per.PermissionID = rpe.PermissionID
			WHERE	uro.UserID = @UserID
		    AND	    per.PermissionCode = 'otib-grace-period-approve')
BEGIN
	SET @CheckPermission = 1
END

IF @CheckPermission = 1
BEGIN 
	SELECT
			esg.GracePeriodID,
            emp.EmployerName
	FROM	sub.tblEmployer_Subsidy_GracePeriod esg
    INNER JOIN sub.tblEmployer_Subsidy ems ON ems.EmployerSubsidyID = esg.EmployerSubsidyID
    INNER JOIN sub.tblEmployer emp ON emp.EmployerNumber = ems.EmployerNumber
	WHERE	esg.GracePeriodStatus = '0001'
    AND     esg.CreationUserID <> @UserID
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.usp_OTIB_Employer_Subsidy_GracePeriod_List ========================================	*/
