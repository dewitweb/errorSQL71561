CREATE PROCEDURE [sub].[usp_OTIB_Employer_IBAN_Change_ReturnToEmployer]
@IBANChangeID	int,
@Reason			varchar(max),
@ReasonInEmail	bit,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose:	Return a IBAN change application to Employer by an OTIB user.

	19-11-2019	Sander van Houten	OTIBSUB-1718	Added update of ReturnToEmployerReason.
	18-11-2019	Sander van Houten	OTIBSUB-1718	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

-- Save new record
SELECT	@XMLdel = (SELECT	* 
					FROM	sub.tblEmployer_IBAN_Change
					WHERE	IBANChangeID = @IBANChangeID
					FOR XML PATH)

-- Update existing record
UPDATE	sub.tblEmployer_IBAN_Change
SET
		ChangeStatus	        = '0005',
		FirstCheck_UserID	    = NULL,
        FirstCheck_DateTime     = NULL,
        SecondCheck_UserID      = NULL,
        SecondCheck_DateTime    = NULL,
        RejectionReason         = NULL,
        ChangeExecutedOn        = @LogDate,
        ReturnToEmployerReason  = @Reason
WHERE	IBANChangeID = @IBANChangeID

-- Save new record
SELECT	@XMLins = (SELECT * 
				   FROM   sub.tblEmployer_IBAN_Change 
				   WHERE  IBANChangeID = @IBANChangeID
				   FOR XML PATH)

-- Log action in tblHistory
SET @KeyID = @IBANChangeID

EXEC his.uspHistory_Add
		'sub.tblEmployer_IBAN_Change',
		@KeyID,
		@CurrentUserID,
		@LogDate,
		@XMLdel,
		@XMLins

-- Send e-mail.
IF @ReasonInEmail = 0
BEGIN
	SET @Reason = ''
END

EXEC sub.usp_OTIB_Employer_IBAN_Change_SendEmail_ReturnToEmployer
	@IBANChangeID,
	@Reason			

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.usp_OTIB_Employer_IBAN_Change_ReturnToEmployer ====================================	*/
