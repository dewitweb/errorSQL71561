CREATE PROCEDURE [sub].[uspReProcessSpecifications]
@PaymentRunID	int
AS
/*	==========================================================================================
	Purpose:	Add record to sub.tblPaymentRun.

	Note:		

	01-04-2019	Sander van Houten	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE	@RC							int,
		@DeclarationID				int,
		@MaxSpecificationSequence	int

/*	First correct JournalEntryCode for rejected specifications.	*/
UPDATE	pd2
SET		pd2.JournalEntryCode = pd1.JournalEntryCode
FROM	sub.tblPaymentRun_Declaration pd1
INNER JOIN sub.tblDeclaration d1 ON d1.DeclarationID = pd1.DeclarationID
INNER JOIN sub.tblDeclaration d2 ON d2.EmployerNumber = d1.EmployerNumber
INNER JOIN sub.tblPaymentRun_Declaration pd2 ON pd2.DeclarationID = d2.DeclarationID AND pd2.PaymentRunID = pd1.PaymentRunID
WHERE	pd1.JournalEntryCode IS NOT NULL
AND		pd2.JournalEntryCode IS NULL

/*	Then recreate the specifications.	*/
DECLARE cur_specs CURSOR FOR 
	SELECT 
			dsp.DeclarationID,
			MAX(dsp.SpecificationSequence)	AS MaxSpecificationSequence
	FROM	sub.tblPaymentRun_Declaration pad
	INNER JOIN sub.tblDeclaration_Specification dsp 
	ON		dsp.DeclarationID = pad.DeclarationID
	AND		dsp.PaymentRunID = pad.PaymentRunID
	WHERE	pad.PaymentRunID = @PaymentRunID
	  AND	pad.JournalEntryCode IS NOT NULL
	GROUP BY 
			dsp.DeclarationID

OPEN cur_specs

FETCH NEXT FROM cur_specs INTO @DeclarationID, @MaxSpecificationSequence

WHILE @@FETCH_STATUS = 0  
BEGIN
	-- Update the voucher used amount.
	EXEC	@RC = sub.uspDeclaration_Specification_Upd
			@DeclarationID,
			@MaxSpecificationSequence,
			@PaymentRunID,
			1

	FETCH NEXT FROM cur_specs INTO @DeclarationID, @MaxSpecificationSequence
END

CLOSE cur_specs
DEALLOCATE cur_specs

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspReProcessSpecifications ========================================================	*/
