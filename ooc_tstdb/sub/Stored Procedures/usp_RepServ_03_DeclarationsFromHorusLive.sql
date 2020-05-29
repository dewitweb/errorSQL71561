
CREATE PROCEDURE [sub].[usp_RepServ_03_DeclarationsFromHorusLive]
@SearchString	varchar(max)
AS

/*	==========================================================================================
	Purpose: 	Source for declaration list from Horus in SSRS.

	10-04-2019	Sander van Houten	Inital version (OTIBSUB-936).
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Testdata.
DECLARE @SearchString varchar(max) = '315264'
--	*/

/*	Prepare SearchString.	*/
SELECT	@SearchString = ISNULL(@SearchString, '')

SELECT	@SearchString = sub.usfCreateSearchString (@SearchString)

DECLARE @SearchWord TABLE (Word nvarchar(max) NOT NULL)

INSERT INTO @SearchWord (Word)
SELECT s FROM sub.utfSplitString(@SearchString, ' ')

/*	Select the resultset. */
SELECT	hor.DeclarationNumber,
		hor.EmployerNumber,
		hor.DeclarationDate,
		hor.InstituteID,
		hor.InstituteName,
		hor.CourseNumber,
		hor.CourseName,
		CONVERT(varchar(10), hor.StartDate, 120)		AS StartDate,
		CONVERT(varchar(10), hor.EndDate, 120)			AS EndDate,
		hor.CourseLocation,
		hor.ElearningSubscription,
		hor.DeclarationAmount,
		hor.DeclarationAmountApproved,
		hor.DeclarationStatus,
		hor.StatusDescription,
		hor.ParentDeclarationNumber,
		CONVERT(varchar(10), hor.PaymentRunDate, 120)	AS PaymentRunDate,
		hor.PaymentRunID,
		hor.DeclarationNumber_ReversalPayment,
		hor.PaymentRunDate_ReversalPayment,
		hor.PaymentRunID_ReversalPayment
FROM	hrs.tblDeclaration_OSR2019 hor
CROSS JOIN @SearchWord sw
WHERE
		'T' = 												-- DeclarationID DS
				CASE
					WHEN		@SearchString = '' 
						THEN 'T'
					WHEN		CHARINDEX(sw.Word, hor.ParentDeclarationNumber, 1) > 0 
						THEN	'T'
				END
	OR
		'T' = 												-- DeclarationNumber Horus
				CASE
					WHEN		@SearchString = '' 
						THEN 'T'
					WHEN		CHARINDEX(sw.Word, hor.DeclarationNumber, 1) > 0 
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

/*	== sub.usp_RepServ_03_DeclarationsFromHorusLive ==========================================	*/