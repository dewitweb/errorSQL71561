
CREATE PROCEDURE [sub].[uspDeclaration_ReversalPayment_Upd]
@ReversalPaymentID			int,
@DeclarationID				int,
@ReversalPaymentReason		varchar(max),
@PaymentRunID				int,
@CurrentUserID				int = 1
AS
/*	==========================================================================================
	Purpose:	Update or Add declaration information for reversal payments 
				on bases of a DeclarationID.
				
	28-10-2019	Sander van Houten		OTUBSUB-1649	Removed execution of 
                                            sub.uspDeclaration_Partition_ReversalPayment_Upd.
	21-02-2019	Sander van Houten		OTIBSUB-792	    Manier van vastlegging terugboeking 
										    bij werknemer veranderen.
	14-11-2018	Sander van Houten		Added logging.
	04-09-2018	Jaap van Assenbergh		Initial version.
	==========================================================================================  */

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF ISNULL(@ReversalPaymentID, 0) = 0
BEGIN
	SELECT	@ReversalPaymentID = MAX(ReversalPaymentID)
	FROM	sub.tblDeclaration_ReversalPayment
	WHERE	DeclarationID = @DeclarationID
	  AND   PaymentRunID IS NULL
END

IF ISNULL(@ReversalPaymentID, 0) = 0
BEGIN
	INSERT INTO sub.tblDeclaration_ReversalPayment
		(
			DeclarationID,
			ReversalPaymentReason,
			ReversalPaymentDateTime,
			PaymentRunID
		)
	VALUES
		(
			@DeclarationID,
			@ReversalPaymentReason,
			@LogDate,
			@PaymentRunID
		)

	SET @ReversalPaymentID = SCOPE_IDENTITY()

	-- Save new record
	SELECT	@XMLdel = NULL,
			@XMLins = (SELECT	* 
					   FROM		sub.tblDeclaration_ReversalPayment
					   WHERE	DeclarationID = @DeclarationID
					   FOR XML PATH)

END
ELSE
BEGIN
	-- Save old record
	SELECT	@XMLdel = (SELECT	* 
					   FROM		sub.tblDeclaration_ReversalPayment
					   WHERE	DeclarationID = @DeclarationID
					   FOR XML PATH)

	-- Update existing record
	UPDATE sub.tblDeclaration_ReversalPayment
	SET
			DeclarationID			= @DeclarationID,
			ReversalPaymentReason	= @ReversalPaymentReason,
			PaymentRunID			= @PaymentRunID
	WHERE	ReversalPaymentID = @ReversalPaymentID

	-- Save new record
	SELECT	@XMLins = (SELECT	*
					   FROM		sub.tblDeclaration_ReversalPayment
					   WHERE	DeclarationID = @DeclarationID
					   FOR XML PATH)
END

-- Log action in tblHistory
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @ReversalPaymentID

	EXEC his.uspHistory_Add
			'sub.tblDeclaration_ReversalPayment',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SELECT ReversalPaymentID = @ReversalPaymentID


EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/* == sub.uspDeclaration_ReversalPayment_Upd =================================================	*/
