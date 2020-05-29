
CREATE PROCEDURE [sub].[uspPaymentRun_XMLExport_Upd]
@PaymentRunID			int,
@XMLCreditors			xml,
@XMLPayments			xml,
@NrOfCreditors			int,
@NrOfDebits				int,
@NrOfCredits			int,
@TotalAmountCredit		decimal(9, 2),
@TotalAmountDebit		decimal(9, 2),
@FirstJournalEntryCode	varchar(10),
@LastJournalEntryCode	varchar(10),
@CreationDate			datetime,
@ExportDate				datetime,
@CurrentUserID			int = 1
AS
/*	==========================================================================================
	Purpose: 	Update sub.tblPaymentRun_XMLExport on basis of PaymentRunID.

	13-04-2019	Sander van Houten		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Return		int = 1

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF NOT EXISTS (	SELECT	1 
				FROM	sub.tblPaymentRun_XMLExport 
				WHERE	PaymentRunID = @PaymentRunID
			  )
BEGIN
	-- Add new record
	INSERT INTO sub.tblPaymentRun_XMLExport
		(
			PaymentRunID,
			XMLCreditors,
			XMLPayments,
			NrOfCreditors,
			NrOfDebits,
			NrOfCredits,
			TotalAmountCredit,
			TotalAmountDebit,
			FirstJournalEntryCode,
			LastJournalEntryCode,
			CreationDate,
			ExportDate
		)
	VALUES
		(
			@PaymentRunID,
			@XMLCreditors,
			@XMLPayments,
			@NrOfCreditors,
			@NrOfDebits,
			@NrOfCredits,
			@TotalAmountCredit,
			@TotalAmountDebit,
			@FirstJournalEntryCode,
			@LastJournalEntryCode,
			@CreationDate,
			@ExportDate
		)

	SET	@PaymentRunID = SCOPE_IDENTITY()

	-- Save new record.
	SELECT	@XMLdel = NULL,
			@XMLins = (	SELECT 	*
						FROM	sub.tblPaymentRun_XMLExport
						WHERE	PaymentRunID = @PaymentRunID
						FOR XML PATH )

END
ELSE
BEGIN
	-- Save old record.
	SELECT	@XMLdel = (	SELECT 	*
						FROM	sub.tblPaymentRun_XMLExport
						WHERE	PaymentRunID = @PaymentRunID
						FOR XML PATH )

	-- Update existing record.
	UPDATE	sub.tblPaymentRun_XMLExport
	SET
			XMLCreditors			= @XMLCreditors,
			XMLPayments				= @XMLPayments,
			NrOfCreditors			= @NrOfCreditors,
			NrOfDebits				= @NrOfDebits,
			NrOfCredits				= @NrOfCredits,
			TotalAmountCredit		= @TotalAmountCredit,
			TotalAmountDebit		= @TotalAmountDebit,
			FirstJournalEntryCode	= @FirstJournalEntryCode,
			LastJournalEntryCode	= @LastJournalEntryCode,
			CreationDate			= @CreationDate,
			ExportDate				= @ExportDate
	WHERE	PaymentRunID = @PaymentRunID

	-- Save new record.
	SELECT	@XMLins = (	SELECT 	*
						FROM	sub.tblPaymentRun_XMLExport
						WHERE	PaymentRunID = @PaymentRunID
						FOR XML PATH )
END

-- Log action in his.tblHistory.
IF CAST(ISNULL(@XMLdel, '') AS varchar(MAX)) <> CAST(ISNULL(@XMLins, '') AS varchar(MAX))
BEGIN
	SET @KeyID = @PaymentRunID

	EXEC his.uspHistory_Add
			'sub.tblPaymentRun_XMLExport',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SELECT PaymentRunID = @PaymentRunID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SET @Return = 0

RETURN @Return

/*	== sub.uspPaymentRun_XMLExport_Upd =======================================================	*/
