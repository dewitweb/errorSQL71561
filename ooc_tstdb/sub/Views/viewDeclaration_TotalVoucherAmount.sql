/*	Adjust views.	*/
CREATE VIEW [sub].[viewDeclaration_TotalVoucherAmount]
AS

SELECT	dpv.DeclarationID, 
		SUM(dpv.DeclarationValue)	AS TotalVoucherAmount
FROM	sub.tblDeclaration_Partition_Voucher dpv
GROUP BY 
		dpv.DeclarationID
