CREATE FUNCTION [sub].[usfGetEmployerBalance]
/*	*********************************************************************************************
	Purpose:	Recalculates the balance amount of a specific employer.

	05-04-2019	Sander van Houten	Initial version.
	********************************************************************************************* */
(
	@PartitionID		int
)
RETURNS decimal(19,4)
AS
BEGIN
	DECLARE @BalanceAmount	decimal(19,4)

	SELECT	@BalanceAmount = ems.Amount - ISNULL(sub1.TotalAmountPaid, 0)
	FROM	sub.tblDeclaration_Partition dep
	INNER JOIN sub.tblDeclaration decl ON decl.DeclarationID = dep.DeclarationID
	INNER JOIN sub.tblEmployer_Subsidy ems ON ems.EmployerNumber = decl.EmployerNumber AND ems.SubsidyYear = dep.PartitionYear
	LEFT JOIN (
				SELECT	d.EmployerNumber, 
						d.SubsidySchemeID, 
						dp.PartitionYear,
						SUM(ISNULL(dp.PartitionAmountCorrected, 0))	AS TotalAmountPaid
				FROM	sub.tblDeclaration_Partition t1
				INNER JOIN sub.tblDeclaration t2 ON t2.DeclarationID = t1.DeclarationID
				INNER JOIN sub.tblDeclaration d ON d.EmployerNumber = t2.EmployerNumber
				LEFT JOIN sub.tblDeclaration_Partition dp ON dp.DeclarationID = d.DeclarationID
														  AND dp.PartitionYear = t1.PartitionYear
														  AND dp.PartitionID <> t1.PartitionID
														  AND dp.PartitionStatus BETWEEN '0009' AND '0015'
				WHERE	t1.PartitionID = @PartitionID
				GROUP BY 
						d.EmployerNumber, 
						d.SubsidySchemeID, 
						dp.PartitionYear
			) sub1
		ON	sub1.EmployerNumber = ems.EmployerNumber
		AND sub1.SubsidySchemeID = ems.SubsidySchemeID
		AND sub1.PartitionYear = ems.SubsidyYear
	WHERE	dep.PartitionID = @PartitionID

	RETURN @BalanceAmount
END
