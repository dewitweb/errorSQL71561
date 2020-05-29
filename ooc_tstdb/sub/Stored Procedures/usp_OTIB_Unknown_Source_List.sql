
CREATE PROCEDURE [sub].[usp_OTIB_Unknown_Source_List]
@kpiID	int
AS
/*	==========================================================================================
	Purpose:	Select list of courses in Etalage by listnumber 8 or 9

	10-05-2019	Jaap van Assenbergh	OTIBSUB-1068
				Originele invoer door werkgever van nieuw instituut en/of opleiding altijd tonen
	05-03-2019	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/
DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT	decl.DeclarationID,
		s.SubsidySchemeName + 
		CASE WHEN evcd.IsEVC500 = 1 
			THEN '-500' 
			ELSE ''
			END SubsidySchemeName,
		CAST(decl.DeclarationID AS varchar(6))				DeclarationNumber,
		di.InstituteName									InstituteName,
		dus.CourseName										CourseName,
		dus.SentToSourceSystemDate							SendDate,
		DATEDIFF(d, dus.SentToSourceSystemDate, GetDate())	DaysWaiting
FROM	sub.tblDeclaration decl
INNER JOIN sub.tblDeclaration_Unknown_Source dus ON dus.DeclarationID = decl.DeclarationID
LEFT JOIN evc.viewDeclaration evcd ON evcd.DeclarationID = decl.DeclarationID
INNER JOIN sub.tblSubsidyScheme s ON s.SubsidySchemeID = decl.SubsidySchemeID
INNER JOIN sub.viewDeclaration_Institute di ON di.DeclarationID = decl.DeclarationID
LEFT JOIN hrs.tblDeclaration_HorusNr_OTIBDSID dhrs ON dhrs.DeclarationID = decl.DeclarationID
WHERE	(
				dus.CourseID IS NULL				-- OSR
		OR		dus.EducationID IS NOT NULL			-- STIP Instituut in combinatie met opleiding niet bekend.
			AND dus.InstituteID IS NULL
		)		
AND		dus.SentToSourceSystemDate IS NOT NULL
AND		decl.DeclarationStatus NOT IN ('0001')
AND		@kpiID = CASE WHEN dhrs.DeclarationID IS NOT NULL THEN 9 ELSE 8 END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.usp_OTIB_Unknown_Source_List ======================================================	*/

