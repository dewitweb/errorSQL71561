CREATE PROCEDURE [sub].[uspUser_Role_Employer_Get]
@UserID	int,
@RoleID int
AS
/*	==========================================================================================
	Purpose:	Get data from sub.tblUser_Role_Employer on basis of UserID, @RoleID

	30-09-2019	Sander van Houten		OTIBSUB-100 Only show active child companies.
	29-09-2019	Jaap van Assenbergh		OTIBSUB-100 EmployerName, EmployerNumber and IBAN
	13-03-2019	Sander van Houten		OTIBSUB-762 Add child/parent data.
	26-07-2018	Jaap van Assenbergh		Initial version.				
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		emr.EmployerNumber,
		emr.EmployerName,
		emr.IBAN,
		CAST(CASE WHEN epa.EmployerNumberParent IS NULL 
				THEN 0 
				ELSE 1 
		END	AS bit)				IsChild,
		emp.EmployerName		ParentEmployerName,
		emp.EmployerNumber		ParentEmployerNumber,
		emp.BusinessAddressCity	ParentBusinessAddressCity
FROM	sub.tblUser_Role_Employer ure
LEFT JOIN sub.tblEmployer_ParentChild epa 
ON		epa.EmployerNumberChild = ure.EmployerNumber
AND		CAST(GETDATE() AS date) BETWEEN epa.StartDate AND COALESCE(epa.EndDate, CAST(GETDATE() AS date))
LEFT JOIN sub.tblEmployer emp 
ON		emp.EmployerNumber = epa.EmployerNumberParent
LEFT JOIN sub.tblEmployer emr
ON		emr.EmployerNumber = ure.EmployerNumber
WHERE	ure.UserID = @UserID
  AND	ure.RoleID = @RoleID
  AND	ure.RequestApproved <= GETDATE()
  AND	COALESCE(ure.RequestDenied, GETDATE()) >= GETDATE()

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== uspUser_Role_Employer_Get ==============================================================	*/
