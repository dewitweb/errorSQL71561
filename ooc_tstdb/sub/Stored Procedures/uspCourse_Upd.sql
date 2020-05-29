
CREATE PROCEDURE [sub].[uspCourse_Upd]
@CourseID				int,
@InstituteID			int,
@CourseName				varchar(200),
@FollowedUpByCourseID	int,
@CourseCosts			decimal(19,4),
@ClusterNumber			varchar(11),
@CurrentUserID			int = 1
AS
/*	==========================================================================================
	Purpose:	Add or Update sub.tblCourse on the basis of known CourseID (from Etalage).

	08-08-2018	Sander van Houten		Initial version (OTIBSUB-111).
	25-01-2019	Jaap van Assenbergh		NEN-EN 12345 en NEN 3140 wordt NENEN12345 en NEN3140 in SearchName
										Ook voor ISO
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @SearchName varchar(MAX)

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF NOT EXISTS (SELECT 1 FROM sub.tblCourse WHERE CourseID = @CourseID)
BEGIN
	-- Add new record
	INSERT INTO sub.tblCourse
        (
			CourseID,
			InstituteID,
            CourseName,
            FollowedUpByCourseID,
            CourseCosts,
			ClusterNumber
		)
	VALUES
		(
			@CourseID,
			@InstituteID,
			@CourseName,
			@FollowedUpByCourseID,
			@CourseCosts,
			@ClusterNumber
		)

	--	Update SearchName
	UPDATE	sub.tblCourse 
	SET		SearchName = sub.usfCreateSearchString(CourseName)
	WHERE	CourseID = @CourseID
	
	-- Save new record
	SELECT	@XMLdel = NULL,
			@XMLins = (SELECT * 
					   FROM sub.tblCourse
					   WHERE CourseID = @CourseID
					   FOR XML PATH)
END
ELSE
BEGIN
	-- Save old record
	SELECT	@XMLdel = (SELECT * 
					   FROM sub.tblCourse
					   WHERE CourseID = @CourseID
					   FOR XML PATH)

	-- Update existing record
	UPDATE	sub.tblCourse
	SET
			InstituteID				= @InstituteID,
			CourseName				= @CourseName,
			FollowedUpByCourseID	= @FollowedUpByCourseID,
			CourseCosts				= @CourseCosts,
			ClusterNumber			= @ClusterNumber
	WHERE	CourseID = @CourseID

	--	Update SearchName
	SELECT @SearchName = sub.usfCreateSearchString(@CourseName)

	/* Replace space when NENENISO #####										*/
	SELECT	@SearchName = REPLACE(@SearchName, 'NENENISO ', 'NENENISO')
	FROM
			(
				SELECT	CHARINDEX( 'NENENISO ', @SearchName, 1) pos
			) p
	WHERE pos <> 0
	AND ISNUMERIC(SUBSTRING(@SearchName, pos + 9, 8)) = 1
	AND 'T' =	CASE	WHEN pos = 1 THEN 'T'
						WHEN SUBSTRING(@SearchName, pos - 1, 1) = ' ' THEN 'T'
						END 

	/* Replace space when ISO #####												*/
	SELECT	@SearchName = REPLACE(@SearchName, 'ISO ', 'ISO')
	FROM
			(
				SELECT	CHARINDEX( 'ISO ', @SearchName, 1) pos
			) p
	WHERE pos <> 0
	AND ISNUMERIC(SUBSTRING(@SearchName, pos + 4, 5)) = 1
	AND 'T' =	CASE	WHEN pos = 1 THEN 'T'
						WHEN SUBSTRING(@SearchName, pos - 1, 1) = ' ' THEN 'T'
						END


	/* Replace space when NENEN #####											*/
	SELECT	@SearchName = REPLACE(@SearchName, 'NENEN ', 'NENEN')
	FROM
			(
				SELECT	CHARINDEX( 'NENEN ', @SearchName, 1) pos
			) p
	WHERE pos <> 0
	AND ISNUMERIC(SUBSTRING(@SearchName, pos + 6, 5)) = 1
	AND 'T' =	CASE	WHEN pos = 1 THEN 'T'
						WHEN SUBSTRING(@SearchName, pos - 1, 1) = ' ' THEN 'T'
						END 

	/* Replace space when NEN ####												*/
	SELECT	@SearchName = REPLACE(@SearchName, 'NEN ', 'NEN')
	FROM
			(
				SELECT	CHARINDEX( 'NEN ', @SearchName, 1) pos
			) p
	WHERE pos <> 0
	AND ISNUMERIC(SUBSTRING(@SearchName, pos + 4, 4)) = 1
	AND 'T' =	CASE	WHEN pos = 1 THEN 'T'
						WHEN SUBSTRING(@SearchName, pos - 1, 1) = ' ' THEN 'T'
						END

	UPDATE	sub.tblCourse 
	SET		SearchName = sub.usfCreateSearchString(@SearchName)
	WHERE	CourseID = @CourseID

	-- Save new record
	SELECT	@XMLins = (SELECT * 
					   FROM sub.tblCourse
					   WHERE CourseID = @CourseID
					   FOR XML PATH)
END

-- Log action in tblHistory
IF CAST(ISNULL(@XMLdel, '') as varchar(MAX)) <> CAST(ISNULL(@XMLins, '') as varchar(MAX))
BEGIN
	SET @KeyID = @CourseID

	EXEC his.uspHistory_Add
			'sub.tblCourse',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins

END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspCourse_Upd =====================================================================	*/
