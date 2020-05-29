

CREATE PROCEDURE [stip].[uspDeclaration_Mentor_Del]
@DeclarationID	int,
@MentorID		int,
@CurrentUserID	int = 1
AS

/*	==========================================================================================
	Purpose: 	Delete from stip.tblDeclaration_Mentor.

	02-05-2019	Jaap van Assenbergh	Inital version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Return		int = 1

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

-- Save old record.
SELECT	@XMLdel = (	SELECT 	*
					FROM	stip.tblDeclaration_Mentor
					WHERE	DeclarationID = @DeclarationID
					AND		MentorID = @MentorID
					FOR XML PATH ),
		@XMLins = NULL

-- Delete record.
DELETE
FROM	stip.tblDeclaration_Mentor
WHERE	DeclarationID = @DeclarationID
AND		MentorID = @MentorID

-- Log action in his.tblHistory.
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @DeclarationID

	EXEC his.uspHistory_Add
			'stip.tblDeclaration_Mentor',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SET @Return = 0

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== stip.uspDeclaration_Mentor_Del ========================================================	*/
