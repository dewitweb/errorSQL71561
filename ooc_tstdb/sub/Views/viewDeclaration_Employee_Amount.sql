CREATE VIEW [sub].[viewDeclaration_Employee_Amount]
AS

WITH cteDeclarationAmount AS
(
	SELECT	
			prd.PaymentRunID,
			decl.DeclarationID, 
			decl.PartitionID, 
			prd.PartitionAmount,
			CASE WHEN ReversalPaymentID = 0 THEN 0 ELSE 1 END IsReversal,
			CASE 
				WHEN prd.ReversalPaymentID = 0 
				THEN	(
							SELECT	COUNT(1) 
							FROM	sub.tblDeclaration_Employee de
							WHERE	de.DeclarationID = decl.DeclarationID
						)
				ELSE
						(
							SELECT	COUNT(1) 
							FROM	sub.tblDeclaration_Employee_ReversalPayment derp 
							WHERE	derp.DeclarationID = decl.DeclarationID
						)
			END CountOfEmployee
	FROM	sub.tblDeclaration_Partition decl
	INNER JOIN sub.tblPaymentRun_Declaration prd
			ON	prd.PartitionID = decl.PartitionID
	WHERE	prd.PaymentRunID >= 60000
),
cteVoucher AS
(
	SELECT	dpv.DeclarationID, dpv.PartitionID, dpv.EmployeeNumber, SUM(dpv.DeclarationValue) VoucherAmount
	FROM	sub.tblDeclaration_Partition dp
	INNER JOIN sub.tblDeclaration_Partition_Voucher dpv 
			ON	dpv.PartitionID = dp.PartitionID
	WHERE	dp.PartitionStatus NOT IN('0007', '0017')		
	GROUP BY dpv.DeclarationID, dpv.PartitionID, dpv.EmployeeNumber
)

SELECT	da.PaymentRunID,
		da.DeclarationID, 
		da.PartitionID, 
		da.IsReversal,
		dee.EmployeeNumber, 
		CAST((da.PartitionAmount/da.CountOfEmployee) AS dec(19,4))  FromBudget, 
		CAST(ISNULL(vo.VoucherAmount, 0) AS dec(19,4)) VoucherAmount
FROM	sub.tblDeclaration_Employee dee
INNER JOIN cteDeclarationAmount da 
		ON	da.DeclarationID = dee.DeclarationID
LEFT JOIN cteVoucher vo 
		ON	vo.DeclarationID = da.DeclarationID
		AND	vo.PartitionID = da.PartitionID
		AND	vo.EmployeeNumber = dee.EmployeeNumber
WHERE	IsReversal = 0
UNION ALL
SELECT	da.PaymentRunID,
		da.DeclarationID, 
		da.PartitionID, 
		da.IsReversal, 
		dee.EmployeeNumber, 
		CAST((da.PartitionAmount/da.CountOfEmployee) AS dec(19,4))  FromBudget, 
		CAST(ISNULL(vo.VoucherAmount, 0) AS dec(19,4)) VoucherAmount
FROM	sub.tblDeclaration_Employee_ReversalPayment dee
INNER JOIN cteDeclarationAmount da 
		ON	da.DeclarationID = dee.DeclarationID
LEFT JOIN cteVoucher vo 
		ON	vo.DeclarationID = da.DeclarationID
		AND	vo.PartitionID = da.PartitionID
		AND	vo.EmployeeNumber = dee.EmployeeNumber
WHERE	IsReversal = 1

