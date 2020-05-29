
CREATE PROCEDURE [auth].[uspRole_Del]
@RoleID			int,
@CurrentUserID	int = 1
AS

/*	==========================================================================================
	Purpose:	Delete a record from the table tblRole

	01-05-2018	Sander van Houten	Conversion from uspGebruikersGroep_Del for new datamodel
	05-03-2018	Sander van Houten	Verwijderen uit auth.tblGebruikersGroep
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

-- Save old record
SELECT	@XMLdel = (SELECT	* 
					FROM	auth.tblRole
					WHERE	RoleID = @RoleID
					FOR XML PATH),
		@XMLins = NULL

-- Delete record
DELETE
FROM	auth.tblRole
WHERE	RoleID = @RoleID

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

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== auth.uspRole_Del ======================================================================	*/
