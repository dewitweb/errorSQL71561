CREATE VIEW [sub].[viewStatistics_Processed_Declarations]
AS
WITH cteEmployeeCount AS
(
	SELECT	DeclarationID,
			COUNT(1)	AS EmployeeCount
	FROM	sub.tblDeclaration_Employee
	GROUP BY 
			DeclarationID
),
ctePartitionAmountCorrected AS
(
	SELECT	DeclarationID,
			SUM(PartitionAmountCorrected)	AS SumPartitionAmountCorrected
	FROM	sub.tblDeclaration_Partition
	WHERE	PartitionStatus IN ('0010', '0012', '0014', '0016', '0017')
	GROUP BY 
			DeclarationID
),
cteEmployeeCountReversal AS
(
	SELECT	DeclarationID,
			COUNT(DISTINCT EmployeeNumber)	AS EmployeeCount
	FROM	sub.tblDeclaration_Employee_ReversalPayment
	GROUP BY 
			DeclarationID
),
cteVoucher AS
(
	SELECT	DeclarationID,
			COUNT(DISTINCT VoucherNumber)	AS NrOfVouchers,
			SUM(DeclarationValue)			AS SumVoucherAmount
	FROM	sub.tblDeclaration_Partition_Voucher
	GROUP BY 
			DeclarationID
)
SELECT	decl.DeclarationID,
		ec.EmployeeCount																							AS NrOfEmployees,
		CAST(pac.SumPartitionAmountCorrected AS decimal(19,2))														AS SumPartitionAmountCorrected,
		CAST(pac.SumPartitionAmountCorrected / ec.EmployeeCount AS decimal(19,2))									AS AmountPerEmployee,
		ISNULL(vou.NrOfVouchers, 0)																					AS NrOfVouchers,
		CAST(ISNULL(vou.SumVoucherAmount, 0.00) AS decimal(19,2))													AS SumAmountVouchers,
		ISNULL(ecr.EmployeeCount, 0)																				AS NrOfEmployeesReversed,
		ISNULL(CAST(pac.SumPartitionAmountCorrected / ec.EmployeeCount * ecr.EmployeeCount AS decimal(19,2)), 0)	AS SumPartitionAmountReversed,
		SUM(CASE ISNULL(dpv.VoucherNumber, '') WHEN '' THEN 0 ELSE 1 END)											AS NrOfVouchersReversed,
		CAST(SUM(ISNULL(dpv.DeclarationValue, 0)) AS decimal(19,2))													AS SumAmountVouchersReversed
FROM	sub.tblDeclaration decl
INNER JOIN cteEmployeeCount ec
ON		ec.DeclarationID = decl.DeclarationID
INNER JOIN ctePartitionAmountCorrected pac
ON		pac.DeclarationID = decl.DeclarationID
LEFT JOIN cteVoucher vou
ON		vou.DeclarationID = decl.DeclarationID
LEFT JOIN cteEmployeeCountReversal ecr
ON		ecr.DeclarationID = decl.DeclarationID
LEFT JOIN sub.tblDeclaration_Employee_ReversalPayment der
ON		der.DeclarationID = decl.DeclarationID
LEFT JOIN sub.tblDeclaration_Partition_Voucher dpv
ON		dpv.DeclarationID = decl.DeclarationID
AND		dpv.PartitionID = der.PartitionID
AND		dpv.EmployeeNumber = der.EmployeeNumber
GROUP BY 
		decl.DeclarationID,
		ec.EmployeeCount,
		ecr.EmployeeCount,
		pac.SumPartitionAmountCorrected,
		vou.NrOfVouchers,
		vou.SumVoucherAmount
