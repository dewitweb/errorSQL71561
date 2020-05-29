
CREATE PROCEDURE [auth].[uspApplication_Upd]
@ApplicationID		int,
@ApplicationName	varchar(100),
@CurrentUserID		int = 1
AS
/*	==========================================================================================
	Purpose:	Insert or update a record in the table tblApplication

	01-05-2018	Sander van Houten	Conversion from uspGebruikersGroep_Upd for new datamodel
	05-03-2018	Sander van Houten	Bijwerken auth.tblGebruikersGroep op basis van GebruikersGroepID
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF ISNULL(@ApplicationID, 0) = 0
BEGIN
	-- Insert new record
	INSERT INTO auth.tblApplication
		(
			ApplicationName
		)
	VALUES
		(
			@ApplicationName
		)

	SET	@ApplicationID = SCOPE_IDENTITY()

	-- Save new data
	SELECT	@XMLdel = NULL,
			@XMLins = (SELECT	* 
					   FROM		auth.tblApplication
					   WHERE	ApplicationID = @ApplicationID
					   FOR XML PATH)
END
ELSE
BEGIN
	-- Save old record
	SELECT	@XMLdel = (SELECT	* 
					   FROM		auth.tblApplication
					   WHERE	ApplicationID = @ApplicationID
					   FOR XML PATH)

	-- Update exisiting record
	UPDATE	auth.tblApplication
	SET		ApplicationName = @ApplicationName
	WHERE	ApplicationID = @ApplicationID

	-- Save new record
	SELECT	@XMLins = (SELECT	* 
					   FROM		auth.tblApplication
					   WHERE	ApplicationID = @ApplicationID
					   FOR XML PATH)
END

-- Log action in tblHistory
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @ApplicationID

	EXEC his.uspHistory_Add
			'auth.tblApplication',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SELECT ApplicationID = @ApplicationID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== auth.uspApplication_Upd ===============================================================	*/
