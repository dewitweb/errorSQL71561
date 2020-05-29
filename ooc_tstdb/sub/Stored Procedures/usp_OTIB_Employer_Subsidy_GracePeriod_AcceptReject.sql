CREATE PROCEDURE [sub].[usp_OTIB_Employer_Subsidy_GracePeriod_AcceptReject]
@GracePeriodID      int,
@Accept             bit = 0,
@GracePeriodToken   varchar(50) = NULL,
@CurrentUserID		int = NULL
AS
/*	==========================================================================================
	Purpose:	Hanlde a request for a grace period in sub.tblEmployer_Subsidy_GracePeriod.

    Notes:      At least 1 of the parameters @GracePeriodToken and @CurrentUserID must be given.
                If the request is succesfully handled a trigger will fire, updating the 
                EndDeclarationPeriod field in the table sub.tblEmployer_Subsidy.
	
    14-01-2020	Sander van Houten	OTIBSUB-1827    Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Testdata
DECLARE	@GracePeriodID      int = 1,
        @Accept             bit = 0,
        @GracePeriodToken   varchar(50) = NULL,
        @CurrentUserID		int = 1
--*/

DECLARE @Return     int = 1

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

-- If @CurrentUserID is not given, get it by using the given token.
IF @CurrentUserID IS NULL
BEGIN
    SELECT  @CurrentUserID = UserID
    FROM    sub.tblEmployer_Subsidy_GracePeriod_Email
    WHERE   GracePeriodID = @GracePeriodID
    AND     Token = @GracePeriodToken
    AND     ValidUntil >= @LogDate
END

IF @CurrentUserID IS NOT NULL
BEGIN
    -- Save old record.
    SELECT	@XMLdel = (	SELECT 	*
                        FROM	sub.tblEmployer_Subsidy_GracePeriod
                        WHERE	GracePeriodID = @GracePeriodID
                        FOR XML PATH )

    -- Update existing record.
    UPDATE	sub.tblEmployer_Subsidy_GracePeriod
    SET
            HandledByUserID	    = @CurrentUserID,
            HandledDate	        = @LogDate,
            GracePeriodStatus   = CASE @Accept
                                    WHEN 1 THEN '0002'
                                    ELSE '0003'
                                    END
    WHERE	GracePeriodID = @GracePeriodID

    -- Save new record.
    SELECT	@XMLins = (	SELECT 	*
                        FROM	sub.tblEmployer_Subsidy_GracePeriod
                        WHERE	GracePeriodID = @GracePeriodID
                        FOR XML PATH )

    -- Log action in tblHistory.
    IF @@ROWCOUNT > 0
    BEGIN
        SET @KeyID = CAST(@GracePeriodID AS varchar(18))

        EXEC his.uspHistory_Add
                'sub.tblEmployer_Subsidy_GracePeriod',
                @KeyID,
                @CurrentUserID,
                @LogDate,
                @XMLdel,
                @XMLins
    END

    SET @Return = 0
END
ELSE
BEGIN   -- Error!
    SET @Return = 1
END

RETURN @Return

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.usp_OTIB_Employer_Subsidy_GracePeriod_AcceptReject ================================	*/
