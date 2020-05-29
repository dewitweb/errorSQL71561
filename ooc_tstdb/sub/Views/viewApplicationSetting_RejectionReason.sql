CREATE VIEW [sub].[viewApplicationSetting_RejectionReason]
AS

SELECT	aps.ApplicationSettingID,
		aps.SettingName,
		aps.SettingCode,
		aps.ApplicationID,
		aps.SettingValue,
		aps.SettingDescription,
		aps.SortOrder,
		ISNULL(apse.NotShownInProcessList, 0) NotShownInProcessList,
		ISNULL(apse.NotShownOnSpecification, 0) NotShownOnSpecification
FROM	sub.tblApplicationSetting aps
LEFT JOIN sub.tblApplicationSetting_Extended apse ON apse.ApplicationSettingID = aps.ApplicationSettingID
WHERE	aps.SettingName = 'RejectionReason'

