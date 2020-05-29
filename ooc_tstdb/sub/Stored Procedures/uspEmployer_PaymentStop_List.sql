
CREATE PROCEDURE [sub].[uspEmployer_PaymentStop_List]
	@EmployerNumber varchar(6)
AS
/* ==========================================================================================
 Purpose:  Get list from sub.tblEmployer_PaymentStop.

 15-10-2018 Jaap van Assenbergh Inital version.
 ========================================================================================== */

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		PaymentStopID,
		EmployerNumber,
		StartDate,
		StartReason,
		EndDate,
		EndReason,
		PaymentstopType
FROM	sub.tblEmployer_PaymentStop
WHERE	EmployerNumber = @EmployerNumber
ORDER BY StartDate DESC

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/* == sub.uspEmployer_PaymentStop_List ===================================================== */
