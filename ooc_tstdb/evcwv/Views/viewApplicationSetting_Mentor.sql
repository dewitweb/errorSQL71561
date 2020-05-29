CREATE VIEW [evcwv].[viewApplicationSetting_Mentor]
AS

SELECT	aps.ApplicationSettingID,
		aps.SettingName,
		aps.SettingCode,
		aps.ApplicationID,
		aps.SettingValue,
		aps.SettingDescription,
		aps.SortOrder
FROM	sub.tblApplicationSetting aps
WHERE	aps.SettingName = 'EVC Mentor'
