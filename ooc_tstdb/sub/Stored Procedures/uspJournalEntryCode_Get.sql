CREATE PROCEDURE [sub].[uspJournalEntryCode_Get]
@JournalEntryCode	int,
@CurrentUserID		int
AS
/*	==========================================================================================
	Purpose: 	Get data from sub.tblJournalEntryCode on basis of JournalEntryCode.

	28-08-2019	Sander van Houten		OTIBSUB-1375		Added parameter @CurrentUserID and
											added the download action to the log.
	04-07-2019	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(100)

/*	Log the download action.	*/
SET @KeyID = CAST(@JournalEntryCode AS varchar(18))

SELECT	@XMLdel = CAST('<download>1</download>' AS xml),
		@XMLins = CAST('<row><FileName>Nota specificatie ' + CAST(@JournalEntryCode AS varchar(18)) + '</FileName></row>' AS xml)

EXEC his.uspHistory_Add
		'sub.tblJournalEntryCode',
		@KeyID,
		@CurrentUserID,
		@LogDate,
		@XMLdel,
		@XMLins

/*	Give back result.	*/
SELECT
		jec.JournalEntryCode,
		pr.SubsidySchemeID,
		jec.EmployerNumber,
		jec.IBAN,
		jec.Ascription,
		jec.Specification
FROM	sub.tblJournalEntryCode jec

INNER JOIN  sub.tblPaymentRun pr 
		ON	pr.PaymentRunID = jec.PaymentRunID
WHERE	jec.JournalEntryCode = @JournalEntryCode

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspJournalEntryCode_Get ===========================================================	*/
