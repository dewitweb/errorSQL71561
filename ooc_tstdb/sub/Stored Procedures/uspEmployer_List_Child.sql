CREATE PROCEDURE [sub].[uspEmployer_List_Child]
@EmployerNumber	varchar(6)
AS
/*	==========================================================================================
	Purpose: 	List all child companies for an employernumber.

	30-09-2019	Sander van Houten		OTIBSUB-100		Added RecordID.
	18-09-2019	Sander van Houten		OTIBSUB-100		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	TestData.
DECLARE	@EmployerNumber varchar(6) = '000031'
--	*/

SELECT	emp.EmployerNumber,
		emp.EmployerName + ' (' + emp.EmployerNumber + ')'	AS EmployerName,
		epa.StartDate,
		epa.EndDate,
		epa.RecordID
FROM	sub.tblEmployer_ParentChild epa
INNER JOIN sub.tblEmployer emp ON emp.EmployerNumber = epa.EmployerNumberChild
WHERE	epa.EmployerNumberParent = @EmployerNumber
ORDER BY 
		emp.EmployerName

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployer_List_Child ============================================================	*/
