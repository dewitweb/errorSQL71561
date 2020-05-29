CREATE TABLE [stip].[tblDeclaration_BPV] (
    [DeclarationID]     INT          NOT NULL,
    [StartDate_BPV]     DATE         NOT NULL,
    [EndDate_BPV]       DATE         NOT NULL,
    [Extension]         BIT          DEFAULT ((0)) NOT NULL,
    [TerminationReason] VARCHAR (20) NULL,
    [TypeBPV]           VARCHAR (10) NULL,
    [EmployerNumber]    VARCHAR (6)  NULL,
    [CourseID]          INT          NULL,
    CONSTRAINT [PK_stip_tblDeclaration_BPV] PRIMARY KEY CLUSTERED ([DeclarationID] ASC),
    CONSTRAINT [FK_stip_tblDeclaration_BPV_tblDeclaration] FOREIGN KEY ([DeclarationID]) REFERENCES [sub].[tblDeclaration] ([DeclarationID])
);

