
CREATE PROCEDURE [sub].[usp_RepServ_07_ParameterList_SubsidyYear]
AS
/*	==========================================================================================
	Purpose:	List of subsidy years for parameters on reports.

	27-09-2019	Jaap van Assenbergh	Initial version.
	==========================================================================================	*/
DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Select OSR. */
SELECT	CASE
		WHEN DATEPART(YEAR, appe_eme.StartDate) = DATEPART(YEAR, appe_eme.EndDate) 
			THEN CONVERT(varchar(10), DATEPART(YEAR, appe_eme.StartDate)) 
		ELSE (CONVERT(varchar(4), DATEPART(YEAR, appe_eme.StartDate)) + '/') + CONVERT(varchar(4), DATEPART(YEAR,appe_eme.EndDate))
	END	SubsidyYear
FROM	sub.tblApplicationSetting apps_emp
INNER JOIN	sub.tblApplicationSetting_Extended appe_emp
		ON	appe_emp.ApplicationSettingID = apps_emp.ApplicationSettingID
		AND	apps_emp.SettingName = 'SubsidyAmountPerEmployer'
		AND	apps_emp.SettingCode = 'OSR'
INNER JOIN	sub.tblApplicationSetting apps_eme
		ON	apps_eme.SettingCode = apps_emp.SettingCode
		AND	apps_eme.SettingName = 'SubsidyAmountPerEmployee'
INNER JOIN	sub.tblApplicationSetting_Extended appe_eme
		ON	appe_eme.ApplicationSettingID = apps_eme.ApplicationSettingID
		AND	appe_eme.StartDate = appe_emp.StartDate
ORDER BY 1

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	==	sub.usp_RepServ_07_ParameterList_SubsidyYear =====================================	*/
