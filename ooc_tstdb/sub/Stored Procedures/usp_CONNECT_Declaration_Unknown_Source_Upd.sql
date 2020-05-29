CREATE PROCEDURE [sub].[usp_CONNECT_Declaration_Unknown_Source_Upd]
@DeclarationID					int,
@InstituteID					int,
@InstituteName					varchar(255),
@Location						varchar(24),
@EndDate						date,
@HorusID						varchar(6),
@IsEVC							bit,
@IsEVCWV						bit,
@IsEducationProvider			bit,
@CourseID						int,
@CourseName						varchar(200),
@EducationID					int,
@NominalDuration				int,
@FollowedUpByCourseID			int,
@CourseCosts					decimal(19,4),
@ClusterNumber					varchar(11),
@IsEligible						bit,
@SentToSourceSystemDate			datetime,
@ReceivedFromSourceSystemDate	datetime
AS
/*	==========================================================================================
	Purpose:	Update the dataset in sub.tblDeclaration_Unknown_Source.

	Notes:		There can 2 moments on which this procedure is executed.
				1. The record was in the result of usp_CONNECT_Declaration_Unknown_Source_Upd
					and Etalage has given a signal that the data was received correctly.
				   In this case the @SentSourceSystemDate will be the only field that has changed.
				
				2. An OTIB employee has matched the unknown source in Etalage and 
					the new information is given in the parameters.
				   In this case the @@ReceivedFromSourceSystemDate will be filled also.

	14-10-2019	Jaap van Assenbergh	OTIBSUB-1619
									Import EVC-WV instituten uit Etalage
	17-06-2018	Jaap van Assenbergh	OTIBSUB-1179 Toevoegen nieuw instituut/Nominale duur

	10-05-2019	Sander van Houten	OTIBSUB-1068	Added call to 
										sub.uspDeclaration_Unknown_Source_Upd_ByConnect.
	20-11-2018	Jaap van Assenbergh	Parameter @IsEVC added.
	22-10-2018	Sander van Houten	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @SubsidyschemeID	int
DECLARE @IsEligibleInDS		bit
DECLARE @GetDate			date = GETDATE()

DECLARE @CurrentUserID	int = 1,
		@RC				int

/* Update the Declaration also.	*/
DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

/*	Update or insert Institute (if necessery).	*/
IF @InstituteID IS NOT NULL
BEGIN
	IF NOT EXISTS	(	SELECT	1 
						FROM	sub.tblInstitute
						WHERE	InstituteID = @InstituteID
						  AND	COALESCE(InstituteName, '') = COALESCE(@InstituteName, '')
					)
	BEGIN
		EXECUTE @RC = [sub].[uspInstitute_Upd] 
			@InstituteID,
			@InstituteName,
			@Location,
			@EndDate,
			@HorusID,
			@IsEvc,
			@IsEvcWV,
			@IsEducationProvider,
			@CurrentUserID
	END
	--IF @IsEvc IS NOT NULL
	--BEGIN
	--	SET @SubsidyschemeID = 3
	--	EXECUTE @RC = sub.uspSubsidyScheme_Institute_Add_Del 
	--		@SubsidyschemeID,
	--		@InstituteID,
	--		@IsEVC,
	--		@CurrentUserID
	--END
END

/*	Update or insert Course (if necessery).	*/
IF @CourseID IS NOT NULL
BEGIN
	IF NOT EXISTS
		(	SELECT	1 
			FROM	sub.tblCourse
			WHERE	CourseID = @CourseID
				AND	COALESCE(CourseName, '') = COALESCE(@CourseName, '')
				AND	COALESCE(FollowedUpByCourseID, 0) = COALESCE(@FollowedUpByCourseID, 0)
				AND	COALESCE(CourseCosts, 0.00) = COALESCE(@CourseCosts, 0.00)
		)
	BEGIN
		EXECUTE @RC = [sub].[uspCourse_Upd] 
			@CourseID,
			@InstituteID,
			@CourseName,
			@FollowedUpByCourseID,
			@CourseCosts,
			@ClusterNumber,
			@CurrentUserID
	END

	SELECT	@IsEligibleInDS = 1
	FROM	sub.tblCourse_IsEligible cie
	WHERE	CourseID = @CourseID
	AND		@GetDate BETWEEN cie.FromDate AND ISNULL(cie.UntilDate, @GetDate)	
	
	IF	@IsEligible <>  @IsEligibleInDS
	BEGIN
		IF @IsEligibleInDS = 0 
		BEGIN
			UPDATE	tblCourse_IsEligible
			SET		UntilDate = @GetDate
			WHERE	CourseID = @CourseID
			AND		FromDate <= @GetDate
			AND		UntilDate IS NULL
		END
		ELSE
		BEGIN 
			INSERT INTO	tblCourse_IsEligible
				(
					CourseID,
					FromDate
				)
			VALUES	
				(
					@CourseID,
					GETDATE()
				)
		END
	END

END

IF @EducationID IS NOT NULL AND @NominalDuration IS NOT NULL			-- NominalDuration vanuit Etalage
BEGIN
	EXECUTE @RC = [sub].[uspEducation_Upd_NominalDuration] 
		@EducationID,
		@NominalDuration,
		@CurrentUserID
END

/*	Update tblDeclaration_Unknown_Source (option 1 and 2).	*/
EXECUTE @RC = [sub].[uspDeclaration_Unknown_Source_Upd_ByConnect] 
	@DeclarationID,
	@InstituteID,
	@CourseID,
	@NominalDuration,
	@SentToSourceSystemDate,
	@ReceivedFromSourceSystemDate,
	@CurrentUserID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

RETURN 0

/*	== sub.usp_CONNECT_Declaration_Unknown_Source_Upd ========================================	*/
