
CREATE PROCEDURE sub.uspEmployer_Subsidy_GracePeriod_Upd
@GracePeriodID		int,
@EmployerSubsidyID	int,
@EndDate			date,
@CreationUserID		int,
@CreationDate		date,
@GracePeriodReason	varchar(MAX),
@HandledByUserID	int,
@HandledDate		date,
@GracePeriodStatus	varchar(20),
@CurrentUserID		int = 1
AS
/*	==========================================================================================
	Purpose: 	Update sub.tblEmployer_Subsidy_GracePeriod on basis of GracePeriodID.

	14-01-2020	Jaap van Assenbergh	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Return		int = 1

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF ISNULL(@GracePeriodID, 0) = 0
BEGIN
	-- Add new record
	INSERT INTO sub.tblEmployer_Subsidy_GracePeriod
		(
			EmployerSubsidyID,
			EndDate,
			CreationUserID,
			CreationDate,
			GracePeriodReason,
			HandledByUserID,
			HandledDate,
			GracePeriodStatus
		)
	VALUES
		(
			@EmployerSubsidyID,
			@EndDate,
			@CreationUserID,
			@CreationDate,
			@GracePeriodReason,
			@HandledByUserID,
			@HandledDate,
			@GracePeriodStatus
		)

	SET	@GracePeriodID = SCOPE_IDENTITY()

	-- Save new record.
	SELECT	@XMLdel = NULL,
			@XMLins = (	SELECT 	*
						FROM	sub.tblEmployer_Subsidy_GracePeriod
						WHERE	GracePeriodID = @GracePeriodID
						FOR XML PATH )

END
ELSE
BEGIN
	-- Save old record.
	SELECT	@XMLdel = (	SELECT 	*
						FROM	sub.tblEmployer_Subsidy_GracePeriod
						WHERE	GracePeriodID = @GracePeriodID
						FOR XML PATH )

	-- Update existing record.
	UPDATE	sub.tblEmployer_Subsidy_GracePeriod
	SET
			EmployerSubsidyID	= @EmployerSubsidyID,
			EndDate				= @EndDate,
			CreationUserID		= @CreationUserID,
			CreationDate		= @CreationDate,
			GracePeriodReason	= @GracePeriodReason,
			HandledByUserID		= @HandledByUserID,
			HandledDate			= @HandledDate,
			GracePeriodStatus	= @GracePeriodStatus
	WHERE	GracePeriodID = @GracePeriodID

	-- Save new record.
	SELECT	@XMLins = (	SELECT 	*
						FROM	sub.tblEmployer_Subsidy_GracePeriod
						WHERE	GracePeriodID = @GracePeriodID
						FOR XML PATH )
END

-- Log action in his.tblHistory.
IF CAST(ISNULL(@XMLdel, '') AS varchar(MAX)) <> CAST(ISNULL(@XMLins, '') AS varchar(MAX))
BEGIN
	SET @KeyID = @GracePeriodID

	EXEC his.uspHistory_Add
			'sub.tblEmployer_Subsidy_GracePeriod',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SELECT GracePeriodID = @GracePeriodID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployer_Subsidy_GracePeriod_Upd ===============================================	*/
