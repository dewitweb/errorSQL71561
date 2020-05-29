
CREATE PROCEDURE [sub].[uspNewsItem_NewsItemPage_List]
@NewsItemID			int
AS
/*	==========================================================================================
	Purpose: 	Get list from sub.uspNewsItem_NewsItemPage_List by NewsItem.

	09-10-2018	Jaap van Assenbergh	Inital version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		ni.NewsItemID,
		v.PageCode
FROM	sub.tblNewsItem ni
INNER JOIN sub.tblNewsItem_NewsItemPage nip on nip.NewsItemID = ni.NewsItemID
INNER JOIN sub.viewApplicationSetting_NewsItemPage v ON v.PageID = nip.PageID
WHERE	ni.NewsItemID	= @NewsItemID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspNewsItem_NewsItemPage_List ====================================================	*/
