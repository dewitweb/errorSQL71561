CREATE TABLE [sub].[tblEncryptedSetting] (
    [EncryptedSettingID] INT             IDENTITY (1, 1) NOT NULL,
    [SettingName]        VARCHAR (50)    NOT NULL,
    [SettingCode]        VARCHAR (24)    NOT NULL,
    [ApplicationID]      INT             NOT NULL,
    [SettingValue]       VARBINARY (128) NULL,
    [SettingDescription] VARCHAR (MAX)   NULL,
    [StartDate]          DATE            NULL,
    [EndDate]            DATE            NULL,
    [SortOrder]          TINYINT         NULL,
    CONSTRAINT [PK_sub_tblEncryptedSetting] PRIMARY KEY CLUSTERED ([EncryptedSettingID] ASC)
);

