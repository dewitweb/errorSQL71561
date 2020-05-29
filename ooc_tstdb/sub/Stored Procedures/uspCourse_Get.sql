
CREATE PROCEDURE [sub].[uspCourse_Get]
	@CourseID int
AS
/*	==========================================================================================
	Purpose:	Get course information from tblCourse for specific course.

	24-09-2018	Sander van Houten	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

	SELECT
			CourseID,
			InstituteID,
			CourseName,
			FollowedUpByCourseID,
			CourseCosts,
			ClusterNumber
	FROM	sub.tblCourse

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspCourse_Get =====================================================================	*/
