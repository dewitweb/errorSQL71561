
CREATE PROCEDURE [sub].[uspNewsItem_ByPageCode_List]
@PageCode	varchar(50)
AS
/*	==========================================================================================
	Purpose: 	Get list from sub.uspNewsItem_NewsItemPage_List by NewsItem.

	17-12-2018	Sander van Houten		OTIBSUB-575 sub.tblApplicationPage.
	09-10-2018	Jaap van Assenbergh	Inital version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT	ni.NewsItemID, 
		ni.NewsItemName, 
		ni.NewsItemType, 
		ni.StartDate, 
		ni.EndDate, 
		ni.Title, 
		ni.NewsItemMessage, 
		ni.CalendarDisplayDate
FROM	sub.tblNewsItem ni
INNER JOIN sub.tblNewsItem_ApplicationPage nip on nip.NewsItemID = ni.NewsItemID
INNER JOIN sub.tblApplicationPage apa ON apa.PageID = nip.PageID
WHERE	apa.PageCode = @PageCode

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspNewsItem_NewsItemPage_List ====================================================	*/
