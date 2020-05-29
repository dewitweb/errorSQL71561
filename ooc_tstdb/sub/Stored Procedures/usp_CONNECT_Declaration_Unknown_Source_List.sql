

CREATE PROCEDURE [sub].[usp_CONNECT_Declaration_Unknown_Source_List]
AS
/*	==========================================================================================
	Purpose:	List all institutes and courses that employers could not relate to 
				an existing institute and/or an existing course (with attachment(s)).

	27-09-2019	Jaap van Assenbergh	OTIBSUB-501
									Nieuw ingevoerd instituut direct kunnen kiezen bij volgende 
									declaratie, ook als deze nog niet in Etalage behandeld is
	03-07-2019	Jaap van Assenbergh	OTIBSUB-1316 Bij nieuw instituut in DS locatie meegeven 
									naar Etalage
	17-06-2019	Jaap van Assenbergh	OTIBSUB-1179 Toevoegen nieuw instituut/Nominale duur
									bij STIP declaratie
	24-05-2019	Jaap van Assenbergh	OTIBSUB-1078 Routing tussen DS en Etalage wijzigen
	16-01-2019	Jaap van Assenbergh	Select only records of declarations that have 
									a StartDate in the future from now (OTIBSUB-673).
	22-10-2018	Sander van Houten	Initial version.
	==========================================================================================	*/

--DECLARE @ExecutedProcedureID int = 0
--EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT	dus.DeclarationID,
		decl.SubsidySchemeID,
		decl.EmployerNumber, 
		dus.InstituteID,
		ISNULL(dus.InstituteName, inst.Institutename) +
		CASE WHEN ISNULL(osrd.ElearningSubscription, 1) = 0 
					AND LTRIM(ISNULL(osrd.[Location], '')) <> ''
					AND dus.InstituteID IS NULL
				THEN ' (' + osrd.[Location] + ')' 
				ELSE '' END  								Institutename,
		dus.CourseID,
		dus.CourseName,
		NULL												EducationID,
		NULL												NominalDuration,
		(	SELECT	
				dea.AttachmentID,
				dea.OriginalFileName,
				dea.DocumentType
				FROM	sub.tblDeclaration_Attachment dea
				WHERE	dea.DeclarationID = dus.DeclarationID
				FOR XML PATH('Attachment'), ROOT('Attachments')
		) AS AttachmentXML
FROM	sub.tblDeclaration decl
INNER JOIN sub.tblDeclaration_Unknown_Source dus ON dus.DeclarationID = decl.DeclarationID
LEFT JOIN sub.tblInstitute inst ON inst.InstituteID = Decl.InstituteID
LEFT JOIN osr.tblDeclaration osrd ON osrD.DeclarationID = decl.DeclarationID
WHERE   dus.SentToSourceSystemDate IS NULL
AND		dus.DeclarationAcceptedDate IS NOT NULL								-- Reason to go to Connect
AND		decl.SubsidySchemeID IN (1, 3)										-- OSR, EVC
AND		decl.StartDate <= CAST(GETDATE() AS date)
AND     decl.DeclarationID >= 400000
AND		decl.DeclarationDate < DATEADD(MINUTE, -5, GETDATE())				-- OTIBET-228
UNION ALL
SELECT	dus.DeclarationID,
		decl.SubsidySchemeID, 
		decl.EmployerNumber, 
		dus.InstituteID,
		ISNULL(dus.InstituteName, inst.Institutename)		Institutename,
		NULL												CourseID,
		NULL												CourseName,
		sdec.EducationID,
		dus.NominalDuration,
		(	SELECT	
				dea.AttachmentID,
				dea.OriginalFileName,
				dea.DocumentType
				FROM	sub.tblDeclaration_Attachment dea
				WHERE	dea.DeclarationID = dus.DeclarationID
				FOR XML PATH('Attachment'), ROOT('Attachments')
		) AS AttachmentXML
FROM	sub.tblDeclaration decl
INNER JOIN sub.tblDeclaration_Unknown_Source dus ON dus.DeclarationID = decl.DeclarationID
INNER JOIN stip.tblDeclaration sdec ON sdec.DeclarationID = decl.DeclarationID				-- STIP
LEFT JOIN sub.tblInstitute inst ON inst.InstituteID = Decl.InstituteID
WHERE   dus.SentToSourceSystemDate IS NULL
AND		decl.StartDate <= CAST(GETDATE() AS date)
AND     decl.DeclarationID >= 400000
AND		decl.DeclarationDate < DATEADD(MINUTE, -5, GETDATE())

--EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.usp_CONNECT_UnknownInstitutes_List ================================================	*/
