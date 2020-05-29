CREATE PROCEDURE [sub].[uspDeclaration_Get]
@DeclarationID	int
AS
/*	==========================================================================================
	Purpose:	Get declaration information on bases of a DeclarationID.

	14-06-2019	Sander van Houten		OTIBSUB-1147	Added STIP parts.
	11-10-2018	Jaap van Assenbergh		OTIBSUB-715		Added ModifyUntil.
	24-09-2018	Sander van Houten		OTIBSUB-295		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		sel.DeclarationID,
		sel.DeclarationNumber,
		sel.EmployerNumber,
		sel.SubsidySchemeID,
		sel.DeclarationDate,
		sel.InstituteID,
		sel.CourseID,
		sel.DeclarationStatus,
		sel.[Location],
		sel.ElearningSubscription,
		sel.StartDate,
		sel.EndDate,
		sel.DeclarationAmount,
		sel.ApprovedAmount,
		sel.StatusReason,
		sel.InternalMemo,
		CAST(CASE WHEN sel.ModifyUntil IS NOT NULL OR sel.DeclarationStatus = '0019' 
				THEN 1 
				ELSE 0 
			 END AS bit) CanModify,
		sel.ModifyUntil
FROM
		(
			SELECT
					d.DeclarationID,
					CAST(d.DeclarationID AS varchar(6))				AS DeclarationNumber,
					d.EmployerNumber,
					d.SubsidySchemeID,
					d.DeclarationDate,
					COALESCE(stpd.InstituteID, d.InstituteID)		AS InstituteID,
					COALESCE(osrd.CourseID, stpd.EducationID)		AS CourseID,
					COALESCE(osrd.CourseName, stpd.EducationName)	AS CourseName,
					d.DeclarationStatus,
					osrd.[Location],
					osrd.ElearningSubscription,
					d.StartDate,
					COALESCE(stpd.EndDate, d.EndDate)				AS EndDate,
					d.DeclarationAmount,
					d.ApprovedAmount,
					d.StatusReason,
					d.InternalMemo,
					CASE WHEN d.SubsidySchemeID = 4
						THEN CASE WHEN DATEADD(MM, 6, d.StartDate) > CAST(GETDATE() AS date) 
								   AND d.DeclarationStatus = '0001' 
								THEN DATEADD(MM, 6, d.StartDate)
								ELSE NULL 
							 END
						ELSE CASE WHEN d.StartDate > CAST(GETDATE() AS date) 
								   AND d.DeclarationStatus = '0001' 
								THEN d.StartDate 
								ELSE NULL 
							 END
					END	ModifyUntil
			FROM	sub.tblDeclaration d
			LEFT JOIN osr.viewDeclaration osrd ON osrd.DeclarationID = d.DeclarationID
			LEFT JOIN stip.viewDeclaration stpd ON stpd.DeclarationID = d.DeclarationID
			WHERE	d.DeclarationID = @DeclarationID
		) sel

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Get ================================================================	*/
