
CREATE PROCEDURE [sub].[uspEducation_Upd]
@EducationID		int,
@EducationName		varchar(200),
@EducationType		varchar(24),
@EducationLevel		varchar(24),
@StartDate			date,
@LatestStartDate	date,
@EndDate			date,
@NominalDuration	int,
@CurrentUserID		int = 1
AS
/*	==========================================================================================
	Purpose: 	Update sub.tblEducation on basis of EducationID.

	31-07-2019	Jaap van Assenbergh	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SET NOCOUNT ON 

DECLARE @SearchName varchar(200)

DECLARE @Return		int = 1

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)


	--	Update SearchName
SELECT @SearchName = sub.usfCreateSearchString(@EducationName)

IF	(
		SELECT	COUNT(EducationID) 
		FROM	sub.tblEducation
		WHERE	EducationID =  @EducationID
	) = 0 
BEGIN
	-- Add new record
	INSERT INTO sub.tblEducation
		(
			EducationID,
			EducationName,
			EducationType,
			EducationLevel,
			StartDate,
			LatestStartDate,
			EndDate,
			SearchName,
			NominalDuration
		)
	VALUES
		(
			@EducationID,
			@EducationName,
			@EducationType,
			@EducationLevel,
			@StartDate,
			@LatestStartDate,
			@EndDate,
			@SearchName,
			@NominalDuration
		)

	-- Save new record.
	SELECT	@XMLdel = NULL,
			@XMLins = (	SELECT 	*
						FROM	sub.tblEducation
						WHERE	EducationID = @EducationID
						FOR XML PATH )

END
ELSE
BEGIN
	-- Save old record.
	SELECT	@XMLdel = (	SELECT 	*
						FROM	sub.tblEducation
						WHERE	EducationID = @EducationID
						FOR XML PATH )

	-- Update existing record.
	UPDATE	sub.tblEducation
	SET
			EducationName	= @EducationName,
			EducationType	= @EducationType,
			EducationLevel	= @EducationLevel,
			StartDate		= @StartDate,
			LatestStartDate	= @LatestStartDate,
			EndDate			= @EndDate,
			SearchName		= @SearchName,
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

/*	== sub.uspEducation_Upd ==================================================================	*/
