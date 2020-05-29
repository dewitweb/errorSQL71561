
CREATE PROCEDURE [sub].[usp_RepServ_01_ParameterList_SubsidyScheme]

AS
/*	==========================================================================================
	Purpose:	List of subsidy schemes for parameters on reports.

	14-03-2019	H. Melissen		Initial version.
	==========================================================================================	*/
DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Select OSR and EVC.
	BPV will be implemented later (after August 1, 2019). */
SELECT	0 AS SubsidySchemeID,
		'Alle' AS Subsidieregeling

UNION ALL

SELECT	SubsidySchemeID,
		SubsidySchemeName AS Subsidieregeling
FROM sub.tblSubsidyScheme
WHERE SubsidySchemeID IN (1, 3)

ORDER BY 1

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID
