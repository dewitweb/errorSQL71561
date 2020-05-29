CREATE VIEW [sub].[viewDeclaration_TotalPaidAmount_PerYear]
AS
SELECT	d.SubsidySchemeID,
		d.EmployerNumber,
		d.DeclarationID,
		dep.PartitionYear,
		SUM(ISNULL(pad.PartitionAmount, 0.00))	AS SumPartitionAmount,
		SUM(ISNULL(pad.VoucherAmount, 0.00))	AS SumVoucherAmount
FROM	sub.tblDeclaration d
INNER JOIN sub.tblDeclaration_Partition dep
ON		dep.DeclarationID = d.DeclarationID
LEFT JOIN sub.tblPaymentRun_Declaration pad
ON		pad.DeclarationID = dep.DeclarationID
AND		pad.PartitionID = dep.PartitionID
GROUP BY
		d.SubsidySchemeID,
		d.EmployerNumber,
		d.DeclarationID,
		dep.PartitionYear
