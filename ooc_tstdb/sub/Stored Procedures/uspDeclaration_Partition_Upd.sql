CREATE PROCEDURE [sub].[uspDeclaration_Partition_Upd]
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

	04-07-2019	Sander van Houten		OTIBSUB-1323	Only write a new log record if there 
											is a change in status (this is not the case if 
											an employer still has a paymentarrear.
	18-04-2018	Jaap van Assenbergh		OTIBSUB-850		Bedrag uitbetaling in de toekomst niet tonen`.
	15-11-2018	Sander van Houten		Added PartitionID.
	04-10-2018	Sander van Houten		OTIBSUB-313		Added PartitionAmountCorrected 
											and PartitionStatus.
	02-08-2018	Sander van Houten		CurrentUserID added.
	19-07-2018	Jaap van Assenbergh		Initial version.
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
			0,					-- OTIBSUB-850 Bedrag uitbetaling in de toekomst niet tonen
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
IF CAST(ISNULL(@XMLdel, '') AS varchar(MAX)) <> CAST(ISNULL(@XMLins, '') AS varchar(MAX))
BEGIN
	DECLARE @PreviousPartitionStatus	varchar(4)

	SET @KeyID = CAST(@PartitionID AS varchar(18))

	-- First check on last log on partition.
	SELECT	@PreviousPartitionStatus = x.r.value('PartitionStatus[1]', 'varchar(4)')
	FROM	his.tblHistory
	CROSS APPLY NewValue.nodes('row') AS x(r)
	WHERE	HistoryID IN (
							SELECT	MAX(HistoryID)	AS MaxHistoryID
							FROM	his.tblHistory
							WHERE	TableName = 'sub.tblDeclaration_Partition'
							AND		KeyID = @KeyID
						 )

	-- Only write a new log record if there is a change in status
	-- (this is not the case if an employer still has a paymentarrear).
	IF @XMLdel IS NULL
	OR @PartitionStatus <> @PreviousPartitionStatus
	BEGIN
		EXEC his.uspHistory_Add
				'sub.tblDeclaration_Partition',
				@KeyID,
				@CurrentUserID,
				@LogDate,
				@XMLdel,
				@XMLins
	END
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Partition_Upd =======================================================	*/
