CREATE VIEW [sub].[viewApplicationSetting_DeclarationStatusGroup]
AS

SELECT	aps.ApplicationSettingID,
		aps.SettingName,
		aps.SettingCode,
		aps.ApplicationID,
		aps.SettingValue,
		aps.SettingDescription,
		aps.SortOrder,
		ds.SettingCode DeclarationStatus
FROM	sub.tblApplicationSetting aps
INNER JOIN	sub.tblApplicationSetting_Extended apse 
		ON	apse.ApplicationSettingID = aps.ApplicationSettingID
INNER JOIN	sub.tblApplicationSetting ds 
		ON	ds.ApplicationSettingID = apse.ReferenceApplicationSettingID
WHERE	aps.SettingName = 'DeclarationStatusGroup'



