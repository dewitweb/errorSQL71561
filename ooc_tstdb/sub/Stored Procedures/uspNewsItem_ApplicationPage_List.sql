
CREATE PROCEDURE [sub].[uspNewsItem_ApplicationPage_List]
@NewsItemID	int
AS
/*	==========================================================================================
	Purpose: 	Get list from sub.uspNewsItem_NewsItemPage_List by NewsItem.

	17-12-2018	Sander van Houten		OTIBSUB-575 Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		ni.NewsItemID,
		apa.PageCode
FROM	sub.tblNewsItem ni
INNER JOIN sub.tblNewsItem_ApplicationPage nip on nip.NewsItemID = ni.NewsItemID
INNER JOIN sub.tblApplicationPage apa ON apa.PageID = nip.PageID
WHERE	ni.NewsItemID	= @NewsItemID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspNewsItem_ApplicationPage_List ==================================================	*/
