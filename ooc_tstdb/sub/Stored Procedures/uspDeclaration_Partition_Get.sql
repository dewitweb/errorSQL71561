
CREATE PROCEDURE [sub].[uspDeclaration_Partition_Get]
@PartitionID	int
AS
/*	==========================================================================================
	Purpose:	Get specific partition from sub.tblDeclaration_Partition 
				on the basis of DeclarationID and PartitionYear.

	15-11-2018	Sander van Houten		Replaced parameters DeclarationID and PartitionYear 
										by PartitionID.
	04-10-2018	Sander van Houten		Added PartitionAmountCorrected 
										and PartitionStatus (OTIBSUB-313).
	19-07-2018	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		PartitionID,
		DeclarationID,
		PartitionYear,
		PartitionAmount,
		PartitionAmountCorrected,
		PaymentDate,
		PartitionStatus
FROM	sub.tblDeclaration_Partition
WHERE	PartitionID = @PartitionID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== uspDeclaration_Partition_Get ===========================================================	*/

