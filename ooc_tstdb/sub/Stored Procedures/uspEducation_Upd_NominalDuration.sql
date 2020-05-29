

CREATE PROCEDURE [sub].[uspEducation_Upd_NominalDuration]
@EducationID		int,
@NominalDuration	int,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose: 	Update sub.tblEducation on basis of EducationID.

	17-06-2019	Jaap van Assenbergh	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Return		int = 1

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

BEGIN
	-- Save old record.
	SELECT	@XMLdel = (	SELECT 	*
						FROM	sub.tblEducation
						WHERE	EducationID = @EducationID
						FOR XML PATH )

	-- Update existing record.
	UPDATE	sub.tblEducation
	SET
			NominalDuration	= @NominalDuration
	WHERE	EducationID = @EducationID

	-- Save new record.
	SELECT	@XMLins = (	SELECT 	*
						FROM	sub.tblEducation
						WHERE	EducationID = @EducationID
						FOR XML PATH )
END

-- Log action in his.tblHistory.
IF CAST(ISNULL(@XMLdel, '') AS varchar(MAX)) <> CAST(ISNULL(@XMLins, '') AS varchar(MAX))
BEGIN
	SET @KeyID = @EducationID

	EXEC his.uspHistory_Add
			'sub.tblEducation',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SELECT EducationID = @EducationID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEducation_Upd_NominalDuration ==============================================	*/
