
CREATE PROCEDURE [sub].[uspDeclaration_Email_Del]
@EmailID		int,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose:	Remove Declaration_Email record.

	02-08-2018	Sander van Houten		CurrentUserID added.
	27-07-2018	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

-- Save old record
SELECT	@XMLdel = (SELECT * 
				   FROM sub.tblDeclaration_Email 
			       WHERE EmailID = @EmailID
				   FOR XML PATH),
		@XMLins = NULL

-- Delete Email Users
DELETE
FROM	sub.tblDeclaration_Email_User
WHERE	EmailID = @EmailID

-- Delete record
DELETE
FROM	sub.tblDeclaration_Email
WHERE	EmailID = @EmailID

-- Log action in tblHistory
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @EmailID

	EXEC his.uspHistory_Add
			'sub.tblDeclaration_Email',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			NULL
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Email_Del ===========================================================	*/
