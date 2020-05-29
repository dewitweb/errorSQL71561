
CREATE PROCEDURE [sub].[uspApplicationPage_List]
AS
/*	==========================================================================================
	Purpose: 	Get list from sub.tblApplicationPage_List.

	26-02-2019	Jaap van Assenbergh		OTIBSUB-804 Bij application pages aangeven of deze 
										nieuwsitems kunnen bevatten. (alleen in deze lijst)
	17-12-2018	Sander van Houten		OTIBSUB-575 Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		PageID,
		PageCode,
		PageDescription_NL	AS PageDescription,
		IncludesNewsItems
FROM	sub.tblApplicationPage

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspApplicationPage_List ===========================================================	*/
