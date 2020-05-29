CREATE TABLE [sub].[tblSubsidyScheme_Institute] (
    [SubsidySchemeID] INT NOT NULL,
    [InstituteID]     INT NOT NULL,
    CONSTRAINT [PK_sub_tblSubsidyScheme_Institute] PRIMARY KEY CLUSTERED ([SubsidySchemeID] ASC, [InstituteID] ASC),
    CONSTRAINT [FK_sub_tblSubsidyScheme_Institute_tblInstitute] FOREIGN KEY ([InstituteID]) REFERENCES [sub].[tblInstitute] ([InstituteID]),
    CONSTRAINT [FK_sub_tblSubsidyScheme_Institute_tblSubsidyScheme] FOREIGN KEY ([SubsidySchemeID]) REFERENCES [sub].[tblSubsidyScheme] ([SubsidySchemeID])
);

