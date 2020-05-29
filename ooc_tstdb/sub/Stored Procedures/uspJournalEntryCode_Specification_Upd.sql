CREATE PROCEDURE [sub].[uspJournalEntryCode_Specification_Upd]
@JournalEntryCode		int,
@CurrentUserID			int = 1
AS
/*	==========================================================================================
	Purpose: 	Update sub.tblJournalEntryCode_Specification on basis of JournalEntryCode.

	12-12-2018	Jaap van Assenbergh		Inital version.
	==========================================================================================	*/

DECLARE @SubsidySchemeID int

SELECT	@SubsidySchemeID = SubsidySchemeID
FROM	sub.tblPaymentRun_Declaration prd
INNER JOIN sub.tblPaymentRun pr ON pr.PaymentRunID = prd.PaymentRunID
WHERE	JournalEntryCode = @JournalEntryCode

IF @SubsidySchemeID = 1
BEGIN
	EXEC	osr.uspJournalEntryCode_Specification_Upd
				@JournalEntryCode,
				@CurrentUserID
END

IF @SubsidySchemeID = 3
BEGIN
	EXEC	evc.uspJournalEntryCode_Specification_Upd
				@JournalEntryCode,
				@CurrentUserID
END

IF @SubsidySchemeID = 4
BEGIN
	EXEC	stip.uspJournalEntryCode_Specification_Upd
				@JournalEntryCode,
				@CurrentUserID
END
/*	== sub.uspJournalEntryCode_Specification_Upd =================================================	*/
