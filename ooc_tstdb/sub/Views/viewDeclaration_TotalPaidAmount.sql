CREATE VIEW [sub].[viewDeclaration_TotalPaidAmount]
AS
SELECT	pad.DeclarationID,
		SUM(ISNULL(pad.PartitionAmount, 0.00))		AS PartitionAmountCorrected,
		SUM(ISNULL(pad.VoucherAmount, 0.00))		AS VoucherAmount,
		SUM(ISNULL(pad.PartitionAmount, 0.00)) 
			+ SUM(ISNULL(pad.VoucherAmount, 0.00))	AS TotalPaidAmount
FROM	sub.tblPaymentRun_Declaration pad 
GROUP BY 
		pad.DeclarationID
