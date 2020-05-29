CREATE TABLE [stip].[tblDeclaration_Mentor] (
    [DeclarationID] INT  NOT NULL,
    [MentorID]      INT  NOT NULL,
    [StartDate]     DATE NOT NULL,
    [EndDate]       DATE NULL,
    CONSTRAINT [PK_stip_tblDeclaration_Mentor] PRIMARY KEY CLUSTERED ([DeclarationID] ASC, [MentorID] ASC, [StartDate] ASC),
    CONSTRAINT [FK_stip_tblDeclaration_Mentor_tblDeclaration] FOREIGN KEY ([DeclarationID]) REFERENCES [sub].[tblDeclaration] ([DeclarationID])
);

