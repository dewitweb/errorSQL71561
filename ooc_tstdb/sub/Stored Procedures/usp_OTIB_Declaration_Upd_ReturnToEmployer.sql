



CREATE PROCEDURE [sub].[usp_OTIB_Declaration_Upd_ReturnToEmployer]
@DeclarationID	int,
@Reason			varchar(max),
@ReasonInEmail	bit,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose:	Return a declaration to Employer by an OTIB user.

	12-11-2019	Jaap van Assenebrgh		OTIBSUB-1539	Declaratieniveau naar Partitieniveau brengen
	07-05-2019	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @DeclarationStatus varchar(4)

/*	Update PartitionStatus.	*/
DECLARE @PartitionID				int,
		@PartitionYear				varchar(20),
		@PartitionAmount			decimal(19,4),
		@PartitionAmountCorrected	decimal(19,4) = 0.00,
		@PaymentDate				date,
		@PartitionStatus			varchar(4) = '0019'

DECLARE cur_Partitions CURSOR FOR 
	SELECT	PartitionID,
			PartitionYear,
			PartitionAmount,
			PaymentDate
	FROM	sub.tblDeclaration_Partition
	WHERE	DeclarationID = @DeclarationID
	AND		PartitionStatus IN ( '0001', '0002', '0005', '0006', '0007', '0008', '0009', '0022')
		
OPEN cur_Partitions

FETCH NEXT FROM cur_Partitions INTO @PartitionID, @PartitionYear, @PartitionAmount, @PaymentDate

WHILE @@FETCH_STATUS = 0  
BEGIN
	EXECUTE [sub].[uspDeclaration_Partition_Upd] 
	@PartitionID,
	@DeclarationID,
	@PartitionYear,
	@PartitionAmount,
	@PartitionAmountCorrected,
	@PaymentDate,
	@PartitionStatus,
	@CurrentUserID

	FETCH NEXT FROM cur_Partitions INTO @PartitionID, @PartitionYear, @PartitionAmount, @PaymentDate
END

CLOSE cur_Partitions
DEALLOCATE cur_Partitions

/*	Finally update Declaration.	*/
SELECT @DeclarationStatus = sub.usfGetDeclarationStatusByPartition(@DeclarationID, NULL, NULL)

EXEC sub.uspDeclaration_Upd_DeclarationStatus
		@DeclarationID,
		@DeclarationStatus,
		@Reason,
		@CurrentUserID

IF @ReasonInEmail = 0 SET @Reason = ''

EXEC sub.usp_OTIB_Declaration_SendEmail_ReturnToEmployer
	@DeclarationID,
	@Reason			

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.usp_OTIB_Declaration_Upd_ReturnToEmployer =========================================	*/
