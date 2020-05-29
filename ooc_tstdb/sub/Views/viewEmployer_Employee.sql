CREATE VIEW [sub].[viewEmployer_Employee]
AS

SELECT	DISTINCT 
		EmployerNumber, 
		EmployeeNumber, 
		StartDate,
		EndDate,
		NULL	AS StartDate_ParentChild,
		NULL	AS EndDate_ParentChild
FROM	sub.tblEmployer_Employee
UNION ALL
SELECT	DISTINCT 
		epc.EmployerNumberParent	AS EmployerNumber, 
		ee.EmployeeNumber, 
		ee.StartDate,
		ee.EndDate,
		epc.StartDate				AS StartDate_ParentChild,
		epc.EndDate					AS EndDate_ParentChild
FROM	sub.tblEmployer_ParentChild	epc
INNER JOIN sub.tblEmployer_Employee ee ON ee.EmployerNumber = epc.EmployerNumberChild

