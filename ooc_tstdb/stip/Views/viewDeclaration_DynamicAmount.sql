CREATE VIEW [stip].[viewDeclaration_DynamicAmount]
AS
WITH cte_DeclarationAmount AS
(
	SELECT	d.DeclarationID,
			SUM(ISNULL(dep.PartitionAmount, 0.00))	AS DeclarationAmount
	FROM	stip.tblDeclaration d
	LEFT JOIN sub.tblDeclaration_Partition dep 
	ON		dep.DeclarationID = d.DeclarationID
    WHERE   dep.PartitionID IS NULL
    OR      dep.PartitionStatus <> '0029'
    GROUP BY
			d.DeclarationID
),
cte_BPV AS
(
	SELECT	stpd.DeclarationID,
			SUM(ISNULL(dtg.PaymentAmount, 0.00))	AS DeclarationAmount
	FROM	stip.tblDeclaration stpd
	INNER JOIN sub.tblDeclaration d
	ON		d.DeclarationID =  stpd.DeclarationID
	INNER JOIN sub.tblDeclaration_Employee dem 
	ON		dem.DeclarationID = stpd.DeclarationID
	INNER JOIN hrs.viewBPV bpv 
	ON		bpv.EmployeeNumber = dem.EmployeeNumber
	AND		bpv.EmployerNumber = d.EmployerNumber
	AND		bpv.CourseID = stpd.EducationID
	INNER JOIN hrs.viewBPV_DTG dtg
	ON		dtg.DSR_ID = bpv.DSR_ID
	AND		dtg.EmployeeNumber = bpv.EmployeeNumber		-- Performance: First field of the clustered index of table tblBPV
	WHERE	dtg.ReferenceDate < d.StartDate
	GROUP BY
			stpd.DeclarationID
)
SELECT	d.DeclarationID,
		ISNULL(da.DeclarationAmount, 0.00) 
		+ ISNULL(bpv.DeclarationAmount, 0.00)	AS DeclarationAmount
FROM	sub.tblDeclaration d
LEFT JOIN cte_DeclarationAmount da ON da.DeclarationID = d.DeclarationID
LEFT JOIN cte_BPV bpv ON bpv.DeclarationID = d.DeclarationID
WHERE	d.SubsidySchemeID = 4
