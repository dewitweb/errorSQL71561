
CREATE PROCEDURE [sub].[uspDeclaration_Investigation_Del]
@DeclarationID	int,
@InvestigationDate datetime,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose:	Remove sub.tblDeclaration_Investigation record.

	02-08-2018	Sander van Houten		CurrentUserID added.
	23-07-2018	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

-- Save old record
SELECT	@XMLdel = (SELECT * 
				   FROM sub.tblDeclaration_Investigation 
			       WHERE DeclarationID = @DeclarationID
				   FOR XML PATH),
		@XMLins = NULL

-- Delete record
DELETE
FROM	sub.tblDeclaration_Investigation
WHERE	DeclarationID = @DeclarationID
AND		InvestigationDate = @InvestigationDate

-- Log action in tblHistory
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @DeclarationID + '|' + CAST(@InvestigationDate AS varchar(19))

	EXEC his.uspHistory_Add
			'sub.tblDeclaration_Investigation',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Investigation_Del ==================================================	*/
