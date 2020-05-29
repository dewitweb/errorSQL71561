CREATE VIEW [sub].[viewApplicationSetting_DeclarationStatus]
AS

SELECT	aps.ApplicationSettingID,
		aps.SettingName,
		aps.SettingCode,
		aps.ApplicationID,
		aps.SettingValue,
		aps.SettingDescription,
		ISNULL(apse.NotShownInProcessList, 0)	AS NotShownInProcessList,
		apse.SubsidySchemeID					AS SubsidySchemeID
FROM	sub.tblApplicationSetting aps
LEFT JOIN sub.tblApplicationSetting_Extended apse 
ON		apse.ApplicationSettingID = aps.ApplicationSettingID
WHERE	aps.SettingName = 'DeclarationStatus'

