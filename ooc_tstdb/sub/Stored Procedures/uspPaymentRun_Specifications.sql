
CREATE PROCEDURE [sub].[uspPaymentRun_Specifications]
@PaymentRunID	int = 0
AS
/*	==========================================================================================
	Purpose:	Create specifications after paymentrun.

	Note	Procedure is the first step in OTIB-DS Automatic paymentrun export
	03-02-2020	Jaap van Assenebrgh	OTIBSUB-1870	Specificaties uit de betaalrun halen
	==========================================================================================	*/

DECLARE @JournalEntryCode	int,
		@UserID				int

DECLARE cur_PaymentRun CURSOR FOR 
	SELECT 	jec.JournalEntryCode,
			par.UserID
	FROM	sub.tblPaymentRun par
	INNER JOIN	sub.tblJournalEntryCode jec ON jec.PaymentRunID = par.PaymentRunID
	WHERE	par.PaymentRunID = @PaymentRunID
	   OR	(		@PaymentRunID = 0 
			AND		par.PaymentRunID > 60000
			AND		par.ExportDate IS NULL 
			AND		par.Completed IS NOT NULL
			)
	ORDER BY par.PaymentRunID, JournalEntryCode
OPEN cur_PaymentRun

FETCH 
	FROM cur_PaymentRun 
	INTO @JournalEntryCode, @UserID

IF @@FETCH_STATUS = 0
BEGIN
	DECLARE @ExecutedProcedureID int = 0
	EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID
END

WHILE @@FETCH_STATUS = 0  
BEGIN

			EXECUTE sub.uspJournalEntryCode_Specification_Upd
		    @JournalEntryCode,
		    @UserID

	FETCH NEXT 
		FROM cur_PaymentRun 
		INTO @JournalEntryCode, @UserID
END

CLOSE cur_PaymentRun
DEALLOCATE cur_PaymentRun

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspPaymentRun_uspPaymentRun_Specifications ========================================	*/
