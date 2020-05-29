CREATE VIEW [sub].[viewDeclaration_Institute]
AS

WITH cte_LastExtension AS
(
	SELECT	DeclarationID,
			MAX(ExtensionID)	AS MaxExtensionID
	FROM	sub.tblDeclaration_Extension
	GROUP BY 
			DeclarationID
)
SELECT	decl.DeclarationID,
		COALESCE( li.InstituteID, inst.InstituteID)													AS InstituteID,
		COALESCE( dus.InstituteName, li.InstituteName, inst.InstituteName, 'Instituut onbekend')	AS InstituteName
FROM	sub.tblDeclaration decl
LEFT JOIN sub.tblInstitute inst ON inst.InstituteID = decl.InstituteID
LEFT JOIN sub.tblDeclaration_Unknown_Source dus ON dus.DeclarationID = decl.DeclarationID
LEFT JOIN cte_LastExtension le ON le.DeclarationID = decl.DeclarationID
LEFT JOIN sub.tblDeclaration_Extension dex ON dex.DeclarationID = le.DeclarationID AND dex.ExtensionID = le.MaxExtensionID
LEFT JOIN sub.tblInstitute li ON li.InstituteID = dex.InstituteID

