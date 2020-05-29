CREATE TABLE [eml].[tblEmailSetting] (
    [EmailSettingID]     INT           IDENTITY (1, 1) NOT NULL,
    [SettingName]        VARCHAR (50)  NOT NULL,
    [SettingCode]        VARCHAR (24)  NOT NULL,
    [SettingValue]       VARCHAR (100) NOT NULL,
    [SettingDescription] VARCHAR (MAX) NULL,
    CONSTRAINT [PK_eml_tblEmailSetting] PRIMARY KEY CLUSTERED ([EmailSettingID] ASC)
);

