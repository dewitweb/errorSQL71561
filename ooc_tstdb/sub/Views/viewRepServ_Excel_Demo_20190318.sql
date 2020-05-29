create view sub.viewRepServ_Excel_Demo_20190318

as

/*	Doel: Demo voor overleg over rapportage op 18-03-2019 met OTIB.

	18-03-2019, H. Melissen		Demoversie (geen ticket in Jira).
*/

SELECT	subsidyscheme.SubsidySchemeName AS Regeling,
		declaration.DeclarationID AS Declaratienummer,
		declaration.EmployerNumber AS Werkgeversnummer,
		employer.EmployerName AS Werkgever,
		declaration.DeclarationDate AS Declaratiedatum,
		institute.InstituteName AS Instituut,
		declaration.StartDate AS Startdatum,
		declaration.EndDate AS Einddatum,
		FORMAT(declaration.DeclarationAmount, 'N', 'nl-NL') AS Gedeclareerd,
		FORMAT(declaration.ApprovedAmount, 'N', 'nl-NL') AS Goedgekeurd,
		declarationstatus.SettingValue AS [Status],
		declaration.StatusReason AS StatusReden,
		declaration.InternalMemo AS Memo,
		FORMAT(paid.TotalPaidAmount, 'N', 'nl-NL') AS Betaald
FROM sub.tblDeclaration declaration
INNER JOIN sub.tblEmployer employer ON declaration.EmployerNumber = employer.EmployerNumber
INNER JOIN sub.tblInstitute institute ON declaration.InstituteID = institute.InstituteID
INNER JOIN sub.tblSubsidyScheme subsidyscheme ON declaration.SubsidySchemeID = subsidyscheme.SubsidySchemeID
INNER JOIN sub.viewApplicationSetting_DeclarationStatus declarationstatus ON declaration.DeclarationStatus = declarationstatus.SettingCode
INNER JOIN sub.viewDeclaration_TotalPaidAmount paid on declaration.DeclarationID = paid.DeclarationID
