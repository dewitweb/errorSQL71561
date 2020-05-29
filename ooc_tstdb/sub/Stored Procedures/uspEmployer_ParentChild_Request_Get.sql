CREATE PROCEDURE [sub].[uspEmployer_ParentChild_Request_Get]
@RequestID	int
AS
/*	==========================================================================================
	Purpose:	Get specific Employer_ParentChild_Request record.

	27-09-2019	Sander van Houten		OTIBSUB-100		Added EmployerNameParent and
											RejectionReason.
	18-09-2019	Sander van Houten		OTIBSUB-100		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		RequestID,
		EmployerNumberParent,
		EmployerNameParent,
		EmployerNumberChild,
		StartDate,
		EndDate,
		Creation_DateTime,
		RequestStatus,
		RejectionReason,
		RequestProcessedOn
FROM	sub.tblEmployer_ParentChild_Request
WHERE	RequestID = @RequestID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployer_ParentChild_Request_Get ===============================================	*/
