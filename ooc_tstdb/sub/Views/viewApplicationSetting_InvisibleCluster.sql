
CREATE VIEW [sub].[viewApplicationSetting_InvisibleCluster]
AS

SELECT	aps.ApplicationSettingID,
		aps.SettingName,
		aps.SettingCode,
		aps.ApplicationID,
		aps.SettingValue,
		aps.SettingDescription,
		ISNULL(apse.NotShownInProcessList, 0) NotShownInProcessList
FROM	sub.tblApplicationSetting aps
LEFT JOIN sub.tblApplicationSetting_Extended apse ON apse.ApplicationSettingID = aps.ApplicationSettingID
WHERE	aps.SettingName = 'InvisibleCluster'

