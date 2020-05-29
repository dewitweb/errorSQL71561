CREATE VIEW [crm].[viewEmployer_MNData_MostRecent]
AS
WITH cteMostRecent AS
(	
	SELECT	fonds,
			nummer,
			MAX(ingangsdatum)	AS MaxIngangsdatum
	FROM 	[10.66.66.11\SQL2017].[OTIBMNData].[dbo].[tblEmployer]
	GROUP BY 
			fonds,
			nummer
)
SELECT	emp.fonds,
		emp.nummer,
		emp.naam,
		emp.telefoonnummer,
		emp.iban,
		emp.kvkNummer,
		CASE WHEN emp.zaakAdresStraat = '' 
			THEN NULL 
			ELSE emp.zaakAdresStraat 
		END AS		zaakAdresStraat,
		CASE WHEN emp.zaakAdresHuisnummer = '' 
			THEN NULL 
			ELSE emp.zaakAdresHuisnummer + emp.zaakAdresToevoeging
		END		AS zaakAdresHuisnummer,
		CASE WHEN emp.zaakAdresPostcode = '' 
			THEN NULL 
			ELSE emp.zaakAdresPostcode 
		END		AS zaakAdresPostcode,
		CASE WHEN emp.zaakAdresPlaats = '' 
			THEN NULL 
			ELSE emp.zaakAdresPlaats 
		END		AS zaakAdresPlaats,
		CASE WHEN emp.zaakAdresLandcode = '' 
			THEN NULL 
			ELSE emp.zaakAdresLandcode 
		END		AS zaakAdresLandcode,
		CASE WHEN emp.correspondentieAdresStraat = '' 
			THEN NULL 
			ELSE emp.correspondentieAdresStraat 
		END		AS correspondentieAdresStraat,
		CASE WHEN emp.correspondentieAdresHuisnummer = '' 
			THEN NULL 
			ELSE emp.correspondentieAdresHuisnummer + correspondentieAdresToevoeging
		END		AS correspondentieAdresHuisnummer,
		CASE WHEN emp.correspondentieAdresPostcode = '' 
			THEN NULL 
			ELSE emp.correspondentieAdresPostcode 
		END		AS correspondentieAdresPostcode,
		CASE WHEN emp.correspondentieAdresPlaats = '' 
			THEN NULL 
			ELSE emp.correspondentieAdresPlaats 
		END		AS correspondentieAdresPlaats,
		CASE WHEN emp.correspondentieAdresLandcode = '' 
			THEN NULL 
			ELSE emp.correspondentieAdresLandcode 
		END		AS correspondentieAdresLandcode,
		MIN(emp.ingangsdatumLidmaatschap)	AS ingangsdatumLidmaatschap,
		MIN(emp.einddatumLidmaatschap)		AS einddatumLidmaatschap,
		MAX(emp.redenBeeindiging)			AS redenBeeindiging
FROM 	cteMostRecent cte
INNER JOIN [10.66.66.11\SQL2017].[OTIBMNData].[dbo].[tblEmployer] emp
ON		emp.nummer = cte.nummer
AND		emp.ingangsdatum = cte.MaxIngangsdatum
AND		emp.fonds = cte.fonds
GROUP BY 
		emp.fonds,
		emp.nummer,
		emp.naam,
		emp.telefoonnummer,
		emp.iban,
		emp.kvkNummer,
		emp.zaakAdresStraat,
		emp.zaakAdresHuisnummer,
		emp.zaakAdresToevoeging,
		emp.zaakAdresPostcode,
		emp.zaakAdresPlaats,
		emp.zaakAdresLandcode,
		emp.correspondentieAdresStraat,
		emp.correspondentieAdresHuisnummer,
		emp.correspondentieAdresToevoeging,
		emp.correspondentieAdresPostcode,
		emp.correspondentieAdresPlaats,
		emp.correspondentieAdresLandcode
