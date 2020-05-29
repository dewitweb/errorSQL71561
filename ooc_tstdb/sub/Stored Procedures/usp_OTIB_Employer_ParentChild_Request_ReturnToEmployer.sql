
CREATE PROCEDURE [sub].[usp_OTIB_Employer_ParentChild_Request_ReturnToEmployer]
@RequestID		int,
@Reason			varchar(max),
@ReasonInEmail	bit,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose:	Return a scholingsbudget transfer request to Employer by an OTIB user.

	27-09-2019	Sander van Houten		OTIBSUB-100		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

-- Save new record
SELECT	@XMLdel = (SELECT	* 
					FROM	sub.tblEmployer_ParentChild_Request
					WHERE	RequestID = @RequestID 
					FOR XML PATH)

-- Update exisiting record
UPDATE	sub.tblEmployer_ParentChild_Request
SET
		RequestStatus		= '0004',
		RejectionReason		= LEFT(@Reason, 200),
		RequestProcessedOn	= @LogDate
WHERE	RequestID = @RequestID

-- Save new record
SELECT	@XMLins = (SELECT * 
				   FROM   sub.tblEmployer_ParentChild_Request 
				   WHERE  RequestID = @RequestID
				   FOR XML PATH)

-- Log action in tblHistory
SET @KeyID = @RequestID

EXEC his.uspHistory_Add
		'sub.tblEmployer_ParentChild_Request',
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

EXEC sub.usp_OTIB_Employer_ParentChild_Request_SendEmail_ReturnToEmployer
	@RequestID,
	@Reason			

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.usp_OTIB_Employer_ParentChild_Request_ReturnToEmployer ========================	*/
