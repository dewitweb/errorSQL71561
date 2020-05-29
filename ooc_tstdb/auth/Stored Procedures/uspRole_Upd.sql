CREATE PROCEDURE [auth].[uspRole_Upd]
@RoleID				        int,
@RoleName			        varchar(50),
@RoleDescription	        varchar(100),
@Abbrevation		        varchar(3),
@ApplicationID		        int = -1,
@IsSubsidySchemeDependent   bit,
@CurrentUserID		        int = 1
AS
/*	==========================================================================================
	Purpose:	Insert or update a record in the table auth.tblRole

    08-10-2019	Sander van Houten	OTIBSUB-1446    Added field IsSubsidySchemeDependent.
	12-02-2019	Sander van Houten	OTIBSUB-764     Added RoleName to resultset.
	23-08-2018	Sander van Houten	CurrentUserID added.
	01-05-2018	Sander van Houten	Conversion from uspGebruikersGroep_Upd for new datamodel
	05-03-2018	Sander van Houten	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF ISNULL(@RoleID, 0) = 0
BEGIN
	INSERT INTO auth.tblRole
		(
			RoleName,
			RoleDescription,
			Abbreviation,
			ApplicationID,
            IsSubsidySchemeDependent
		)
	VALUES
		(
			@RoleName,
			@RoleDescription,
			@Abbrevation,
			@ApplicationID,
            @IsSubsidySchemeDependent
		)

	SET	@RoleID = SCOPE_IDENTITY()

	-- Save new data
	SELECT	@XMLdel = NULL,
			@XMLins = (SELECT	* 
					   FROM		auth.tblRole
					   WHERE	RoleID = @RoleID
					     AND	ApplicationID = @ApplicationID
					   FOR XML PATH)
END
ELSE
BEGIN
	-- Save old record
	SELECT	@XMLdel = (SELECT	* 
					   FROM		auth.tblRole
					   WHERE	RoleID = @RoleID
					     AND	ApplicationID = @ApplicationID
					   FOR XML PATH)

	-- Update exisiting record
	UPDATE	auth.tblRole
	SET		RoleName = @RoleName,
			RoleDescription = @RoleDescription,
			Abbreviation = @Abbrevation,
            IsSubsidySchemeDependent = @IsSubsidySchemeDependent
	WHERE	RoleID = @RoleID
	  AND	ApplicationID = @ApplicationID

	-- Save new record
	SELECT	@XMLins = (SELECT	* 
					   FROM		auth.tblRole
					   WHERE	RoleID = @RoleID
					     AND	ApplicationID = @ApplicationID
					   FOR XML PATH)
END

-- Log action in tblHistory
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @RoleID

	EXEC his.uspHistory_Add
			'auth.tblRole',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SELECT RoleID = @RoleID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== auth.uspRole_Upd ======================================================================	*/
