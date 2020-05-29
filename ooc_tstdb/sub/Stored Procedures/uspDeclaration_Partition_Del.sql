
CREATE PROCEDURE [sub].[uspDeclaration_Partition_Del]
@PartitionID	int,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose:	Remove tblDeclaration_Partition record.

	15-11-2018	Sander van Houten		Replaced PartitionYear by PartitionID.
	02-08-2018	Sander van Houten		CurrentUserID added.
	19-07-2018	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

-- Save old record
SELECT	@XMLdel = (SELECT	* 
				   FROM		sub.tblDeclaration_Partition
				   WHERE	PartitionID = @PartitionID
				   FOR XML PATH),
		@XMLins = NULL

-- Delete record
DELETE
FROM	sub.tblDeclaration_Partition
WHERE	PartitionID = @PartitionID

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

/*	== sub.uspDeclaration_Partition_Del ======================================================	*/

