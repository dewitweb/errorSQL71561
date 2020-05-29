


CREATE PROCEDURE [sub].[uspEducation_Institute_Upd]
@EducationID	int,
@InstituteID	int,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose: 	Update sub.tblEducation_Institute on basis of EducationID.

	31-07-2019	Jaap van Assenbergh	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Return		int = 1

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF	(
		SELECT	COUNT(EducationID) 
		FROM	sub.tblEducation_Institute
		WHERE	EducationID =  @EducationID
		AND		InstituteID = @InstituteID
	) = 0
BEGIN
	-- Add new record
	INSERT INTO sub.tblEducation_Institute
		(
			EducationID,
			InstituteID
		)
	VALUES
		(
			@EducationID,
			@InstituteID
		)

	-- Save new record.
	SELECT	@XMLdel = NULL,
			@XMLins = (	SELECT 	*
						FROM	sub.tblEducation_Institute
						WHERE	EducationID = @EducationID
						FOR XML PATH )

END

-- Log action in his.tblHistory.
IF CAST(ISNULL(@XMLdel, '') AS varchar(MAX)) <> CAST(ISNULL(@XMLins, '') AS varchar(MAX))
BEGIN
	SET @KeyID = @EducationID

	EXEC his.uspHistory_Add
			'sub.tblEducation_Institute',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEducation_Institute_Upd ========================================================	*/
