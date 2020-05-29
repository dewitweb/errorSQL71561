CREATE view [sub].[zzviewEmployerBalance]
AS
SELECT	TOP 10000000
		ems.EmployerNumber, 
		sus.SubsidySchemeName, 
		YEAR(ems.StartDate)									AS DeclarationYear,
		ems.StartDate,
		ems.EndDate,
		ems.Amount											AS Budget,
		SUM(decl.DeclaratedAmount)							AS DeclaratedAmount,
		ems.Amount - SUM(decl.DeclaratedAmount)				AS Balance
FROM	sub.tblEmployer_Subsidy ems
LEFT JOIN (SELECT	DeclarationID, 
					EmployerNumber, 
					SubsidySchemeID, 
					StartDate, 
					CASE WHEN DeclarationStatus < '0009'
						THEN DeclarationAmount
						ELSE ApprovedAmount
					END AS DeclaratedAmount 
		   FROM sub.tblDeclaration
		   WHERE	DeclarationStatus NOT IN ('0001', '0007', '0017')
		  ) AS decl
ON	decl.EmployerNumber = ems.EmployerNumber
AND decl.SubsidySchemeID = ems.SubsidySchemeID
AND decl.StartDate BETWEEN ems.StartDate AND ems.EndDate
LEFT JOIN sub.tblSubsidyScheme sus
ON sus.SubsidySchemeID = ems.SubsidySchemeID
GROUP BY	ems.EmployerNumber,
			sus.SubsidySchemeName, 
			ems.StartDate,
			ems.EndDate,
			ems.Amount
ORDER BY	ems.EmployerNumber,
			sus.SubsidySchemeName, 
			ems.StartDate
