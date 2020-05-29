
CREATE PROCEDURE sub.uspNewsItem_SubsidyScheme_List
@NewsItemID			int
AS
/*	==========================================================================================
	Purpose: 	Get list from sub.tblNewsItem_SubsidyScheme by NewsItem.

	09-10-2018	Jaap van Assenbergh	Inital version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		NewsItemID,
		SubsidySchemeID
FROM	sub.tblNewsItem_SubsidyScheme
WHERE	NewsItemID	= @NewsItemID
ORDER BY SubsidySchemeID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspNewsItem_SubsidyScheme__List ===================================================	*/
