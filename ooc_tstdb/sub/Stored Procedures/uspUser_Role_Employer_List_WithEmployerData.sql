CREATE PROCEDURE [sub].[uspUser_Role_Employer_List_WithEmployerData]
@UserID	int,
@RoleID int
AS
/*	==========================================================================================
	Purpose:	List all data from sub.tblUser_Role_Employer on basis of UserID and @RoleID.

	30-09-2019	Sander van Houten		OTIBSUB-100		Changed join to only active concern relations.
	18-09-2019	Sander van Houten		OTIBSUB-100		Added concern relations.
	26-07-2018	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT	sub1.EmployerNumberParent,
		sub1.EmployerNumber,
		sub1.EmployerName,
		sub1.FullName,
		sub1.ConcernType,
		sub1.EmployerNameParent,
		sub1.BusinessAddressCityParent,
		sub1.IBAN
FROM	(
			SELECT	ep.EmployerNumberParent,
					emp.EmployerNumber,
					emp.EmployerName,
					emp.EmployerName + ' (' + emp.EmployerNumber + ')'	AS FullName,
					CASE WHEN ep.EmployerNumberParent IS NULL 
						THEN 0
						ELSE 1
					END													AS ConcernType,
					emp.EmployerName									AS EmployerNameParent,
					emp.BusinessAddressCity								AS BusinessAddressCityParent,
					emp.IBAN
			FROM	sub.tblUser_Role_Employer ure
			INNER JOIN sub.tblEmployer emp 
			ON		emp.EmployerNumber = ure.EmployerNumber
			LEFT JOIN sub.tblEmployer_ParentChild ep 
			ON		ep.EmployerNumberParent = emp.EmployerNumber
			AND		CAST(GETDATE() AS date) BETWEEN ep.StartDate AND COALESCE(ep.EndDate, CAST(GETDATE() AS date))
			LEFT JOIN sub.tblEmployer_ParentChild ec 
			ON		ec.EmployerNumberChild = emp.EmployerNumber
			AND		CAST(GETDATE() AS date) BETWEEN ec.StartDate AND COALESCE(ec.EndDate, CAST(GETDATE() AS date))
			WHERE	ure.UserID = @UserID
			AND		ure.RoleID = COALESCE(@RoleID, ure.RoleID)
			AND		ure.RequestApproved <= GETDATE()
			AND		COALESCE(ure.RequestDenied, GETDATE()) >= GETDATE()
			AND		ec.EmployerNumberChild IS NULL

			UNION

			SELECT	epc.EmployerNumberParent,
					emp.EmployerNumber,
					emp.EmployerName,
					emp.EmployerName + ' (' + emp.EmployerNumber + ')'	AS FullName,
					2													AS ConcernType,
					parent.EmployerName									AS EmployerNameParent,
					parent.BusinessAddressCity							AS BusinessAddressCityParent,
					parent.IBAN
			FROM	sub.tblUser_Role_Employer ure
			INNER JOIN sub.tblEmployer_ParentChild epc 
			ON		epc.EmployerNumberChild = ure.EmployerNumber
			AND		CAST(GETDATE() AS date) BETWEEN epc.StartDate AND COALESCE(epc.EndDate, CAST(GETDATE() AS date))
			INNER JOIN sub.tblEmployer emp 
			ON		emp.EmployerNumber = epc.EmployerNumberChild
			INNER JOIN sub.tblEmployer parent
			ON		parent.EmployerNumber = epc.EmployerNumberParent
			WHERE	ure.UserID = @UserID
			AND		ure.RoleID = COALESCE(@RoleID, ure.RoleID)
			AND		ure.RequestApproved <= GETDATE()
			AND		COALESCE(ure.RequestDenied, GETDATE()) >= GETDATE()
		) sub1
ORDER BY
		sub1.EmployerNumberParent,
		sub1.ConcernType
			
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== uspUser_Role_Employer_List_EmployerName ===============================================	*/
