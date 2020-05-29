
CREATE PROCEDURE [sub].[usp_CONNECT_Course_Upd]
@tblCourse	sub.uttCourse READONLY
AS
/*	==========================================================================================
	Purpose:	update courses with current course data from Etalage.

	22-10-2018	Sander van Houten			Initial version.
	==========================================================================================	*/
DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @CourseID				int,
		@InstituteID			int,
		@CourseName				varchar(255),
		@FollowedUpByCourseID	int,
		@CourseCosts			decimal(19,4),
		@ClusterNumber			varchar(11),
		@IsEligible				bit,
		@IsEligibleInDS			bit,
		@CurrentUserID			int = 1,
		@RC						int

DECLARE @GetDate				date = GETDATE()

DECLARE cur_Course CURSOR FOR 
	SELECT	imp.CourseID,
			imp.InstituteID,
			imp.CourseName,
			imp.FollowedUpByCourseID,
			imp.CourseCosts,
			imp.ClusterNumber,
			imp.IsEligible,
			CASE
				WHEN cie.CourseID IS NULL
				THEN 0
				ELSE 1
			END IsEligibleInDS
	FROM	@tblCourse imp
	LEFT JOIN sub.tblCourse sub
			ON	sub.CourseID = imp.CourseID
	LEFT JOIN sub.tblCourse_IsEligible cie
			ON	cie.CourseID = imp.CourseID
			AND	cie.FromDate <= @GetDate
			AND (
					cie.UntilDate IS NULL
				OR
					cie.UntilDate > @GetDate
				)	
	WHERE	sub.CourseID IS NULL
	   OR	( sub.CourseID IS NOT NULL
			AND (	COALESCE(sub.InstituteID, 0) <> COALESCE(imp.InstituteID, 0)
				OR	COALESCE(sub.CourseName, '') <> COALESCE(imp.coursename, '')
				OR	COALESCE(sub.FollowedUpByCourseID, 0) <> COALESCE(imp.FollowedUpByCourseID, 0)
				OR	COALESCE(sub.ClusterNumber, '') <> COALESCE(imp.ClusterNumber, '')
				OR	COALESCE(sub.CourseCosts, 0.00) <> COALESCE(imp.CourseCosts, 0.00)
				OR	COALESCE(imp.IsEligible, 0) <>	
						CASE
							WHEN cie.CourseID IS NULL
							THEN 0
							ELSE 1
						END
				)
			)
		
/* Loop through all selected institutes to update or insert the data from Etalage.	*/
OPEN cur_Course

FETCH NEXT FROM cur_Course 
INTO	@CourseID, 
		@InstituteID, 
		@CourseName, 
		@FollowedUpByCourseID,
		@CourseCosts, 
		@ClusterNumber, 
		@IsEligible, 
		@IsEligibleInDS

WHILE @@FETCH_STATUS = 0  
BEGIN
	EXECUTE @RC = [sub].[uspCourse_Upd] 
		@CourseID,
		@InstituteID,
		@CourseName,
		@FollowedUpByCourseID,
		@CourseCosts,
		@ClusterNumber,
		@CurrentUserID

	IF	@IsEligible <>  @IsEligibleInDS
	BEGIN
		IF @IsEligible = 0 
		BEGIN
			UPDATE	sub.tblCourse_IsEligible
			SET		UntilDate = @GetDate
			WHERE	CourseID = @CourseID
			AND		FromDate <= @GetDate
			AND		UntilDate IS NULL
		END
		ELSE
		BEGIN 


			UPDATE	sub.tblCourse_IsEligible					-- If change is on the same day.
			SET		UntilDate = NULL							-- Insert results into duplicate key
			WHERE	CourseID = @CourseID						-- So clear the UntilDate
			AND		FromDate = @GetDate

			IF @@ROWCOUNT = 0
			BEGIN
				INSERT INTO	sub.tblCourse_IsEligible
					(
						CourseID,
						FromDate
					)
				VALUES	
					(
						@CourseID,
						@GetDate
					)
			END
		END
	END

	FETCH FROM cur_Course
	INTO	@CourseID, 
			@InstituteID, 
			@CourseName, 
			@FollowedUpByCourseID,
			@CourseCosts, 
			@ClusterNumber, 
			@IsEligible, 
			@IsEligibleInDS
END

CLOSE cur_Course
DEALLOCATE cur_Course

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.usp_CONNECT_Course_Upd ============================================================	*/
