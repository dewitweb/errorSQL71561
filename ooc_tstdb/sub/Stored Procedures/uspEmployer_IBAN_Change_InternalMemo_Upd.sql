
CREATE PROCEDURE [sub].[uspEmployer_IBAN_Change_InternalMemo_Upd]
@IBANChangeID		int,
@InternalMemo		varchar(max),
@CurrentUserID		int = 1
AS
/*	==========================================================================================
	Purpose:	Update a internal memo in sub.tblEmployer_IBAN_Change.

	10-01-2019	Sander van Houten		Initial version (OTIBSUB-642).
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Testdata
DECLARE	@IBANChangeID		int = 1,
		@InternalMemo		varchar(max) = 'test',
		@CurrentUserID		int = 1
*/

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF (ISNULL(@IBANChangeID, 0) <> 0)
BEGIN
	-- Save old record
	SELECT	@XMLdel = (SELECT * 
					   FROM sub.tblEmployer_IBAN_Change 
					   WHERE IBANChangeID = @IBANChangeID
					   FOR XML PATH)

	-- Update internal memo
	UPDATE	sub.tblEmployer_IBAN_Change
	SET
			InternalMemo	= @InternalMemo
	WHERE	IBANChangeID = @IBANChangeID

	-- Save new record
	SELECT	@XMLins = (SELECT * 
					   FROM sub.tblEmployer_IBAN_Change 
					   WHERE IBANChangeID = @IBANChangeID
					   FOR XML PATH)
END

-- Log action in tblHistory
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @IBANChangeID

	EXEC his.uspHistory_Add
			'sub.tblEmployer_IBAN_Change',
			@IBANChangeID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SELECT	IBANChangeID = @IBANChangeID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployer_IBAN_Change_InternalMemo_Upd ==========================================	*/
