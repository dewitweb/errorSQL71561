
CREATE PROCEDURE [sub].[uspDeclaration_Unknown_Source_Del]
@DeclarationID	int,
@CurrentUserID	int = 1
AS

/*	==========================================================================================
	Purpose:	Remove tblDeclaration_Unknown_Source record.

	03-08-2018	Sander van Houten		CurrentUserID added.
	20-07-2018	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)
		
-- Save old record
SELECT	@XMLdel = (SELECT	* 
				   FROM		sub.tblDeclaration_Unknown_Source
				   WHERE	DeclarationID = @DeclarationID
				   FOR XML PATH),
		@XMLins = NULL

-- Delete record
DELETE
FROM	sub.tblDeclaration_Unknown_Source
WHERE	DeclarationID = @DeclarationID

-- Log action in tblHistory
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @DeclarationID

	EXEC his.uspHistory_Add
			'sub.tblDeclaration_Unknown_Source',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Unknown_Source_Del ==================================================	*/
