
CREATE VIEW sub.viewApplicationSetting_ThumbnailSize
AS

SELECT	aps.ApplicationSettingID,
		aps.SettingName,
		aps.SettingCode,
		aps.ApplicationID,
		aps.SettingValue,
		aps.SettingDescription
FROM	sub.tblApplicationSetting aps
WHERE	aps.SettingName = 'ThumbnailSize'

