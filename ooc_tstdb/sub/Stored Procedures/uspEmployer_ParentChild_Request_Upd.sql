CREATE PROCEDURE [sub].[uspEmployer_ParentChild_Request_Upd]
@RequestID				int,
@EmployerNumberParent	varchar(6),
@EmployerNameParent		varchar(100),
@EmployerNumberChild	varchar(6),
@StartDate				date,
@EndDate				date,
@RequestStatus			varchar(4),
@RejectionReason		varchar(200),
@CurrentUserID			int = 1
AS
/*	==========================================================================================
	Purpose:	Update sub.tblEmployer_ParentChild_Request on the basis of RequestID.

	27-09-2019	Sander van Houten		OTIBSUB-100		Added EmployerNameParent and
											RejectionReason.
	18-09-2019	Sander van Houten		OTIBSUB-100		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Testdata
DECLARE	@RequestID				int = 0,
		@EmployerNumberParent	varchar(6) = '000007',
		@EmployerNameParent		varchar(100) = 'WGR testcase',
		@EmployerNumberChild	varchar(6) = '000008',
		@StartDate				date = '20190918',
		@EndDate				date = NULL,
		@RequestStatus			varchar(4) = '0001',
		@RejectionReason		varchar(200) = NULL,
		@CurrentUserID			int = 1
*/

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF (ISNULL(@RequestID, 0) = 0)
BEGIN
	-- Set RequestStatus.
	SET @RequestStatus = '0001'	-- In process.

	-- Add new record
	INSERT INTO sub.tblEmployer_ParentChild_Request
		(
			EmployerNumberParent,
			EmployerNameParent,
			EmployerNumberChild,
			StartDate,
			EndDate,
			Creation_DateTime,
			RequestStatus
		)
	SELECT
			@EmployerNumberParent,
			@EmployerNameParent,
			@EmployerNumberChild,
			@StartDate,
			@EndDate,
			@LogDate,
			@RequestStatus

	-- Save new RequestID
	SET	@RequestID = SCOPE_IDENTITY()

	-- Save new record
	SELECT	@XMLdel = NULL,
			@XMLins = (SELECT	* 
					   FROM		sub.tblEmployer_ParentChild_Request
					   WHERE	RequestID = @RequestID
					   FOR XML PATH)
END
ELSE
BEGIN
	-- Save old record
	SELECT	@XMLdel = (SELECT	* 
					   FROM		sub.tblEmployer_ParentChild_Request
					   WHERE	RequestID = @RequestID
					   FOR XML PATH)

	-- Update exisiting record
	UPDATE	sub.tblEmployer_ParentChild_Request
	SET
			EmployerNumberParent = @EmployerNumberParent,
			EmployerNameParent = @EmployerNameParent,
			EmployerNumberChild = @EmployerNumberChild,
			StartDate = @StartDate,
			EndDate = @EndDate,
			RequestStatus = @RequestStatus,
			RejectionReason = @RejectionReason,
			RequestProcessedOn = CASE WHEN @RequestStatus <> '0001'
									THEN @LogDate
									ELSE NULL
								 END
	WHERE	RequestID = @RequestID

	-- Save new record
	SELECT	@XMLins = (SELECT	* 
					   FROM		sub.tblEmployer_ParentChild_Request
					   WHERE	RequestID = @RequestID
					   FOR XML PATH)

END

-- Log action in tblHistory
IF CAST(ISNULL(@XMLdel, '') AS varchar(MAX)) <> CAST(ISNULL(@XMLins, '') AS varchar(MAX))
BEGIN
	SET @KeyID = CAST(@RequestID AS varchar(18))

	EXEC his.uspHistory_Add
			'sub.tblEmployer_ParentChild_Request',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SELECT	RequestID = @RequestID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployer_ParentChild_Request_Upd =======================================	*/
