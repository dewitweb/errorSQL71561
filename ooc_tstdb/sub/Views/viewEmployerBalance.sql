CREATE VIEW [sub].[viewEmployerBalance]
AS
SELECT	TOP 1000000
		ems.SubsidySchemeID,
		ems.EmployerNumber,
		ems.SubsidyYear,
		CASE WHEN ems.Amount - ISNULL(sub1.TotalApprovedAmount, 0) < 0
			THEN 0.00
			ELSE ems.Amount - ISNULL(sub1.TotalApprovedAmount, 0)
		END		AS BalanceAmount
FROM	sub.tblEmployer_Subsidy ems 
LEFT JOIN (
				SELECT	sub2.SubsidySchemeID,
						sub2.EmployerNumber,
						sub2.PartitionYear,
						SUM(ISNULL(sub2.TotalApprovedAmount, 0))	AS TotalApprovedAmount
				FROM	(
							SELECT	decl.SubsidySchemeID,
									decl.EmployerNumber,
									dep.PartitionYear,
									SUM(ISNULL(dep.PartitionAmountCorrected, 0))	AS TotalApprovedAmount
							FROM	sub.tblDeclaration decl 
							LEFT JOIN sub.tblDeclaration_Partition dep ON dep.DeclarationID = decl.DeclarationID
							WHERE	dep.PartitionStatus = '0009'
							GROUP BY 
									decl.SubsidySchemeID,
									decl.EmployerNumber,
									dep.PartitionYear

							UNION ALL

							SELECT	dtpa.SubsidySchemeID,
									d.EmployerNumber,
									dtpa.PartitionYear,
									dtpa.SumPartitionAmount		AS TotalApprovedAmount
							FROM	sub.viewDeclaration_TotalPaidAmount_PerYear dtpa
							INNER JOIN sub.tblDeclaration d ON d.DeclarationID = dtpa.DeclarationID
						) sub2
				GROUP BY 
						sub2.SubsidySchemeID,
						sub2.EmployerNumber,
						sub2.PartitionYear
			) sub1
ON		sub1.SubsidySchemeID = ems.SubsidySchemeID
AND		sub1.EmployerNumber = ems.EmployerNumber
AND		sub1.PartitionYear = ems.SubsidyYear
ORDER BY	
		ems.SubsidySchemeID,
		ems.EmployerNumber,
		ems.SubsidyYear