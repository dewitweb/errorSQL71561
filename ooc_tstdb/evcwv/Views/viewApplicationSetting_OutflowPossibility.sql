CREATE VIEW [evcwv].[viewApplicationSetting_OutflowPossibility]
AS

SELECT	aps.ApplicationSettingID,
		aps.SettingName,
		aps.SettingCode,
		aps.ApplicationID,
		aps.SettingValue,
		aps.SettingDescription,
		aps.SortOrder
FROM	sub.tblApplicationSetting aps
WHERE	aps.SettingName = 'OutflowPossibility'

