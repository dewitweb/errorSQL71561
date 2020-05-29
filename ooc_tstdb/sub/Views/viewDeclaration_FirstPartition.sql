/*	New view.	*/
CREATE VIEW [sub].[viewDeclaration_FirstPartition]
AS
--WITH cte_FirstPartition AS
--(
--	SELECT	DeclarationID,
--			MIN(PartitionYear)	AS	MinPartitionYear
--	FROM	sub.tblDeclaration_Partition
--	GROUP BY 
--			DeclarationID
--)
--SELECT	dep.DeclarationID,
--		MIN(PartitionID)	AS	FirstPartition
--FROM	sub.tblDeclaration_Partition dep
--INNER JOIN cte_FirstPartition fp 
--ON		fp.DeclarationID = dep.DeclarationID
--AND		fp.MinPartitionYear = dep.PartitionYear
--GROUP BY 
--		dep.DeclarationID

SELECT	DeclarationID, PartitionID FirstPartition
FROM	(
			SELECT	DeclarationID, PartitionID, ROW_NUMBER() OVER(PARTITION BY DeclarationID ORDER BY PartitionYear, PartitionID) Seq
			FROM	sub.tblDeclaration_Partition
		) sel
WHERE Seq = 1

