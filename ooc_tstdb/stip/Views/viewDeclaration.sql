
CREATE VIEW [stip].[viewDeclaration]
AS
WITH cte_LastMentor AS
(
	SELECT	dem.*
	FROM	stip.tblDeclaration_Mentor dem
	INNER JOIN (
				SELECT	DeclarationID, 
						MAX(StartDate)	AS MaxStartDate
				FROM	stip.tblDeclaration_Mentor 
				GROUP BY 
						DeclarationID
			   ) sub1
	ON		sub1.DeclarationID = dem.DeclarationID
	AND		sub1.MaxStartDate = dem.StartDate
),
cte_LastExtension AS
(
	SELECT	dex.*
	FROM	sub.tblDeclaration_Extension dex
	INNER JOIN (
				SELECT	DeclarationID, 
						MAX(ExtensionID)	AS MaxExtensionID
				FROM	sub.tblDeclaration_Extension
				GROUP BY 
						DeclarationID
			   ) sub1
	ON		sub1.DeclarationID = dex.DeclarationID
	AND		sub1.MaxExtensionID = dex.ExtensionID
)
SELECT	DISTINCT
		d.DeclarationID, 
		d.EmployerNumber, 
		d.SubsidySchemeID,
		d.DeclarationDate,
		d.InstituteID,
		d.StartDate															AS OriginalStartDate,
		d.EndDate															AS OriginalEndDate,
		le.ExtensionID														AS LastExtensionID, 
		ISNULL(le.StartDate, d.StartDate)									AS StartDate,
		ISNULL(le.EndDate, d.EndDate)										AS EndDate,
		CAST(ISNULL(d.DeclarationAmount, 0.00) AS decimal (19,2))			AS DeclarationAmount,
		d.ApprovedAmount,
		d.DeclarationStatus,
		d.StatusReason,
		d.InternalMemo,
		sd.EducationID,
		CASE	WHEN edu.EducationName IS NULL 
				THEN COALESCE(dus.CourseName, 'Opleiding onbekend')
				ELSE edu.EducationName + ' (' + CAST(edu.EducationID AS varchar(10)) + ')'
		END																	AS EducationName,
        edu.EducationLevel,
		edu.NominalDuration,
		sd.DiplomaDate,
		sd.DiplomaCheckedByUserID,
		sd.DiplomaCheckedDate,
		sd.TerminationDate,
		sd.TerminationReason,
		lm.MentorID															AS LastMentorID,
		men.FullName														AS LastMentorFullName,
		emp.EmployeeNumber,
		emp.FullName														AS Employee,
		emp.DateOfBirth
FROM	sub.tblDeclaration d
INNER JOIN stip.tblDeclaration sd 
		ON sd.DeclarationID =  d.DeclarationID
LEFT JOIN sub.tblEducation edu 
		ON edu.EducationID = sd.EducationID
LEFT JOIN sub.tblDeclaration_Employee dem 
		ON dem.DeclarationID = d.DeclarationID
LEFT JOIN sub.tblEmployee emp 
		ON emp.EmployeeNumber = dem.EmployeeNumber
LEFT JOIN sub.tblDeclaration_Unknown_Source dus 
		ON dus.DeclarationID = d.DeclarationID
LEFT JOIN cte_LastMentor lm 
		ON lm.DeclarationID = d.DeclarationID
LEFT JOIN sub.tblMentor men	
		ON men.MentorID = lm.MentorID
LEFT JOIN cte_LastExtension le 
		ON le.DeclarationID = d.DeclarationID
WHERE	d.SubsidySchemeID = 4
