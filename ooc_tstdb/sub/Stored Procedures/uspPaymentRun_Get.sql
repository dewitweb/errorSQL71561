
CREATE PROCEDURE [sub].[uspPaymentRun_Get]
@StartDate			date,
@EndDate			date
AS
/*	==========================================================================================
	Purpose:	Get all executed PaymentRuns optionaly within a certain time period.

	10-08-2018	Sander van Houten		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/* Testdata
DECLARE	@StartDate	date,
		@EndDate	date
*/

SELECT	par.PaymentRunID,
		par.SubsidySchemeID,
		par.RunDate,
		par.EndDate,
		par.UserID,
		usr.Fullname AS UserName,
		decl.DeclarationID,
		decl.EmployerNumber,
		decl.DeclarationAmount,
		decl.ApprovedAmount
FROM	sub.tblPaymentRun par
INNER JOIN sub.tblPaymentRun_Declaration pad
ON pad.PaymentRunID = par.PaymentRunID
INNER JOIN sub.tblDeclaration decl
ON decl.DeclarationID = pad.DeclarationID
LEFT JOIN auth.tblUser usr
ON usr.UserID = par.UserID
WHERE	par.RunDate BETWEEN COALESCE(@StartDate, '20180101') 
						AND COALESCE(@EndDate, '20990101')
ORDER BY par.RunDate, par.PaymentRunID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== uspPaymentRunCandidates_Get ===========================================================	*/
