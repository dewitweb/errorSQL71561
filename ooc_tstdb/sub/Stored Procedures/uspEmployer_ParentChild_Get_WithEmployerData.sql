CREATE PROCEDURE [sub].[uspEmployer_ParentChild_Get_WithEmployerData]
@RecordID	int
AS
/*	==========================================================================================
	Purpose:	Get specific Employer_ParentChild record.

	01-10-2019	Sander van Houten		OTIBSUB-100		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		epc.EmployerNumberParent,
		emp.EmployerName			AS EmployerNameParent,
		epc.EmployerNumberChild,
		epc.StartDate,
		epc.EndDate,
		epc.RecordID
FROM	sub.tblEmployer_ParentChild epc
INNER JOIN sub.tblEmployer emp ON emp.EmployerNumber = epc.EmployerNumberParent
WHERE	RecordID = @RecordID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployer_ParentChild_Get_WithEmployerData ======================================	*/
