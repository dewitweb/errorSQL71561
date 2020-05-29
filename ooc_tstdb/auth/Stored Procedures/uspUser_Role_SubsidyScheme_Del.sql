CREATE PROCEDURE [auth].[uspUser_Role_SubsidyScheme_Del]
@UserID			    int,
@RoleID			    int,
@SubsidySchemeID    int,
@CurrentUserID	    int
AS
/*	==========================================================================================
	Puspose:	Delete a subsidyschemeid from a specific role connection for a specific user.

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

-- Save old record
SELECT	@XMLdel = (SELECT	* 
					FROM	auth.tblUser_Role_SubsidyScheme
					WHERE	UserID = @UserID
					  AND	RoleID = @RoleID
                      AND   SubsidySchemeID = @SubsidySchemeID
					FOR XML PATH),
		@XMLins = NULL

-- Delete record
DELETE
FROM	auth.tblUser_Role_SubsidyScheme
WHERE	UserID = @UserID
AND     RoleID = @RoleID
AND     SubsidySchemeID = @SubsidySchemeID

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

/*	== auth.uspUser_Role_Del =================================================================	*/
