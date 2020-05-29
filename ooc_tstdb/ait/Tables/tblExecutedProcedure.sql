CREATE TABLE [ait].[tblExecutedProcedure] (
    [ExecutedProcedureID] INT           IDENTITY (1, 1) NOT NULL,
    [ObjectID]            INT           NULL,
    [StartTime]           DATETIME2 (7) NULL,
    [StopTime]            DATETIME2 (7) NULL,
    CONSTRAINT [PK_tblProc] PRIMARY KEY CLUSTERED ([ExecutedProcedureID] ASC)
);

