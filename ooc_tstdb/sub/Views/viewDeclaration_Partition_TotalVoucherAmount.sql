
CREATE VIEW [sub].[viewDeclaration_Partition_TotalVoucherAmount]
AS

SELECT	dpv.DeclarationID, 
		dpv.PartitionID, 
		SUM(dpv.DeclarationValue)	AS TotalVoucherAmount
FROM	sub.tblDeclaration_Partition_Voucher dpv
GROUP BY 
		dpv.DeclarationID,
		dpv.PartitionID

