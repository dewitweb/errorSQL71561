CREATE VIEW [sub].[viewApplicationSetting_SubsidyAmountPerType]
AS

SELECT	aps.ApplicationSettingID,
		aps.SettingName,
		aps.SettingCode,
		aps.ApplicationID,
		CAST(ISNULL(apse.SettingValue ,aps.SettingValue) as Money) SubsidyAmount,
		aps.SettingDescription,
		apse.SubsidySchemeID,
		apse.StartDate,
		apse.EndDate,
		apse.ReferenceDate
FROM	sub.tblApplicationSetting aps
LEFT JOIN sub.tblApplicationSetting_Extended apse
		ON	apse.ApplicationSettingID = aps.ApplicationSettingID
WHERE	aps.SettingName = 'SubsidyAmountPerType'

