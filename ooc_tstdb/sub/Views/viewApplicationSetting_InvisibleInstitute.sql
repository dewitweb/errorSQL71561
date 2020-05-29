
--INSERT INTO [sub].[tblApplicationSetting]
--           ([SettingName]
--           ,[SettingCode]
--           ,[ApplicationID]
--           ,[SettingValue]
--           ,[SettingDescription]
--           ,[SortOrder])
--     VALUES
--           ('InvisibleInstitute'
--           ,'0001'
--           ,1
--           ,6873
--           ,'Fake institute for DS'
--           ,1)
--GO

CREATE VIEW [sub].[viewApplicationSetting_InvisibleInstitute]
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
WHERE	aps.SettingName = 'InvisibleInstitute'

