
CREATE PROCEDURE [sub].[usp_OTIB_Declaration_Upd_Investigation]
@DeclarationID	int,
@Reason			varchar(max),
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose:	Place a declaration in or out of investigation by an OTIB user.

	12-11-2019	Jaap van Assenebrgh		OTIBSUB-1539	Declaratieniveau naar Partitieniveau brengen
	03-04-2019	Sander van Houten		OTIBSUB-851 Adjust PartitionAmountCorrected to 0.
	03-08-2018	Sander van Houten		CurrentUserID added.
	02-08-2018	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @DeclarationStatus varchar(4)

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

/*	Register Investigation record.	*/
--	Add new record.
INSERT INTO	sub.tblDeclaration_Investigation 
	(
		DeclarationID, 
		InvestigationDate, 
		InvestigationMemo
	)
VALUES
	(
		@DeclarationID, 
		GETDATE(), 
		@Reason
	)

-- Save new record
SELECT	@XMLdel = NULL,
		@XMLins = (SELECT * 
					FROM   sub.tblDeclaration_Investigation 
					WHERE  DeclarationID = @DeclarationID 
					FOR XML PATH)

-- Log action in tblHistory
EXEC his.uspHistory_Add
		'sub.tblDeclaration_Investigation',
		@DeclarationID,
		@CurrentUserID,
		@LogDate,
		@XMLdel,
		@XMLins

/*	Update PartitionStatus.	*/
DECLARE @PartitionID				int,
		@PartitionYear				varchar(20),
		@PartitionAmount			decimal(19,4),
		@PartitionAmountCorrected	decimal(19,4) = 0.00,
		@PaymentDate				date,
		@PartitionStatus			varchar(4) = '0008'

DECLARE cur_Partitions CURSOR FOR 
	SELECT	PartitionID,
			PartitionYear,
			PartitionAmount,
			PaymentDate
	FROM	sub.tblDeclaration_Partition
	WHERE	DeclarationID = @DeclarationID
	AND		PartitionStatus IN ( '0001', '0002', '0005', '0006', '0007', '0009', '0022' )
		
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

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.usp_OTIB_Declaration_Upd_Investigation ============================================	*/
