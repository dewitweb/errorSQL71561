

/*	==========================================================================================
	12-09-2019:	J.v.Assenbergh
				Create a searching
	==========================================================================================
*/
CREATE FUNCTION [sub].[usfDeclaration_SearchField] 
(
	@DeclarationID int
)
RETURNS nvarChar(MAX)
AS
BEGIN

DECLARE @SearchString varchar(MAX)

SELECT @SearchString =
	CAST(d.DeclarationID AS varchar(6)) 
	+ ' ' + s.SubsidySchemeName  
	+ ' ' + ISNULL(er.EmployerNumber, '') 
	+ ' ' + ISNULL(er.EmployerName, '') 
	+ ' ' + ISNULL(c.SearchName, '') 
	+ ' ' + ISNULL(e.SearchName, '') 
	+ ' ' + ISNULL(
					CAST(
							(
								SELECT	CAST(pd.JournalEntryCode as varchar(8)) + ' ' 
								FROM	sub.tblPaymentRun_Declaration pd 
								WHERE	JournalEntryCode IS NOT NULL
								AND		pd.DeclarationID = d.DeclarationID
								FOR XML PATH(''), TYPE
							)	AS varchar(MAX))
					, '')
FROM	sub.tblDeclaration d
INNER JOIN sub.tblSubsidyScheme s ON s.SubsidySchemeID = d.SubsidySchemeID
INNER JOIN sub.tblEmployer er ON er.EmployerNumber = d.EmployerNumber
LEFT JOIN osr.viewDeclaration osrd ON osrd.DeclarationID = d.DeclarationID
LEFT JOIN evc.viewDeclaration evcd ON evcd.DeclarationID = d.DeclarationID
LEFT JOIN stip.viewDeclaration stpd ON stpd.DeclarationID = d.DeclarationID
LEFT JOIN sub.tblCourse c ON c.CourseID = osrd.CourseID
LEFT JOIN sub.tblEducation e ON e.EducationID = stpd.EducationID
LEFT JOIN sub.viewDeclaration_TotalPaidAmount_2019 dtp ON dtp.DeclarationID = d.DeclarationID
LEFT JOIN sub.tblPaymentRun_Declaration pd ON pd.DeclarationID = d.DeclarationID
WHERE d.DeclarationID = @DeclarationID


RETURN	@SearchString

END

