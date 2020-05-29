
CREATE PROCEDURE [osr].[uspDeclaration_Get_ApprovedAmount]
@DeclarationID	int
AS
/*	==========================================================================================
	Purpose:	Get PartitionAmountCorrected on bases of a PartitionID.

	Notes:		

	13-11-2019	Jaap van Assenbergh		OTIBSUB-1539	Declaratieniveau naar Partitieniveau brengen
	08-05-2019	Sander van Houten		OTIBSUB-1046	Move vouchers to partition level.
	05-04-2019	Sander van Houten		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Testdata.
DECLARE @DeclarationID	int = 400131
--	*/

DECLARE @PartitionID		int,
		@TotalVoucherAmount	decimal(19,2),
		@ApprovedAmount		decimal(19,2)

SELECT	@PartitionID = dep.PartitionID,
		@ApprovedAmount = sub.usfGetPartitionAmountCorrected (dep.PartitionID, 1)
FROM	sub.tblDeclaration decl
INNER JOIN sub.tblDeclaration_Partition dep ON dep.DeclarationID = decl.DeclarationID
WHERE	decl.DeclarationID = @DeclarationID
AND		dep.PartitionStatus IN ('0005', '0006', '0008', '0022')
GROUP BY 
		dep.PartitionID

SELECT ApprovedAmount = @ApprovedAmount

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== osr.uspDeclaration_Get_ApprovedAmount ================================================	*/
