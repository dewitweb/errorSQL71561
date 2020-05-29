

CREATE PROCEDURE [hrs].[uspBPV_Upd]
@EmployeeNumber		varchar(8),
@EmployerNumber		varchar(6),
@StartDate			date,
@EndDate			date,
@CourseID			int,
@CourseName			varchar(200),
@StatusCode			tinyint,
@StatusDescription	varchar(100),
@TypeBPV            varchar(10),
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose: 	Update hrs.tblBPV on basis of 
				- EmployeeNumber
				- EmployerNumber
				- StartDate
				- CourseID

	05-06-2019	Jaap van Assenbergh	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Return		int = 1

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF	ISNULL(@StatusDescription, '') = ''
	SELECT @StatusDescription = SettingValue
	FROM	sub.tblApplicationSetting
	WHERE	SettingName = 'HorusStatusCode'
	AND		SettingCode = @StatusCode

IF (
		SELECT	COUNT(EmployerNumber)
		FROM	hrs.tblBPV
		WHERE	EmployerNumber = @EmployerNumber
		AND		EmployeeNumber = @EmployeeNumber
		AND		StartDate = @StartDate
		AND		CourseID = @CourseID
	) = 0
BEGIN
	-- Add new record
	INSERT INTO hrs.tblBPV
		(
			EmployeeNumber,
			EmployerNumber,
			StartDate,
			EndDate,
			CourseID,
			CourseName,
			StatusCode,
			StatusDescription,
            TypeBPV
		)
	VALUES
		(
			@EmployeeNumber,
			@EmployerNumber,
			@StartDate,
			@EndDate,
			@CourseID,
			@CourseName,
			@StatusCode,
			@StatusDescription,
            @TypeBPV
		)

	SET	@EmployeeNumber = SCOPE_IDENTITY()

	-- Save new record.
	SELECT	@XMLdel = NULL,
			@XMLins = (	SELECT 	*
						FROM	hrs.tblBPV
						WHERE	EmployeeNumber = @EmployeeNumber
						FOR XML PATH )

END
ELSE
BEGIN
	-- Save old record.
	SELECT	@XMLdel = (	SELECT 	*
						FROM	hrs.tblBPV
						WHERE	EmployeeNumber = @EmployeeNumber
						FOR XML PATH )

	-- Update existing record.
	UPDATE	hrs.tblBPV
	SET
			EmployeeNumber		= @EmployeeNumber,
			EmployerNumber		= @EmployerNumber,
			StartDate			= @StartDate,
			EndDate				= @EndDate,
			CourseID			= @CourseID,
			CourseName			= @CourseName,
			StatusCode			= @StatusCode,
			StatusDescription	= @StatusDescription,
            TypeBPV             = @TypeBPV
	WHERE	EmployerNumber = @EmployerNumber
	AND		EmployeeNumber = @EmployeeNumber
	AND		StartDate = @StartDate
	AND		CourseID = @CourseID

	-- Save new record.
	SELECT	@XMLins = (	SELECT 	*
						FROM	hrs.tblBPV
						WHERE	EmployeeNumber = @EmployeeNumber
						FOR XML PATH )
END

-- Log action in his.tblHistory.
IF CAST(ISNULL(@XMLdel, '') AS varchar(MAX)) <> CAST(ISNULL(@XMLins, '') AS varchar(MAX))
BEGIN
	SET @KeyID = @EmployeeNumber

	EXEC his.uspHistory_Add
			'hrs.tblBPV',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SELECT EmployeeNumber = @EmployeeNumber

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== hrs.uspBPV_Upd ========================================================================	*/
