CREATE TABLE [evcwv].[tblDeclaration] (
    [DeclarationID]      INT         NOT NULL,
    [MentorCode]         VARCHAR (4) NULL,
    [ParticipantID]      INT         NOT NULL,
    [OutflowPossibility] VARCHAR (4) NULL,
    CONSTRAINT [PK_evcwv_tblDeclaration] PRIMARY KEY CLUSTERED ([DeclarationID] ASC)
);

