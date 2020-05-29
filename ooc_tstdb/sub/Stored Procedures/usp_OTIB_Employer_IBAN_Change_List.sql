
CREATE PROCEDURE [sub].[usp_OTIB_Employer_IBAN_Change_List] 
@UserID	int
AS
/*	==========================================================================================
	Purpose:	List all submitted IBAN changes which are not handled fully yet.

	19-11-2019	Sander van Houten	OTIBSUB-1718	Changes that do not need handling by OTIB
                                        must not be selected in this procedure.
	14-02-2019	Sander van Houten	OTIBSUB-699     Update after decision on 4-eye principle check.
	01-02-2019	Sander van Houten	OTIBSUB-529     Altered permissioncodes.
	10-01-2019	Sander van Houten	OTIBSUB-640     Check on user role permission.
	19-11-2018	Sander van Houten	OTIBSUB-98      Initial version.
	==========================================================================================	*/

/*	Testdata.
DECLARE @UserID	int = 1
--*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE	@FirstCheckPermission	bit = 0,
		@SecondCheckPermission	bit

-- Check if the current user has the permission to approve the IBAN change
IF EXISTS (	SELECT 1
			FROM	auth.tblUser_Role uro
			INNER JOIN auth.tblRole_Permission rpe ON rpe.RoleID = uro.RoleID
			INNER JOIN auth.tblPermission per ON per.PermissionID = rpe.PermissionID
			WHERE	uro.UserID = @UserID
			  AND	per.PermissionCode = 'otib-iban-change-approve-first')
BEGIN
	SET @FirstCheckPermission = 1
END

IF EXISTS (	SELECT 1
			FROM	auth.tblUser_Role uro
			INNER JOIN auth.tblRole_Permission rpe ON rpe.RoleID = uro.RoleID
			INNER JOIN auth.tblPermission per ON per.PermissionID = rpe.PermissionID
			WHERE	uro.UserID = @UserID
			  AND	per.PermissionCode = 'otib-iban-change-approve-second')
BEGIN
	SET @SecondCheckPermission = 1
END

IF @FirstCheckPermission = 1 OR @SecondCheckPermission = 1
BEGIN 
	SELECT
			eic.IBANChangeID,
			emp.EmployerName
	FROM	sub.tblEmployer_IBAN_Change eic
	INNER JOIN sub.tblEmployer emp ON emp.EmployerNumber = eic.EmployerNumber
	WHERE	eic.ChangeStatus IN ('0000', '0001')
    AND     (
                ( eic.FirstCheck_UserID IS NULL
            AND	  @FirstCheckPermission = 1 )
            OR	( eic.FirstCheck_UserID <> @UserID
            AND	  eic.SecondCheck_UserID IS NULL
            AND   @SecondCheckPermission = 1 
            AND   eic.ChangeStatus = '0001')
            )
	ORDER BY emp.EmployerName
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.usp_OTIB_Employer_IBAN_Change_List ================================================	*/
