
CREATE VIEW [osr].[viewDeclaration]
AS

SELECT	d.DeclarationID, 
		d.EmployerNumber, 
		d.SubsidySchemeID,
		d.DeclarationDate,
		d.InstituteID,
		d.StartDate,
		d.EndDate,
		d.DeclarationAmount,
		d.ApprovedAmount,
		d.DeclarationStatus,
		d.StatusReason,
		d.InternalMemo,
		osrd.CourseID,
		osrd.ElearningSubscription,
		osrd.[Location],
		COALESCE(dus.CourseName, cur.CourseName, 'Opleiding onbekend')	CourseName
FROM	sub.tblDeclaration d
LEFT JOIN osr.tblDeclaration osrd ON osrd.DeclarationID =  d.DeclarationID
LEFT JOIN sub.tblCourse cur ON cur.CourseID = osrd.CourseID
LEFT JOIN sub.tblDeclaration_Unknown_Source dus ON dus.DeclarationID = d.DeclarationID
WHERE	d.SubsidySchemeID = 1

