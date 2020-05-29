

CREATE PROCEDURE [sub].[usp_CONNECT_Education_Upd]
@tblEducation	sub.uttEducation READONLY
AS
/*	==========================================================================================
	Purpose:	Update Educations with current Education data from Etalage.

	23-08-2019	Sander van Houten			OTIBSUB-1263		Process change in nominal duration.
	29-07-2019	Jaap van Assenbergh			Initial version.
	==========================================================================================	*/
DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SET NOCOUNT ON

DECLARE @EducationID			int,
		@EducationName			varchar(255),
		@EducationType			varchar(24),
		@EducationLevel			varchar(24),
		@StartDate				date,
		@LatestStartDate		date,
		@EndDate				date,
		@NominalDuration		int,
		@NominalDuration_Prev	int,
		@IsEligible				bit = 1,
		@IsEligibleInDS			bit,
		@CurrentUserID			int = 1,
		@RC						int

DECLARE @GetDate				date = GETDATE()

DECLARE cur_Education CURSOR FOR 
	SELECT	imp.EducationID,
			imp.EducationName,
			imp.EducationType,
			imp.EducationLevel,
			imp.StartDate,
			imp.LatestStartDate,
			imp.EndDate,
			imp.IsEligible,
			CASE
				WHEN eie.EducationID IS NULL
				THEN 0
				ELSE 1
			END IsEligibleInDS,					
			imp.NominalDuration,
			sub.NominalDuration
	FROM	@tblEducation imp
	LEFT JOIN sub.tblEducation sub
			ON	sub.EducationID = imp.EducationID
	LEFT JOIN sub.tblEducation_IsEligible eie
			ON	eie.EducationID = imp.EducationID
			AND	eie.FromDate <= @GetDate
			AND (
					eie.UntilDate IS NULL
				OR
					eie.UntilDate > @GetDate
				)	
	WHERE	sub.EducationID IS NULL
	   OR	( sub.EducationID IS NOT NULL
			AND (	COALESCE(sub.EducationName, '') <> COALESCE(imp.EducationName, '')
				OR	COALESCE(sub.EducationType, '') <> COALESCE(imp.EducationType, '')
				OR	COALESCE(sub.EducationLevel, '') <> COALESCE(imp.EducationLevel, '')
				OR	COALESCE(sub.StartDate, '1900-01-01') <> COALESCE(imp.StartDate, '1900-01-01')
				OR	COALESCE(sub.LatestStartDate, '1900-01-01') <> COALESCE(imp.LatestStartDate, '1900-01-01')
				OR	COALESCE(sub.EndDate, '1900-01-01') <> COALESCE(imp.EndDate, '1900-01-01')
				OR	COALESCE(sub.NominalDuration, 0) <> COALESCE(imp.NominalDuration, 0)
				OR	COALESCE(imp.IsEligible, 0) <>	
				CASE
					WHEN eie.EducationID IS NULL
					THEN 0
					ELSE 1
				END
				)
			)
/* Loop through all selected institutes to update or insert the data from Etalage.	*/
OPEN cur_Education

FETCH FROM cur_Education INTO	@EducationID,
								@EducationName,
								@EducationType,
								@EducationLevel,
								@StartDate,
								@LatestStartDate,
								@EndDate,
								@IsEligible,
								@IsEligibleInDS,
								@NominalDuration,
								@NominalDuration_Prev

WHILE @@FETCH_STATUS = 0  
BEGIN
	-- Update or Insert education.
	EXECUTE @RC =	sub.uspEducation_Upd
					@EducationID,
					@EducationName,
					@EducationType,
					@EducationLevel,
					@StartDate,
					@LatestStartDate,
					@EndDate,
					@NominalDuration,
					@CurrentUserID	

	IF	@IsEligible <>  @IsEligibleInDS
	BEGIN
		IF @IsEligible = 0 
		BEGIN
			UPDATE	sub.tblEducation_IsEligible
			SET		UntilDate = @GetDate
			WHERE	EducationID = @EducationID
			AND		FromDate <= @GetDate
			AND		UntilDate IS NULL
		END
		ELSE
		BEGIN 
			UPDATE	sub.tblEducation_IsEligible				-- If change is on the same day.
			SET		UntilDate = NULL						-- Insert results into duplicate key
			WHERE	EducationID = @EducationID				-- So clear the UntilDate
			AND		FromDate = @GetDate

			IF @@ROWCOUNT = 0
			BEGIN
				INSERT INTO	sub.tblEducation_IsEligible
					(
						EducationID,
						FromDate
					)
				VALUES	
					(
						@EducationID,
						@GetDate
					)
			END
		END
	END

	-- Save education for processing change in nominal duration.
	IF ISNULL(@NominalDuration, 0) <> ISNULL(@NominalDuration_Prev, 0)
	BEGIN
		INSERT INTO sub.tblEducation_NominalDuration_History
			(
				EducationID,
				NominalDuration_New,
				NominalDuration_Old,
				DateCreated,
				DateProcessed
			)
		VALUES
			(
				@EducationID,
				@NominalDuration,
				@NominalDuration_Prev,
				GETDATE(),
				NULL
			)
	END

	-- Get next education.
	FETCH NEXT FROM cur_Education INTO	@EducationID,
										@EducationName,
										@EducationType,
										@EducationLevel,
										@StartDate,
										@LatestStartDate,
										@EndDate,
										@IsEligible,
										@IsEligibleInDS,
										@NominalDuration,
										@NominalDuration_Prev
END

CLOSE cur_Education
DEALLOCATE cur_Education

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.usp_CONNECT_Education_Upd =====================================================	*/
