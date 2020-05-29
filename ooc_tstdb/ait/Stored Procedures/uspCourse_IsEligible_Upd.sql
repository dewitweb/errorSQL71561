
CREATE PROCEDURE [ait].[uspCourse_IsEligible_Upd]
@CourseID	int,
@FromDate	date,
@UntilDate	date,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose: 	Update sub.tblCourse_IsEligible on basis of CourseID.

	02-10-2019	Jaap van Assenbergh	Initial version.
				
	Noot		Wordt alleen gebruikt in de front-end test
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Return		int = 1

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF (
		SELECT	COUNT(1)
		FROM	sub.tblCourse_IsEligible
		WHERE	CourseID = @CourseID
		AND		UntilDate IS NULL
	) = 0
BEGIN
	-- Add new record
	INSERT INTO sub.tblCourse_IsEligible
		(
			CourseID,
			FromDate,
			UntilDate
		)
	VALUES
		(
			@CourseID,
			@FromDate,
			@UntilDate
		)

	-- Save new record.
	SELECT	@XMLdel = NULL,
			@XMLins = (	SELECT 	*
						FROM	sub.tblCourse_IsEligible
						WHERE	CourseID = @CourseID
						FOR XML PATH )

END
ELSE
BEGIN
	-- Save old record.
	SELECT	@XMLdel = (	SELECT 	*
						FROM	sub.tblCourse_IsEligible
						WHERE	CourseID = @CourseID
						FOR XML PATH )

	-- Update existing record.
	UPDATE	sub.tblCourse_IsEligible
	SET
			FromDate	= @FromDate,
			UntilDate	= @UntilDate
	WHERE	CourseID = @CourseID

	-- Save new record.
	SELECT	@XMLins = (	SELECT 	*
						FROM	sub.tblCourse_IsEligible
						WHERE	CourseID = @CourseID
						FOR XML PATH )
END

-- Log action in his.tblHistory.
IF CAST(ISNULL(@XMLdel, '') AS varchar(MAX)) <> CAST(ISNULL(@XMLins, '') AS varchar(MAX))
BEGIN
	SET @KeyID = @CourseID

	EXEC his.uspHistory_Add
			'sub.tblCourse_IsEligible',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SELECT CourseID = @CourseID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== ait.uspCourse_IsEligible_Upd ==========================================================	*/
