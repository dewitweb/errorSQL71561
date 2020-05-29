CREATE PROCEDURE [stip].[uspEmail_Partition_List_ByPartition]
@PartitionID int
AS
/*	==========================================================================================
	Purpose: 	Get list from stip.tblEmail_Partition.

	02-05-2019	Jaap van Assenbergh	Inital version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		ep.EmailID,
		ep.PartitionID,
		eml.SentDate,
		ep.ReplyDate,
		ep.ReplyCode,
		ep.LetterType
FROM	stip.tblEmail_Partition ep
INNER JOIN eml.tblEmail eml ON eml.EmailID = ep.EmailID 
WHERE	PartitionID = @PartitionID
ORDER BY eml.SentDate

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== stip.uspEmail_Partition_List ==========================================================	*/
