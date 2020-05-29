CREATE PROCEDURE [stip].[uspDeclaration_Delete]
@DeclarationID	int,
@CurrentUserID	int = 1
AS

/*	==========================================================================================
	Purpose: 	Delete record from stip.tblDeclaration and all linked tables.

	13-06-2019	Sander van Houten		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Return		int = 1

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

DECLARE @MentorID int

/*	01. Delete stip.tblDeclaration_BPV.	*/
-- Save old record.
SELECT	@XMLdel = (	SELECT 	*
					FROM	stip.tblDeclaration_BPV
					WHERE	DeclarationID = @DeclarationID
					FOR XML PATH ),
		@XMLins = NULL

-- Delete record.
DELETE
FROM	stip.tblDeclaration_BPV
WHERE	DeclarationID = @DeclarationID

-- Log action in his.tblHistory.
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @DeclarationID

	EXEC his.uspHistory_Add
			'stip.tblDeclaration_BPV',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

/*	02. Delete stip.tblDeclaration_Mentor.	*/
-- Save old record.
DECLARE crs_Mentor CURSOR    
	LOCAL    
	FAST_FORWARD    
	READ_ONLY    
	FOR	SELECT	MentorID
		FROM	stip.tblDeclaration_Mentor
		WHERE	DeclarationID = @DeclarationID
	OPEN crs_Mentor
	FETCH FROM crs_Mentor
	INTO @MentorID
WHILE @@FETCH_STATUS = 0   
BEGIN

	EXECUTE stip.uspDeclaration_Mentor_Del @DeclarationID, @MentorID, @CurrentUserID

	FETCH NEXT FROM crs_Mentor
	INTO @MentorID
END
CLOSE crs_Mentor   
DEALLOCATE crs_Mentor

/*	03. Delete stip.tblDeclaration.	*/
-- Save old record.
SELECT	@XMLdel = (	SELECT 	*
					FROM	stip.tblDeclaration
					WHERE	DeclarationID = @DeclarationID
					FOR XML PATH ),
		@XMLins = NULL

-- Delete record.
DELETE
FROM	stip.tblDeclaration
WHERE	DeclarationID = @DeclarationID

-- Log action in his.tblHistory.
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @DeclarationID

	EXEC his.uspHistory_Add
			'stip.tblDeclaration',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SET @Return = 0

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

usp_Exit:
RETURN @Return

/*	== stip.uspDeclaration_Delete ============================================================	*/
