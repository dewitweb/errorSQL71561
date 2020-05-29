CREATE VIEW [sub].[viewPaymentRun_Declaration]
AS

SELECT	DeclarationID,
		PaymentRunID,
		SUM(PartitionAmount)	AS SumPartitionAmount,
		SUM(VoucherAmount)		AS SumVoucherAmount
FROM	sub.tblPaymentRun_Declaration
GROUP BY 
		DeclarationID, 
		PaymentRunID
