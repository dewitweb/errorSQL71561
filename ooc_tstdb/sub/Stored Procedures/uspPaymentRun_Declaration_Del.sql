
CREATE PROCEDURE [sub].[uspPaymentRun_Declaration_Del]
	@DeclarationID	int,
	@PaymentRunID	int,
	@CurrentUserID	int = 1
AS

/*	==========================================================================================
	11-09-2018	Jaap van Assenbergh
				Verwijderen uit sub.tblPaymentRun_Declaration
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

-- Save old record sub.tblEmployer_Employee
SELECT	@XMLdel = (SELECT	* 
				   FROM		sub.tblPaymentRun_Declaration 
			       WHERE	DeclarationID = @DeclarationID
				   AND		PaymentRunID = @PaymentRunID
				   FOR XML PATH),
		@XMLins = NULL

DELETE
FROM	sub.tblPaymentRun_Declaration
WHERE	DeclarationID = @DeclarationID
AND		PaymentRunID = @PaymentRunID

-- Log action in tblHistory
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = CONVERT(varchar(18), @DeclarationID) + '|' + CONVERT(varchar(18), @PaymentRunID)

	EXEC his.uspHistory_Add
			'sub.tblPaymentRun_Declaration',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspPaymentRun_Declaration__Del =====================================================	*/
