CREATE PROCEDURE [sub].[uspDeclaration_Partition_Upd_PartitionStatus]
@PartitionID		int,
@PartitionStatus	varchar(4),
@CurrentUserID		int = 1
AS
/*	==========================================================================================
	Purpose:	Update status only.

	04-07-2019	Sander van Houten		OTIBSUB-1323	Only write a new log record if there 
											is a change in status (this is not the case if 
											an employer still has a paymentarrear.
	24-04-2019	Sander van Houten		OTIBSUB-1013	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

-- Save old record
SELECT	@XMLdel = (	SELECT	* 
					FROM	sub.tblDeclaration_Partition 
					WHERE	PartitionID = @PartitionID
					FOR XML PATH)

-- Update exisiting record
UPDATE	sub.tblDeclaration_Partition
SET		PartitionStatus	= @PartitionStatus
WHERE	PartitionID = @PartitionID

-- Save new record
SELECT	@XMLins = (	SELECT	* 
					FROM	sub.tblDeclaration_Partition 
					WHERE	PartitionID = @PartitionID
					FOR XML PATH)

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
	IF @PartitionStatus <> @PreviousPartitionStatus
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

/*	== sub.uspDeclaration_Partition_Upd_PartitionStatus ======================================	*/
