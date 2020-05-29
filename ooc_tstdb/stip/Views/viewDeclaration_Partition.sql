CREATE VIEW [stip].[viewDeclaration_Partition]
AS

SELECT	dp.PartitionID,
		dp.DeclarationID,
		dp.PartitionYear,
		dp.PartitionAmount,
		dp.PartitionAmountCorrected,
		dp.PaymentDate,
		dp.PartitionStatus,
		CASE WHEN CAST(dp.PaymentDate AS date) = decl.DiplomaDate
				THEN 'Eindtegemoetkoming'
				ELSE 'Basistegemoetkoming deel ' + sub.usfConvertIntToRoman(ROW_NUMBER () OVER(PARTITION BY dp.DeclarationID ORDER BY dp.PaymentDate))
		END		Title 
FROM	stip.viewDeclaration decl
INNER JOIN sub.tblDeclaration_Partition dp ON dp.DeclarationID = decl.DeclarationID

