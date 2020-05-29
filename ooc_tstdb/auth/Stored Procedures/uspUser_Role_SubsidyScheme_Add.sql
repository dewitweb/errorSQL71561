CREATE PROCEDURE [auth].[uspUser_Role_SubsidyScheme_Add]
@UserID			    int,
@RoleID			    int,
@SubsidySchemeID    int,
@CurrentUserID	    int
AS
/*	==========================================================================================
	Purpose:	Connect a subsidyschemeid to a role for a specific user.

	08-10-2019	Sander van Houten	OTIBSUB-1446     Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*  Testdata.
DECLARE @UserID			    int = 7,
        @RoleID			    int = 1,
        @SubsidySchemeID    int = 1,
        @CurrentUserID	    int = 1
--  */

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

-- Insert new record in auth.tblUser_Role
INSERT INTO auth.tblUser_Role_SubsidyScheme
	(
		UserID,
		RoleID,
        SubsidySchemeID
	)
VALUES
	(
		@UserID,
		@RoleID,
        @SubsidySchemeID
	)

-- Save new data
SELECT	@XMLdel = NULL,
		@XMLins = (SELECT	* 
					FROM	auth.tblUser_Role_SubsidyScheme
					WHERE	UserID = @UserID
					  AND	RoleID = @RoleID
                      AND   SubsidySchemeID = @SubsidySchemeID
					FOR XML PATH)

-- Log action in tblHistory
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = CAST(@UserID AS varchar(18)) + '|' 
               + CAST(@RoleID AS varchar(18)) + '|' 
               + CAST(@SubsidySchemeID AS varchar(18))

	EXEC his.uspHistory_Add
			'auth.tblUser_Role_SubsidyScheme',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== auth.uspUserRole_Add_SubsidyScheme ================================================	*/
