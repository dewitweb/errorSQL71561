CREATE VIEW [sub].[viewApplicationSetting_OTIB_Dashboard_KPI_Header]
AS

SELECT	aps.ApplicationSettingID,
		aps.SettingName,
		aps.SettingCode,
		aps.ApplicationID,
		aps.SettingValue,
		aps.SettingDescription,
		dsg.SettingCode		AS SettingCode_DeclarationStatusGroup,
		dsg.SettingValue	AS SettingValue_DeclarationStatusGroup
FROM	sub.tblApplicationSetting aps
LEFT JOIN sub.tblApplicationSetting_Extended apse ON apse.ApplicationSettingID = aps.ApplicationSettingID
LEFT JOIN sub.viewApplicationSetting_DeclarationStatusGroup dsg ON dsg.ApplicationSettingID = apse.ReferenceApplicationSettingID
WHERE	aps.SettingName = 'OTIB_Dashboard_KPI_Header'

