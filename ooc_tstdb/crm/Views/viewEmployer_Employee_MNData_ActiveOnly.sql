





CREATE VIEW [crm].[viewEmployer_Employee_MNData_ActiveOnly]
AS
SELECT	DISTINCT 
		fonds,
		werkgevernummer,
		nummer						AS werknemernummer,
		aanvangsdatumDienstverband,
		einddatumDienstverband
FROM	[10.66.66.11\SQL2017].[OTIBMNData].[dbo].[tblEmployee]
WHERE	ISNULL(einddatumDienstverband, GETDATE()+1) >= GETDATE()
