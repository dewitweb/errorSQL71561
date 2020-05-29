










CREATE VIEW [crm].[viewEmployee_MNData_MostRecent]
AS
-- Select only the most recent data of the employee.
WITH cteMostRecent AS
(	
	SELECT	fonds,
			nummer,
			MAX(ingangsdatum)	AS MaxIngangsdatum
	FROM [10.66.66.11\SQL2017].[OTIBMNData].[dbo].[tblEmployee]
	GROUP BY fonds,
			 nummer
)
SELECT	DISTINCT 
		emp.fonds,
		emp.nummer,
		emp.naam,
		emp.voorletters,
		emp.voorvoegsels,
		emp.geslacht,
		emp.voorvoegselsEchtgenoot,
		emp.naamEchtgenoot,
		emp.geboortedatum
FROM cteMostRecent cte
INNER JOIN [10.66.66.11\SQL2017].[OTIBMNData].[dbo].[tblEmployee] emp
ON		emp.nummer = cte.nummer
AND		emp.ingangsdatum = cte.MaxIngangsdatum
AND		emp.fonds = cte.fonds
