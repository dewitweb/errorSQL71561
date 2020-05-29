CREATE PROCEDURE [sub].[uspEmployer_PaymentStop_Upd]
@PaymentStopID				int,
@EmployerNumber				varchar(6),
@StartDate					date,
@StartReason				varchar(254),
@EndDate					date,
@EndReason					varchar(100),
@PaymentstopType			varchar(4),
@CurrentUserID				int = 1
AS
/*	==========================================================================================
	Purpose:	Add or Update sub.tblEmployer_PaymentStop.

	20-06-2019	Sander van Houten		OTIBSUB-1241	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF ISNULL(@PaymentStopID, 0) = 0
BEGIN
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

	-- Save new record
	SELECT	@XMLdel = NULL,
			@XMLins = (SELECT	* 
					   FROM		sub.tblEmployer_PaymentStop 
					   WHERE	PaymentStopID = @PaymentStopID
					   FOR XML PATH)
END
ELSE
BEGIN
	-- Save old record
	SELECT	@XMLdel = (SELECT	* 
					   FROM		sub.tblEmployer_PaymentStop 
					   WHERE	PaymentStopID = @PaymentStopID
					   FOR XML PATH)

	-- Update existing record
	UPDATE	sub.tblEmployer_PaymentStop
	SET		EmployerNumber	= @EmployerNumber,
			StartDate		= @StartDate,
			StartReason		= @StartReason,
			EndDate			= @EndDate,
			EndReason		= @EndReason,
			PaymentstopType	= @PaymentstopType
	WHERE	PaymentStopID	= @PaymentStopID

	-- Save new record
	SELECT	@XMLins = (SELECT	* 
					   FROM		sub.tblEmployer_PaymentStop 
					   WHERE	PaymentStopID = @PaymentStopID
					   FOR XML PATH)
END

-- Log action in tblHistory
IF CAST(ISNULL(@XMLdel, '') AS varchar(MAX)) <> CAST(ISNULL(@XMLins, '') AS varchar(MAX))
BEGIN
	SET @KeyID = CAST(@PaymentStopID AS varchar(18))

	EXEC his.uspHistory_Add
			'tblEmployer_PaymentStop',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployer_PaymentStop_Upd =======================================================	*/
