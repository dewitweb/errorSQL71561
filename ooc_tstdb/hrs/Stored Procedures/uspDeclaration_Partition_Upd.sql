
CREATE PROCEDURE [hrs].[uspDeclaration_Partition_Upd]
@PartitionID				int,
@DeclarationID				int,
@PartitionYear				varchar(20),
@PartitionAmount			decimal(9,4),
@PartitionAmountCorrected	decimal(9,4),
@PaymentDate				date,
@PartitionStatus			varchar(4),
@CurrentUserID				int = 1
AS
/*	==========================================================================================
	Purpose:	Update sub.tblDeclaration_Partition on the basis of 
				DeclarationID and PartitionYear.

	12-03-2019	Sander van Houten		Alternate version for Horus OSR2019 import.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF ISNULL(@PartitionID, 0) = 0
BEGIN
	SELECT	@PartitionID = PartitionID
	FROM	sub.tblDeclaration_Partition 
	WHERE	DeclarationID = @DeclarationID 
	  AND	PartitionYear = @PartitionYear
END

IF ISNULL(@PartitionID, 0) = 0
BEGIN
	-- Add new record
	INSERT INTO sub.tblDeclaration_Partition
		(
			DeclarationID,
			PartitionYear,
			PartitionAmount,
			PartitionAmountCorrected,
			PaymentDate,
			PartitionStatus
		)
	VALUES
		(
			@DeclarationID,
			@PartitionYear,
			@PartitionAmount,
			@PartitionAmountCorrected,
			@PaymentDate,
			@PartitionStatus
		)

	-- Save new PartitionID
	SET	@PartitionID = SCOPE_IDENTITY()

	-- Save new record
	SELECT	@XMLdel = NULL,
			@XMLins = (SELECT	* 
					   FROM		sub.tblDeclaration_Partition 
					   WHERE	PartitionID = @PartitionID
					   FOR XML PATH)
END
ELSE
BEGIN
	-- Save old record
	SELECT	@XMLdel = (SELECT	* 
					   FROM		sub.tblDeclaration_Partition 
					   WHERE	PartitionID = @PartitionID
					   FOR XML PATH)

	-- Update exisiting record
	UPDATE	sub.tblDeclaration_Partition
	SET
			PartitionYear				= @PartitionYear,
			PartitionAmount				= @PartitionAmount,
			PartitionAmountCorrected	= @PartitionAmountCorrected,
			PaymentDate					= @PaymentDate,
			PartitionStatus				= @PartitionStatus
	WHERE	PartitionID = @PartitionID

	-- Save new record
	SELECT	@XMLins = (SELECT	* 
					   FROM		sub.tblDeclaration_Partition 
					   WHERE	PartitionID = @PartitionID
					   FOR XML PATH)
END

-- Log action in tblHistory
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = CAST(@PartitionID AS varchar(18))

	EXEC his.uspHistory_Add
			'sub.tblDeclaration_Partition',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== hrs.uspDeclaration_Partition_Upd =======================================================	*/