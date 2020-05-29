
CREATE PROCEDURE [sub].[usp_RepServ_01_ParameterList_DeclarationStatus]

AS
/*	==========================================================================================
	Purpose:	List of declaration statuses for parameters on reports.

	14-03-2019	H. Melissen		Initial version.
	==========================================================================================	*/
DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Select the declaration statuses. */
SELECT	'0000' AS DeclarationStatusCode,
		'Alle' AS DeclarationStatusText

UNION ALL

SELECT	SettingCode AS DeclarationStatusCode,
		SettingValue AS DeclarationStatusText
FROM sub.tblApplicationSetting
WHERE SettingName = 'DeclarationStatus'

ORDER BY 1

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID
