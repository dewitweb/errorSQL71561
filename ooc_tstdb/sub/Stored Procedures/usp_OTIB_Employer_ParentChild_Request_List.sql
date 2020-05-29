
CREATE PROCEDURE [sub].[usp_OTIB_Employer_ParentChild_Request_List]
AS
/*	==========================================================================================
	Purpose:	List all submitted parent child requests which are not handled fully yet.

	18-09-2019	Sander van Houten		OTIBSUB-100		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT	CASE WHEN epc.EmployerNumberParent IS NULL
			THEN 'New'
			ELSE 'Existing'
		END													AS RequestType,
		epcr.RequestID,
		COALESCE(emp.EmployerName, epcr.EmployerNameParent)	AS EmployerName
FROM	sub.tblEmployer_ParentChild_Request epcr
LEFT JOIN sub.tblEmployer emp 
ON		emp.EmployerNumber = epcr.EmployerNumberParent
LEFT JOIN sub.tblEmployer_ParentChild epc
ON		epc.EmployerNumberParent = epcr.EmployerNumberParent
AND		epc.EmployerNumberChild = epcr.EmployerNumberChild
AND		epc.StartDate = epc.StartDate
WHERE	epcr.RequestProcessedOn IS NULL

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.usp_OTIB_Employer_ParentChild_Request_List ========================================	*/
