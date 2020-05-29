CREATE VIEW [sub].[viewApplicationSetting_PartitionStatus]
AS

SELECT	TOP 1000
		aps.ApplicationSettingID,
		aps.SettingName,
		aps.SettingCode,
		aps.ApplicationID,
		aps.SettingValue,
		aps.SettingDescription,
		ISNULL(apse.NotShownInProcessList, 0) NotShownInProcessList,
		apse.SubsidySchemeID
FROM	sub.tblApplicationSetting aps
LEFT JOIN sub.tblApplicationSetting_Extended apse ON apse.ApplicationSettingID = aps.ApplicationSettingID
WHERE	aps.SettingName = 'PartitionStatus'
ORDER BY 
		aps.SettingName,
		aps.SettingCode
