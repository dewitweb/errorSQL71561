CREATE TABLE [sub].[tblApplicationSetting_Role] (
    [SettingName]  VARCHAR (50)  NOT NULL,
    [SettingCode]  VARCHAR (24)  NOT NULL,
    [RoleID]       INT           NOT NULL,
    [SettingValue] VARCHAR (100) NOT NULL,
    CONSTRAINT [PK_sub_tblApplicationSetting_Role] PRIMARY KEY CLUSTERED ([SettingName] ASC, [SettingCode] ASC, [RoleID] ASC)
);

