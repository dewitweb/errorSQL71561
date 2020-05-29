
CREATE PROCEDURE sub.uspEmployer_Subsidy_GracePeriod_Email_Upd
@GracePeriodID	int,
@EmailID		int,
@Token			varchar(50),
@UserID			int,
@ValidUntil		date,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose: 	Update sub.tblEmployer_Subsidy_GracePeriod_Email on basis of GracePeriodID.

	14-01-2020	Sander van Houten	OTIBSUB-1827    Initial version.
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
	INSERT INTO sub.tblEmployer_Subsidy_GracePeriod_Email
		(
			GracePeriodID,
            EmailID,
			Token,
			UserID,
			ValidUntil
		)
	VALUES
		(
			@GracePeriodID,
            @EmailID,
			@Token,
			@UserID,
			@ValidUntil
		)

	SET	@GracePeriodID = SCOPE_IDENTITY()

	-- Save new record.
	SELECT	@XMLdel = NULL,
			@XMLins = (	SELECT 	*
						FROM	sub.tblEmployer_Subsidy_GracePeriod_Email
						WHERE	GracePeriodID = @GracePeriodID
                        AND     EmailID = @EmailID
						FOR XML PATH )

END
ELSE
BEGIN
	-- Save old record.
	SELECT	@XMLdel = (	SELECT 	*
						FROM	sub.tblEmployer_Subsidy_GracePeriod_Email
						WHERE	GracePeriodID = @GracePeriodID
                        AND     EmailID = @EmailID
						FOR XML PATH )

	-- Update existing record.
	UPDATE	sub.tblEmployer_Subsidy_GracePeriod_Email
	SET
			Token			= @Token,
			UserID			= @UserID,
			ValidUntil		= @ValidUntil
	WHERE	GracePeriodID = @GracePeriodID
    AND     EmailID = @EmailID

	-- Save new record.
	SELECT	@XMLins = (	SELECT 	*
						FROM	sub.tblEmployer_Subsidy_GracePeriod_Email
						WHERE	GracePeriodID = @GracePeriodID
                        AND     EmailID = @EmailID
						FOR XML PATH )
END

-- Log action in his.tblHistory.
IF CAST(ISNULL(@XMLdel, '') AS varchar(MAX)) <> CAST(ISNULL(@XMLins, '') AS varchar(MAX))
BEGIN
	SET @KeyID = CAST(@GracePeriodID AS varchar(18)) + '|' + CAST(@EmailID AS varchar(18))

	EXEC his.uspHistory_Add
			'sub.tblEmployer_Subsidy_GracePeriod_Email',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SELECT GracePeriodID = @GracePeriodID,
       EmailID = @EmailID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployer_Subsidy_GracePeriod_Email_Upd =========================================	*/
