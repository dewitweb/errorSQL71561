CREATE PROCEDURE [sub].[uspEmployer_ParentChild_Request_Update]
@RequestID				int,
@EmployerNumberParent	varchar(6),
@EmployerNameParent		varchar(100),
@EmployerNumberChild	varchar(6),
@StartDate				date,
@EndDate				date,
@CurrentUserID			int = 1
AS
/*	==========================================================================================
	Purpose:	Update sub.tblEmployer_ParentChild_Request on the basis of RequestID.

	30-09-2019	Sander van Houten		OTIBSUB-100		Initial version.
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
		@CurrentUserID			int = 1
*/

DECLARE @RC					int,
		@RejectionReason	varchar(200) = NULL,
		@RequestStatus		varchar(4) = '0001'

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

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployer_ParentChild_Request_Update ============================================	*/
