CREATE PROCEDURE [stip].[uspEmail_Partition_Get]
@EmailID	int
AS
/*	==========================================================================================
	Purpose: 	Get data from stip.tblEmail_Partition on basis of EmailID.

	02-05-2019	Jaap van Assenbergh	Inital version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		EmailID,
		PartitionID,
		ReplyDate,
		ReplyCode,
		LetterType
FROM	stip.tblEmail_Partition
WHERE	EmailID = @EmailID
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== uspEmail_Partition_Get ================================================================	*/
