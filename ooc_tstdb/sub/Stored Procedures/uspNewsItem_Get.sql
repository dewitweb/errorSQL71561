
CREATE PROCEDURE [sub].[uspNewsItem_Get]
@NewsItemID	int
AS
/*	==========================================================================================
	Purpose: 	Get data from sub.tblNewsItem on basis of NewsItemID.

	09-10-2018	Jaap van Assenbergh	Inital version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		NewsItemID,
		NewsItemName,
		NewsItemType,
		StartDate,
		EndDate,
		Title,
		NewsItemMessage,
		CalendarDisplayDate
FROM	sub.tblNewsItem
WHERE	NewsItemID = @NewsItemID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== uspNewsItem_Get =======================================================================	*/
