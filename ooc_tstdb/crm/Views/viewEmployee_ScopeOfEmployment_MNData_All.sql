CREATE VIEW [crm].[viewEmployee_ScopeOfEmployment_MNData_All]
AS
WITH cteLatest AS
(
	SELECT	fonds,
			nummer,
			werkgeverNummer,
			MAX(ingangsdatum)	AS MaxIngangsDatum
	FROM	[10.66.66.11\SQL2017].[OTIBMNData].[dbo].[tblEmployee]
	WHERE	inkomensfrequentie <> 'J'
	GROUP BY 
			fonds,
			nummer,
			werkgeverNummer
)
SELECT	emp.fonds,
		emp.nummer				AS EmployeeNumber,
		emp.werkgeverNummer		AS EmployerNumber,
		emp.ingangsdatum		AS StartDate,
		CASE WHEN cte.nummer IS NULL 
			THEN emp.einddatum
			ELSE CASE WHEN emp.einddatumDienstverband IS NULL
					THEN NULL
					ELSE emp.einddatum
					END
		END						AS EndDate,
		emp.omvangDienstverband	AS ScopeOfEmployment
FROM	[10.66.66.11\SQL2017].[OTIBMNData].[dbo].[tblEmployee] emp
LEFT JOIN cteLatest cte
ON		cte.fonds = emp.fonds
AND		cte.nummer = emp.nummer
AND		cte.werkgeverNummer = emp.werkgeverNummer
AND		cte.MaxIngangsDatum = emp.ingangsdatum
WHERE	emp.inkomensfrequentie <> 'J'
