CREATE TABLE [sub].[tblApplicationSetting_Extended] (
    [ApplicationSettingID]          INT           NOT NULL,
    [StartDate]                     DATE          NULL,
    [EndDate]                       DATE          NULL,
    [ReferenceDate]                 DATE          NULL,
    [ReferenceApplicationSettingID] INT           NULL,
    [NotShownInProcessList]         BIT           DEFAULT ((0)) NOT NULL,
    [SubsidySchemeID]               INT           NULL,
    [SettingValue]                  VARCHAR (100) NULL,
    [NotShownOnSpecification]       BIT           DEFAULT ((0)) NOT NULL,
    [InitialCalculation]            DATETIME      NULL,
    CONSTRAINT [FK_sub_tblApplicationSetting_Extended_tblApplicationSetting] FOREIGN KEY ([ApplicationSettingID]) REFERENCES [sub].[tblApplicationSetting] ([ApplicationSettingID]),
    CONSTRAINT [FK_sub_tblApplicationSetting_Extended_tblSubsidyScheme] FOREIGN KEY ([SubsidySchemeID]) REFERENCES [sub].[tblSubsidyScheme] ([SubsidySchemeID])
);


GO
CREATE CLUSTERED INDEX [CI_sub.tblApplicationSetting_Extended_ApplicationSettingID]
    ON [sub].[tblApplicationSetting_Extended]([ApplicationSettingID] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Concerns DeclarationStatus and RejectionReason. The item will not be shown when value = 1. In all other cases (0, NULL or no record) the item will be shown.', @level0type = N'SCHEMA', @level0name = N'sub', @level1type = N'TABLE', @level1name = N'tblApplicationSetting_Extended', @level2type = N'COLUMN', @level2name = N'NotShownInProcessList';

