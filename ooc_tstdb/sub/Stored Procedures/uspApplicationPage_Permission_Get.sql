
CREATE PROCEDURE [sub].[uspApplicationPage_Permission_Get]
@PageID int
AS
/*	==========================================================================================
	Puspose:	Get all permissions connected to a specific applicationpage.

	12-02-2019	Sander van Houten	Initial version (OTIBSUB-722).
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

	SELECT
			apa.PageID,
			apa.PageCode,
			apa.PageDescription_NL			AS PageDescription,
			prm.PermissionID,
			prm.PermissionCode,
			prm.PermissionDescription_NL	AS PermissionDescription
	FROM	sub.tblApplicationPage apa 
	LEFT JOIN sub.tblApplicationPage_Permission app ON app.PageID = apa.PageID
	LEFT JOIN auth.tblPermission prm ON prm.PermissionID = app.PermissionID
	WHERE	apa.PageID = @PageID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspApplicationPage_Permission_Get =================================================	*/
