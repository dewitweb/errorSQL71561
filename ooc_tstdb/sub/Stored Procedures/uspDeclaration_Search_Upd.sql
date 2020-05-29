
CREATE PROCEDURE [sub].[uspDeclaration_Search_Upd]
AS

/*	==========================================================================================
	Purpose:	Generate a searchstring for declaration

	16-09-2019	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

IF (
		SELECT	COUNT(1)
		FROM	sub.tblDeclaration_Search decls
		WHERE	decls.DateChanged IS NOT NULL
	)	> 0
BEGIN
	DECLARE @ExecutedProcedureID int = 0
	EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

	UPDATE	decls
	SET		SearchField =	CAST(decls.DeclarationID AS varchar(6))
							+ '|' + ISNULL(s.SubsidySchemeName, '')
							+ '|' + ISNULL(er.EmployerNumber, '')
							+ '|' + ISNULL(er.EmployerName, '')
							+ '|' + COALESCE(osrd.CourseName, stpd.EducationName, '')
							+ '|' + COALESCE(c.SearchName, e.SearchName, '')
							+ '|' + ISNULL(CAST(pd.JournalEntryCode AS varchar(8)), ''),
			DateChanged = NULL
	FROM	sub.tblDeclaration_Search decls
	INNER JOIN sub.tblDeclaration decl
			ON	decls.DeclarationID = decl.DeclarationID
	INNER JOIN sub.tblSubsidyScheme s 
			ON	s.SubsidySchemeID = decl.SubsidySchemeID
	INNER JOIN sub.tblEmployer er 
			ON	er.EmployerNumber = decl.EmployerNumber
	LEFT JOIN osr.viewDeclaration osrd 
			ON	osrd.DeclarationID = decl.DeclarationID
	LEFT JOIN evc.viewDeclaration evcd 
			ON	evcd.DeclarationID = decl.DeclarationID
	LEFT JOIN stip.viewDeclaration stpd 
			ON	stpd.DeclarationID = decl.DeclarationID
	LEFT JOIN sub.tblCourse c 
			ON	c.CourseID = osrd.CourseID
	LEFT JOIN sub.tblEducation e 
			ON	e.EducationID = stpd.EducationID
	LEFT JOIN sub.tblPaymentRun_Declaration pd 
			ON	pd.DeclarationID = decls.DeclarationID
	WHERE	decls.DateChanged IS NOT NULL

	EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

END
/*	== sub.uspDeclaration_Search_Upd ============================================================	*/
