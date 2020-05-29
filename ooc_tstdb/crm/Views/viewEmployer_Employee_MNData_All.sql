






CREATE VIEW [crm].[viewEmployer_Employee_MNData_All]
AS
SELECT	EmployerNumber,
		EmployeeNumber,
		StartDate,
		EndDate
FROM	[10.66.66.11\SQL2017].[OTIBMNData].[dbo].[tblEmployer_Employee]
