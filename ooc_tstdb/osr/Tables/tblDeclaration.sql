CREATE TABLE [osr].[tblDeclaration] (
    [DeclarationID]         INT           NOT NULL,
    [CourseID]              INT           NULL,
    [Location]              VARCHAR (100) NULL,
    [ElearningSubscription] BIT           NULL,
    CONSTRAINT [PK_osr_tblDeclaration] PRIMARY KEY CLUSTERED ([DeclarationID] ASC)
);

