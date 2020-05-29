
CREATE PROCEDURE [sub].[uspDeclaration_Partition_List]
@DeclarationID		int
AS
/*	==========================================================================================
	Purpose:	List all partitions from sub.tblDeclaration_Partition 
				on the basis of DeclarationID.

	04-10-2018	Sander van Houten		Added PartitionAmountCorrected 
										and PartitionStatus (OTIBSUB-313).
	19-07-2018	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

	SELECT
			DeclarationID,
			PartitionID,
			PartitionYear,
			PartitionAmount,
			PartitionAmountCorrected,
			PaymentDate,
			PartitionStatus
	FROM	sub.tblDeclaration_Partition
	WHERE	DeclarationID = @DeclarationID
	ORDER BY PartitionYear

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Partition_List ======================================================	*/

