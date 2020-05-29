/*	New view.	*/
CREATE VIEW [sub].[viewDeclaration_LastPartition]
AS
WITH cte_LastPartition AS
(
	SELECT	DeclarationID,
			MAX(PartitionYear)	AS	MaxPartitionYear
	FROM	sub.tblDeclaration_Partition
	GROUP BY 
			DeclarationID
)
SELECT	dep.DeclarationID,
		MAX(PartitionID)	AS	LastPartition
FROM	sub.tblDeclaration_Partition dep
INNER JOIN cte_LastPartition fp 
ON		fp.DeclarationID = dep.DeclarationID
AND		fp.MaxPartitionYear = dep.PartitionYear
GROUP BY 
		dep.DeclarationID
