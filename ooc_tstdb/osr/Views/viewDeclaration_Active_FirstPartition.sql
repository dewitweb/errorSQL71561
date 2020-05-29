/*	New view.	*/
CREATE VIEW [osr].[viewDeclaration_Active_FirstPartition]
AS
WITH cte_FirstPartition AS
(
	SELECT	decl.DeclarationID,
			MIN(dep.PartitionYear)	AS	MinPartitionYear
	FROM	sub.tblDeclaration decl
	INNER JOIN sub.tblDeclaration_Partition dep 
			ON dep.DeclarationID = decl.DeclarationID
	WHERE	decl.SubsidySchemeID = 1
	AND		decl.DeclarationStatus <> '0035'
	GROUP BY 
			decl.DeclarationID
)
SELECT	dep.DeclarationID,
		MIN(PartitionID)	AS	FirstPartition
FROM	sub.tblDeclaration_Partition dep
INNER JOIN cte_FirstPartition fp 
ON		fp.DeclarationID = dep.DeclarationID
AND		fp.MinPartitionYear = dep.PartitionYear
GROUP BY 
		dep.DeclarationID
