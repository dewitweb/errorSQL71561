CREATE PROCEDURE [sub].[usp_CONNECT_Education_Institute_Upd]
	@tblEducation_Institute	sub.uttEducation_Institute READONLY
AS
/*	==========================================================================================
	Purpose:	update Educations with current Education data from Etalage.

	29-07-2019	Jaap van Assenbergh			Initial version.
	==========================================================================================	*/
DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @EducationID		int,
		@InstituteID		int,
		@CurrentUserID		int = 1,
		@RC					int

DECLARE cur_Education_Institute CURSOR FOR 
	SELECT	imp.EducationID,
			imp.InstituteID
	FROM	@tblEducation_Institute imp
	LEFT JOIN sub.tblEducation_Institute sub 
			ON	sub.EducationID = imp.EducationID
			AND	sub.InstituteID = imp.InstituteID
	WHERE	sub.EducationID IS NULL
		
/* Loop through all selected institutes to insert the data from Etalage.	*/
OPEN cur_Education_Institute

FETCH FROM cur_Education_Institute 
	INTO	@EducationID,
			@InstituteID

WHILE @@FETCH_STATUS = 0  
BEGIN

	EXECUTE @RC =	sub.uspEducation_Institute_Upd
					@EducationID,
					@InstituteID,
					@CurrentUserID	

	FETCH NEXT FROM cur_Education_Institute
			INTO	@EducationID,
					@InstituteID
END

CLOSE cur_Education_Institute
DEALLOCATE cur_Education_Institute

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.usp_CONNECT_Education_Institute_Upd ===========================================	*/
