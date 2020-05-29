
CREATE PROCEDURE [sub].[usp_OTIB_Employer_PaymentStop_Upd]
@PaymentStopID		int,
@EmployerNumber		varchar(6),
@StartDate			date,
@StartReason		varchar(MAX),
@EndDate			date,
@EndReason			varchar(MAX),
@PaymentstopType	varchar(4),
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose: 	Update sub.tblEmployer_PaymentStop on basis of PaymentStopID.

	24-10-2018	Jaap van Assenbergh	Based on PK PaymentStop instead of EmployerNumber StartDate
									StartDate must be able to be changed
	05-10-2018	Sander van Houten	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Return		int = 1

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF ISNULL(@PaymentStopID, 0) = 0
BEGIN
	-- Add new record
	SET @PaymentstopType = ISNULL(@PaymentstopType, '0001')

	INSERT INTO sub.tblEmployer_PaymentStop
		(
			EmployerNumber,
			StartDate,
			StartReason,
			EndDate,
			EndReason,
			PaymentstopType
		)
	VALUES
		(
			@EmployerNumber,
			@StartDate,
			@StartReason,
			@EndDate,
			@EndReason,
			@PaymentstopType
		)

	SET	@PaymentStopID = SCOPE_IDENTITY()

	-- Save new record.
	SELECT	@XMLdel = NULL,
			@XMLins = (	SELECT 	*
						FROM	sub.tblEmployer_PaymentStop
						WHERE	PaymentStopID = @PaymentStopID
						FOR XML PATH )

END
ELSE
BEGIN
	-- Save old record.
	SELECT	@XMLdel = (	SELECT 	*
						FROM	sub.tblEmployer_PaymentStop
						WHERE	PaymentStopID = @PaymentStopID
						FOR XML PATH )

	-- Update existing record.
	UPDATE	sub.tblEmployer_PaymentStop
	SET
			EmployerNumber	= @EmployerNumber,
			StartDate		= @StartDate,
			StartReason		= @StartReason,
			EndDate			= @EndDate,
			EndReason		= @EndReason,
			PaymentstopType	= @PaymentstopType
	WHERE	PaymentStopID = @PaymentStopID

	-- Save new record.
	SELECT	@XMLins = (	SELECT 	*
						FROM	sub.tblEmployer_PaymentStop
						WHERE	PaymentStopID = @PaymentStopID
						FOR XML PATH )
END

-- Log action in his.tblHistory.
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @PaymentStopID

	EXEC his.uspHistory_Add
			'sub.tblEmployer_PaymentStop',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SELECT PaymentStopID = @PaymentStopID

SET @Return = 0

RETURN @Return

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.usp_OTIB_Employer_PaymentStop_Upd =================================================	*/
