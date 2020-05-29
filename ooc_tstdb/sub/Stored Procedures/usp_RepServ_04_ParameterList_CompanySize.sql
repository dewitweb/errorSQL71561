
CREATE proc [sub].[usp_RepServ_04_ParameterList_CompanySize]
AS

/*	==========================================================================================
	Purpose:	List with Company size

	07-06-2019	H. Melissen				'0000' added for 'Alle' option.
										Sort order changed to 1 instead of SortOrder field.
	05-06-2019	Jaap van Assenbergh	
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT	'0000' AS SettingCode,
		'Alle' AS SettingValue

UNION ALL

SELECT	SettingCode, SettingValue
FROM	sub.tblApplicationSetting
WHERE	SettingName = 'CompanySize'
ORDER BY 1

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== usp_RepServ_04_ParameterList_CompanySize ========================================================	*/
