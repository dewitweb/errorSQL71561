
CREATE VIEW [sub].[viewApplicationSetting_SubsidyAmountPerEmployee]
AS

SELECT	aps.ApplicationSettingID,
		aps.SettingName,
		aps.SettingCode,
		aps.ApplicationID,
		apse.SettingValue,
		aps.SettingDescription,
		apse.SubsidySchemeID,
		apse.StartDate,
		apse.EndDate,
		apse.ReferenceDate
FROM	sub.tblApplicationSetting aps
INNER JOIN sub.tblApplicationSetting_Extended apse
	ON	apse.ApplicationSettingID = aps.ApplicationSettingID
WHERE	aps.SettingName = 'SubsidyAmountPerEmployee'
