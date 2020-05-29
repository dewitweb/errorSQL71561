CREATE PROCEDURE [sub].[usp_OTIB_Employer_ParentChild_Request_AcceptReject]
@RequestID			int,
@Accept				bit,
@RejectionReason	varchar(200),
@CurrentUserID		int = 1
AS
/*	==========================================================================================
	Purpose:	Accept or Reject an employers request, to transfer the scholings budget 
				to a mother company, by an OTIB user.

	27-09-2019	Sander van Houten		OTIBSUB-100		Added EmployerNameParent and
											RejectionReason.
	18-09-2019	Sander van Houten		OTIBSUB-100		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

DECLARE @RC						int,
		@EmployerNumberParent	varchar(6),
		@EmployerNameParent		varchar(100),
		@EmployerNumberChild	varchar(6),
		@StartDate				date,
		@EndDate				date,
		@RequestStatus			varchar(4)

SELECT	@EmployerNumberParent = EmployerNumberParent,
		@EmployerNameParent = EmployerNameParent,
		@EmployerNumberChild = EmployerNumberChild,
		@StartDate = StartDate,
		@EndDate = EndDate,
		@RequestStatus = CASE @Accept
							WHEN 0 THEN '0002'
							ELSE '0003'
						 END
FROM	sub.tblEmployer_ParentChild_Request
WHERE	RequestID = @RequestID

EXECUTE @RC = [sub].[uspEmployer_ParentChild_Request_Upd] 
	@RequestID,
	@EmployerNumberParent,
	@EmployerNameParent,
	@EmployerNumberChild,
	@StartDate,
	@EndDate,
	@RequestStatus,
	@RejectionReason,
	@CurrentUserID

IF @Accept = 1
BEGIN
	EXECUTE @RC = [sub].[uspEmployer_ParentChild_Upd]
		@EmployerNumberParent,
		@EmployerNumberChild,
		@StartDate,
		@EndDate,
		@CurrentUserID
END
 
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.usp_OTIB_Employer_ParentChild_Request_AcceptReject ================================	*/
