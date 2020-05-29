CREATE PROCEDURE [sub].[usp_OTIB_NewsItem_List]
@PageCode			varchar(50),
@SubsidySchemeID	int
AS
/*	==========================================================================================
	Purpose: 	Get list from sub.tblNewsItem with actual and future newsitem.

	15-10-2019	Sander van Houten	    OTIBSUB-1618	If EVC is selected then also select EVC-WV.
	17-12-2018	Sander van Houten		OTIBSUB-575     sub.tblApplicationPage.
	09-10-2018	Jaap van Assenbergh		Inital version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @GetDate date = GETDATE()

/*  Initialize variables.   */
SELECT	@PageCode = ISNULL(@PageCode, ''),
		@SubsidySchemeID = ISNULL(@SubsidySchemeID, 0)

/*  Insert @SubsidySchemeID into a table variable.   */
DECLARE @tblSubsidyScheme   sub.uttSubsidySchemeID
INSERT INTO @tblSubsidyScheme (SubsidySchemeID) VALUES (@SubsidySchemeID)

/*  If EVC is selected then also select EVC-WV (OTIBSUB-1618).  */
IF EXISTS ( SELECT  1
            FROM    @tblSubsidyScheme
            WHERE   SubsidySchemeID = 3)
BEGIN
    INSERT INTO @tblSubsidyScheme (SubsidySchemeID) VALUES (5)
END

/*  Get resultset.  */
SELECT	DISTINCT
		ni.NewsItemID,
		ni.NewsItemName,
		ni.NewsItemType,
		ni.StartDate,
		ni.EndDate,
		ni.Title,
		ni.NewsItemMessage,
		ni.CalendarDisplayDate
FROM	sub.tblNewsItem ni
LEFT JOIN sub.tblNewsItem_ApplicationPage nip ON nip.NewsItemID = ni.NewsItemID
LEFT JOIN sub.tblApplicationPage apa ON apa.PageID = nip.PageID
LEFT JOIN sub.tblNewsItem_SubsidyScheme niss ON niss.NewsItemID = ni.NewsItemID
WHERE	(
			ni.Enddate IS NULL 
		OR
			ni.EndDate >= @GetDate
		)
	AND		@PageCode =	
			CASE
				WHEN		@PageCode = ''
					THEN	@PageCode
					ELSE	apa.PageCode
			END
	AND		(   @SubsidySchemeID = 0
        OR      niss.SubsidySchemeID IN 
                                        (
                                            SELECT	SubsidySchemeID 
                                            FROM	@tblSubsidyScheme
                                        )
            )
ORDER BY ni.StartDate DESC

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.usp_OTIB_NewsItem_List ============================================================	*/
