CREATE PROCEDURE [sub].[usp_RepServ_05_DeclarationsBPVFromHorusLive]
@SearchString	varchar(max)
AS

/*	==========================================================================================
	Purpose: 	Source for BPV declaration list from Horus in SSRS.

	16-08-2019	Sander van Houten		OTIBSUB-1176	Use hrs.viewBPV instead of hrs.tblBPV.
	28-06-2019	H. Melissen				OTIBSUB-926		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Testdata. */
--DECLARE @SearchString varchar(max) = '00036251'

/*	Prepare SearchString.	*/
SELECT	@SearchString = ISNULL(@SearchString, '')

SELECT	@SearchString = sub.usfCreateSearchString (@SearchString)

DECLARE @SearchWord TABLE (Word nvarchar(max) NOT NULL)

INSERT INTO @SearchWord (Word)
SELECT s FROM sub.utfSplitString(@SearchString, ' ')

/*	Select the resultset. */
SELECT	hor.EmployeeNumber,
		hor.EmployerNumber,
		CONVERT(varchar(10), hor.StartDate, 120)		AS StartDate,
		CONVERT(varchar(10), hor.EndDate, 120)			AS EndDate,
		hor.CourseID,
		hor.CourseName,
		hor.StatusCode,
		hor.StatusDescription
FROM	hrs.viewBPV hor
CROSS JOIN @SearchWord sw
WHERE
		'T' = 												-- MN Number employee
				CASE
					WHEN		@SearchString = '' 
						THEN 'T'
					WHEN		CHARINDEX(sw.Word, hor.EmployeeNumber, 1) > 0 
						THEN	'T'
				END
	OR		'T' = 											-- MN Number employer
				CASE
					WHEN		@SearchString = '' 
						THEN 'T'
					WHEN		CHARINDEX(sw.Word, hor.EmployerNumber, 1) > 0 
						THEN	'T'
				END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.usp_RepServ_05_DeclarationsBPVFromHorusLive ==========================================	*/
