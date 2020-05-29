
CREATE PROCEDURE [ait].[uspLog_Upd]
@LogID			int,
@LogDateTime	datetime,
@LogMessage		varchar(255),
@LogURL			varchar(255),
@LogLevel		int,
@PostBody		varchar(MAX),
@Stacktrace		varchar(MAX),
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose: 	Update ait.tblLog on basis of LogID.

	20-06-2019	Jaap van Assenbergh	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Return		int = 1

IF ISNULL(@LogID, 0) = 0
BEGIN
	-- Add new record
	INSERT INTO ait.tblLog
		(
			LogDateTime,
			LogMessage,
			LogURL,
			LogLevel,
			PostBody,
			Stacktrace,
			CurrentUserID
		)
	VALUES
		(
			@LogDateTime,
			@LogMessage,
			@LogURL,
			@LogLevel,
			@PostBody,
			@Stacktrace,
			@CurrentUserID
		)

	SET	@LogID = SCOPE_IDENTITY()
END
ELSE
BEGIN

	-- Update existing record.
	UPDATE	ait.tblLog
	SET
			LogDateTime		= @LogDateTime,
			LogMessage		= @LogMessage,
			LogURL			= @LogURL,
			LogLevel		= @LogLevel,
			PostBody		= @PostBody,
			Stacktrace		= @Stacktrace,
			CurrentUserID	= @CurrentUserID
	WHERE	LogID = @LogID
END

SELECT LogID = @LogID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== ait.uspLog_Upd ========================================================================	*/
