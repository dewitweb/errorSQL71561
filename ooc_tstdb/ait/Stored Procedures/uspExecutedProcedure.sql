
CREATE procedure [ait].[uspExecutedProcedure] 
(	@ExecutedProcedureID int = 0, 
	@ObjectID int
)

AS

BEGIN

IF @ExecutedProcedureID = 0 
BEGIN
	INSERT INTO ait.tblExecutedProcedure(ObjectID, StartTime)
	VALUES (@ObjectID, GETDATE())

	SET @ExecutedProcedureID = SCOPE_IDENTITY()
END
ELSE
BEGIN
	UPDATE	ait.tblExecutedProcedure
	SET		StopTime = GETDATE()
	WHERE	ExecutedProcedureID = @ExecutedProcedureID
END

RETURN @ExecutedProcedureID

END
