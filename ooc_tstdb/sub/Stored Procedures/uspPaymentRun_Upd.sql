
CREATE PROCEDURE sub.uspPaymentRun_Upd
@PaymentRunID		int,
@RunDate			datetime,
@EndDate			datetime,
@ExportDate			datetime,
@UserID				int,
@SubsidySchemeID	int,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose: 	Update sub.tblPaymentRun on basis of PaymentRunID.

	16-04-2019	Sander van Houten	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Return		int = 1

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF ISNULL(@PaymentRunID, 0) = 0
BEGIN
	-- Add new record
	INSERT INTO sub.tblPaymentRun
		(
			RunDate,
			EndDate,
			ExportDate,
			UserID,
			SubsidySchemeID
		)
	VALUES
		(
			@RunDate,
			@EndDate,
			@ExportDate,
			@UserID,
			@SubsidySchemeID
		)

	SET	@PaymentRunID = SCOPE_IDENTITY()

	-- Save new record.
	SELECT	@XMLdel = NULL,
			@XMLins = (	SELECT 	*
						FROM	sub.tblPaymentRun
						WHERE	PaymentRunID = @PaymentRunID
						FOR XML PATH )

END
ELSE
BEGIN
	-- Save old record.
	SELECT	@XMLdel = (	SELECT 	*
						FROM	sub.tblPaymentRun
						WHERE	PaymentRunID = @PaymentRunID
						FOR XML PATH )

	-- Update existing record.
	UPDATE	sub.tblPaymentRun
	SET
			RunDate			= @RunDate,
			EndDate			= @EndDate,
			ExportDate		= @ExportDate,
			UserID			= @UserID,
			SubsidySchemeID	= @SubsidySchemeID
	WHERE	PaymentRunID = @PaymentRunID

	-- Save new record.
	SELECT	@XMLins = (	SELECT 	*
						FROM	sub.tblPaymentRun
						WHERE	PaymentRunID = @PaymentRunID
						FOR XML PATH )
END

-- Log action in his.tblHistory.
IF CAST(ISNULL(@XMLdel, '') AS varchar(MAX)) <> CAST(ISNULL(@XMLins, '') AS varchar(MAX))
BEGIN
	SET @KeyID = @PaymentRunID

	EXEC his.uspHistory_Add
			'sub.tblPaymentRun',
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

/*	== sub.uspPaymentRun_Upd =================================================================	*/
