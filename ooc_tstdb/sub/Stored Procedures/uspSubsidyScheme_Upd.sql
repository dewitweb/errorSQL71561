
CREATE PROCEDURE [sub].[uspSubsidyScheme_Upd]
@SubsidySchemeID	int,
@SubsidySchemeName	varchar(50),
@CurrentUserID		int = 1
AS
/*	==========================================================================================
	Purpose:	Update sub.tblSubsidyScheme on the basis of SubsidySchemeID.

	03-08-2018	Sander van Houten		CurrentUserID added.
	18-07-2018	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF ISNULL(@SubsidySchemeID, 0) = 0
BEGIN
	-- Add new record
	INSERT INTO sub.tblSubsidyScheme
		(
			SubsidySchemeName
		)
	VALUES
		(
			@SubsidySchemeName
		)

	SET	@SubsidySchemeID = SCOPE_IDENTITY()

	-- Save new record
	SELECT	@XMLdel = NULL,
			@XMLins = (SELECT * 
					   FROM   sub.tblSubsidyScheme 
					   WHERE  SubsidySchemeID = @SubsidySchemeID
					   FOR XML PATH)
END
ELSE
BEGIN
	-- Save old record
	SELECT	@XMLdel = (SELECT * 
					   FROM   sub.tblSubsidyScheme 
					   WHERE  SubsidySchemeID = @SubsidySchemeID
					   FOR XML PATH)

	-- Update exisiting record
	UPDATE	sub.tblSubsidyScheme
	SET
			SubsidySchemeName	= @SubsidySchemeName
	WHERE	SubsidySchemeID = @SubsidySchemeID

	-- Save new record
	SELECT	@XMLins = (SELECT * 
					   FROM   sub.tblSubsidyScheme 
					   WHERE  SubsidySchemeID = @SubsidySchemeID
					   FOR XML PATH)
END

-- Log action in tblHistory
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @SubsidySchemeID

	EXEC his.uspHistory_Add
			'sub.tblSubsidyScheme',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SELECT SubsidySchemeID = @SubsidySchemeID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspSubsidyScheme_Upd ==============================================================	*/
